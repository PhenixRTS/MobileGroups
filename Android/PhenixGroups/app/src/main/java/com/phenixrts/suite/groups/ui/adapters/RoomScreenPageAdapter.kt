/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.adapters

import android.content.res.Resources
import android.os.Bundle
import androidx.annotation.StringRes
import androidx.fragment.app.Fragment
import androidx.fragment.app.FragmentManager
import androidx.fragment.app.FragmentPagerAdapter
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.ui.screens.fragments.ChatFragment
import com.phenixrts.suite.groups.ui.screens.fragments.EXTRA_ROOM_ALIAS
import com.phenixrts.suite.groups.ui.screens.fragments.InfoFragment
import com.phenixrts.suite.groups.ui.screens.fragments.MemberFragment

class RoomScreenPageAdapter(
    private val resources: Resources,
    fragmentManager: FragmentManager,
    private val roomAlias: String) :
    FragmentPagerAdapter(fragmentManager, BEHAVIOR_RESUME_ONLY_CURRENT_FRAGMENT) {

    private data class Page(@StringRes val title: Int, val fragment: Fragment)

    private val pages = arrayOf(
        Page(R.string.members_page_title, MemberFragment()),
        Page(R.string.chat_page_title, ChatFragment()),
        Page(R.string.call_info_page_title, getInfoFragment())
    )

    private fun getInfoFragment(): InfoFragment {
        val fragment = InfoFragment()
        val bundle = Bundle()
        bundle.putString(EXTRA_ROOM_ALIAS, roomAlias)
        fragment.arguments = bundle
        return fragment
    }

    override fun getItem(position: Int) = pages[position].fragment

    override fun getCount() = pages.size

    override fun getPageTitle(position: Int) = resources.getString(pages[position].title)
}
