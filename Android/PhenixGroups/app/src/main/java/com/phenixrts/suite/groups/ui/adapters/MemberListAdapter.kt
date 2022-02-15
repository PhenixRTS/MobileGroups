/*
 * Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.adapters

import android.annotation.SuppressLint
import android.view.*
import android.widget.ImageView
import androidx.lifecycle.LifecycleOwner
import androidx.recyclerview.widget.DiffUtil
import androidx.recyclerview.widget.RecyclerView
import com.phenixrts.suite.groups.common.AdapterDiff
import com.phenixrts.suite.groups.databinding.RowMemberItemBinding
import com.phenixrts.suite.phenixcore.repositories.models.PhenixMember
import timber.log.Timber
import kotlin.properties.Delegates

@SuppressLint("NotifyDataSetChanged")
class MemberListAdapter(
    private val onMemberClicked: (PhenixMember) -> Unit,
    private val onMemberDrawn: (PhenixMember, ImageView) -> Unit
) : RecyclerView.Adapter<MemberListAdapter.ViewHolder>() {

    var members: List<PhenixMember> by Delegates.observable(emptyList()) { _, old, new ->
        DiffUtil.calculateDiff(
            AdapterDiff(old, new) { oldItem, newItem ->
                oldItem.id == newItem.id
            }
        ).dispatchUpdatesTo(this)
    }

    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        return ViewHolder(RowMemberItemBinding.inflate(LayoutInflater.from(parent.context)).apply {
            lifecycleOwner = parent.context as? LifecycleOwner
        })
    }

    override fun getItemCount() = members.size

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val member = members[position]
        holder.binding.member = member
        holder.binding.memberItem.tag = member
        holder.binding.memberItem.setOnClickListener {
            val selectedMember = it.tag as PhenixMember
            Timber.d("Member clicked: $selectedMember")
            onMemberClicked(selectedMember)
        }
        onMemberDrawn(member, holder.binding.memberSurface)
    }

    class ViewHolder(val binding: RowMemberItemBinding) : RecyclerView.ViewHolder(binding.root)

}
