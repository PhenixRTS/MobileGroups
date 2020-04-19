/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui

import android.content.Intent
import android.view.View
import androidx.core.content.FileProvider
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.phenixrts.suite.groups.BuildConfig
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.common.FileWriterDebugTree
import com.phenixrts.suite.groups.common.extensions.*
import com.phenixrts.suite.groups.viewmodels.GroupsViewModel
import kotlinx.android.synthetic.main.activity_main.*
import kotlinx.android.synthetic.main.view_bottom_menu.*
import kotlinx.android.synthetic.main.view_debug_menu.*
import kotlinx.coroutines.delay
import timber.log.Timber
import java.io.File

class MenuHandler(
    private val activity: MainActivity,
    private val viewModel: GroupsViewModel
) {

    private var lastTapTime = System.currentTimeMillis()
    private var tapCount = 0
    private val bottomMenu by lazy { BottomSheetBehavior.from(activity.bottom_menu) }
    private val debugMenu by lazy { BottomSheetBehavior.from(activity.debug_menu)}

    private val sheetListener = object : BottomSheetBehavior.BottomSheetCallback() {
        override fun onSlide(bottomSheet: View, slideOffset: Float) {
            activity.menu_background.visibility = View.VISIBLE
            activity.menu_background.alpha = slideOffset
        }

        override fun onStateChanged(bottomSheet: View, newState: Int) {
            if (newState == BottomSheetBehavior.STATE_HIDDEN || newState == BottomSheetBehavior.STATE_COLLAPSED) {
                activity.menu_background.visibility = View.GONE
                activity.menu_background.alpha = 0f
            }
        }
    }

    private fun showDebugMenu() {
        Timber.d("Showing debug menu")
        debugMenu.open()
    }

    private fun hideDebugMenu() {
        Timber.d("Hiding bottom menu")
        debugMenu.hide()
    }

    private fun switchBottomMenu() {
        if (!bottomMenu.isOpened()) {
            showBottomMenu()
        } else {
            hideBottomMenu()
        }
    }

    private fun hideBottomMenu() {
        Timber.d("Hiding bottom menu")
        bottomMenu.hide()
    }

    fun showBottomMenu() {
        Timber.d("Showing bottom menu")
        bottomMenu.open()
    }

    fun onStart() {
        bottomMenu.addBottomSheetCallback(sheetListener)
        debugMenu.addBottomSheetCallback(sheetListener)

        activity.menu_button.setOnClickListener { switchBottomMenu() }
        activity.menu_background.setOnClickListener { hideBottomMenu() }
        activity.menu_close.setOnClickListener { hideBottomMenu() }
        activity.menu_switch_camera.setOnClickListener {
            launchMain {
                hideBottomMenu()
                delay(MENU_HIDE_DELAY)
                launchIO {
                    viewModel.switchCameraFacing()
                }
            }
        }

        activity.debug_app_version.text = activity.getString(R.string.debug_app_version,
            BuildConfig.VERSION_NAME,
            BuildConfig.VERSION_CODE
        )
        activity.debug_sdk_version.text = activity.getString(R.string.debug_sdk_version,
            com.phenixrts.sdk.BuildConfig.VERSION_NAME,
            com.phenixrts.sdk.BuildConfig.VERSION_CODE
        )
        activity.debug_close.setOnClickListener { hideDebugMenu() }
        activity.debug_share.setOnClickListener { shareLogs() }
    }

    private fun getFileUri(fileName: String) = FileProvider.getUriForFile(
        activity,
        "${BuildConfig.APPLICATION_ID}.provider",
        File(activity.filesDir.toString() + "/logs", fileName)
    )

    private fun shareLogs() = launchMain {
        Timber.d("Share Logs clicked")
        viewModel.collectPhenixLogs()
        val sdkLogs = getFileUri(FileWriterDebugTree.SDK_LOGS_FILENAME)
        val appLogs = getFileUri(FileWriterDebugTree.APP_LOGS_FILENAME)
        Timber.d("Sharing files: $sdkLogs $appLogs")
        val files = arrayListOf(sdkLogs, appLogs)

        val intent = Intent().apply {
            action = Intent.ACTION_SEND_MULTIPLE
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            putParcelableArrayListExtra(Intent.EXTRA_STREAM, files)
            type = INTENT_CHOOSER_TYPE
        }
        intent.resolveActivity(activity.packageManager)?.run {
            activity.startActivity(Intent.createChooser(intent, activity.getString(R.string.debug_share_app_logs)))
        }
    }

    fun onStop() {
        bottomMenu.removeBottomSheetCallback(sheetListener)
        debugMenu.removeBottomSheetCallback(sheetListener)
    }

    fun isClosed(): Boolean {
        if (bottomMenu.isOpened()) {
            bottomMenu.hide()
            return false
        } else if (debugMenu.isOpened()) {
            debugMenu.hide()
            return false
        }
        return true
    }

    fun showTopMenu() {
        if (activity.main_menu_holder.alpha == MENU_INVISIBLE) {
            Timber.d("Showing top menu")
            activity.main_menu_holder.visibility = View.VISIBLE
            activity.main_menu_holder.animate()
                .setStartDelay(MENU_FADE_DURATION)
                .setDuration(MENU_FADE_DURATION)
                .alpha(MENU_VISIBLE)
                .withEndAction {
                    activity.main_menu_holder.alpha = MENU_VISIBLE
                }.start()
        }
    }

    fun hideTopMenu() {
        if (activity.main_menu_holder.alpha == MENU_VISIBLE) {
            Timber.d("Hiding top menu")
            activity.main_menu_holder.animate()
                .setStartDelay(0)
                .setDuration(MENU_FADE_DURATION)
                .alpha(MENU_INVISIBLE)
                .withEndAction {
                    activity.main_menu_holder.alpha = MENU_INVISIBLE
                    activity.main_menu_holder.visibility = View.GONE
                }.start()
        }
    }

    fun onScreenTapped() {
        val currentTapTime = System.currentTimeMillis()
        if (currentTapTime - lastTapTime <= TAP_DELTA) {
            tapCount++
        } else {
            tapCount = 0
        }
        lastTapTime = currentTapTime
        if (tapCount == TAP_GOAL) {
            tapCount = 0
            Timber.d("Debug menu unlocked")
            showDebugMenu()
        }
    }

    private companion object {
        private const val INTENT_CHOOSER_TYPE = "text/plain"
        private const val MENU_HIDE_DELAY = 200L
        private const val MENU_FADE_DURATION = 300L
        private const val MENU_VISIBLE = 1f
        private const val MENU_INVISIBLE = 0f
        private const val TAP_DELTA = 250L
        private const val TAP_GOAL = 5
    }
}
