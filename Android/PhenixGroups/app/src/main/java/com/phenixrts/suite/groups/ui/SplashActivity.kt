/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui

import android.content.Intent
import android.os.Bundle
import android.os.Handler
import androidx.fragment.app.FragmentActivity
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.cache.PreferenceProvider
import com.phenixrts.suite.groups.common.extensions.*
import com.phenixrts.suite.groups.models.DeepLinkModel
import com.phenixrts.suite.groups.repository.RoomExpressRepository
import com.phenixrts.suite.groups.repository.UserMediaRepository
import com.phenixrts.suite.groups.viewmodels.GroupsViewModel
import timber.log.Timber
import javax.inject.Inject

class SplashActivity : FragmentActivity() {

    @Inject lateinit var roomExpressRepository: RoomExpressRepository
    @Inject lateinit var userMediaRepository: UserMediaRepository
    @Inject lateinit var cacheProvider: CacheProvider
    @Inject lateinit var preferenceProvider: PreferenceProvider

    private val viewModel: GroupsViewModel by lazyViewModel {
        GroupsViewModel(cacheProvider, preferenceProvider, roomExpressRepository, userMediaRepository)
    }

    private val timeoutHandler = Handler()
    private val timeoutRunnable = Runnable {
        launchMain {
            showSnackBar(getString(R.string.err_network_problems))
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GroupsApplication.component.inject(this)
        setContentView(R.layout.activity_splash)
        checkDeepLink(intent)
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        Timber.d("On new intent $intent")
        checkDeepLink(intent)
    }

    private fun checkDeepLink(intent: Intent?) = launchMain {
        Timber.d("Checking deep link: ${intent?.data}")
        var deepLinkModel: DeepLinkModel? = null
        intent?.data?.let { data ->
            val roomCode = data.toString().takeIf { it.contains("#") }?.substringAfterLast("#")
            val uri = data.getQueryParameter(QUERY_URI)
            val backend = data.getQueryParameter(QUERY_BACKEND)
            DeepLinkModel(roomCode, uri, backend).let { model ->
                deepLinkModel = model
                if (GroupsApplication.module.hasUrisChanged(model)) {
                    roomExpressRepository = GroupsApplication.module.provideRoomExpressRepository(cacheProvider)
                    userMediaRepository = GroupsApplication.module.provideUserMediaRepository(roomExpressRepository)
                    viewModel.updateRepositories(roomExpressRepository, userMediaRepository)
                    Timber.d("URIs changed - view model updated")
                }
            }
        }
        showLandingScreen(deepLinkModel)
    }

    private fun showLandingScreen(deepLinkModel: DeepLinkModel?) = launchMain {
        Timber.d("Waiting for PCast")
        timeoutHandler.postDelayed(timeoutRunnable, TIMEOUT_DELAY)
        viewModel.waitForPCast()
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
        private const val QUERY_URI = "uri"
        private const val QUERY_BACKEND = "backend"
    }
}
