/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui

import android.annotation.SuppressLint
import android.content.pm.PackageManager.PERMISSION_GRANTED
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import java.util.*

/**
 * Simplifies permission request to single Callback method call
 */
@SuppressLint("Registered")
open class EasyPermissionActivity : FragmentActivity() {

    private val permissionRequestHistory = hashMapOf<Int, (a: Boolean) -> Unit>()

    fun askForPermission(permission: String, callback: (granted: Boolean) -> Unit) {
        run {
            if (ContextCompat.checkSelfPermission(this, permission) != PERMISSION_GRANTED) {
                // RequestCode supports only low 16 bits of int
                val requestCode = Date().time.toInt().low16bits()
                permissionRequestHistory[requestCode] = callback
                ActivityCompat.requestPermissions(this, arrayOf(permission), requestCode)
            } else {
                callback(true)
            }
        }
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
