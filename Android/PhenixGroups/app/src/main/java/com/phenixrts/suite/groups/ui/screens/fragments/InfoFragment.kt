/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens.fragments

import android.content.Intent
import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.databinding.FragmentInfoBinding
import com.phenixrts.suite.phenixcore.common.launchMain

const val INTENT_CHOOSER_TYPE = "text/plain"

class InfoFragment : BaseFragment() {

    private lateinit var binding: FragmentInfoBinding

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?) =
        FragmentInfoBinding.inflate(inflater, container, false).apply {
            binding = this
            roomAlias = viewModel.currentRoomAlias
            lifecycleOwner = this@InfoFragment
        }.root

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        binding.fragmentInfoShare.setOnClickListener {
            showIntentChooser()
        }
    }

    private fun showIntentChooser() = launchMain {
        val intent = Intent(Intent.ACTION_SEND).apply {
            putExtra(Intent.EXTRA_SUBJECT, R.string.info_meeting_subject)
            putExtra(Intent.EXTRA_TEXT, getString(R.string.info_meeting_url, viewModel.currentRoomAlias))
            type = INTENT_CHOOSER_TYPE
        }
        startActivity(Intent.createChooser(intent, getString(R.string.info_share)))
    }

}
