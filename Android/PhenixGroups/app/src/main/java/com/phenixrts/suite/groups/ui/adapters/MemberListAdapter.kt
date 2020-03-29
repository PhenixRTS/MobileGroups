/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.adapters

import android.view.*
import android.widget.ImageView
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import androidx.lifecycle.viewModelScope
import androidx.recyclerview.widget.RecyclerView
import com.phenixrts.common.RequestStatus
import com.phenixrts.pcast.RendererStartStatus
import com.phenixrts.room.MemberState
import com.phenixrts.room.TrackState
import com.phenixrts.suite.groups.common.extensions.call
import com.phenixrts.suite.groups.common.getSubscribeAudioOptions
import com.phenixrts.suite.groups.common.getSubscribeToMemberOptions
import com.phenixrts.suite.groups.databinding.RowMemberItemBinding
import com.phenixrts.suite.groups.models.RoomMember
import com.phenixrts.suite.groups.viewmodels.GroupsViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import timber.log.Timber
import kotlin.properties.Delegates

class MemberListAdapter(
    private val viewModel: GroupsViewModel,
    private val mainSurface: SurfaceView,
    private val micIcon: ImageView,
    private val callback: OnMemberListener
) : RecyclerView.Adapter<MemberListAdapter.ViewHolder>() {

    private val subscriptionsInProgress = arrayListOf<String>()

    var members: List<RoomMember> by Delegates.observable(emptyList(), { _, _, _ ->
        notifyDataSetChanged()
    })

    fun dispose() {
        members.forEach { it.dispose() }
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        return ViewHolder(RowMemberItemBinding.inflate(LayoutInflater.from(parent.context)).apply {
            lifecycleOwner = parent.context as? LifecycleOwner
        })
    }

    override fun getItemCount() = members.size

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val roomMember = members[position]
        holder.binding.member = roomMember
        holder.binding.memberItem.tag = roomMember
        holder.binding.memberItem.setOnClickListener {
            val selectedMember = it.tag as RoomMember
            Timber.d("Member clicked: $selectedMember")
            callback.onMemberClicked(selectedMember)
        }
        roomMember.setSurfaces(mainSurface.holder, holder.binding.memberSurface.holder)
        subscribeToMember(holder.binding, position)
        updateMemberStream(roomMember)
    }

    private fun subscribeToMember(binding: RowMemberItemBinding, position: Int) {
        members.getOrNull(position)?.let { roomMember ->
            binding.lifecycleOwner?.let {
                if (roomMember.onUpdate.hasActiveObservers()) {
                    Timber.d("Removing active observers for: $roomMember")
                    roomMember.onUpdate.removeObservers(it)
                    roomMember.dispose()
                }
                Timber.d("Observing member: $roomMember")
                val memberStream = roomMember.member.observableStreams?.value?.get(0)
                roomMember.onUpdate.observe(it, Observer { restartRenderer ->
                    members.getOrNull(position)?.let { member ->
                        Timber.d("Member updated: $member $restartRenderer")
                        binding.member = member
                        updateMemberStream(member)

                        // Update mic icon
                        if (roomMember.isActiveRenderer) {
                            if (roomMember.isMuted) {
                                micIcon.visibility = View.VISIBLE
                            } else {
                                micIcon.visibility = View.GONE
                            }
                        }
                    }
                })

                roomMember.member.observableState?.subscribe {
                    viewModel.viewModelScope.launch {
                        members.getOrNull(position)?.let { member ->
                            if (member.canRenderVideo && member.canShowPreview != (it == MemberState.ACTIVE)) {
                                Timber.d("Active state changed: $member state: $it")
                                member.canShowPreview = it == MemberState.ACTIVE
                                member.onUpdate.call()
                            }
                        }
                    }
                }?.run { roomMember.addDisposable(this) }

                memberStream?.observableVideoState?.subscribe {
                    viewModel.viewModelScope.launch {
                        members.getOrNull(position)?.let { member ->
                            if (member.canRenderVideo && member.canShowPreview != (it == TrackState.ENABLED)) {
                                Timber.d("Video state changed: $member state: $it")
                                member.canShowPreview = it == TrackState.ENABLED
                                member.onUpdate.call()
                            }
                        }
                    }
                }?.run { roomMember.addDisposable(this) }

                memberStream?.observableAudioState?.subscribe {
                    viewModel.viewModelScope.launch {
                        members.getOrNull(position)?.let { member ->
                            if (member.isMuted != (it == TrackState.DISABLED)) {
                                Timber.d("Audio state changed: $member state: $it")
                                member.isMuted = it == TrackState.DISABLED
                                member.onUpdate.call(false)
                            }
                        }
                    }
                }?.run { roomMember.addDisposable(this) }
            }
        }
    }

    private fun updateMemberStream(roomMember: RoomMember)
            = viewModel.viewModelScope.launch(Dispatchers.Main) {
        if (subscriptionsInProgress.contains(roomMember.member.sessionId)) {
            return@launch
        }

        Timber.d("Updating member stream: $roomMember")
        subscriptionsInProgress.add(roomMember.member.sessionId)
        val isSelf = roomMember.member.sessionId == viewModel.currentSessionsId.value
        var status = if (roomMember.canShowPreview) RequestStatus.OK else RequestStatus.FAILED

        // Subscribe to member media if not self member and not subscribed yet
        if (!roomMember.isSubscribed() && !isSelf) {
            val options = if (roomMember.canRenderVideo) {
                getSubscribeToMemberOptions()
            } else {
                getSubscribeAudioOptions()
            }
            status = viewModel.subscribeToMemberStream(roomMember, options).status
            Timber.d("Subscribed to member media: $status")
        }

        // Update member media renderer if all is good
        if (status == RequestStatus.OK && roomMember.canShowPreview) {
            if (isSelf) {
                status = viewModel.startUserMediaPreview(if (roomMember.isActiveRenderer)
                    roomMember.mainSurface else roomMember.previewSurface).status
            } else {
                roomMember.startMemberRenderer().takeIf { it != RendererStartStatus.OK }?.let {
                    status = RequestStatus.FAILED
                }
            }
        }

        // Update active renderer
        if (roomMember.isActiveRenderer) {
            if (status == RequestStatus.OK) {
                Timber.d("Showing surface: $roomMember")
                mainSurface.visibility = View.VISIBLE
            } else {
                Timber.d("Hiding surface: $roomMember")
                mainSurface.visibility = View.GONE
            }
            // Update display name
            viewModel.displayName.value = roomMember.member.observableScreenName.value
            // Update mic icon
            if (roomMember.isMuted) {
                micIcon.visibility = View.VISIBLE
            } else {
                micIcon.visibility = View.GONE
            }
        }

        Timber.d("Updated member renderer: $status $roomMember isSelf: $isSelf")
        subscriptionsInProgress.remove(roomMember.member.sessionId)
    }

    inner class ViewHolder(val binding: RowMemberItemBinding) : RecyclerView.ViewHolder(binding.root)

    interface OnMemberListener {
        fun onMemberClicked(roomMember: RoomMember)
    }

}
