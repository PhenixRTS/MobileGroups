/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui

import android.Manifest
import android.os.Bundle
import android.os.Handler
import android.view.View
import androidx.databinding.DataBindingUtil
import com.google.android.material.bottomsheet.BottomSheetBehavior
import com.phenixrts.common.RequestStatus
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.cache.PreferenceProvider
import com.phenixrts.suite.groups.common.extensions.*
import com.phenixrts.suite.groups.databinding.ActivityMainBinding
import com.phenixrts.suite.groups.repository.RoomExpressRepository
import com.phenixrts.suite.groups.repository.UserMediaRepository
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
        launch {
            if (viewModel.isInRoom.isTrue()) {
                Timber.d("Hiding controls")
                viewModel.isControlsEnabled.value = false
            }
        }
    }

    private val viewModel: GroupsViewModel by lazyViewModel {
        GroupsViewModel(cacheProvider, preferenceProvider, roomExpressRepository, userMediaRepository,
            getSurfaceView().holder, this)
    }

    private val activityScope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        GroupsApplication.component.inject(this)

        DataBindingUtil.setContentView<ActivityMainBinding>(this, R.layout.activity_main).apply {
            model = viewModel
            lifecycleOwner = this@MainActivity
        }

        camera_button.setOnCheckedChangeListener { enabled ->
            launch {
                setCameraPreviewEnabled(enabled)
            }
        }
        microphone_button.setOnCheckedChangeListener(::setMicrophoneEnabled)
        preview_container.setOnClickListener {
            launch {
                if (viewModel.isInRoom.isTrue()) {
                    timerHandler.removeCallbacks(timerRunnable)
                    timerHandler.postDelayed(timerRunnable, HIDE_CONTROLS_DELAY)
                    val enabled = viewModel.isControlsEnabled.value?.not() ?: true
                    Timber.d("Switching controls: $enabled")
                    viewModel.isControlsEnabled.value = enabled
                }
            }
        }
        end_call_button.setOnClickListener {
            hideKeyboard()
            onBackPressed()
        }

        bottomMenu.addBottomSheetCallback(sheetListener)
        menu_button.setOnClickListener {
            switchMenu()
        }

        menu_background.setOnClickListener {
            hideBottomMenu()
        }

        menu_close.setOnClickListener {
            hideBottomMenu()
        }

        menu_switch_camera.setOnClickListener {
            launch {
                hideBottomMenu()
                delay(200)
                launch(Dispatchers.IO) {
                    viewModel.switchCameraFacing()
                }
            }
        }

        launch {
            setMicrophoneEnabled(viewModel.isMicrophoneEnabled.isTrue(true))
            setCameraPreviewEnabled(viewModel.isVideoEnabled.isTrue(true))
        }

        // Show splash screen if wasn't started already
        if (savedInstanceState == null) {
            supportFragmentManager
                .beginTransaction()
                .replace(R.id.fullscreen_fragment_container, SplashScreen(), SplashScreen::class.java.name)
                .addToBackStack(SplashScreen::class.java.name)
                .commit()
        }
        viewModel.initObservers(this)
    }

    override fun onDestroy() {
        super.onDestroy()
        bottomMenu.removeBottomSheetCallback(sheetListener)
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

    private fun launch(block: suspend CoroutineScope.() -> Unit) = activityScope.launch(
        context = CoroutineExceptionHandler { _, e -> Timber.e("Coroutine failed: ${e.localizedMessage}") },
        block = block
    )

    private fun switchMenu() {
        if (bottomMenu.state != BottomSheetBehavior.STATE_EXPANDED) {
            showBottomMenu()
        } else {
            hideBottomMenu()
        }
    }

    private fun showBottomMenu() {
        Timber.d("Showing bottom menu")
        bottomMenu.state = BottomSheetBehavior.STATE_EXPANDED
    }

    private fun hideBottomMenu() {
        Timber.d("Hiding bottom menu")
        bottomMenu.state = BottomSheetBehavior.STATE_HIDDEN
    }

    private suspend fun setCameraPreviewEnabled(enabled: Boolean): Unit = suspendCoroutine { continuation ->
        Timber.d("Camera preview enabled: $enabled")
        askForPermission(Manifest.permission.CAMERA) { granted ->
            launch {
                if (!granted) {
                    camera_button.isChecked = false
                    viewModel.isVideoEnabled.value = false
                } else {
                    previewUserVideo(enabled)
                }
                Timber.d("Camera permission granted: $enabled $granted")
                continuation.resume(Unit)
            }
        }
    }

    private fun setMicrophoneEnabled(enabled: Boolean) {
        askForPermission(Manifest.permission.RECORD_AUDIO) { granted ->
            Timber.d("Mute clicked: $enabled ${viewModel.isInRoom.isFalse()}")
            if (!granted) {
                microphone_button.isChecked = false
                viewModel.isMicrophoneEnabled.value = false
                if (viewModel.isInRoom.isFalse()) {
                    active_member_mic.visibility = View.VISIBLE
                }
            } else if (viewModel.isInRoom.isFalse()) {
                viewModel.isMicrophoneEnabled.value = enabled
                active_member_mic.visibility = if (enabled) View.GONE else View.VISIBLE
            }
        }
    }

    private suspend fun previewUserVideo(start: Boolean) {
        Timber.d("Preview user video: $start")
        viewModel.isVideoEnabled.value = start
        if (viewModel.isInRoom.isFalse()) {
            if (start) {
                val response = viewModel.startUserMediaPreview(surface_view.holder)
                Timber.d("Preview started: ${response.status}")
                if (response.status == RequestStatus.OK) {
                    surface_view.visibility = View.VISIBLE
                } else {
                    showToast(response.message)
                }
            } else {
                surface_view.visibility = View.GONE
            }
        }
    }

    companion object {
        private const val HIDE_CONTROLS_DELAY = 5000L
    }

}
