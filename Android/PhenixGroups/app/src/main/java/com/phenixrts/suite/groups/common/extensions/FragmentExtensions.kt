/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common.extensions

import android.os.Handler
import android.view.SurfaceView
import android.view.inputmethod.InputMethodManager
import android.widget.ImageView
import android.widget.Toast
import androidx.core.content.ContextCompat.getSystemService
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.ui.screens.fragments.BaseFragment
import kotlinx.android.synthetic.main.activity_main.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import kotlin.system.exitProcess

private const val QUIT_DELAY = 1000L

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
fun FragmentActivity.closeApp(message: String) {
    showToast(message)
    Handler().postDelayed({
        finishAndRemoveTask()
        exitProcess(0)
    }, QUIT_DELAY)
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

fun FragmentActivity.getSurfaceView(): SurfaceView = main_surface_view

fun Fragment.getSurfaceView(): SurfaceView = requireActivity().getSurfaceView()

fun FragmentActivity.getMicIcon(): ImageView = active_member_mic

fun Fragment.getMicIcon(): ImageView = requireActivity().getMicIcon()
