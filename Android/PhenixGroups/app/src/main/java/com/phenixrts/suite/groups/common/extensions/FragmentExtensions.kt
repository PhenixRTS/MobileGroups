/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common.extensions

import android.view.SurfaceView
import android.view.View
import android.view.inputmethod.InputMethodManager
import android.widget.Toast
import androidx.core.content.ContextCompat.getSystemService
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.common.SurfaceIndex
import com.phenixrts.suite.groups.models.RoomMember
import com.phenixrts.suite.groups.ui.screens.fragments.BaseFragment
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import timber.log.Timber

/**
 * Used to show simple toast with given message
 */
fun Fragment.showToast(message: String) {
    if (isAdded) {
        requireActivity().showToast(message)
    }
}

fun FragmentActivity.showToast(message: String) {
    if (message.isNotBlank()) {
        GlobalScope.launch(Dispatchers.Main) {
            Toast.makeText(this@showToast, message, Toast.LENGTH_SHORT).show()
        }
    }
}

/**
 * Used to inject dagger dependencies
 */
fun BaseFragment.injectDependencies() {
    GroupsApplication.component.inject(this)
}

/**
 * Terminates the app with a message in case SDK failed to initializes
 */
fun BaseFragment.closeApp(message: String) {
    showToast(message)
    requireActivity().finish()
}

/**
 * Hides current active keyboard and clears focus
 */
fun Fragment.hideKeyboard() {
    if (isAdded) {
        requireActivity().hideKeyboard()
    }
}

fun FragmentActivity.hideKeyboard() {
    val view = currentFocus ?: window.decorView
    val token = view.windowToken
    view.clearFocus()
    getSystemService(this, InputMethodManager::class.java)?.hideSoftInputFromWindow(token, 0)
}

fun FragmentActivity.showGivenSurfaceView(surfaceIndex: SurfaceIndex) {
    Timber.d("Showing surface: $surfaceIndex")
    SurfaceIndex.values().forEach {
        getSurfaceView(it)?.let { surfaceView ->
            if (it == surfaceIndex) {
                surfaceView.visibility = View.VISIBLE
            } else {
                surfaceView.visibility = View.GONE
            }
        }
    }
}

fun FragmentActivity.hideUnusedSurfaces(members: List<RoomMember> = arrayListOf()) {
    Timber.d("Hiding all unused surfaces")
    SurfaceIndex.values().forEach { surface ->
        if (members.firstOrNull { it.surface == surface } == null) {
            getSurfaceView(surface)?.visibility = View.GONE
        }
    }
}

fun FragmentActivity.getSurfaceView(surfaceIndex: SurfaceIndex): SurfaceView? = findViewById<SurfaceView?>(surfaceIndex.surfaceId)

fun Fragment.showGivenSurfaceView(surfaceIndex: SurfaceIndex) = requireActivity().showGivenSurfaceView(surfaceIndex)

fun Fragment.hideUnusedSurfaces(members: List<RoomMember> = arrayListOf()) = requireActivity().hideUnusedSurfaces(members)

fun Fragment.getSurfaceView(surfaceIndex: SurfaceIndex): SurfaceView? = requireActivity().getSurfaceView(surfaceIndex)
