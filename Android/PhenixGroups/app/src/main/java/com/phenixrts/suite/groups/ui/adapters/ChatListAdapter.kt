/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.adapters

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.lifecycle.LifecycleOwner
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.RecyclerView
import com.phenixrts.chat.ChatMessage
import com.phenixrts.suite.groups.databinding.RowChatMessageItemBinding
import com.phenixrts.suite.groups.viewmodels.GroupsViewModel
import kotlin.properties.Delegates

class ChatListAdapter(private val viewModel: GroupsViewModel) : RecyclerView.Adapter<ChatListAdapter.ViewHolder>() {

    var data: List<ChatMessage> by Delegates.observable(emptyList()) { _, old, new ->
        DiffUtil.calculateDiff(ChatMessageDiff(old, new)).dispatchUpdatesTo(this)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        return ViewHolder(RowChatMessageItemBinding.inflate(LayoutInflater.from(parent.context)).apply {
            lifecycleOwner = parent.context as? LifecycleOwner
        })
    }

    override fun getItemCount() = data.size

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.binding.chatMessage = data[position]
        holder.binding.isLocal = viewModel.displayName.value == data[position].observableFrom.value.observableScreenName.value
    }

    inner class ViewHolder(val binding: RowChatMessageItemBinding) : RecyclerView.ViewHolder(binding.root)

    inner class ChatMessageDiff(private val oldItems: List<ChatMessage>,
                                private val newItems: List<ChatMessage>
    ) : DiffUtil.Callback() {

        override fun getOldListSize() = oldItems.size

        override fun getNewListSize() = newItems.size

        override fun areItemsTheSame(oldItemPosition: Int, newItemPosition: Int): Boolean {
            return oldItems[oldItemPosition].messageId == newItems[newItemPosition].messageId
        }

        override fun areContentsTheSame(oldItemPosition: Int, newItemPosition: Int): Boolean {
            return oldItems[oldItemPosition] == newItems[newItemPosition]
        }
    }
}
