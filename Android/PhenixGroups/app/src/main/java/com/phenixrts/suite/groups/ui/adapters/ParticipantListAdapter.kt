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
import com.phenixrts.room.Member
import com.phenixrts.room.MemberState
import com.phenixrts.room.Stream
import com.phenixrts.room.TrackState
import com.phenixrts.suite.groups.databinding.RowParticipantItemBinding
import com.phenixrts.suite.groups.viewmodels.GroupsViewModel
import kotlinx.coroutines.launch
import timber.log.Timber
import kotlin.properties.Delegates

class ParticipantListAdapter(
    private val viewModel: GroupsViewModel,
    private val callback: OnParticipant
) : RecyclerView.Adapter<ParticipantListAdapter.ViewHolder>() {

    var data: List<Member> by Delegates.observable(emptyList()) { _, old, new ->
        DiffUtil.calculateDiff(ChatMessageDiff(old, new)).dispatchUpdatesTo(this)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        return ViewHolder(RowParticipantItemBinding.inflate(LayoutInflater.from(parent.context)).apply {
            lifecycleOwner = parent.context as? LifecycleOwner
        })
    }

    override fun getItemCount() = data.size

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.binding.participant = data[position]
        val isActive = MutableLiveData<Boolean>()
        val isMicOn = MutableLiveData<Boolean>()
        data[position].observableState?.subscribe {
            viewModel.viewModelScope.launch {
                isActive.value = it == MemberState.ACTIVE
            }
        }
        data[position].observableStreams?.value?.get(0)?.observableAudioState?.subscribe {
            viewModel.viewModelScope.launch {
                isMicOn.value = it == TrackState.ENABLED
            }
        }
        holder.binding.isActive = isActive
        holder.binding.isMicOn = isMicOn
        holder.binding.participantItem.setOnClickListener {
            val participant = data[position]
            Timber.d("Participant clicked: $participant")
            callback.onParticipantClicked(participant.observableStreams.value.getOrNull(0),
                participant.observableScreenName.value == viewModel.displayName.value)
        }
    }

    inner class ViewHolder(val binding: RowParticipantItemBinding) : RecyclerView.ViewHolder(binding.root)

    inner class ChatMessageDiff(private val oldItems: List<Member>,
                                private val newItems: List<Member>
    ) : DiffUtil.Callback() {

        override fun getOldListSize() = oldItems.size

        override fun getNewListSize() = newItems.size

        override fun areItemsTheSame(oldItemPosition: Int, newItemPosition: Int): Boolean {
            return oldItems[oldItemPosition].observableScreenName.value == newItems[newItemPosition].observableScreenName.value
        }

        override fun areContentsTheSame(oldItemPosition: Int, newItemPosition: Int): Boolean {
            return oldItems[oldItemPosition] == newItems[newItemPosition]
        }
    }

    interface OnParticipant {
        fun onParticipantClicked(stream: Stream?, isSelf: Boolean)
    }
}
