/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.activecall

import android.content.res.Resources
import androidx.annotation.StringRes
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentManager
import androidx.fragment.app.FragmentPagerAdapter
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.activecall.chat.ChatFragment
import com.phenixrts.suite.groups.activecall.info.CallInfoFragment
import com.phenixrts.suite.groups.activecall.participants.ParticipantsListFragment


class GroupCallScreenPageAdapter(private val resources: Resources, fragmentManager: FragmentManager) :
    FragmentPagerAdapter(fragmentManager, BEHAVIOR_RESUME_ONLY_CURRENT_FRAGMENT) {

    private data class Page(@StringRes val title: Int, val fragment: Fragment)

    private val pages = arrayOf(
        Page(R.string.participants_page_title, ParticipantsListFragment()),
        Page(R.string.chat_page_title, ChatFragment()),
        Page(R.string.call_info_page_title, CallInfoFragment())
    )

    override fun getItem(position: Int) = pages[position].fragment

    override fun getCount() = pages.size

    override fun getPageTitle(position: Int) = resources.getString(pages[position].title)
}