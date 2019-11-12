/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.activecall.chat

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.databinding.ObservableList
import androidx.lifecycle.LifecycleOwner
import androidx.recyclerview.widget.RecyclerView
import com.phenixrts.suite.groups.databinding.GroupCallChatMessageRecordBinding
import com.phenixrts.suite.groups.models.ChatMessage
import com.phenixrts.suite.groups.utils.ListObservableRecyclerViewAdapter

open class ChatListAdapter(
    private val data: ObservableList<ChatMessage>
) : ListObservableRecyclerViewAdapter<ChatMessage, ChatListAdapter.ViewHolder>(data) {

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        return ViewHolder(GroupCallChatMessageRecordBinding.inflate(LayoutInflater.from(parent.context)).apply {
            lifecycleOwner = parent.context as? LifecycleOwner
        })
    }

    override fun getItemCount() = data.size

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.bind.apply {
            this.chatMessage = data[position]
        }
    }

    inner class ViewHolder(val bind: GroupCallChatMessageRecordBinding) :
        RecyclerView.ViewHolder(bind.root)
}