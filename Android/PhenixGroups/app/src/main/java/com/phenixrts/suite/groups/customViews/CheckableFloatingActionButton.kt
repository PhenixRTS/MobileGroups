/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.customViews

import android.content.Context
import android.util.AttributeSet
import android.widget.Checkable
import androidx.databinding.InverseBindingListener
import com.google.android.material.floatingactionbutton.FloatingActionButton


private typealias OnCheckedChangeListener = (isChecked: Boolean) -> Unit


class CheckableFloatingActionButton @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null, defStyleAttr: Int = 0
) : Checkable, FloatingActionButton(context, attrs, defStyleAttr) {

    private var checked = true
    private var onCheckedChangeListener: OnCheckedChangeListener? = null
    internal var onInverseBindingListener: InverseBindingListener? = null

    override fun isChecked() = checked

    override fun toggle() {
        isChecked = !isChecked
    }

    override fun setChecked(checked: Boolean) {
        if (isChecked != checked) {
            this.checked = checked
            onCheckedChangeListener?.invoke(checked)
            onInverseBindingListener?.onChange()
            refreshDrawableState()
        }
    }

    override fun onCreateDrawableState(extraSpace: Int): IntArray {
        val drawableState = super.onCreateDrawableState(extraSpace + 1)
        if (isChecked) {
            mergeDrawableStates(drawableState, intArrayOf(android.R.attr.state_checked))
        }
        return drawableState
    }

    override fun performClick(): Boolean {
        toggle()
        return super.performClick()
    }

    fun setOnCheckedChangeListener(listener: OnCheckedChangeListener?) {
        onCheckedChangeListener = listener
    }
}