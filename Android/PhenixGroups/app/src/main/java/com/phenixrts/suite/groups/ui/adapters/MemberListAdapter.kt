/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.adapters

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.viewModelScope
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.RecyclerView
import com.phenixrts.room.MemberState
import com.phenixrts.room.TrackState
import com.phenixrts.suite.groups.databinding.RowMemberItemBinding
import com.phenixrts.suite.groups.models.RoomMember
import com.phenixrts.suite.groups.viewmodels.GroupsViewModel
import kotlinx.coroutines.launch
import timber.log.Timber
import kotlin.properties.Delegates

class MemberListAdapter(
    private val viewModel: GroupsViewModel,
    private val callback: OnMemberListener
) : RecyclerView.Adapter<MemberListAdapter.ViewHolder>() {

    var data: List<RoomMember> by Delegates.observable(emptyList()) { _, old, new ->
        DiffUtil.calculateDiff(MemberListDiff(old, new)).dispatchUpdatesTo(this)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        return ViewHolder(RowMemberItemBinding.inflate(LayoutInflater.from(parent.context)).apply {
            lifecycleOwner = parent.context as? LifecycleOwner
        })
    }

    override fun getItemCount() = data.size

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.binding.member = data[position].member
        val isActive = MutableLiveData<Boolean>()
        val isMicOn = MutableLiveData<Boolean>()
        data[position].member.observableState?.subscribe {
            viewModel.viewModelScope.launch {
                isActive.value = it == MemberState.ACTIVE
            }
        }
        data[position].member.observableStreams?.value?.get(0)?.observableAudioState?.subscribe {
            viewModel.viewModelScope.launch {
                isMicOn.value = it == TrackState.ENABLED
            }
        }
        holder.binding.isActive = isActive
        holder.binding.isMicOn = isMicOn
        holder.binding.memberItem.tag = data[position]
        holder.binding.memberItem.setOnClickListener {
            val roomMember = it.tag as RoomMember
            Timber.d("Member clicked: $roomMember")
            callback.onMemberClicked(roomMember)
        }
    }

    inner class ViewHolder(val binding: RowMemberItemBinding) : RecyclerView.ViewHolder(binding.root)

    inner class MemberListDiff(private val oldItems: List<RoomMember>,
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
