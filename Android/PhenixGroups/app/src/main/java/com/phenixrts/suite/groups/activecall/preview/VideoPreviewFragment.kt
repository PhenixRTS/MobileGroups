/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.activecall.preview

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.databinding.ObservableBoolean
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import com.phenixrts.suite.groups.databinding.GroupCallPreviewBinding
import com.phenixrts.suite.groups.viewmodels.RoomViewModel
import java.util.*
import kotlin.concurrent.schedule

class VideoPreviewFragment : Fragment() {

    private val roomViewModel: RoomViewModel by viewModels({ activity!! })
    private lateinit var binding: GroupCallPreviewBinding

    private val areControlsShown = ObservableBoolean(false)

    init {
        retainInstance = true
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        binding = GroupCallPreviewBinding.inflate(inflater)
        binding.lifecycleOwner = this
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        binding.participant = roomViewModel.activeParticipant
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
                activity?.onBackPressed()
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