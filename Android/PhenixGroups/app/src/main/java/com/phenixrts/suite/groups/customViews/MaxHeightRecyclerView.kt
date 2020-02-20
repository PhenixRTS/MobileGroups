/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.customViews

import android.content.Context
import android.content.res.TypedArray
import android.util.AttributeSet
import androidx.recyclerview.widget.RecyclerView
import com.phenixrts.suite.groups.R

/**
 * Used to limit the max height of a recycler view
 */
class MaxHeightRecyclerView : RecyclerView {

    private var maxHeight = 0

    constructor(context: Context?) : super(context!!)

    constructor(context: Context, attrs: AttributeSet?) : super(context, attrs) {
        initialize(context, attrs)
    }

    constructor(context: Context, attrs: AttributeSet?, defStyleAttr: Int) : super(context, attrs, defStyleAttr) {
        initialize(context, attrs)
    }

    private fun initialize(context: Context, attrs: AttributeSet?) {
        val arr: TypedArray = context.obtainStyledAttributes(attrs, R.styleable.MaxHeightRecyclerView)
        maxHeight = arr.getLayoutDimension(R.styleable.MaxHeightRecyclerView_maxHeight, maxHeight)
        arr.recycle()
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        var heightSpec = heightMeasureSpec
        if (maxHeight > 0) {
            heightSpec = MeasureSpec.makeMeasureSpec(maxHeight, MeasureSpec.AT_MOST)
        }
        var totalHeight = 0
        val count = adapter?.itemCount ?: 0
        for (i in 0 .. count) {
            findViewHolderForAdapterPosition(i)?.itemView?.let {
                it.measure(MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED),
                    MeasureSpec.makeMeasureSpec(0, MeasureSpec.UNSPECIFIED))
                totalHeight += it.measuredHeight
            }
        }

        if (totalHeight in 1 until maxHeight) {
            heightSpec = MeasureSpec.makeMeasureSpec(totalHeight, MeasureSpec.AT_MOST)
        }
        super.onMeasure(widthMeasureSpec, heightSpec)
    }
}
