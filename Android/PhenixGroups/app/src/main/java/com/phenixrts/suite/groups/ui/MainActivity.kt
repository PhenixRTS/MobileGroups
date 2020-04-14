/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui

import android.Manifest
import android.content.res.ColorStateList
import android.content.res.Configuration
import android.os.Bundle
import android.os.Handler
import android.view.View
import androidx.core.content.ContextCompat
import androidx.databinding.DataBindingUtil
import androidx.lifecycle.Observer
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.phenixrts.common.RequestStatus
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.cache.PreferenceProvider
import com.phenixrts.suite.groups.common.extensions.*
import com.phenixrts.suite.groups.databinding.ActivityMainBinding
import com.phenixrts.suite.groups.receivers.CellularStateReceiver
import com.phenixrts.suite.groups.repository.RoomExpressRepository
import com.phenixrts.suite.groups.repository.UserMediaRepository
import com.phenixrts.suite.groups.ui.screens.RoomScreen
import com.phenixrts.suite.groups.ui.screens.SplashScreen
import com.phenixrts.suite.groups.ui.screens.fragments.BaseFragment
import com.phenixrts.suite.groups.viewmodels.GroupsViewModel
import kotlinx.android.synthetic.main.activity_main.*
import kotlinx.android.synthetic.main.view_bottom_menu.*
import kotlinx.coroutines.*
import timber.log.Timber
import javax.inject.Inject
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class MainActivity : EasyPermissionActivity() {

    @Inject lateinit var roomExpressRepository: RoomExpressRepository
    @Inject lateinit var userMediaRepository: UserMediaRepository
    @Inject lateinit var cacheProvider: CacheProvider
    @Inject lateinit var preferenceProvider: PreferenceProvider
    @Inject lateinit var cellularStateReceiver: CellularStateReceiver

    private val bottomMenu by lazy { BottomSheetBehavior.from(bottom_menu) }
    private val sheetListener = object : BottomSheetBehavior.BottomSheetCallback() {
        override fun onSlide(bottomSheet: View, slideOffset: Float) {
            menu_background.visibility = View.VISIBLE
            menu_background.alpha = slideOffset
        }

        override fun onStateChanged(bottomSheet: View, newState: Int) {
            if (newState == BottomSheetBehavior.STATE_HIDDEN || newState == BottomSheetBehavior.STATE_COLLAPSED) {
                menu_background.visibility = View.GONE
                menu_background.alpha = 0f
            }
        }
    }

    private val timerHandler = Handler()
    private val timerRunnable = Runnable {
        launchMain {
            if (viewModel.isInRoom.isTrue()) {
                Timber.d("Hiding controls")
                viewModel.isControlsEnabled.value = false
            }
        }
    }

    private val viewModel: GroupsViewModel by lazyViewModel {
        GroupsViewModel(cacheProvider, preferenceProvider, roomExpressRepository, userMediaRepository)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GroupsApplication.component.inject(this)
        DataBindingUtil.setContentView<ActivityMainBinding>(this, R.layout.activity_main).apply {
            model = viewModel
            lifecycleOwner = this@MainActivity
        }
        handleExceptions()
        observeCellularState()
        initViews(savedInstanceState == null)
    }

    override fun onDestroy() {
        super.onDestroy()
        bottomMenu.removeBottomSheetCallback(sheetListener)
        cellularStateReceiver.unregister()
    }

    override fun onBackPressed() {
        supportFragmentManager.run {
            fragments.forEach {
                if (it is BaseFragment) {
                    it.onBackPressed()
                }
            }
        }
        if (bottomMenu.state == BottomSheetBehavior.STATE_EXPANDED) {
            hideBottomMenu()
        } else {
            super.onBackPressed()
        }
    }

    private fun initViews(firstLaunch: Boolean) {
        camera_button.setOnClickListener {
            launchMain {
                restartTimer()
                if (!cellularStateReceiver.isInCall()) {
                    val enabled = !viewModel.isVideoEnabled.isTrue(true)
                    setCameraPreviewEnabled(enabled)
                }
            }
        }
        microphone_button.setOnClickListener {
            launchMain {
                restartTimer()
                if (!cellularStateReceiver.isInCall()) {
                    val enabled = !viewModel.isMicrophoneEnabled.isTrue(true)
                    setMicrophoneEnabled(enabled)
                }
            }
        }
        preview_container.setOnClickListener {
            launchMain {
                if (viewModel.isInRoom.isTrue()) {
                    restartTimer()
                    if (tryHideRoomScreen()) {
                        viewModel.isControlsEnabled.value = true
                    } else {
                        val enabled = viewModel.isControlsEnabled.value?.not() ?: true
                        Timber.d("Switching controls: $enabled")
                        viewModel.isControlsEnabled.value = enabled
                    }
                }
            }
        }
        end_call_button.setOnClickListener {
            hideKeyboard()
            onBackPressed()
        }

        bottomMenu.addBottomSheetCallback(sheetListener)
        menu_button.setOnClickListener { switchMenu() }
        menu_background.setOnClickListener { hideBottomMenu() }
        menu_close.setOnClickListener { hideBottomMenu() }
        menu_switch_camera.setOnClickListener {
            launchMain {
                hideBottomMenu()
                delay(BOTTOM_MENU_DELAY)
                launchIO {
                    viewModel.switchCameraFacing()
                }
            }
        }

        main_landscape_members_holder.setOnClickListener {
            restartTimer()
            showRoomScreen(0)
        }

        main_landscape_chat.setOnClickListener {
            restartTimer()
            showRoomScreen(1)
        }

        main_landscape_info.setOnClickListener {
            restartTimer()
            showRoomScreen(2)
        }

        // Show splash screen if wasn't started already
        if (firstLaunch) {
            supportFragmentManager
                .beginTransaction()
                .replace(R.id.fullscreen_fragment_container, SplashScreen(), SplashScreen::class.java.name)
                .addToBackStack(SplashScreen::class.java.name)
                .commit()
        }
        viewModel.initObservers(this)
        viewModel.isMicrophoneEnabled.observe(this, Observer { enabled ->
            val color = ContextCompat.getColor(this, if (enabled) R.color.accentGrayColor else R.color.accentColor)
            microphone_button.setImageResource(if (enabled) R.drawable.ic_mic_on else R.drawable.ic_mic_off)
            microphone_button.backgroundTintList = ColorStateList.valueOf(color)
            if (viewModel.isInRoom.isFalse()) {
                active_member_mic.visibility = if (enabled) View.GONE else View.VISIBLE
            }
        })
        viewModel.isVideoEnabled.observe(this, Observer { enabled ->
            val color = ContextCompat.getColor(this, if (enabled) R.color.accentGrayColor else R.color.accentColor)
            camera_button.setImageResource(if (enabled) R.drawable.ic_camera_on else R.drawable.ic_camera_off)
            camera_button.backgroundTintList = ColorStateList.valueOf(color)
            showUserVideoPreview(enabled)
        })
        viewModel.memberCount.observe(this, Observer { memberCount ->
            val label =  if (memberCount > 0) getString(R.string.tab_members_count, memberCount) else " "
            main_landscape_member_count.visibility = if (memberCount > 0) View.VISIBLE else View.GONE
            main_landscape_member_count.text = label
        })
        viewModel.isControlsEnabled.observe(this, Observer { enabled ->
            if (enabled) {
                showTopMenu()
            } else {
                hideTopMenu()
            }
        })

        launchMain {
            Timber.d("Init user media: ${viewModel.isVideoEnabled.value} ${viewModel.isMicrophoneEnabled.value}")
            setMicrophoneEnabled(viewModel.isMicrophoneEnabled.isTrue(true))
            setCameraPreviewEnabled(viewModel.isVideoEnabled.isTrue(true))
        }
    }

    private fun observeCellularState() {
        cellularStateReceiver.observeCellularState(object: CellularStateReceiver.OnCallStateChanged {
            override fun onAnswered() {
                Timber.d("On Call Answered")
                viewModel.isMicrophoneEnabled.value = false
                viewModel.isVideoEnabled.value = false
            }

            override fun onHungUp() {
                Timber.d("On Call Hung Up")
                if (hasRecordAudioPermission()) {
                    viewModel.isMicrophoneEnabled.value = true
                }
                if (hasCameraPermission()) {
                    viewModel.isVideoEnabled.value = true
                }
            }
        })
    }

    private fun handleExceptions() {
        roomExpressRepository.roomStatus.observe(this, Observer {
            if (it.status != RequestStatus.OK) {
                closeApp(it.message)
            }
        })
        userMediaRepository.observeMediaState(object: UserMediaRepository.OnMediaStateChange {
            override fun onMicrophoneLost() {
                showToast(getString(R.string.err_microphone_lost))
                viewModel.isMicrophoneEnabled.value = false
            }

            override fun onCameraLost() {
                closeApp(getString(R.string.err_camera_lost))
            }
        })
    }

    private fun restartTimer() {
        if (viewModel.isInRoom.isTrue()) {
            timerHandler.removeCallbacks(timerRunnable)
            timerHandler.postDelayed(timerRunnable, HIDE_CONTROLS_DELAY)
        }
    }

    private fun switchMenu() {
        if (bottomMenu.state != BottomSheetBehavior.STATE_EXPANDED) {
            showBottomMenu()
        } else {
            hideBottomMenu()
        }
    }

    private fun showTopMenu() {
        if (main_menu_holder.alpha == MENU_INVISIBLE) {
            Timber.d("Showing top menu")
            main_menu_holder.visibility = View.VISIBLE
            main_menu_holder.animate()
                .setStartDelay(MENU_FADE_DURATION)
                .setDuration(MENU_FADE_DURATION)
                .alpha(MENU_VISIBLE)
                .withEndAction {
                    main_menu_holder.alpha = MENU_VISIBLE
                }.start()
        }
    }

    private fun hideTopMenu() {
        if (main_menu_holder.alpha == MENU_VISIBLE) {
            Timber.d("Hiding top menu")
            main_menu_holder.animate()
                .setStartDelay(0)
                .setDuration(MENU_FADE_DURATION)
                .alpha(MENU_INVISIBLE)
                .withEndAction {
                    main_menu_holder.alpha = MENU_INVISIBLE
                    main_menu_holder.visibility = View.GONE
                }.start()
        }
    }

    fun showBottomMenu() {
        Timber.d("Showing bottom menu")
        bottomMenu.state = BottomSheetBehavior.STATE_EXPANDED
    }

    private fun hideBottomMenu() {
        Timber.d("Hiding bottom menu")
        bottomMenu.state = BottomSheetBehavior.STATE_HIDDEN
    }

    private fun showRoomScreen(selectedTab: Int) {
        if (resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            hideTopMenu()
            (supportFragmentManager.findFragmentByTag(RoomScreen::class.java.name) as? RoomScreen)?.let { roomScreen ->
                roomScreen.selectTab(selectedTab)
                roomScreen.fadeIn()
            }
        }
    }

    private fun tryHideRoomScreen(): Boolean {
        if (resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            (supportFragmentManager.findFragmentByTag(RoomScreen::class.java.name) as? RoomScreen)?.tryFadeOut()?.let { fadedOut ->
                return fadedOut
            }
        }
        return false
    }

    private fun showUserVideoPreview(enabled: Boolean) = launchMain {
        if (viewModel.isInRoom.isFalse()) {
            if (enabled) {
                val response = viewModel.startUserMediaPreview(main_surface_view.holder)
                Timber.d("Preview started: ${response.status}")
                if (response.status == RequestStatus.OK) {
                    main_surface_view.visibility = View.VISIBLE
                    if (viewModel.isVideoEnabled.isFalse()) {
                        viewModel.isVideoEnabled.value = true
                    }
                } else {
                    showToast(response.message)
                    if (viewModel.isVideoEnabled.isTrue()) {
                        viewModel.isVideoEnabled.value = false
                    }
                }
            } else {
                main_surface_view.visibility = View.GONE
            }
        }
    }

    private suspend fun setCameraPreviewEnabled(enabled: Boolean): Unit = suspendCoroutine { continuation ->
        Timber.d("Camera preview enabled: $enabled")
        askForPermission(Manifest.permission.CAMERA) { granted ->
            launchMain {
                viewModel.isVideoEnabled.value = granted && enabled
                Timber.d("Camera state changed: $enabled $granted")
                continuation.resume(Unit)
            }
        }
    }

    private suspend fun setMicrophoneEnabled(enabled: Boolean): Unit = suspendCoroutine { continuation ->
        Timber.d("Microphone enabled: $enabled")
        askForPermission(Manifest.permission.RECORD_AUDIO) { granted ->
            launchMain {
                viewModel.isMicrophoneEnabled.value = granted && enabled
                Timber.d("Microphone state changed: $enabled $granted")
                continuation.resume(Unit)
            }
        }
    }

    private companion object {
        private const val HIDE_CONTROLS_DELAY = 5000L
        private const val BOTTOM_MENU_DELAY = 200L
        private const val MENU_FADE_DURATION = 300L
        private const val MENU_VISIBLE = 1f
        private const val MENU_INVISIBLE = 0f
    }

}
