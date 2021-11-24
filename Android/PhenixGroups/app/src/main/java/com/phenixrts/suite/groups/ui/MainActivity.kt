/*
 * Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui

import android.content.Intent
import android.content.res.ColorStateList
import android.content.res.Configuration
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.View
import androidx.core.content.ContextCompat
import com.phenixrts.suite.groups.BuildConfig
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.common.extensions.*
import com.phenixrts.suite.groups.databinding.ActivityMainBinding
import com.phenixrts.suite.groups.receivers.CellularStateReceiver
import com.phenixrts.suite.groups.services.CameraForegroundService
import com.phenixrts.suite.groups.ui.screens.LandingScreen
import com.phenixrts.suite.groups.ui.screens.RoomScreen
import com.phenixrts.suite.groups.ui.screens.fragments.BaseFragment
import com.phenixrts.suite.groups.ui.viewmodels.GroupsViewModel
import com.phenixrts.suite.phenixcore.common.launchUI
import com.phenixrts.suite.phenixdeeplinks.models.DeepLinkStatus
import com.phenixrts.suite.phenixdeeplinks.models.PhenixDeepLinkConfiguration
import com.phenixrts.suite.phenixcore.repositories.models.PhenixError
import com.phenixrts.suite.phenixcore.repositories.models.PhenixEvent
import com.phenixrts.suite.phenixcore.repositories.models.PhenixMember
import kotlinx.coroutines.Runnable
import kotlinx.coroutines.delay
import timber.log.Timber

class MainActivity : EasyPermissionActivity() {

    lateinit var binding: ActivityMainBinding

    private val viewModel: GroupsViewModel by lazyViewModel({ application as GroupsApplication }, {
        GroupsViewModel(cacheProvider, preferenceProvider, phenixCore)
    })

    val menuHandler: MenuHandler by lazy { MenuHandler(binding, viewModel) }

    private val cameraService by lazy { Intent(this, CameraForegroundService::class.java) }
    private val timerHandler = Handler(Looper.getMainLooper())
    private val timerRunnable = Runnable {
        launchUI {
            if (viewModel.isInRoom) {
                Timber.d("Hiding controls")
                viewModel.enableControls(false)
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        binding.isInRoom = false
        binding.controlsEnabled = false
        binding.dataLost = false
        binding.lifecycleOwner = this@MainActivity
        setContentView(binding.root)
        observeCellularState()
        initViews(savedInstanceState == null)
    }

    override fun onDeepLinkQueried(
        status: DeepLinkStatus,
        configuration: PhenixDeepLinkConfiguration,
        rawConfiguration: Map<String, String>,
        deepLink: String
    ) {
        Timber.d("Deep link queried: $status, $deepLink")
        launchUI {
            if (viewModel.isInRoom) {
                Timber.d("Leaving current room")
                onBackPressed()
                showLoadingScreen()
                delay(LEAVE_ROOM_DELAY)
            }
            val roomAlias = configuration.channels.firstOrNull()
            if (roomAlias != null) {
                Timber.d("Joining deep link room: $roomAlias")
                joinRoom(roomAlias)
            } else {
                hideLoadingScreen()
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        menuHandler.onStop()
        binding.debugMenu.onStop()
        cellularStateReceiver.unregister()
        switchCameraForegroundService(false)
    }

    override fun onBackPressed() {
        supportFragmentManager.run {
            fragments.forEach {
                (it as? BaseFragment)?.onBackPressed()
            }
        }
        if (menuHandler.isClosed() && binding.debugMenu.isClosed()) {
            super.onBackPressed()
        }
    }

    private fun joinRoom(roomAlias: String) {
        if (!hasCameraPermission()) {
            askForPermissions { joinRoom(roomAlias) }
            Timber.d("No camera permission")
            return
        }
        hideKeyboard()
        showLoadingScreen()
        viewModel.joinRoom(roomAlias = roomAlias)
    }

    private fun initViews(firstLaunch: Boolean) {
        binding.cameraButton.setOnClickListener {
            Timber.d("Camera button clicked")
            restartTimer()
            if (!cellularStateReceiver.isInCall()) {
                viewModel.enableVideo(!viewModel.isVideoEnabled)
            }
        }
        binding.microphoneButton.setOnClickListener {
            Timber.d("Microphone button clicked")
            restartTimer()
            if (!cellularStateReceiver.isInCall()) {
                viewModel.enableAudio(!viewModel.isAudioEnabled)
            }
        }
        binding.previewContainer.setOnClickListener {
            if (viewModel.isInRoom) {
                restartTimer()
                if (tryHideRoomScreen()) {
                    viewModel.enableControls(true)
                } else {
                    viewModel.enableControls(!viewModel.areControlsEnabled)
                }
            }
        }
        binding.endCallButton.setOnClickListener {
            hideKeyboard()
            onBackPressed()
        }

        binding.mainLandscapeMembersHolder.setOnClickListener {
            restartTimer()
            showRoomScreen(0)
        }

        binding.mainLandscapeChat.setOnClickListener {
            restartTimer()
            showRoomScreen(1)
        }

        binding.mainLandscapeInfo.setOnClickListener {
            restartTimer()
            showRoomScreen(2)
        }

        if (firstLaunch) {
            launchFragment(LandingScreen(), false)
        }

        launchUI {
            viewModel.members.collect { members ->
                Timber.d("Members collected: $members")
                binding.isDataLost = members.firstOrNull { it.isSelected }?.isDataLost ?: false
                val audioEnabled = members.firstOrNull { it.isSelected }?.isAudioEnabled ?: true
                binding.activeMemberMic.setVisibleOr(!audioEnabled)

                // Selected member
                var isAnyMemberSelected = false
                members.firstOrNull { it.isSelected }?.let { selectedMember ->
                    isAnyMemberSelected = true
                    updateMainSurface(selectedMember)
                }
                // Pick loudest if no one is selected
                if (!isAnyMemberSelected) {
                    members.maxByOrNull { it.volume }?.let { loudestMember ->
                        updateMainSurface(loudestMember)
                    }
                }

                // Member count
                val label = if (members.isNotEmpty()) getString(R.string.tab_members_count, members.size) else " "
                binding.mainLandscapeMemberCount.visibility = if (members.isNotEmpty()) View.VISIBLE else View.GONE
                binding.mainLandscapeMemberCount.text = label
            }
        }

        launchUI {
            viewModel.messages.collect { messages ->
                val label = if (messages.size < 100) "${messages.size}" else getString(R.string.tab_message_count)
                binding.mainLandscapeMessageCount.visibility = if (messages.isNotEmpty()) View.VISIBLE else View.GONE
                binding.mainLandscapeMessageCount.text = label
            }
        }

        launchUI {
            viewModel.onVideoEnabled.collect { enabled ->
                updateVideoState(enabled)
            }
        }

        launchUI {
            viewModel.onAudioEnabled.collect { enabled ->
                updateAudioState(enabled)
            }
        }

        launchUI {
            viewModel.onControlsEnabled.collect { enabled ->
                binding.isInRoom = viewModel.isInRoom
                binding.controlsEnabled = enabled
                if (viewModel.isInRoom) {
                    if (enabled) {
                        menuHandler.showTopMenu()
                    } else {
                        menuHandler.hideTopMenu()
                    }
                }
            }
        }

        launchUI {
            phenixCore.onEvent.collect { event ->
                Timber.d("Phenix core event: $event")
                when (event) {
                    PhenixEvent.PHENIX_ROOM_PUBLISHING -> showLoadingScreen()
                    PhenixEvent.PHENIX_ROOM_PUBLISHED -> {
                        binding.isInRoom = true
                        hideLoadingScreen()
                        launchFragment(RoomScreen())
                    }
                    PhenixEvent.PHENIX_ROOM_LEFT -> {
                        binding.isInRoom = false
                        launchFragment(LandingScreen(), false)
                    }
                    else -> { /* Ignored */ }
                }
            }
        }

        launchUI {
            phenixCore.onError.collect { error ->
                when (error) {
                    PhenixError.JOIN_ROOM_FAILED -> showToast(getString(R.string.err_join_room_failed))
                    PhenixError.CREATE_ROOM_FAILED -> showToast(getString(R.string.err_create_room_failed))
                    PhenixError.SEND_MESSAGE_FAILED -> showToast(getString(R.string.err_chat_message_failed))
                    PhenixError.ROOM_GONE -> {
                        showToast(getString(R.string.err_network_problems))
                        viewModel.onConnectionLost()
                    }
                    else -> { /* Ignored */ }
                }
            }
        }
        menuHandler.onStart()
        viewModel.enableAudio(hasRecordAudioPermission() && !cellularStateReceiver.isInCall())
        viewModel.enableVideo(hasCameraPermission() && !cellularStateReceiver.isInCall())
        phenixCore.previewOnSurface(binding.mainSurfaceView)
        viewModel.observeDebugMenu(
            binding.debugMenu,
            onError = {
                showToast(getString(R.string.err_share_logs_failed))
            },
            onShow = {
                binding.debugMenu.showAppChooser(this@MainActivity)
            }
        )
        binding.debugMenu.onStart(getString(R.string.debug_app_version,
            BuildConfig.VERSION_NAME,
            BuildConfig.VERSION_CODE
        ), getString(R.string.debug_sdk_version,
            com.phenixrts.sdk.BuildConfig.VERSION_NAME,
            com.phenixrts.sdk.BuildConfig.VERSION_CODE
        ))
        switchCameraForegroundService(true)
    }

    private fun updateMainSurface(member: PhenixMember) {
        binding.mainSurfaceView.setVisibleOr(member.isVideoEnabled)
        binding.displayName = member.name
        if (member.isSelf) {
            phenixCore.previewOnSurface(binding.mainSurfaceView)
        } else {
            phenixCore.previewOnSurface(null)
            phenixCore.renderOnSurface(member.id, binding.mainSurfaceView)
        }
    }

    private fun updateVideoState(videoEnabled: Boolean) {
        Timber.d("Updating video state: $videoEnabled")
        val color = ContextCompat.getColor(this@MainActivity, if (videoEnabled) R.color.accentGrayColor else R.color.accentColor)
        binding.cameraButton.setImageResource(if (videoEnabled) R.drawable.ic_camera_on else R.drawable.ic_camera_off)
        binding.cameraButton.backgroundTintList = ColorStateList.valueOf(color)
        if (!viewModel.isInRoom) {
            binding.mainSurfaceView.setVisibleOr(videoEnabled)
        }
    }

    private fun updateAudioState(audioEnabled: Boolean) {
        Timber.d("Updating audio state: $audioEnabled")
        val color = ContextCompat.getColor(this@MainActivity, if (audioEnabled) R.color.accentGrayColor else R.color.accentColor)
        binding.microphoneButton.setImageResource(if (audioEnabled) R.drawable.ic_mic_on else R.drawable.ic_mic_off)
        binding.microphoneButton.backgroundTintList = ColorStateList.valueOf(color)
    }

    private fun switchCameraForegroundService(enabled: Boolean) {
        if (CameraForegroundService.isRunning() != enabled) {
            Timber.d(if (enabled) "Starting service" else "Stopping service")
            if (enabled) {
                ContextCompat.startForegroundService(this, cameraService)
            } else {
                stopService(cameraService)
                phenixCore.release()
                closeApp()
            }
        }
    }

    private fun observeCellularState() {
        cellularStateReceiver.observeCellularState(object: CellularStateReceiver.OnCallStateChanged {
            override fun onAnswered() {
                Timber.d("On Call Answered")
                viewModel.enableAudio(false)
                viewModel.enableVideo(false)
            }

            override fun onHungUp() {
                Timber.d("On Call Hung Up")
                viewModel.enableAudio(hasRecordAudioPermission())
                viewModel.enableVideo(hasCameraPermission())
            }
        })
    }

    private fun restartTimer() {
        if (viewModel.isInRoom) {
            timerHandler.removeCallbacks(timerRunnable)
            timerHandler.postDelayed(timerRunnable, HIDE_CONTROLS_DELAY)
        }
    }

    private fun showRoomScreen(selectedTab: Int) {
        if (resources.configuration.orientation == Configuration.ORIENTATION_LANDSCAPE) {
            menuHandler.hideTopMenu()
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

    private companion object {
        private const val HIDE_CONTROLS_DELAY = 5000L
        private const val LEAVE_ROOM_DELAY = 1000L
    }

}
