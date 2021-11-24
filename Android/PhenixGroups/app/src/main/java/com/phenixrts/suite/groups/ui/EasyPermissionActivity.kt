/*
 * Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui

import android.Manifest
import android.annotation.SuppressLint
import android.content.pm.PackageManager.PERMISSION_GRANTED
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.cache.PreferenceProvider
import com.phenixrts.suite.groups.receivers.CellularStateReceiver
import com.phenixrts.suite.phenixcore.PhenixCore
import com.phenixrts.suite.phenixdeeplinks.DeepLinkActivity
import java.util.*
import javax.inject.Inject

@SuppressLint("Registered")
abstract class EasyPermissionActivity : DeepLinkActivity() {

    @Inject lateinit var preferenceProvider: PreferenceProvider
    @Inject lateinit var cacheProvider: CacheProvider
    @Inject lateinit var cellularStateReceiver: CellularStateReceiver
    @Inject lateinit var phenixCore: PhenixCore

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

    override val additionalConfiguration = hashMapOf<String, String>()

    override fun isAlreadyInitialized() = phenixCore.isInitialized

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        permissionRequestHistory[requestCode]?.run {
            this(grantResults.isNotEmpty() && grantResults[0] == PERMISSION_GRANTED)
            permissionRequestHistory.remove(requestCode)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        GroupsApplication.component.inject(this)
        super.onCreate(savedInstanceState)
    }

    private fun Int.low16bits() = this and 0xFFFF

}
