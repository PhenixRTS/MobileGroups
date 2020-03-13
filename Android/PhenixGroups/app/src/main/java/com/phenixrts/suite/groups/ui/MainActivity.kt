/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui

import android.Manifest
import android.os.Bundle
import androidx.databinding.DataBindingUtil
import com.phenixrts.common.RequestStatus
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.cache.PreferenceProvider
import com.phenixrts.suite.groups.common.SurfaceIndex
import com.phenixrts.suite.groups.common.extensions.*
import com.phenixrts.suite.groups.databinding.ActivityMainBinding
import com.phenixrts.suite.groups.repository.RoomExpressRepository
import com.phenixrts.suite.groups.repository.UserMediaRepository
import com.phenixrts.suite.groups.ui.screens.SplashScreen
import com.phenixrts.suite.groups.ui.screens.fragments.BaseFragment
import com.phenixrts.suite.groups.viewmodels.GroupsViewModel
import kotlinx.android.synthetic.main.activity_main.*
import kotlinx.coroutines.*
import timber.log.Timber
import java.util.*
import javax.inject.Inject
import kotlin.concurrent.schedule
import kotlin.coroutines.resume
import kotlin.coroutines.suspendCoroutine

class MainActivity : EasyPermissionActivity() {

    @Inject lateinit var roomExpressRepository: RoomExpressRepository
    @Inject lateinit var userMediaRepository: UserMediaRepository
    @Inject lateinit var cacheProvider: CacheProvider
    @Inject lateinit var preferenceProvider: PreferenceProvider

    private var hideControlsTask: TimerTask? = null

    private val viewModel: GroupsViewModel by lazyViewModel {
        GroupsViewModel(cacheProvider, preferenceProvider, roomExpressRepository, userMediaRepository, this)
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
                viewModel.isControlsEnabled.value = true
                hideControlsTask?.cancel()
                hideControlsTask = Timer("hide buttons").schedule(HIDE_CONTROLS_DELAY) {
                    launch {
                        viewModel.isControlsEnabled.value = false
                    }
                }
            }
        }
        end_call_button.setOnClickListener {
            hideKeyboard()
            onBackPressed()
        }

        launch {
            setMicrophoneEnabled(viewModel.isMicrophoneEnabled.value ?: true)
            setCameraPreviewEnabled(viewModel.isVideoEnabled.value ?: true)
        }

        // Show splash screen if wasn't started already
        if (savedInstanceState == null) {
            supportFragmentManager
                .beginTransaction()
                .replace(R.id.fullscreen_fragment_container, SplashScreen(), SplashScreen::class.java.name)
                .addToBackStack(SplashScreen::class.java.name)
                .commit()
        }
    }

    override fun onBackPressed() {
        supportFragmentManager.run {
            fragments.forEach {
                if (it is BaseFragment) {
                    it.onBackPressed()
                }
            }
        }
        super.onBackPressed()
    }

    override fun onDestroy() {
        launch {
            Timber.d("App destroyed, stopping renderer")
            viewModel.disposeMediaRenderer()
        }
        super.onDestroy()
    }

    private fun launch(block: suspend CoroutineScope.() -> Unit) = activityScope.launch(
        context = CoroutineExceptionHandler { _, e -> Timber.e("Coroutine failed: ${e.localizedMessage}") },
        block = block
    )

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
        if (enabled) {
            askForPermission(Manifest.permission.RECORD_AUDIO) { granted ->
                if (!granted) {
                    microphone_button.isChecked = false
                    viewModel.isMicrophoneEnabled.value = false
                } else {
                    viewModel.isMicrophoneEnabled.value = enabled
                }
            }
        }
    }

    private suspend fun previewUserVideo(start: Boolean) {
        Timber.d("Preview user video: $start")
        viewModel.isVideoEnabled.value = start
        if (start) {
            val response = viewModel.startUserMediaPreview(surface_view_1.holder)
            Timber.d("Preview started: ${response.status}")
            if (response.status == RequestStatus.OK) {
                showGivenSurfaceView(SurfaceIndex.SURFACE_1)
            } else {
                showToast(response.message)
            }
        } else {
            // TODO: Probably should behave differently while in a room
            hideUnusedSurfaces()
            viewModel.stopUserMediaPreview()
        }
    }

    companion object {
        private const val HIDE_CONTROLS_DELAY = 5000L
    }

}
