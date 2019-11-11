/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.utils

import android.util.Log
import androidx.databinding.ObservableList
import androidx.recyclerview.widget.RecyclerView

abstract class ListObservableRecyclerViewAdapter<T, VH : RecyclerView.ViewHolder?>(private val data: ObservableList<T>) :
    RecyclerView.Adapter<VH>() {

    private val TAG: String by lazy { this::class.java.simpleName }

    private val onListChanged = OnDataSetChange()

    init {
        data.addOnListChangedCallback(onListChanged)
    }

    override fun getItemCount() = data.size

    inner class OnDataSetChange : ObservableList.OnListChangedCallback<ObservableList<T>>() {
        override fun onChanged(sender: ObservableList<T>?) {
            Log.d(TAG, "onChanged()")
            notifyDataSetChanged()
        }

        override fun onItemRangeRemoved(
            sender: ObservableList<T>?,
            positionStart: Int,
            itemCount: Int
        ) {
            Log.d(TAG, "onItemRangeRemoved()")
            notifyItemRangeRemoved(positionStart, itemCount)
        }

        override fun onItemRangeMoved(
            sender: ObservableList<T>?,
            fromPosition: Int,
            toPosition: Int,
            itemCount: Int
        ) {
            Log.d(TAG, "onItemRangeMoved()")
            notifyDataSetChanged()
        }

        override fun onItemRangeInserted(
            sender: ObservableList<T>?,
            positionStart: Int,
            itemCount: Int
        ) {
            Log.d(TAG, "onItemRangeInserted()")
            notifyItemRangeInserted(positionStart, itemCount)
        }

        override fun onItemRangeChanged(
            sender: ObservableList<T>?,
            positionStart: Int,
            itemCount: Int
        ) {
            Log.d(TAG, "onItemRangeChanged()")
            notifyItemRangeChanged(positionStart, itemCount)
        }

    }
}