/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups


import android.Manifest
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import com.phenixrts.suite.groups.databinding.CallSettingsScreenBinding
import com.phenixrts.suite.groups.models.UserSettings
import com.phenixrts.suite.groups.utils.EasyPermissionFragment
import kotlinx.android.synthetic.main.call_settings_screen.*

/**
 * A simple [Fragment] subclass.
 */
class CallSettingsScreen : EasyPermissionFragment() {

    private val userSettings = UserSettings()
    private lateinit var binding: CallSettingsScreenBinding

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        binding = CallSettingsScreenBinding.inflate(inflater)
        binding.userSettings = userSettings
        binding.lifecycleOwner = this
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        cameraButton.setOnCheckedChangeListener(::setCameraPreviewEnabled)
        microphoneButton.setOnCheckedChangeListener(::setMicrophoneEnabled)
    }

    private fun setCameraPreviewEnabled(enabled: Boolean) {
        if (enabled) {
            askForPermission(Manifest.permission.CAMERA) { granted ->
                // TODO (YM): add camera preview switch logic
                if (!granted) {
                    cameraButton.isChecked = false
                }
            }
        }
    }

    private fun setMicrophoneEnabled(enabled: Boolean) {
        if (enabled) {
            askForPermission(Manifest.permission.RECORD_AUDIO) { granted ->
                // TODO (YM): show settings dialog if denied
                if (!granted) {
                    microphoneButton.isChecked = false
                }
            }
        }
    }
}
