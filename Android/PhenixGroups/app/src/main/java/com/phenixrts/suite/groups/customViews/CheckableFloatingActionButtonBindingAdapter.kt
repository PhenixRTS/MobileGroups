/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.customViews

import androidx.databinding.BindingAdapter
import androidx.databinding.InverseBindingListener
import androidx.databinding.InverseBindingMethod
import androidx.databinding.InverseBindingMethods

@InverseBindingMethods(
    InverseBindingMethod(
        type = CheckableFloatingActionButton::class,
        attribute = "android:checked"
    )
)
class CheckableFloatingActionButtonBindingAdapter {

    companion object {
        @BindingAdapter("android:checkedAttrChanged")
        @JvmStatic
        fun CheckableFloatingActionButton.setCheckedAdapter(inverseListener: InverseBindingListener) {
            onInverseBindingListener = inverseListener
        }
    }
}