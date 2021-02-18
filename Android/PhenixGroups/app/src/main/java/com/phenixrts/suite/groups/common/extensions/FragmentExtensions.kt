/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common.extensions

import android.view.SurfaceView
import android.widget.ImageView
import androidx.fragment.app.Fragment
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.ui.MainActivity
import com.phenixrts.suite.groups.ui.screens.fragments.BaseFragment
import com.phenixrts.suite.groups.ui.viewmodels.GroupsViewModel
import com.phenixrts.suite.phenixcommon.common.launchMain
import timber.log.Timber

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

fun Fragment.getSurfaceView(): SurfaceView = (requireActivity() as MainActivity).getSurfaceView()

fun Fragment.getMicIcon(): ImageView = (requireActivity() as MainActivity).getMicIcon()

fun Fragment.joinRoom(viewModel: GroupsViewModel, roomAlias: String, displayName: String)
        = (requireActivity() as? MainActivity)?.joinRoom(viewModel, roomAlias, displayName)

fun Fragment.launchFragment(fragment: Fragment, addToBackStack: Boolean = true)
        = requireActivity().launchFragment(fragment, addToBackStack)

fun Fragment.showLoadingScreen() = requireActivity().showLoadingScreen()

fun Fragment.hideLoadingScreen() = requireActivity().hideLoadingScreen()

fun Fragment.dismissFragment() = launchMain {
    hideKeyboard()
    requireActivity().onBackPressed()
}

fun Fragment.restartVideoPreview(viewModel: GroupsViewModel) = launchMain {
    if (hasCameraPermission()) {
        Timber.d("Restarting video preview")
        viewModel.startUserMediaPreview(getSurfaceView().holder)
    }
}

fun Fragment.hideTopMenu() = (requireActivity() as? MainActivity)?.menuHandler?.hideTopMenu()

fun Fragment.showBottomMenu() = (requireActivity() as? MainActivity)?.menuHandler?.showBottomMenu()

fun Fragment.hasCameraPermission() = (requireActivity() as? MainActivity)?.hasCameraPermission() ?: false
