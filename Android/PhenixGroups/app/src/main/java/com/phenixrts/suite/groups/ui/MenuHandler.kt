/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui

import android.view.View
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.phenixrts.suite.groups.databinding.ActivityMainBinding
import com.phenixrts.suite.groups.viewmodels.GroupsViewModel
import com.phenixrts.suite.phenixcommon.common.*
import kotlinx.coroutines.delay
import timber.log.Timber

class MenuHandler(
    private val binding: ActivityMainBinding,
    private val viewModel: GroupsViewModel
) {

    private val bottomMenu by lazy { BottomSheetBehavior.from(binding.bottomMenu.root as View) }

    private val sheetListener = object : BottomSheetBehavior.BottomSheetCallback() {
        override fun onSlide(bottomSheet: View, slideOffset: Float) {
            binding.menuBackground.visibility = View.VISIBLE
            binding.menuBackground.alpha = slideOffset
        }

        override fun onStateChanged(bottomSheet: View, newState: Int) {
            if (newState == BottomSheetBehavior.STATE_HIDDEN || newState == BottomSheetBehavior.STATE_COLLAPSED) {
                binding.menuBackground.visibility = View.GONE
                binding.menuBackground.alpha = 0f
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

        binding.menuButton.setOnClickListener { switchBottomMenu() }
        binding.menuBackground.setOnClickListener { hideBottomMenu() }
        binding.bottomMenu.menuClose.setOnClickListener { hideBottomMenu() }
        binding.bottomMenu.menuSwitchCamera.setOnClickListener {
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
        if (binding.mainMenuHolder.alpha == MENU_INVISIBLE) {
            Timber.d("Showing top menu")
            binding.mainMenuHolder.visibility = View.VISIBLE
            binding.mainMenuHolder.animate()
                .setStartDelay(MENU_FADE_DURATION)
                .setDuration(MENU_FADE_DURATION)
                .alpha(MENU_VISIBLE)
                .withEndAction {
                    binding.mainMenuHolder.alpha = MENU_VISIBLE
                }.start()
        }
    }

    fun hideTopMenu() {
        if (binding.mainMenuHolder.alpha == MENU_VISIBLE) {
            Timber.d("Hiding top menu")
            binding.mainMenuHolder.animate()
                .setStartDelay(0)
                .setDuration(MENU_FADE_DURATION)
                .alpha(MENU_INVISIBLE)
                .withEndAction {
                    binding.mainMenuHolder.alpha = MENU_INVISIBLE
                    binding.mainMenuHolder.visibility = View.GONE
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
