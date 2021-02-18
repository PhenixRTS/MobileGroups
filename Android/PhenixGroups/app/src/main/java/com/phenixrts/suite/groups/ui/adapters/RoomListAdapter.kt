/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.adapters

import android.view.LayoutInflater
import android.view.ViewGroup
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.RecyclerView
import com.phenixrts.suite.groups.databinding.RowRoomItemBinding
import com.phenixrts.suite.groups.cache.entities.RoomInfoItem
import kotlin.properties.Delegates

class RoomListAdapter(private val callback: OnRoomJoin) : RecyclerView.Adapter<RoomListAdapter.ViewHolder>() {

    var data: List<RoomInfoItem> by Delegates.observable(emptyList()) { _, old, new ->
        DiffUtil.calculateDiff(RoomInfoDiff(old, new)).dispatchUpdatesTo(this)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        return ViewHolder(RowRoomItemBinding.inflate(LayoutInflater.from(parent.context), parent, false))
    }

    override fun getItemCount() = data.size

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.binding.room = data[position]
        holder.binding.roomRejoinButton.tag = data[position].roomId
        holder.binding.roomRejoinButton.setOnClickListener {
            callback.onRoomJoinClicked(it.tag as String)
        }
    }

    class ViewHolder(val binding: RowRoomItemBinding) : RecyclerView.ViewHolder(binding.root)

    class RoomInfoDiff(private val oldItems: List<RoomInfoItem>,
                             private val newItems: List<RoomInfoItem>
    ) : DiffUtil.Callback() {

        override fun getOldListSize() = oldItems.size

        override fun getNewListSize() = newItems.size

        override fun areItemsTheSame(oldItemPosition: Int, newItemPosition: Int): Boolean {
            return oldItems[oldItemPosition].roomId == newItems[newItemPosition].roomId
        }

        override fun areContentsTheSame(oldItemPosition: Int, newItemPosition: Int): Boolean {
            return oldItems[oldItemPosition] == newItems[newItemPosition]
        }
    }

    interface OnRoomJoin {
        fun onRoomJoinClicked(roomId: String)
    }
}
