/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens.fragments

import android.os.Bundle
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.Observer
import com.phenixrts.common.RequestStatus
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.common.extensions.*
import com.phenixrts.suite.groups.phenix.RoomExpressRepository
import com.phenixrts.suite.groups.ui.screens.JoinScreen
import com.phenixrts.suite.groups.ui.screens.LoadingScreen
import com.phenixrts.suite.groups.ui.screens.RoomScreen
import com.phenixrts.suite.groups.viewmodels.GroupsViewModel
import kotlinx.coroutines.*
import timber.log.Timber
import javax.inject.Inject

abstract class BaseFragment : Fragment() {

    private val mainScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    /**
     * The shared view model containing all necessary view data
     */
    val viewModel: GroupsViewModel by lazyViewModel { GroupsViewModel(cacheProvider) }

    @Inject
    lateinit var roomExpressRepository: RoomExpressRepository
    @Inject
    lateinit var cacheProvider: CacheProvider

    open fun onBackPressed() {}

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        injectDependencies()

        handleExceptions()
    }

    /**
     * Listen for Phenix SDK exceptions and terminate app in case an exception has occurred
     */
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
     * Join just created room with given room ID
     */
    fun joinRoomById(roomId: String) {
        showLoadingScreen()
        roomExpressRepository.launch {
            val status = roomExpressRepository.joinRoomById(roomId, viewModel.screenName)
            hideLoadingScreen()
            if (status == RequestStatus.OK) {
                launchFragment(RoomScreen())
            } else {
                showToast(getString(R.string.err_join_room_failed))
            }
        }
    }

    /**
     * Join just created room with given room alias
     */
    fun joinRoomByAlias(roomAlias: String) {
        showLoadingScreen()
        roomExpressRepository.launch {
            val status = roomExpressRepository.joinRoomByAlias(roomAlias, viewModel.screenName)
            hideLoadingScreen()
            if (status == RequestStatus.OK) {
                launchFragment(RoomScreen())
            } else {
                showToast(getString(R.string.err_join_room_failed))
            }
        }
    }

    /**
     * Launch a new Fragment on Main thread
     */
    fun launchFragment(fragment: Fragment, addToBackStack: Boolean = true) {
        launch {
            parentFragmentManager.run {
                if (fragments.lastOrNull() is JoinScreen) {
                    popBackStackImmediate()
                }
                val transaction = beginTransaction()
                    .replace(R.id.fragment, fragment, fragment.javaClass.name)
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
                        .add(R.id.fragment, LoadingScreen(), LoadingScreen::class.java.name)
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
}
