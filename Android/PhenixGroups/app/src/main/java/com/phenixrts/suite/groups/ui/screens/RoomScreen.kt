/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
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
import androidx.lifecycle.Observer
import androidx.viewpager.widget.ViewPager
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.common.extensions.hideKeyboard
import com.phenixrts.suite.groups.common.extensions.showBottomMenu
import com.phenixrts.suite.groups.ui.adapters.RoomScreenPageAdapter
import com.phenixrts.suite.groups.ui.screens.fragments.*
import kotlinx.android.synthetic.main.screen_room.*
import timber.log.Timber

class RoomScreen : BaseFragment(), ViewPager.OnPageChangeListener {

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

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?) =
        inflater.inflate(R.layout.screen_room, container, false)!!

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        fragment_pager.addOnPageChangeListener(this)
        fragment_pager.offscreenPageLimit = 2
        fragment_pager?.adapter = adapter
        fragment_tab_layout.setupWithViewPager(fragment_pager)
        room_menu_button.setOnClickListener {
            showBottomMenu()
        }
        refreshTabs(0)

        viewModel.isControlsEnabled.value = false
        viewModel.isInRoom.value = true

        viewModel.memberCount.observe(viewLifecycleOwner, Observer { count ->
            Timber.d("Member count changed: $count")
            refreshTabs(count)
        })
    }

    override fun onBackPressed() {
        fragment_pager.removeOnPageChangeListener(this)
        viewModel.leaveRoom()
    }

    override fun onPageScrollStateChanged(state: Int) { /* Ignored */ }

    override fun onPageScrolled(position: Int, positionOffset: Float, positionOffsetPixels: Int) { /* Ignored */ }

    override fun onPageSelected(position: Int) {
        // Hide member list surfaces when page scrolled
        (childFragmentManager.findFragmentByTag(
            "android:switcher:${fragment_pager.id}:0"
        ) as? MemberFragment)?.hidePreviews(position != 0)
        hideKeyboard()
    }

    private fun getInfoFragment(): InfoFragment {
        val fragment = InfoFragment()
        val bundle = Bundle()
        bundle.putString(EXTRA_ROOM_ALIAS, viewModel.currentRoomAlias.value ?: "")
        fragment.arguments = bundle
        return fragment
    }

    private fun refreshTabs(memberCount: Int) {
        val label =  if (memberCount > 0) resources.getString(R.string.tab_members_count, memberCount) else " "
        fragment_tab_layout.getTabAt(0)?.text = label
        fragment_tab_layout.getTabAt(0)?.setIcon(R.drawable.ic_people)
        fragment_tab_layout.getTabAt(1)?.setIcon(R.drawable.ic_chat)
        fragment_tab_layout.getTabAt(2)?.setIcon(R.drawable.ic_info)
        fragment_tab_layout.getTabAt(0)?.view?.id = R.id.tab_members
        fragment_tab_layout.getTabAt(1)?.view?.id = R.id.tab_chat
        fragment_tab_layout.getTabAt(2)?.view?.id = R.id.tab_info
    }

    fun selectTab(index: Int) {
        Timber.d("Selecting tab: $index")
        fragment_pager.setCurrentItem(index, false)
    }

    fun fadeIn() {
        val params: FrameLayout.LayoutParams = fragment_room_root.layoutParams as FrameLayout.LayoutParams
        val currentOffset = params.rightMargin
        val offset = resources.getDimension(R.dimen.room_pager_offset_gone).toInt()
        if (currentOffset < 0) {
            Timber.d("Fading in")
            val animation: Animation = object : Animation() {
                override fun applyTransformation(interpolatedTime: Float, t: Transformation?) {
                    params.rightMargin = offset - (offset * interpolatedTime).toInt()
                    fragment_room_root.layoutParams = params
                }
            }
            animation.duration = SCREEN_FADE_DELAY
            animation.interpolator = OvershootInterpolator()
            fragment_room_root.startAnimation(animation)
        }
    }

    fun tryFadeOut(): Boolean {
        val params: FrameLayout.LayoutParams = fragment_room_root.layoutParams as FrameLayout.LayoutParams
        val currentOffset = params.rightMargin
        val offset = resources.getDimension(R.dimen.room_pager_offset_gone)
        if (currentOffset == 0) {
            Timber.d("Fading out")
            val animation: Animation = object : Animation() {
                override fun applyTransformation(interpolatedTime: Float, t: Transformation?) {
                    params.rightMargin = (offset * interpolatedTime).toInt()
                    fragment_room_root.layoutParams = params
                }
            }
            animation.duration = SCREEN_FADE_DELAY
            animation.interpolator = OvershootInterpolator()
            fragment_room_root.startAnimation(animation)
            return true
        }
        return false
    }

    private companion object {
        private const val SCREEN_FADE_DELAY = 300L
    }
}
