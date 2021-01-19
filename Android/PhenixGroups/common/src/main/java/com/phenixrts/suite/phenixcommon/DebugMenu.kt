/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.phenixcommon

import android.content.Intent
import android.net.Uri
import android.view.LayoutInflater
import android.view.View
import androidx.coordinatorlayout.widget.CoordinatorLayout
import androidx.fragment.app.FragmentActivity
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.phenixrts.express.RoomExpress
import com.phenixrts.suite.phenixcommon.common.*
import com.phenixrts.suite.phenixcommon.databinding.ViewDebugBackgroundBinding
import com.phenixrts.suite.phenixcommon.databinding.ViewDebugMenuBinding
import timber.log.Timber
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class DebugMenu(
    private val fileWriterDebugTree: FileWriterDebugTree,
    private val roomExpress: RoomExpress?,
    rootView: CoordinatorLayout,
    private val onShowChooser:(files: ArrayList<Uri>) -> Unit,
    private val onError:(error: Int) -> Unit
) {

    private var lastTapTime = System.currentTimeMillis()
    private var tapCount = 0
    private var background = ViewDebugBackgroundBinding.inflate(LayoutInflater.from(rootView.context), rootView, false)
    private var menuBinding = ViewDebugMenuBinding.inflate(LayoutInflater.from(rootView.context), rootView, false)
    private val debugMenu: BottomSheetBehavior<View>

    init {
        rootView.addView(background.root)
        rootView.addView(menuBinding.root)
        debugMenu = BottomSheetBehavior.from(menuBinding.debugMenu)
    }

    private val menuStateListener = object : BottomSheetBehavior.BottomSheetCallback() {
        override fun onSlide(bottomSheet: View, slideOffset: Float) {
            background.root.visibility = View.VISIBLE
            background.root.alpha = slideOffset
        }

        override fun onStateChanged(bottomSheet: View, newState: Int) {
            if (newState == BottomSheetBehavior.STATE_HIDDEN || newState == BottomSheetBehavior.STATE_COLLAPSED) {
                background.root.visibility = View.GONE
                background.root.alpha = 0f
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

    private fun shareLogs() = launchMain {
        Timber.d("Share Logs clicked")
        val files = ArrayList<Uri>()
        collectPhenixLogs(fileWriterDebugTree)
        files.addAll(fileWriterDebugTree.getLogFileUris())
        if (files.isNotEmpty()) {
            onShowChooser(files)
        } else {
            onError(R.string.debug_failed_to_collect_logs)
        }
    }

    private suspend fun collectPhenixLogs(fileWriterTree: FileWriterDebugTree): Unit = suspendCoroutine { continuation ->
        launchIO {
            fileWriterTree.writeSdkLogs(collectLogMessages())
            continuation.resume(Unit)
        }
    }

    private suspend fun collectLogMessages(): String = suspendCoroutine { continuation ->
        roomExpress?.pCastExpress?.pCast?.collectLogMessages { _, _, messages ->
            continuation.resume(messages)
        } ?: continuation.resume("")
    }

    fun showAppChooser(activity: FragmentActivity, files: ArrayList<Uri>) {
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

    fun onStart(appVersion: String, sdkVersion: String) {
        debugMenu.addBottomSheetCallback(menuStateListener)
        menuBinding.debugClose.setOnClickListener { hideDebugMenu() }
        menuBinding.debugAppVersion.text = appVersion
        menuBinding.debugSdkVersion.text = sdkVersion
        menuBinding.debugShare.setOnClickListener { shareLogs() }
    }

    fun onStop() {
        debugMenu.removeBottomSheetCallback(menuStateListener)
    }

    fun isClosed(): Boolean {
        if (debugMenu.isOpened()) {
            debugMenu.hide()
            return false
        }
        return true
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
        private const val TAP_DELTA = 250L
        private const val TAP_GOAL = 5
    }
}
