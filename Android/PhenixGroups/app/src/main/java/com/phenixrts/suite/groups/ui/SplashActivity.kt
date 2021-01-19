/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.appcompat.app.AlertDialog
import com.phenixrts.suite.groups.BuildConfig
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.cache.PreferenceProvider
import com.phenixrts.suite.groups.common.extensions.*
import com.phenixrts.suite.groups.databinding.ActivitySplashBinding
import com.phenixrts.suite.groups.models.*
import com.phenixrts.suite.groups.repository.RepositoryProvider
import com.phenixrts.suite.phenixcommon.common.launchMain
import timber.log.Timber
import javax.inject.Inject

class SplashActivity : EasyPermissionActivity() {

    @Inject lateinit var repositoryProvider: RepositoryProvider
    @Inject lateinit var preferenceProvider: PreferenceProvider
    private lateinit var binding: ActivitySplashBinding

    private val timeoutHandler = Handler(Looper.getMainLooper())
    private val timeoutRunnable = Runnable {
        launchMain {
            binding.root.showSnackBar(getString(R.string.err_network_problems))
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GroupsApplication.component.inject(this)
        binding = ActivitySplashBinding.inflate(layoutInflater)
        setContentView(binding.root)
        checkDeepLink(intent)
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        Timber.d("On new intent $intent")
        checkDeepLink(intent)
    }

    private fun checkDeepLink(intent: Intent?) {
        launchMain {
            val savedConfiguration = preferenceProvider.getConfiguration()
            val savedRoomAlias = preferenceProvider.getRoomAlias()
            Timber.d("Checking deep link: ${intent?.data} $savedConfiguration $savedRoomAlias")
            var deepLinkModel: DeepLinkModel? = null
            savedRoomAlias?.let { alias ->
                deepLinkModel = DeepLinkModel(alias)
            }
            if (intent?.data != null) {
                intent.data?.let { data ->
                    val roomCode = data.toString().takeIf { it.contains(ROOM_CODE_DELIMITER) }
                        ?.substringAfterLast(ROOM_CODE_DELIMITER)
                    deepLinkModel = DeepLinkModel(roomCode)
                    val uri = data.getQueryParameter(QUERY_URI) ?: BuildConfig.PCAST_URL
                    val backend = data.getQueryParameter(QUERY_BACKEND) ?: BuildConfig.BACKEND_URL
                    val configuration = RoomExpressConfiguration(uri, backend)
                    Timber.d("Checking deep link: $roomCode $uri $backend")
                    if (repositoryProvider.hasConfigurationChanged(configuration)) {
                        if (repositoryProvider.isRoomExpressInitialized()) {
                            preferenceProvider.saveConfiguration(configuration)
                            preferenceProvider.saveRoomAlias(roomCode)
                            showAppRestartRequired()
                            return@launchMain
                        }
                        Timber.d("Repository not yet initialized")
                        repositoryProvider.reinitializeRoomExpress(configuration)
                        deepLinkModel?.hasConfigurationChanged = true
                    }
                }
            } else if (savedConfiguration != null) {
                repositoryProvider.reinitializeRoomExpress(savedConfiguration)
            }
            preferenceProvider.saveConfiguration(null)
            preferenceProvider.saveRoomAlias(null)

            if (arePermissionsGranted()) {
                showLandingScreen(deepLinkModel)
            } else {
                askForPermissions { granted ->
                    if (granted) {
                        showLandingScreen(deepLinkModel)
                    } else {
                        checkDeepLink(intent)
                    }
                }
            }
        }
    }

    private fun showAppRestartRequired() {
        AlertDialog.Builder(this@SplashActivity)
            .setCancelable(false)
            .setView(R.layout.view_popup)
            .setPositiveButton(getString(R.string.popup_ok)) { _, _ ->
                closeApp()
            }
            .create()
            .show()
    }

    private fun showLandingScreen(deepLinkModel: DeepLinkModel?) = launchMain {
        Timber.d("Waiting for PCast")
        timeoutHandler.postDelayed(timeoutRunnable, TIMEOUT_DELAY)
        repositoryProvider.waitForPCast()
        timeoutHandler.removeCallbacks(timeoutRunnable)
        Timber.d("Navigating to Landing Screen")
        val intent = Intent(this@SplashActivity, MainActivity::class.java)
        deepLinkModel?.let { model ->
            intent.putExtra(EXTRA_DEEP_LINK_MODEL, model)
        }
        startActivity(intent)
        finish()
    }

    private companion object {
        private const val TIMEOUT_DELAY = 5000L
        private const val ROOM_CODE_DELIMITER = "#"
    }
}
