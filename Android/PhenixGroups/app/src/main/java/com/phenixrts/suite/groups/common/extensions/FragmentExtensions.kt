/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common.extensions

import androidx.fragment.app.Fragment
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.ui.MainActivity
import com.phenixrts.suite.groups.ui.screens.fragments.BaseFragment
import com.phenixrts.suite.phenixcore.common.launchUI

fun BaseFragment.injectDependencies() {
    GroupsApplication.component.inject(this)
}

fun Fragment.showToast(message: String) {
    if (isAdded) {
        requireActivity().showToast(message)
    }
}

fun Fragment.hideKeyboard() {
    if (isAdded) {
        requireActivity().hideKeyboard()
    }
}

fun Fragment.launchFragment(fragment: Fragment, addToBackStack: Boolean = true)
        = requireActivity().launchFragment(fragment, addToBackStack)

fun Fragment.dismissFragment() = launchUI {
    hideKeyboard()
    requireActivity().onBackPressed()
}

fun Fragment.hideTopMenu() = (activity as? MainActivity)?.menuHandler?.hideTopMenu()

fun Fragment.showBottomMenu() = (activity as? MainActivity)?.menuHandler?.showBottomMenu()

fun Fragment.hasCameraPermission() = (activity as? MainActivity)?.hasCameraPermission() ?: false

fun Fragment.askForPermissions(callback: (Boolean) -> Unit) = (activity as? MainActivity)?.askForPermissions(callback)
