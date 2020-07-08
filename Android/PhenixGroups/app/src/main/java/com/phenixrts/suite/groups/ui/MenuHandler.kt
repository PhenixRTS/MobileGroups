/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui

import android.view.View
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.phenixrts.suite.groups.viewmodels.GroupsViewModel
import com.phenixrts.suite.phenixcommon.common.*
import kotlinx.android.synthetic.main.activity_main.*
import kotlinx.android.synthetic.main.view_bottom_menu.*
import kotlinx.coroutines.delay
import timber.log.Timber

class MenuHandler(
    private val activity: MainActivity,
    private val viewModel: GroupsViewModel
) {

    private val bottomMenu by lazy { BottomSheetBehavior.from(activity.bottom_menu) }

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
    }

    fun onStop() {
        bottomMenu.removeBottomSheetCallback(sheetListener)
    }

    fun isClosed(): Boolean {
        if (bottomMenu.isOpened()) {
            bottomMenu.hide()
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

    private companion object {
        private const val MENU_HIDE_DELAY = 200L
        private const val MENU_FADE_DURATION = 300L
        private const val MENU_VISIBLE = 1f
        private const val MENU_INVISIBLE = 0f
    }
}
