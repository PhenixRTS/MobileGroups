/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.adapters

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.lifecycle.LifecycleOwner
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.RecyclerView
import com.phenixrts.suite.groups.databinding.RowChatMessageItemBinding
import com.phenixrts.suite.groups.models.RoomMessage
import kotlin.properties.Delegates

class ChatListAdapter : RecyclerView.Adapter<ChatListAdapter.ViewHolder>() {

    var data: List<RoomMessage> by Delegates.observable(emptyList()) { _, old, new ->
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
    }

    class ViewHolder(val binding: RowChatMessageItemBinding) : RecyclerView.ViewHolder(binding.root)

    class ChatMessageDiff(
        private val oldItems: List<RoomMessage>,
        private val newItems: List<RoomMessage>
    ) : DiffUtil.Callback() {

        override fun getOldListSize() = oldItems.size

        override fun getNewListSize() = newItems.size

        override fun areItemsTheSame(oldItemPosition: Int, newItemPosition: Int): Boolean {
            return oldItems[oldItemPosition].message.messageId == newItems[newItemPosition].message.messageId
        }

        override fun areContentsTheSame(oldItemPosition: Int, newItemPosition: Int): Boolean {
            return oldItems[oldItemPosition] == newItems[newItemPosition]
        }
    }
}
