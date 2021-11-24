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
import com.phenixrts.suite.groups.common.AdapterDiff
import kotlin.properties.Delegates

class RoomListAdapter(
    private val onRoomJoinClicked: (String) -> Unit
) : RecyclerView.Adapter<RoomListAdapter.ViewHolder>() {

    var data: List<RoomInfoItem> by Delegates.observable(emptyList()) { _, old, new ->
        DiffUtil.calculateDiff(
            AdapterDiff(old, new) { oldItem, newItem ->
                oldItem.roomId == newItem.roomId
            }
        ).dispatchUpdatesTo(this)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        return ViewHolder(RowRoomItemBinding.inflate(LayoutInflater.from(parent.context), parent, false))
    }

    override fun getItemCount() = data.size

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        holder.binding.room = data[position]
        holder.binding.roomRejoinButton.tag = data[position].alias
        holder.binding.roomRejoinButton.setOnClickListener {
            onRoomJoinClicked(it.tag as String)
        }
    }

    class ViewHolder(val binding: RowRoomItemBinding) : RecyclerView.ViewHolder(binding.root)
}
