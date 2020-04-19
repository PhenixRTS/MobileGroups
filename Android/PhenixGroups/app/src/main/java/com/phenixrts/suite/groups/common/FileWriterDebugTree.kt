/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common

import android.app.Application
import android.content.Context
import com.phenixrts.suite.groups.common.extensions.launchIO
import timber.log.Timber

class FileWriterDebugTree(private val context: Application) : Timber.DebugTree() {

    init {
        applicationContext = context
    }

    override fun log(priority: Int, tag: String?, message: String, t: Throwable?) {
        super.log(priority, tag, message, t)
        message.run {
            writeAppLogs(this)
        }
    }

    override fun log(priority: Int, message: String?, vararg args: Any?) {
        super.log(priority, message, *args)
        message?.run {
            writeAppLogs(this)
        }
    }

    override fun log(priority: Int, t: Throwable?, message: String?, vararg args: Any?) {
        super.log(priority, t, message, *args)
        message?.run {
            writeAppLogs(this)
        }
    }

    private fun writeAppLogs(message: String) = launchIO {
        context.openFileOutput(APP_LOGS_FILENAME, Context.MODE_APPEND).use {
            it.write(message.toByteArray())
        }
    }

    companion object {
        const val APP_LOGS_FILENAME = "appLogs.txt"
        const val SDK_LOGS_FILENAME = "sdkLogs.txt"

        private lateinit var applicationContext: Application

        fun writeSdkLogs(message: String) = launchIO {
            applicationContext.openFileOutput(SDK_LOGS_FILENAME, Context.MODE_PRIVATE).use {
                it.write(message.toByteArray())
            }
        }

        fun clearLogs() {
            applicationContext.deleteFile(APP_LOGS_FILENAME)
            applicationContext.deleteFile(SDK_LOGS_FILENAME)
        }
    }
}
