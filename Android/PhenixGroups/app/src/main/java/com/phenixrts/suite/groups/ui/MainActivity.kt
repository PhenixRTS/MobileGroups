/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
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
import androidx.databinding.DataBindingUtil
import com.phenixrts.common.RequestStatus
import com.phenixrts.suite.groups.BuildConfig
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.cache.PreferenceProvider
import com.phenixrts.suite.groups.common.extensions.*
import com.phenixrts.suite.groups.databinding.ActivityMainBinding
import com.phenixrts.suite.groups.models.DeepLinkModel
import com.phenixrts.suite.groups.receivers.CellularStateReceiver
import com.phenixrts.suite.groups.repository.RepositoryProvider
import com.phenixrts.suite.groups.repository.UserMediaRepository
import com.phenixrts.suite.groups.ui.screens.LandingScreen
import com.phenixrts.suite.groups.ui.screens.RoomScreen
import com.phenixrts.suite.groups.ui.screens.fragments.BaseFragment
import com.phenixrts.suite.groups.viewmodels.GroupsViewModel
import com.phenixrts.suite.phenixcommon.DebugMenu
import com.phenixrts.suite.phenixcommon.common.FileWriterDebugTree
import com.phenixrts.suite.phenixcommon.common.launchMain
import kotlinx.android.synthetic.main.activity_main.*
import kotlinx.coroutines.Runnable
import kotlinx.coroutines.delay
import timber.log.Timber
import javax.inject.Inject
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

const val EXTRA_DEEP_LINK_MODEL = "ExtraDeepLinkModel"

class MainActivity : EasyPermissionActivity() {

    @Inject lateinit var repositoryProvider: RepositoryProvider
    @Inject lateinit var cacheProvider: CacheProvider
    @Inject lateinit var preferenceProvider: PreferenceProvider
    @Inject lateinit var cellularStateReceiver: CellularStateReceiver
    @Inject lateinit var fileWriterTree: FileWriterDebugTree

    private val viewModel: GroupsViewModel by lazyViewModel({ application as GroupsApplication }, {
        GroupsViewModel(cacheProvider, preferenceProvider, repositoryProvider)
    })

    private val debugMenu: DebugMenu by lazy {
        DebugMenu(fileWriterTree, repositoryProvider.roomExpress, main_root, { files ->
            debugMenu.showAppChooser(this, files)
        }, { error ->
            showToast(getString(error))
        })
    }
    val menuHandler: MenuHandler by lazy { MenuHandler(this, viewModel) }

    private val timerHandler = Handler(Looper.getMainLooper())
    private val timerRunnable = Runnable {
        launchMain {
            if (viewModel.isInRoom.isTrue()) {
                Timber.d("Hiding controls")
                viewModel.isControlsEnabled.value = false
            }
        }
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
        checkDeepLink(intent)
    }

    override fun onNewIntent(intent: Intent?) {
        super.onNewIntent(intent)
        Timber.d("On new intent $intent")
        checkDeepLink(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        menuHandler.onStop()
        debugMenu.onStop()
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
        if (menuHandler.isClosed() && debugMenu.isClosed()){
            super.onBackPressed()
        }
    }

    private fun checkDeepLink(intent: Intent?) = launchMain {
        intent?.let { intent ->
            if (intent.hasExtra(EXTRA_DEEP_LINK_MODEL)) {
                (intent.getSerializableExtra(EXTRA_DEEP_LINK_MODEL) as? DeepLinkModel)?.let { deepLinkModel ->
                    Timber.d("Received deep link: $deepLinkModel")
                    if (viewModel.isInRoom.isTrue() && deepLinkModel.isUpdated()) {
                        Timber.d("Leaving current room")
                        onBackPressed()
                        showLoadingScreen()
                        delay(LEAVE_ROOM_DELAY)
                    }
                    if (deepLinkModel.roomCode != null) {
                        Timber.d("Joining deep link room: $deepLinkModel")
                        joinRoom(viewModel, deepLinkModel.roomCode, preferenceProvider.getDisplayName())
                    } else {
                        hideLoadingScreen()
                    }
                }
                intent.removeExtra(EXTRA_DEEP_LINK_MODEL)
            }
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
                debugMenu.onScreenTapped()
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

        if (firstLaunch) {
            launchFragment(LandingScreen(), false)
        }
        viewModel.initObservers(this)
        viewModel.isMicrophoneEnabled.observe(this, { enabled ->
            val color = ContextCompat.getColor(this, if (enabled) R.color.accentGrayColor else R.color.accentColor)
            microphone_button.setImageResource(if (enabled) R.drawable.ic_mic_on else R.drawable.ic_mic_off)
            microphone_button.backgroundTintList = ColorStateList.valueOf(color)
            if (viewModel.isInRoom.isFalse()) {
                active_member_mic.visibility = if (enabled) View.GONE else View.VISIBLE
            }
        })
        viewModel.isVideoEnabled.observe(this, { enabled ->
            val color = ContextCompat.getColor(this, if (enabled) R.color.accentGrayColor else R.color.accentColor)
            camera_button.setImageResource(if (enabled) R.drawable.ic_camera_on else R.drawable.ic_camera_off)
            camera_button.backgroundTintList = ColorStateList.valueOf(color)
            showUserVideoPreview(enabled)
        })
        viewModel.memberCount.observe(this, { memberCount ->
            val label =  if (memberCount > 0) getString(R.string.tab_members_count, memberCount) else " "
            main_landscape_member_count.visibility = if (memberCount > 0) View.VISIBLE else View.GONE
            main_landscape_member_count.text = label
        })
        viewModel.unreadMessageCount.observe(this, { messageCount ->
            val label = if (messageCount < 100) "$messageCount" else getString(R.string.tab_message_count)
            main_landscape_message_count.visibility = if (messageCount > 0) View.VISIBLE else View.GONE
            main_landscape_message_count.text = label
        })
        viewModel.isControlsEnabled.observe(this, { enabled ->
            if (viewModel.isInRoom.isTrue()) {
                if (enabled) {
                    menuHandler.showTopMenu()
                } else {
                    menuHandler.hideTopMenu()
                }
            }
        })
        viewModel.onPermissionRequested.observe(this, {
            initMediaButtons()
        })
        viewModel.onRoomJoined.observe(this, { status ->
            launchMain {
                if (viewModel.isInRoom.isFalse()) {
                    Timber.d("Room joined with status: $status")
                    hideLoadingScreen()
                    if (status == RequestStatus.OK) {
                        launchFragment(RoomScreen())
                    } else if (status != RequestStatus.GONE) {
                        showToast(getString(R.string.err_join_room_failed))
                    }
                }
            }
        })
        initMediaButtons()
        menuHandler.onStart()
        debugMenu.onStart(getString(R.string.debug_app_version,
            BuildConfig.VERSION_NAME,
            BuildConfig.VERSION_CODE
        ), getString(R.string.debug_sdk_version,
            com.phenixrts.sdk.BuildConfig.VERSION_NAME,
            com.phenixrts.sdk.BuildConfig.VERSION_CODE
        ))
    }

    private fun initMediaButtons() = launchMain {
        Timber.d("Init user media buttons: ${viewModel.isVideoEnabled.value} ${viewModel.isMicrophoneEnabled.value}")
        setMicrophoneEnabled(viewModel.isMicrophoneEnabled.isTrue(true))
        setCameraPreviewEnabled(viewModel.isVideoEnabled.isTrue(true))
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
                viewModel.isMicrophoneEnabled.value = hasRecordAudioPermission()
                viewModel.isVideoEnabled.value = hasCameraPermission()
            }
        })
    }

    private fun handleExceptions() {
        repositoryProvider.onRoomStatusChanged.observe(this, {
            if (it.status != RequestStatus.OK) {
                closeApp(it.message)
            }
        })
        repositoryProvider.getUserMediaRepository()?.observeMediaState(object: UserMediaRepository.OnMediaStateChange {
            override fun onMicrophoneStateChanged(available: Boolean) {
                launchMain {
                    Timber.d("Microphone available: $available")
                    viewModel.isMicrophoneEnabled.value = available
                }
            }

            override fun onCameraStateChanged(available: Boolean) {
                launchMain {
                    Timber.d("Camera available: $available")
                    viewModel.isVideoEnabled.value = available
                }
            }
        })
    }

    private fun restartTimer() {
        if (viewModel.isInRoom.isTrue()) {
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

    private fun showUserVideoPreview(enabled: Boolean) = launchMain {
        if (viewModel.isInRoom.isFalse() && hasCameraPermission()) {
            if (enabled) {
                val response = viewModel.startUserMediaPreview(main_surface_view.holder)
                Timber.d("Preview started: ${response.status}")
                if (response.status == RequestStatus.OK) {
                    main_surface_view.visibility = View.VISIBLE
                    if (viewModel.isVideoEnabled.isFalse()) {
                        viewModel.isVideoEnabled.value = hasCameraPermission()
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
        launchMain {
            viewModel.isVideoEnabled.value = enabled
            Timber.d("Camera state changed: $enabled")
            continuation.resume(Unit)
        }
    }

    private suspend fun setMicrophoneEnabled(enabled: Boolean): Unit = suspendCoroutine { continuation ->
        Timber.d("Microphone enabled: $enabled")
        launchMain {
            viewModel.isMicrophoneEnabled.value = enabled
            Timber.d("Microphone state changed: $enabled")
            continuation.resume(Unit)
        }
    }

    private companion object {
        private const val HIDE_CONTROLS_DELAY = 5000L
        private const val LEAVE_ROOM_DELAY = 1000L
    }

}
