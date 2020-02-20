/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.databinding.ObservableBoolean
import com.phenixrts.suite.groups.databinding.FragmentVideoPreviewBinding
import java.util.*
import kotlin.concurrent.schedule

// TODO: Needs refactoring
class VideoPreviewFragment : BaseFragment() {

    private lateinit var binding: FragmentVideoPreviewBinding

    private val areControlsShown = ObservableBoolean(false)

    init {
        retainInstance = true
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        binding = FragmentVideoPreviewBinding.inflate(inflater)
        binding.lifecycleOwner = this
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        binding.showControls = areControlsShown
        binding.eventHandler = object : EventHandler {
            private var hideControlsTask: TimerTask? = null
            override fun onPreviewClick() {
                // temporary show or hide controls
                areControlsShown.set(!areControlsShown.get())
                hideControlsTask?.cancel()
                hideControlsTask = Timer("hide buttons").schedule(HIDE_CONTROLS_DELAY) {
                    areControlsShown.set(false)
                }
            }

            override fun onEndCallButtonClick() {
                dismissFragment()
            }
        }
    }

    companion object {
        private const val HIDE_CONTROLS_DELAY = 5000L
    }

    interface EventHandler {
        fun onPreviewClick()
        fun onEndCallButtonClick()
    }
}
