/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.adapters

import android.view.*
import android.widget.ImageView
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.Observer
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.RecyclerView
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

    var members: List<RoomMember> by Delegates.observable(emptyList()) { _, old, new ->
        DiffUtil.calculateDiff(RoomMemberDiff(old, new)).dispatchUpdatesTo(this)
    }

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
        holder.binding.lifecycleOwner?.let { owner ->
            holder.binding.member?.onUpdate?.observe(owner, Observer {
                Timber.d("Member updated: $roomMember :: ${holder.binding.member}")
                holder.binding.refresh()
                updateMemberStream(roomMember)
            })
        }
        updateMemberStream(roomMember)
        roomMember.setSurfaces(mainSurface.holder, holder.binding.memberSurface.holder)
    }

    private fun updateMemberStream(roomMember: RoomMember) {
        roomMember.launch {
            if (subscriptionsInProgress.contains(roomMember.member.sessionId)) {
                return@launch
            }
            subscriptionsInProgress.add(roomMember.member.sessionId)
            val isSelf = roomMember.member.sessionId == viewModel.currentSessionsId.value

            // Subscribe to member media if not self member and not subscribed yet
            if (!roomMember.isSubscribed() && !isSelf) {
                val options = if (roomMember.canRenderVideo) {
                    getSubscribeVideoOptions()
                } else {
                    getSubscribeAudioOptions()
                }
                viewModel.subscribeToMemberStream(roomMember, options).status
                Timber.d("Subscribed to member media")
            }

            if (isSelf) {
                val surface = if (roomMember.isActiveRenderer) roomMember.mainSurface else roomMember.previewSurface
                viewModel.startUserMediaPreview(surface)
            } else {
                roomMember.startMemberRenderer()
            }

            // Update active renderer
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
            }

            Timber.d("Updated member renderer $roomMember isSelf: $isSelf")
            subscriptionsInProgress.remove(roomMember.member.sessionId)
        }
    }

    inner class ViewHolder(val binding: RowMemberItemBinding) : RecyclerView.ViewHolder(binding.root)

    inner class RoomMemberDiff(private val oldItems: List<RoomMember>,
                               private val newItems: List<RoomMember>
    ) : DiffUtil.Callback() {

        override fun getOldListSize() = oldItems.size

        override fun getNewListSize() = newItems.size

        override fun areItemsTheSame(oldItemPosition: Int, newItemPosition: Int): Boolean {
            return oldItems[oldItemPosition].member.sessionId == newItems[newItemPosition].member.sessionId
        }

        override fun areContentsTheSame(oldItemPosition: Int, newItemPosition: Int): Boolean {
            return oldItems[oldItemPosition] == newItems[newItemPosition]
        }
    }

    interface OnMemberListener {
        fun onMemberClicked(roomMember: RoomMember)
    }

}
