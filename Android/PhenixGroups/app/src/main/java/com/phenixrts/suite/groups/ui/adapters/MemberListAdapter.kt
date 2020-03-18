/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.adapters

import android.view.*
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import androidx.lifecycle.viewModelScope
import androidx.recyclerview.widget.RecyclerView
import com.phenixrts.common.Disposable
import com.phenixrts.common.RequestStatus
import com.phenixrts.pcast.RendererStartStatus
import com.phenixrts.room.MemberState
import com.phenixrts.room.TrackState
import com.phenixrts.suite.groups.common.extensions.call
import com.phenixrts.suite.groups.common.getSubscribeAudioOptions
import com.phenixrts.suite.groups.common.getSubscribeVideoOptions
import com.phenixrts.suite.groups.databinding.RowMemberItemBinding
import com.phenixrts.suite.groups.models.RoomMember
import com.phenixrts.suite.groups.viewmodels.GroupsViewModel
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import timber.log.Timber
import kotlin.properties.Delegates

class MemberListAdapter(
    private val viewModel: GroupsViewModel,
    private val mainSurface: SurfaceView,
    private val callback: OnMemberListener
) : RecyclerView.Adapter<MemberListAdapter.ViewHolder>() {

    private val disposables: MutableList<Disposable> = mutableListOf()
    private val subscriptionsInProgress = arrayListOf<String>()

    var data: List<RoomMember> by Delegates.observable(emptyList(), { _, old, _ ->
        old.forEach { it.dispose() }
        dispose()
        viewModel.viewModelScope.launch(Dispatchers.Main) {
            delay(200)
            Timber.d("Member list updated: $data")
            notifyDataSetChanged()
        }
    })

    fun dispose() {
        disposables.forEach { it.dispose() }
        disposables.clear()
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        return ViewHolder(RowMemberItemBinding.inflate(LayoutInflater.from(parent.context)).apply {
            lifecycleOwner = parent.context as? LifecycleOwner
        })
    }

    override fun getItemCount() = data.size

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val roomMember = data[position]
        holder.binding.member = roomMember
        holder.binding.memberItem.tag = roomMember
        holder.binding.memberItem.setOnClickListener {
            val selectedMember = it.tag as RoomMember
            Timber.d("Member clicked: $selectedMember")
            callback.onMemberClicked(selectedMember)
        }
        subscribeToMember(holder.binding, position)
        updateMemberStream(roomMember, holder.binding.memberSurface)
    }

    private fun subscribeToMember(binding: RowMemberItemBinding, position: Int) {
        data.getOrNull(position)?.let { roomMember ->
            binding.lifecycleOwner?.let {
                if (!roomMember.onUpdate.hasActiveObservers()) {
                    roomMember.onUpdate.removeObservers(it)
                }
                Timber.d("Observing member: $roomMember")
                val memberStream = roomMember.member.observableStreams?.value?.get(0)
                roomMember.onUpdate.observe(it, Observer { restartRenderer ->
                    data.getOrNull(position)?.let { member ->
                        Timber.d("Member updated: $member $restartRenderer")
                        binding.member = member
                        if (restartRenderer) {
                            updateMemberStream(member, binding.memberSurface)
                        }
                    }
                })

                roomMember.member.observableState?.subscribe {
                    viewModel.viewModelScope.launch {
                        data.getOrNull(position)?.let { member ->
                            if (member.canRenderVideo != (it == MemberState.ACTIVE)) {
                                Timber.d("Active state changed: $member state: $it")
                                member.canRenderVideo = it == MemberState.ACTIVE
                                member.onUpdate.call()
                            }
                        }
                    }
                }?.run {
                    disposables.add(this)
                    Timber.d("Updating active disposable: ${disposables.size}")
                }

                memberStream?.observableVideoState?.subscribe {
                    viewModel.viewModelScope.launch {
                        data.getOrNull(position)?.let { member ->
                            Timber.d("Video state changed: $member state: $it")
                            // TODO: This is called when audio stream is disabled which is wrong
                            // member.canRenderVideo = it == TrackState.ENABLED
                            // member.onUpdate.call()
                        }
                    }
                }?.run {
                    disposables.add(this)
                    Timber.d("Updating video disposable: ${disposables.size}")
                }

                memberStream?.observableAudioState?.subscribe {
                    viewModel.viewModelScope.launch {
                        data.getOrNull(position)?.let { member ->
                            if (member.isMuted != (it == TrackState.DISABLED)) {
                                Timber.d("Audio state changed: $member state: $it")
                                member.isMuted = it == TrackState.DISABLED
                                member.onUpdate.call(false)
                            }
                        }
                    }
                }?.run {
                    disposables.add(this)
                    Timber.d("Updating audio disposable: ${disposables.size}")
                }
            }
        }
    }

    private fun updateMemberStream(roomMember: RoomMember, surfaceView: SurfaceView) = viewModel.viewModelScope.launch(Dispatchers.Main) {
        if (subscriptionsInProgress.contains(roomMember.member.sessionId)) {
            return@launch
        }
        Timber.d("Updating member stream: $roomMember $surfaceView ${surfaceView.holder} $subscriptionsInProgress")
        subscriptionsInProgress.add(roomMember.member.sessionId)
        val isSelf = roomMember.member.sessionId == viewModel.currentSessionsId.value
        var status = if (roomMember.canRenderVideo) RequestStatus.OK else RequestStatus.FAILED
        if (!roomMember.isSubscribed() && !isSelf) {
            val options = if (roomMember.canRenderVideo) {
                getSubscribeVideoOptions(surfaceView.holder)
            } else {
                getSubscribeAudioOptions()
            }
            status = viewModel.subscribeToMemberStream(roomMember, options).status
        }
        Timber.d("Subscribed to member stream: $status")
        if (status != RequestStatus.OK && roomMember.canRenderVideo) {
            Timber.d("Member video stream ended: $roomMember")
            roomMember.canRenderVideo = false
            roomMember.onUpdate.call()
        } else if (status == RequestStatus.OK) {
            val holder = if (roomMember.isActiveRenderer) mainSurface.holder else surfaceView.holder
            if (isSelf) {
                status = viewModel.startUserMediaPreview(holder).status
            } else {
                viewModel.restartMediaRenderer(roomMember.renderer, holder).let {
                    if (it != RendererStartStatus.OK) {
                        status = RequestStatus.FAILED
                    }
                }
            }

            Timber.d("Restarted member renderer: $status $roomMember isSelf: $isSelf")
            launch(Dispatchers.Main) {
                if (status == RequestStatus.OK) {
                    Timber.d("Showing surface: $roomMember")
                    if (!roomMember.canRenderVideo) {
                        roomMember.canRenderVideo = true
                        roomMember.onUpdate.call()
                    }
                    if (roomMember.isActiveRenderer) {
                        mainSurface.visibility = View.VISIBLE
                    }
                } else {
                    Timber.d("Hiding surface: $roomMember")
                    if (roomMember.canRenderVideo) {
                        roomMember.canRenderVideo = false
                        roomMember.onUpdate.call()
                    }
                    if (roomMember.isActiveRenderer) {
                        mainSurface.visibility = View.GONE
                    }
                }
            }
        }
        subscriptionsInProgress.remove(roomMember.member.sessionId)
    }

    inner class ViewHolder(val binding: RowMemberItemBinding) : RecyclerView.ViewHolder(binding.root)

    interface OnMemberListener {
        fun onMemberClicked(roomMember: RoomMember)
    }

}
