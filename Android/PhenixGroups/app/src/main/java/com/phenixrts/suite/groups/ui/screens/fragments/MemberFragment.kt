/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.lifecycle.Observer
import com.phenixrts.common.RequestStatus
import com.phenixrts.pcast.RendererStartStatus
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.common.SurfaceIndex
import com.phenixrts.suite.groups.common.extensions.*
import com.phenixrts.suite.groups.common.getSubscribeAudioOptions
import com.phenixrts.suite.groups.common.getSubscribeVideoOptions
import com.phenixrts.suite.groups.databinding.FragmentMembersBinding
import com.phenixrts.suite.groups.models.RoomMember
import com.phenixrts.suite.groups.ui.adapters.MemberListAdapter
import timber.log.Timber

class MemberFragment : BaseFragment(), MemberListAdapter.OnMemberListener {

    private lateinit var binding: FragmentMembersBinding

    private val adapter by lazy { MemberListAdapter(viewModel, this) }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        binding = FragmentMembersBinding.inflate(inflater)
        binding.lifecycleOwner = this
        binding.memberList.adapter = adapter

        viewModel.getRoomMembers().observe(viewLifecycleOwner, Observer { members ->
            Timber.d("Member adapter updated ${members.size} $members")
            if (members.isListUpdated(adapter.data)) {
                showMemberStreams(members)
            }
            adapter.data = members
        })
        return binding.root
    }

    override fun onMemberClicked(roomMember: RoomMember) {
        launch {
            getSurfaceView(SurfaceIndex.SURFACE_1)?.let { surfaceView ->
                var status = RequestStatus.OK
                if (roomMember.member.sessionId == viewModel.currentSessionsId.value) {
                    Timber.d("Self clicked")
                    status = viewModel.startUserMediaPreview(surfaceView.holder).status
                } else {
                    viewModel.restartMediaRenderer(roomMember.renderer, surfaceView.holder).let {
                        if (it != RendererStartStatus.OK) {
                            status = RequestStatus.FAILED
                        }
                    }
                }
                if (status == RequestStatus.OK) {
                    showGivenSurfaceView(SurfaceIndex.SURFACE_1)
                } else {
                    showToast(getString(R.string.err_failed_to_load_stream))
                }
            } ?: showToast(getString(R.string.err_failed_to_load_stream))
        }
    }

    private fun showMemberStreams(members: List<RoomMember>) = launch {
        hideUnusedSurfaces(members)
        if (members.size > 1) {
            members.forEach { roomMember ->
                val isSelf = roomMember.member.sessionId == viewModel.currentSessionsId.value
                val surfaceView = getSurfaceView(roomMember.surface)
                var status = if (roomMember.isSubscribed() || isSelf) RequestStatus.OK else RequestStatus.FAILED
                if (!roomMember.isSubscribed() && !isSelf) {
                    val options = if (surfaceView != null) {
                        getSubscribeVideoOptions(surfaceView.holder)
                    } else {
                        getSubscribeAudioOptions()
                    }
                    status = viewModel.subscribeToMemberStream(roomMember, options).status
                }
                surfaceView?.let {
                    if (status == RequestStatus.OK) {
                        val renderer = if (isSelf) viewModel.userMediaRenderer else roomMember.renderer
                        val renderStatus = viewModel.restartMediaRenderer(renderer, surfaceView.holder)
                        if (renderStatus == RendererStartStatus.OK) {
                            Timber.d("Showing surface: $roomMember")
                            surfaceView.visibility = View.VISIBLE
                        }
                    } else {
                        Timber.d("Hiding surface: $roomMember")
                        surfaceView.visibility = View.GONE
                    }
                }
            }
        } else {
            getSurfaceView(SurfaceIndex.SURFACE_1)?.let { surfaceView ->
                Timber.d("Showing self preview when all members are gone")
                showGivenSurfaceView(SurfaceIndex.SURFACE_1)
                viewModel.startUserMediaPreview(surfaceView.holder)
            }
        }
    }

}
