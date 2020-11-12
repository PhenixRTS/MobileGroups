/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens.fragments

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.databinding.FragmentInfoBinding
import com.phenixrts.suite.phenixcommon.common.launchMain
import kotlinx.android.synthetic.main.fragment_info.*


const val EXTRA_ROOM_ALIAS = "extraRoomAlias"
const val INTENT_CHOOSER_TYPE = "text/plain"

class InfoFragment : Fragment() {

    private lateinit var roomCode: String

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?) =
        FragmentInfoBinding.inflate(inflater).apply {
            roomCode = arguments?.getString(EXTRA_ROOM_ALIAS, "") ?: ""
            roomAlias = roomCode
            lifecycleOwner = this@InfoFragment
        }.root

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        fragment_info_share.setOnClickListener {
            showIntentChooser()
        }
    }

    private fun showIntentChooser() = launchMain {
        val intent = Intent(Intent.ACTION_SEND).apply {
            putExtra(Intent.EXTRA_SUBJECT, R.string.info_meeting_subject)
            putExtra(Intent.EXTRA_TEXT, getString(R.string.info_meeting_url, roomCode))
            type = INTENT_CHOOSER_TYPE
        }
        startActivity(Intent.createChooser(intent, getString(R.string.info_share)))
    }

}
