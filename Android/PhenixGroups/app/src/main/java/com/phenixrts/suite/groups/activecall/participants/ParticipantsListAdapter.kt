/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.activecall.participants

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.databinding.ObservableList
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.Transformations
import androidx.recyclerview.widget.RecyclerView
import com.phenixrts.suite.groups.databinding.GroupCallParticipantRecordBinding
import com.phenixrts.suite.groups.models.Participant
import com.phenixrts.suite.groups.utils.ListObservableRecyclerViewAdapter

open class ParticipantsListAdapter(
    private val data: ObservableList<Participant>,
    private val selected: MutableLiveData<Participant>
) : ListObservableRecyclerViewAdapter<Participant, ParticipantsListAdapter.ViewHolder>(data) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        return ViewHolder(GroupCallParticipantRecordBinding.inflate(LayoutInflater.from(parent.context)).apply {
            lifecycleOwner = parent.context as? LifecycleOwner
        })
    }

    override fun getItemCount() = data.size

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val participant = data[position]

        holder.bind.apply {
            this.participant = participant
            isActive = Transformations.map(selected) {
                participant == selected.value
            }
        }
    }

    inner class ViewHolder(val bind: GroupCallParticipantRecordBinding) :
        RecyclerView.ViewHolder(bind.root) {

        init {
            itemView.setOnClickListener { selected.value = bind.participant }
        }
    }
}