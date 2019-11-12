/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.activecall.chat

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import com.phenixrts.suite.groups.databinding.GroupCallChatFragmentBinding
import com.phenixrts.suite.groups.viewmodels.ChatViewModel

class ChatFragment : Fragment() {

    private val chatViewModel: ChatViewModel by viewModels({ activity!! })
    private lateinit var binding: GroupCallChatFragmentBinding

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        binding = GroupCallChatFragmentBinding.inflate(inflater)
        binding.lifecycleOwner = this
        binding.chatViewModel = chatViewModel
        binding.chatHistory.adapter = ChatListAdapter(chatViewModel.roomChat)
        return binding.root
    }
}