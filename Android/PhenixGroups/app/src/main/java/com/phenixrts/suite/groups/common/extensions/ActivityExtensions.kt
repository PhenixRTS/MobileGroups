/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common.extensions

import android.os.Handler
import android.view.SurfaceView
import android.view.inputmethod.InputMethodManager
import android.widget.ImageView
import android.widget.Toast
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import com.google.android.material.snackbar.Snackbar
import com.phenixrts.common.RequestStatus
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.ui.MainActivity
import com.phenixrts.suite.groups.ui.SplashActivity
import com.phenixrts.suite.groups.ui.screens.JoinScreen
import com.phenixrts.suite.groups.ui.screens.LoadingScreen
import com.phenixrts.suite.groups.ui.screens.RoomScreen
import com.phenixrts.suite.groups.viewmodels.GroupsViewModel
import com.phenixrts.suite.phenixcommon.common.launchMain
import kotlinx.android.synthetic.main.activity_main.*
import kotlinx.android.synthetic.main.activity_splash.*
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch
import timber.log.Timber
import kotlin.system.exitProcess

private const val QUIT_DELAY = 1000L

fun SplashActivity.showSnackBar(message: String) {
    if (message.isNotBlank()) {
        GlobalScope.launch(Dispatchers.Main) {
            Snackbar.make(splash_root, message, Snackbar.LENGTH_INDEFINITE).show()
        }
    }
}

fun FragmentActivity.showToast(message: String) {
    if (message.isNotBlank()) {
        GlobalScope.launch(Dispatchers.Main) {
            Toast.makeText(this@showToast, message, Toast.LENGTH_SHORT).show()
        }
    }
}

fun FragmentActivity.closeApp(message: String? = null) {
    message?.let { showToast(it) }
    Handler().postDelayed({
        finishAffinity()
        finishAndRemoveTask()
        exitProcess(0)
    }, QUIT_DELAY)
}

fun FragmentActivity.hideKeyboard() {
    val view = currentFocus ?: window.decorView
    val token = view.windowToken
    view.clearFocus()
    ContextCompat.getSystemService(this, InputMethodManager::class.java)?.hideSoftInputFromWindow(token, 0)
}

fun FragmentActivity.getSurfaceView(): SurfaceView = main_surface_view

fun FragmentActivity.getMicIcon(): ImageView = active_member_mic

fun FragmentActivity.showLoadingScreen() = launchMain {
    Timber.d("Showing loading")
    supportFragmentManager.run {
        if (findFragmentByTag(LoadingScreen::class.java.name) == null) {
            beginTransaction()
                .add(R.id.fullscreen_fragment_container, LoadingScreen(), LoadingScreen::class.java.name)
                .commitNow()
        }
    }
}

fun FragmentActivity.hideLoadingScreen() = launchMain {
    Timber.d("Hiding loading")
    supportFragmentManager.run {
        findFragmentByTag(LoadingScreen::class.java.name)?.let {
            Timber.d("Hiding loading $it")
            beginTransaction().remove(it).commitNowAllowingStateLoss()
        }
    }
}

fun FragmentActivity.launchFragment(fragment: Fragment, addToBackStack: Boolean = true) = launchMain {
    supportFragmentManager.run {
        val fullscreen = fragment is JoinScreen
        val container = if (fullscreen) R.id.fullscreen_fragment_container else R.id.fragment_container
        if (fragments.lastOrNull() is JoinScreen) {
            popBackStackImmediate()
        }
        val transaction = beginTransaction()
            .replace(container, fragment, fragment.javaClass.name)
        if (addToBackStack) {
            transaction.addToBackStack(fragment.javaClass.name)
        }
        transaction.commit()
    }
}

fun MainActivity.joinRoom(viewModel: GroupsViewModel, roomAlias: String, displayName: String) = launchMain {
    if (!hasCameraPermission()) {
        viewModel.onPermissionRequested.call()
        return@launchMain
    }
    hideKeyboard()
    showLoadingScreen()
    val joinedRoomStatus = viewModel.joinRoomByAlias(roomAlias, displayName)
    Timber.d("Room joined with status: $joinedRoomStatus $roomAlias")
    hideLoadingScreen()
    if (joinedRoomStatus.status == RequestStatus.OK) {
        launchFragment(RoomScreen())
    } else {
        showToast(getString(R.string.err_join_room_failed))
    }
}
