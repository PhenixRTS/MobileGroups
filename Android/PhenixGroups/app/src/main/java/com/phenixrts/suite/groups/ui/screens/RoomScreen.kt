/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.animation.Animation
import android.view.animation.OvershootInterpolator
import android.view.animation.Transformation
import android.widget.FrameLayout
import androidx.viewpager.widget.ViewPager
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.common.extensions.hideKeyboard
import com.phenixrts.suite.groups.common.extensions.showBottomMenu
import com.phenixrts.suite.groups.databinding.ScreenRoomBinding
import com.phenixrts.suite.groups.ui.adapters.RoomScreenPageAdapter
import com.phenixrts.suite.groups.ui.screens.fragments.*
import timber.log.Timber

class RoomScreen : BaseFragment(), ViewPager.OnPageChangeListener {

    private lateinit var binding: ScreenRoomBinding

    private val adapter by lazy {
        RoomScreenPageAdapter(
            childFragmentManager,
            listOf(
                MemberFragment(),
                ChatFragment(),
                getInfoFragment()
            )
        )
    }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        binding = ScreenRoomBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        binding.fragmentPager.addOnPageChangeListener(this)
        binding.fragmentPager.offscreenPageLimit = 2
        binding.fragmentPager.adapter = adapter
        binding.fragmentTabLayout.setupWithViewPager(binding.fragmentPager)
        binding.roomMenuButton.setOnClickListener {
            showBottomMenu()
        }
        setMessageCount(0)
        refreshTabs()

        viewModel.isControlsEnabled.value = false
        viewModel.isInRoom.value = true

        viewModel.memberCount.observe(viewLifecycleOwner, { count ->
            Timber.d("Member count changed: $count")
            setMemberCount(count)
        })
        viewModel.unreadMessageCount.observe(viewLifecycleOwner, { count ->
            Timber.d("Unread message count changed: $count")
            setMessageCount(count)
        })
        Timber.d("Room screen created: ${viewModel.currentRoomAlias}")
    }

    override fun onBackPressed() {
        binding.fragmentPager.removeOnPageChangeListener(this)
        viewModel.leaveRoom()
    }

    override fun onPageScrollStateChanged(state: Int) { /* Ignored */ }

    override fun onPageScrolled(position: Int, positionOffset: Float, positionOffsetPixels: Int) { /* Ignored */ }

    override fun onPageSelected(position: Int) {
        viewModel.setViewingChat(position == TAB_CHAT)
        hideKeyboard()
    }

    private fun getInfoFragment(): InfoFragment {
        val fragment = InfoFragment()
        val bundle = Bundle()
        bundle.putString(EXTRA_ROOM_ALIAS, viewModel.currentRoomAlias)
        fragment.arguments = bundle
        return fragment
    }

    private fun setMemberCount(memberCount: Int) {
        val label =  if (memberCount > 0) resources.getString(R.string.tab_members_count, memberCount) else " "
        binding.fragmentTabLayout.getTabAt(TAB_MEMBERS)?.text = label
        refreshTabs()
    }

    private fun setMessageCount(messageCount: Int) {
        binding.fragmentTabLayout.getTabAt(TAB_CHAT)?.orCreateBadge?.apply {
            isVisible = messageCount > 0
            maxCharacterCount = 3
            number = messageCount
        }
        refreshTabs()
    }

    private fun refreshTabs() {
        binding.fragmentTabLayout.getTabAt(TAB_MEMBERS)?.setIcon(R.drawable.ic_people)
        binding.fragmentTabLayout.getTabAt(TAB_CHAT)?.setIcon(R.drawable.ic_chat)
        binding.fragmentTabLayout.getTabAt(TAB_INFO)?.setIcon(R.drawable.ic_info)
        binding.fragmentTabLayout.getTabAt(TAB_MEMBERS)?.view?.id = R.id.tab_members
        binding.fragmentTabLayout.getTabAt(TAB_CHAT)?.view?.id = R.id.tab_chat
        binding.fragmentTabLayout.getTabAt(TAB_INFO)?.view?.id = R.id.tab_info
    }

    fun selectTab(index: Int) {
        Timber.d("Selecting tab: $index")
        binding.fragmentPager.setCurrentItem(index, false)
    }

    fun fadeIn() {
        val params: FrameLayout.LayoutParams = binding.fragmentRoomRoot.layoutParams as FrameLayout.LayoutParams
        val currentOffset = params.rightMargin
        val offset = resources.getDimension(R.dimen.room_pager_offset_gone).toInt()
        if (currentOffset < 0) {
            Timber.d("Fading in")
            val animation: Animation = object : Animation() {
                override fun applyTransformation(interpolatedTime: Float, t: Transformation?) {
                    params.rightMargin = offset - (offset * interpolatedTime).toInt()
                    binding.fragmentRoomRoot.layoutParams = params
                }
            }
            animation.duration = SCREEN_FADE_DELAY
            animation.interpolator = OvershootInterpolator()
            binding.fragmentRoomRoot.startAnimation(animation)
        }
    }

    fun tryFadeOut(): Boolean {
        val params: FrameLayout.LayoutParams = binding.fragmentRoomRoot.layoutParams as FrameLayout.LayoutParams
        val currentOffset = params.rightMargin
        val offset = resources.getDimension(R.dimen.room_pager_offset_gone)
        if (currentOffset == 0) {
            Timber.d("Fading out")
            viewModel.setViewingChat(false)
            val animation: Animation = object : Animation() {
                override fun applyTransformation(interpolatedTime: Float, t: Transformation?) {
                    params.rightMargin = (offset * interpolatedTime).toInt()
                    binding.fragmentRoomRoot.layoutParams = params
                }
            }
            animation.duration = SCREEN_FADE_DELAY
            animation.interpolator = OvershootInterpolator()
            binding.fragmentRoomRoot.startAnimation(animation)
            return true
        }
        return false
    }

    private companion object {
        private const val SCREEN_FADE_DELAY = 300L
        private const val TAB_MEMBERS = 0
        private const val TAB_CHAT = 1
        private const val TAB_INFO= 2
    }
}
