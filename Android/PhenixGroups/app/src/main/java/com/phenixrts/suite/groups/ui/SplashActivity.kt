/*
 * Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui

import android.annotation.SuppressLint
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.appcompat.app.AlertDialog
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.common.extensions.*
import com.phenixrts.suite.groups.databinding.ActivitySplashBinding
import com.phenixrts.suite.phenixcore.common.launchUI
import com.phenixrts.suite.phenixdeeplinks.models.DeepLinkStatus
import com.phenixrts.suite.phenixdeeplinks.models.PhenixDeepLinkConfiguration
import com.phenixrts.suite.phenixcore.repositories.models.PhenixError
import com.phenixrts.suite.phenixcore.repositories.models.PhenixEvent
import com.phenixrts.suite.phenixdeeplinks.common.init
import timber.log.Timber

@SuppressLint("CustomSplashScreen")
class SplashActivity : EasyPermissionActivity() {

    private lateinit var binding: ActivitySplashBinding

    private val timeoutHandler = Handler(Looper.getMainLooper())
    private val timeoutRunnable = Runnable {
        launchUI {
            binding.root.showSnackBar(getString(R.string.err_network_problems))
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        Timber.d("Splash activity created")
        super.onCreate(savedInstanceState)
        binding = ActivitySplashBinding.inflate(layoutInflater)
        setContentView(binding.root)
        launchUI {
            phenixCore.onError.collect { error ->
                if (error == PhenixError.FAILED_TO_INITIALIZE || error == PhenixError.MISSING_TOKEN) {
                    Timber.d("Splash: Failed to initialize Phenix Core: $error")
                    showErrorDialog(error.message)
                }
            }
        }
        launchUI {
            phenixCore.onEvent.collect { event ->
                Timber.d("Splash: Phenix core event: $event")
                if (event == PhenixEvent.PHENIX_CORE_INITIALIZED) {
                    showLandingScreen()
                }
            }
        }
    }

    override fun onDeepLinkQueried(
        status: DeepLinkStatus,
        configuration: PhenixDeepLinkConfiguration,
        rawConfiguration: Map<String, String>,
        deepLink: String
    ) {
        launchUI {
            Timber.d("Deep link queried: $status, $deepLink")
            when (status) {
                DeepLinkStatus.RELOAD -> showAppRestartRequired()
                DeepLinkStatus.READY -> if (arePermissionsGranted()) {
                    initializePhenixCore(configuration)
                } else {
                    preferenceProvider.roomAlias = null
                    askForPermissions { granted ->
                        if (granted) {
                            initializePhenixCore(configuration)
                        } else {
                            onDeepLinkQueried(status, configuration, rawConfiguration, deepLink)
                        }
                    }
                }
            }
        }
    }

    private fun initializePhenixCore(configuration: PhenixDeepLinkConfiguration) = launchUI {
        timeoutHandler.postDelayed(timeoutRunnable, TIMEOUT_DELAY)
        Timber.d("Initializing phenix core: $configuration")
        phenixCore.init(configuration)
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

    private fun showLandingScreen() {
        timeoutHandler.removeCallbacks(timeoutRunnable)
        Timber.d("Navigating to Landing Screen")
        startActivity(Intent(this@SplashActivity, MainActivity::class.java))
        finish()
    }

    private companion object {
        private const val TIMEOUT_DELAY = 5000L
    }
}
