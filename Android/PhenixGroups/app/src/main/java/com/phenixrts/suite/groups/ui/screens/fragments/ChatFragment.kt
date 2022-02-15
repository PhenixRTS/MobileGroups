/*
 * Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.phenixrts.suite.groups.databinding.FragmentChatBinding
import com.phenixrts.suite.groups.ui.adapters.ChatListAdapter
import com.phenixrts.suite.phenixcore.common.launchUI
import com.phenixrts.suite.phenixcore.repositories.models.PhenixEvent

class ChatFragment : BaseFragment() {

    private lateinit var binding: FragmentChatBinding

    private val adapter by lazy { ChatListAdapter() }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        binding = FragmentChatBinding.inflate(inflater, container, false)
        binding.lifecycleOwner = viewLifecycleOwner
        binding.chatHistory.adapter = adapter
        binding.sendButton.setOnClickListener {
            sendMessage()
        }
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        launchUI {
            viewModel.messages.collect { messages ->
                adapter.data = messages
                if (messages.isNotEmpty()) {
                    binding.chatHistory.scrollToPosition(messages.size - 1)
                }
            }
        }
        launchUI {
            phenixCore.onEvent.collect { event ->
                if (event == PhenixEvent.MESSAGE_SENT) {
                    binding.messageInputField.text.clear()
                }
            }
        }
    }

    private fun sendMessage() {
        binding.messageInputField.text.toString().takeIf { it.isNotBlank() }?.let { message ->
            viewModel.sendChatMessage(message)
        }
    }

}
