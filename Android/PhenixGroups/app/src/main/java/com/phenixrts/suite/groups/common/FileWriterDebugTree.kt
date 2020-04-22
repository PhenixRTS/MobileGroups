/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common

import android.app.Application
import android.content.ContextWrapper
import android.net.Uri
import androidx.core.content.FileProvider
import com.phenixrts.suite.groups.BuildConfig
import com.phenixrts.suite.groups.TIMBER_TAG
import com.phenixrts.suite.groups.common.extensions.launchIO
import timber.log.Timber
import java.io.*
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class FileWriterDebugTree(private val context: Application) : Timber.DebugTree() {

    private var filePath: File? = null
    private var sdkFileWriter: BufferedWriter? = null
    private var appFileWriter: BufferedWriter? = null
    private var sdkLogFile: File? = null
    private var firstAppLogFile: File? = null
    private var secondAppLogFile: File? = null
    private var lineCount = 0
    private var isUsingFirstFile = true

    init {
        initFileWriter()
    }

    override fun log(priority: Int, tag: String?, message: String, t: Throwable?) {
        super.log(priority, tag, message, t)
        launchIO {
            getFormattedLogMessage(tag, priority, message, t).run {
                writeAppLogs(this)
            }
        }
    }

    override fun log(priority: Int, message: String?, vararg args: Any?) {
        super.log(priority, message, *args)
        launchIO {
            getFormattedLogMessage(TIMBER_TAG, priority, message, null).run {
                writeAppLogs(this)
            }
        }
    }

    override fun log(priority: Int, t: Throwable?, message: String?, vararg args: Any?) {
        super.log(priority, t, message, *args)
        launchIO {
            getFormattedLogMessage(TIMBER_TAG, priority, message, t).run {
                writeAppLogs(this)
            }
        }
    }

    private fun initFileWriter() {
        val contextWrapper = ContextWrapper(context)
        filePath = File(contextWrapper.filesDir, LOG_FOLDER)
        if (filePath?.exists() == false && filePath?.mkdir() == false) {
            d("Failed to create log file directory")
            return
        }

        sdkLogFile = File(filePath, SDK_LOGS_FILE)
        firstAppLogFile = File(filePath, FIRST_APP_LOGS_FILE)
        secondAppLogFile = File(filePath, SECOND_APP_LOGS_FILE)

        try {
            sdkLogFile?.let { file ->
                sdkFileWriter = BufferedWriter(FileWriter(file, false))
            }
            firstAppLogFile?.let { file ->
                appFileWriter = BufferedWriter(FileWriter(file, true))
                getLineCount(file)
            }
        } catch (e: IOException) {
            e.printStackTrace()
            lineCount = 0
        }
    }

    private fun getLineCount(file: File) {
        lineCount = try {
            val lineReader = LineNumberReader(BufferedReader(InputStreamReader(FileInputStream(file))))
            lineReader.skip(Long.MAX_VALUE)
            lineReader.lineNumber + 1
        } catch (e: IOException) {
            e.printStackTrace()
            0
        }
    }

    private suspend fun writeAppLogs(message: String) = suspendCoroutine<Unit> { continuation ->
        try {
            if (lineCount == MAX_LINES_PER_FILE) {
                appFileWriter?.flush()
                appFileWriter?.close()
                if (isUsingFirstFile) {
                    isUsingFirstFile = false
                    secondAppLogFile?.let { file ->
                        appFileWriter = BufferedWriter(FileWriter(file, false))
                    }
                } else {
                    firstAppLogFile?.let { file ->
                        appFileWriter = BufferedWriter(FileWriter(file, false))
                    }
                }
                lineCount = 0
            }
            appFileWriter?.append(message + "\n")
            lineCount++
        } catch (e: IOException) {
            d(e, "Failed to write app logs")
        }
        continuation.resume(Unit)
    }

    suspend fun writeSdkLogs(message: String) = suspendCoroutine<Unit> { continuation ->
        try {
            sdkFileWriter?.write(message)
        } catch (e: IOException) {
            d(e, "Failed to write sdk logs")
        }
        continuation.resume(Unit)
    }

    fun getLogFileUris(): List<Uri> {
        val fileUris = arrayListOf<Uri>()
        sdkFileWriter?.flush()
        appFileWriter?.flush()
        sdkLogFile?.takeIf { it.length() > 0 }?.let { file ->
            FileProvider.getUriForFile(context, "${BuildConfig.APPLICATION_ID}.provider", file)
        }?.let { sdkUri ->
            fileUris.add(sdkUri)
        }
        firstAppLogFile?.takeIf { it.length() > 0 }?.let { file ->
            FileProvider.getUriForFile(context, "${BuildConfig.APPLICATION_ID}.provider", file)
        }?.let { appUri ->
            fileUris.add(appUri)
        }
        secondAppLogFile?.takeIf { it.length() > 0 }?.let { file ->
            FileProvider.getUriForFile(context, "${BuildConfig.APPLICATION_ID}.provider", file)
        }?.let { appUri ->
            fileUris.add(appUri)
        }
        return fileUris
    }

    companion object {
        private const val LOG_FOLDER = "logs"
        private const val FIRST_APP_LOGS_FILE = "Phenix_appLogs_1.txt"
        private const val SECOND_APP_LOGS_FILE = "Phenix_appLogs_2.txt"
        private const val SDK_LOGS_FILE = "Phenix_sdkLogs.txt"
        private const val MAX_LINES_PER_FILE = 1000 * 10 // 10k Lines per log file
    }
}
