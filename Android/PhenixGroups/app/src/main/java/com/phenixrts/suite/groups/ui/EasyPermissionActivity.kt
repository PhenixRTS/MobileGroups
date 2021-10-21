/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
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
import com.phenixrts.suite.groups.repository.RepositoryProvider
import com.phenixrts.suite.phenixcommon.common.FileWriterDebugTree
import com.phenixrts.suite.phenixdeeplink.DeepLinkActivity
import com.phenixrts.suite.phenixdeeplink.models.DeepLinkStatus
import com.phenixrts.suite.phenixdeeplink.models.PhenixDeepLinkConfiguration
import java.util.*
import javax.inject.Inject
import kotlin.collections.HashMap

@SuppressLint("Registered")
open class EasyPermissionActivity : DeepLinkActivity() {

    @Inject lateinit var repositoryProvider: RepositoryProvider
    @Inject lateinit var preferenceProvider: PreferenceProvider
    @Inject lateinit var cacheProvider: CacheProvider
    @Inject lateinit var cellularStateReceiver: CellularStateReceiver
    @Inject lateinit var fileWriterTree: FileWriterDebugTree

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

    override fun onDeepLinkQueried(status: DeepLinkStatus, configuration: PhenixDeepLinkConfiguration,
                                   rawConfiguration: Map<String, String>, deepLink: String) {
        /* Ignored */
    }

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
