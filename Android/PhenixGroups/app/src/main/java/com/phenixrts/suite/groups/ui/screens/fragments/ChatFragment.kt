/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.phenixrts.common.RequestStatus
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.common.extensions.showToast
import com.phenixrts.suite.groups.databinding.FragmentChatBinding
import com.phenixrts.suite.groups.ui.adapters.ChatListAdapter
import com.phenixrts.suite.phenixcommon.common.launchMain
import timber.log.Timber

class ChatFragment : BaseFragment() {

    private lateinit var binding: FragmentChatBinding

    private val adapter by lazy { ChatListAdapter() }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        binding = FragmentChatBinding.inflate(inflater)
        binding.lifecycleOwner = this
        binding.chatHistory.adapter = adapter
        binding.sendButton.setOnClickListener {
            sendMessage()
        }
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)
        observeMessages()
    }

    private fun observeMessages() = launchMain {
        if (isAdded) {
            viewModel.getChatMessages().observe(viewLifecycleOwner, { messages ->
                launchMain {
                    viewModel.unreadMessageCount.value = messages.count { !it.isRead }
                    adapter.data = messages
                    if (messages.isNotEmpty()) {
                        binding.chatHistory.scrollToPosition(messages.size - 1)
                    }
                }
            })
        }
    }

    private fun sendMessage() = launchMain {
        val status = viewModel.sendChatMessage(binding.messageInputField.text.toString())
        if (status.status == RequestStatus.OK) {
            binding.messageInputField.text.clear()
        } else {
            Timber.e("Cannot send message ${status.message}")
            showToast(getString(R.string.err_chat_message_failed, status.message))
        }
    }

}
