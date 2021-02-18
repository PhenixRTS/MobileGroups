/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.appcompat.app.AlertDialog
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.cache.PreferenceProvider
import com.phenixrts.suite.groups.common.extensions.*
import com.phenixrts.suite.groups.databinding.ActivitySplashBinding
import com.phenixrts.suite.groups.models.*
import com.phenixrts.suite.groups.repository.RepositoryProvider
import com.phenixrts.suite.phenixcommon.common.launchMain
import com.phenixrts.suite.phenixdeeplink.models.DeepLinkStatus
import com.phenixrts.suite.phenixdeeplink.models.PhenixConfiguration
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

    override fun isAlreadyInitialized() = repositoryProvider.isRoomExpressInitialized()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GroupsApplication.component.inject(this)
        binding = ActivitySplashBinding.inflate(layoutInflater)
        setContentView(binding.root)
    }

    override fun onDeepLinkQueried(status: DeepLinkStatus, configuration: PhenixConfiguration, deepLink: String) {
        launchMain {
            when (status) {
                DeepLinkStatus.RELOAD -> showAppRestartRequired()
                DeepLinkStatus.READY -> if (arePermissionsGranted()) {
                    showLandingScreen(configuration)
                } else {
                    preferenceProvider.saveRoomAlias(null)
                    askForPermissions { granted ->
                        if (granted) {
                            showLandingScreen(configuration)
                        } else {
                            onDeepLinkQueried(status, configuration, deepLink)
                        }
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

    private fun showLandingScreen(configuration: PhenixConfiguration) = launchMain {
        Timber.d("Waiting for PCast")
        timeoutHandler.postDelayed(timeoutRunnable, TIMEOUT_DELAY)
        repositoryProvider.setupRoomExpress(configuration)
        repositoryProvider.waitForPCast()
        timeoutHandler.removeCallbacks(timeoutRunnable)
        Timber.d("Navigating to Landing Screen")
        val intent = Intent(this@SplashActivity, MainActivity::class.java)
        intent.putExtra(EXTRA_DEEP_LINK_MODEL, configuration.channels.getOrNull(0) ?: "")
        startActivity(intent)
        finish()
    }

    private companion object {
        private const val TIMEOUT_DELAY = 5000L
    }
}
