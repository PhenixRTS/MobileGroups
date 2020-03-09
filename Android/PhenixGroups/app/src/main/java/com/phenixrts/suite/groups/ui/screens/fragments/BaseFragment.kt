/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens.fragments

import android.os.Bundle
import android.view.SurfaceHolder
import androidx.fragment.app.Fragment
import androidx.lifecycle.Observer
import com.phenixrts.common.RequestStatus
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.cache.PreferenceProvider
import com.phenixrts.suite.groups.common.extensions.*
import com.phenixrts.suite.groups.repository.RoomExpressRepository
import com.phenixrts.suite.groups.repository.UserMediaRepository
import com.phenixrts.suite.groups.ui.MainActivity
import com.phenixrts.suite.groups.ui.screens.JoinScreen
import com.phenixrts.suite.groups.ui.screens.LoadingScreen
import com.phenixrts.suite.groups.ui.screens.SplashScreen
import com.phenixrts.suite.groups.viewmodels.GroupsViewModel
import kotlinx.android.synthetic.main.activity_main.*
import kotlinx.coroutines.*
import timber.log.Timber
import javax.inject.Inject
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

abstract class BaseFragment : Fragment() {

    @Inject lateinit var roomExpressRepository: RoomExpressRepository
    @Inject lateinit var userMediaRepository: UserMediaRepository
    @Inject lateinit var cacheProvider: CacheProvider
    @Inject lateinit var preferenceProvider: PreferenceProvider

    private val mainScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    val viewModel: GroupsViewModel by lazyViewModel {
        GroupsViewModel(cacheProvider, preferenceProvider, roomExpressRepository, userMediaRepository,this)
    }

    open fun onBackPressed() {}

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        injectDependencies()
        handleExceptions()
    }

    private fun handleExceptions() {
        roomExpressRepository.roomStatus.observe(this, Observer {
            if (it.status != RequestStatus.OK) {
                closeApp(it.message)
            }
        })
    }

    /**
     * Launch a suspendable function on main tread
     */
    fun launch(block: suspend CoroutineScope.() -> Unit) = mainScope.launch(
        context = CoroutineExceptionHandler { _, e -> Timber.e("Coroutine failed: ${e.localizedMessage}") },
        block = block
    )

    /**
     * Launch a new Fragment on Main thread
     */
    fun launchFragment(fragment: Fragment, addToBackStack: Boolean = true) {
        launch {
            parentFragmentManager.run {
                val fullscreen = fragment is JoinScreen
                val container = if (fullscreen) R.id.fullscreen_fragment_container else R.id.fragment_container
                if (fragments.lastOrNull() is JoinScreen || fragments.lastOrNull() is SplashScreen) {
                    popBackStackImmediate()
                }
                val transaction = beginTransaction()
                    .replace(container, fragment, fragment.javaClass.name)
                if (addToBackStack) {
                    transaction.addToBackStack(fragment.javaClass.name)
                }
                transaction.commit()
            }
        }
    }

    /**
     * Show loading screen overlay
     */
    fun showLoadingScreen() {
        Timber.d("Showing loading")
        launch {
            parentFragmentManager.run {
                if (findFragmentByTag(LoadingScreen::class.java.name) == null) {
                    beginTransaction()
                        .add(R.id.fullscreen_fragment_container, LoadingScreen(), LoadingScreen::class.java.name)
                        .commitNow()
                }
            }
        }
    }

    /**
     * Hide loading screen overlay
     */
    fun hideLoadingScreen() {
        Timber.d("Hiding loading")
        launch {
            parentFragmentManager.run {
                findFragmentByTag(LoadingScreen::class.java.name)?.let {
                    Timber.d("Hiding loading $it")
                    beginTransaction().remove(it).commitNowAllowingStateLoss()
                }
            }
        }
    }

    /**
     * Used to dismiss a fragment and navigate up the stack
     */
    fun dismissFragment() {
        hideKeyboard()
        requireActivity().onBackPressed()
    }

    fun restartVideoPreview() = launch {
        Timber.d("Restarting video preview")
        viewModel.startMediaPreview(getSurfaceHolder())
    }

    suspend fun getSurfaceHolder(): SurfaceHolder = suspendCoroutine { continuation ->
        val surface = (requireActivity() as MainActivity).video_surface
        surface.post {
            continuation.resume(surface.holder)
        }
    }

}
