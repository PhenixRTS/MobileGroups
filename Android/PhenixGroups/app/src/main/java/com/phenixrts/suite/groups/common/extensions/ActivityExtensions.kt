/*
 * Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common.extensions

import android.os.Process.killProcess
import android.os.Process.myPid
import android.view.View
import android.view.inputmethod.InputMethodManager
import android.widget.Toast
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentActivity
import com.google.android.material.snackbar.Snackbar
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.ui.screens.JoinScreen
import com.phenixrts.suite.groups.ui.screens.LoadingScreen
import com.phenixrts.suite.phenixcore.common.launchMain
import com.phenixrts.suite.phenixcore.common.launchUI
import kotlinx.coroutines.delay
import timber.log.Timber
import kotlin.system.exitProcess

private const val QUIT_DELAY = 1000L

fun View.showSnackBar(message: String, length: Int = Snackbar.LENGTH_INDEFINITE) {
    if (message.isNotBlank()) {
        launchMain {
            Snackbar.make(this@showSnackBar, message, length).show()
        }
    }
}

fun View.setVisibleOr(visible: Boolean, orWhat: Int = View.GONE) {
    visibility = if (visible) View.VISIBLE else orWhat
}

fun FragmentActivity.showToast(message: String) {
    if (message.isNotBlank()) {
        launchUI {
            Toast.makeText(this@showToast, message, Toast.LENGTH_SHORT).show()
        }
    }
}

fun FragmentActivity.closeApp(message: String? = null) {
    message?.let { showToast(it) }
    launchUI {
        delay(QUIT_DELAY)
        Timber.d("Finishing app process")
        finishAffinity()
        finishAndRemoveTask()
        killProcess(myPid())
        exitProcess(1)
    }
}

fun FragmentActivity.hideKeyboard() {
    val view = currentFocus ?: window.decorView
    val token = view.windowToken
    view.clearFocus()
    ContextCompat.getSystemService(this, InputMethodManager::class.java)?.hideSoftInputFromWindow(token, 0)
}

fun FragmentActivity.showLoadingScreen() = launchUI {
    Timber.d("Showing loading")
    supportFragmentManager.run {
        if (findFragmentByTag(LoadingScreen::class.java.name) == null) {
            beginTransaction()
                .add(R.id.fullscreen_fragment_container, LoadingScreen(), LoadingScreen::class.java.name)
                .commitNow()
        }
    }
}

fun FragmentActivity.hideLoadingScreen() = launchUI {
    Timber.d("Hiding loading")
    supportFragmentManager.run {
        findFragmentByTag(LoadingScreen::class.java.name)?.let {
            Timber.d("Hiding loading $it")
            beginTransaction().remove(it).commitNowAllowingStateLoss()
        }
    }
}

fun AppCompatActivity.showErrorDialog(error: String) {
    AlertDialog.Builder(this, R.style.AlertDialogTheme)
        .setCancelable(false)
        .setMessage(error)
        .setPositiveButton(getString(R.string.popup_ok)) { dialog, _ ->
            dialog.dismiss()
            closeApp()
        }
        .create()
        .show()
}

fun FragmentActivity.launchFragment(fragment: Fragment, addToBackStack: Boolean = true) = launchUI {
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
