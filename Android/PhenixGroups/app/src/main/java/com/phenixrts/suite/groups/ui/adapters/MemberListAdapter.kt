/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.adapters

import android.view.*
import android.widget.ImageView
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import androidx.recyclerview.widget.RecyclerView
import com.phenixrts.suite.groups.common.extensions.isFalse
import com.phenixrts.suite.groups.common.extensions.isTrue
import com.phenixrts.suite.groups.common.extensions.launchMain
import com.phenixrts.suite.groups.common.extensions.refresh
import com.phenixrts.suite.groups.common.getSubscribeAudioOptions
import com.phenixrts.suite.groups.common.getSubscribeVideoOptions
import com.phenixrts.suite.groups.databinding.RowMemberItemBinding
import com.phenixrts.suite.groups.models.RoomMember
import com.phenixrts.suite.groups.viewmodels.GroupsViewModel
import timber.log.Timber
import kotlin.properties.Delegates

class MemberListAdapter(
    private val viewModel: GroupsViewModel,
    private val mainSurface: SurfaceView,
    private val micIcon: ImageView,
    private val callback: OnMemberListener
) : RecyclerView.Adapter<MemberListAdapter.ViewHolder>() {

    private val subscriptionsInProgress = arrayListOf<String>()

    var members: List<RoomMember> by Delegates.observable(emptyList()) { _, _, _ ->
        notifyDataSetChanged()
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
        roomMember.setSurfaces(mainSurface.holder, holder.binding.memberSurface)
        holder.binding.lifecycleOwner?.let { owner ->
            holder.binding.member?.onUpdate?.observe(owner, Observer { member ->
                Timber.d("Member updated: $member")
                holder.binding.refresh()
                updateMemberStream(member)
            })
        }
        holder.binding.lifecycleOwner?.let { owner ->
            holder.binding.member?.audioLevel?.observe(owner, Observer { volume ->
                holder.binding.memberVolumeIndicator.setImageResource(volume.icon)
                holder.binding.refresh()
            })
        }
        updateMemberStream(roomMember)
    }

    private fun updateMemberStream(roomMember: RoomMember) {
        launchMain {
            if (subscriptionsInProgress.contains(roomMember.member.sessionId) || viewModel.isInRoom.isFalse()) {
                return@launchMain
            }
            subscriptionsInProgress.add(roomMember.member.sessionId)

            // Subscribe to member media if not subscribed yet
            if (!roomMember.isSubscribed()) {
                val options = if (roomMember.canRenderVideo) {
                    getSubscribeVideoOptions()
                } else {
                    getSubscribeAudioOptions()
                }
                val status = viewModel.subscribeToMemberStream(roomMember, options)
                Timber.d("Subscribed to member media: $status")
            }

            Timber.d("Starting member preview: $roomMember")
            roomMember.startMemberRenderer()

            // Update member surfaces
            if (viewModel.isInRoom.isTrue()) {
                if (roomMember.isActiveRenderer) {
                    // Update main surface visibility
                    if (roomMember.canShowPreview) {
                        Timber.d("Showing main surface: $roomMember")
                        mainSurface.visibility = View.VISIBLE
                    } else {
                        Timber.d("Hiding main surface: $roomMember")
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
                } else {
                    roomMember.previewSurfaceView?.visibility = if (roomMember.isOffscreen) View.GONE else View.VISIBLE
                }
            }
            Timber.d("Updated member renderer $roomMember")
            subscriptionsInProgress.remove(roomMember.member.sessionId)
        }
    }

    fun hidePreviews(hide: Boolean) {
        Timber.d("Hiding surfaces: $hide")
        members.forEach { it.isOffscreen = hide }
        notifyDataSetChanged()
    }

    inner class ViewHolder(val binding: RowMemberItemBinding) : RecyclerView.ViewHolder(binding.root)

    interface OnMemberListener {
        fun onMemberClicked(roomMember: RoomMember)
    }

}
