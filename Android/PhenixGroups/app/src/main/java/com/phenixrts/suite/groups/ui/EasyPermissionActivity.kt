/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui

import android.Manifest
import android.annotation.SuppressLint
import android.content.pm.PackageManager.PERMISSION_GRANTED
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.phenixrts.suite.phenixdeeplink.DeepLinkActivity
import com.phenixrts.suite.phenixdeeplink.models.DeepLinkStatus
import com.phenixrts.suite.phenixdeeplink.models.PhenixConfiguration
import java.util.*
import kotlin.collections.HashMap

/**
 * Simplifies permission request to single Callback method call
 */
@SuppressLint("Registered")
open class EasyPermissionActivity : DeepLinkActivity() {

    private val permissionRequestHistory = hashMapOf<Int, (a: Boolean) -> Unit>()

    fun hasCameraPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.CAMERA) == PERMISSION_GRANTED

    fun hasRecordAudioPermission(): Boolean =
        ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) == PERMISSION_GRANTED

    fun arePermissionsGranted(): Boolean = hasCameraPermission() && hasRecordAudioPermission()

    fun askForPermissions(callback: (granted: Boolean) -> Unit) {
        run {
            val permissions = arrayListOf<String>()
            if (!hasRecordAudioPermission()) {
                permissions.add(Manifest.permission.RECORD_AUDIO)
            }
            if (!hasCameraPermission()) {
                permissions.add(Manifest.permission.CAMERA)
            }
            if (permissions.isNotEmpty()) {
                val requestCode = Date().time.toInt().low16bits()
                permissionRequestHistory[requestCode] = callback
                ActivityCompat.requestPermissions(this, permissions.toTypedArray(), requestCode)
            } else {
                callback(true)
            }
        }
    }

    override val additionalConfiguration: HashMap<String, String>
        get() = hashMapOf()

    override fun isAlreadyInitialized(): Boolean = false

    override fun onDeepLinkQueried(status: DeepLinkStatus, configuration: PhenixConfiguration, deepLink: String) {
        /* Ignored */
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        permissionRequestHistory[requestCode]?.run {
            this(grantResults.isNotEmpty() && grantResults[0] == PERMISSION_GRANTED)
            permissionRequestHistory.remove(requestCode)
        }
    }

    private fun Int.low16bits() = this and 0xFFFF

}
