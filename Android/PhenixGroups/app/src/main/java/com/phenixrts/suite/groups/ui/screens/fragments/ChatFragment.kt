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
import com.phenixrts.suite.groups.R
import com.phenixrts.suite.groups.common.extensions.showToast
import com.phenixrts.suite.groups.databinding.FragmentChatBinding
import com.phenixrts.suite.groups.ui.adapters.ChatListAdapter
import timber.log.Timber

class ChatFragment : BaseFragment() {

    private lateinit var binding: FragmentChatBinding

    private val adapter by lazy { ChatListAdapter(viewModel) }

    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View? {
        binding = FragmentChatBinding.inflate(inflater)
        binding.lifecycleOwner = this
        binding.chatHistory.adapter = adapter
        binding.sendButton.setOnClickListener {
            sendMessage()
        }

        roomExpressRepository.getObservableChatMessages().observe(this, Observer {
            adapter.data = it
            if (it.isNotEmpty()) {
                binding.chatHistory.scrollToPosition(it.size - 1)
            }
        })
        return binding.root
    }

    /**
     * Sends a chat message and handles response
     */
    private fun sendMessage() {
        roomExpressRepository.launch {
            val status = roomExpressRepository.sendChatMessage(binding.newMessageEditText.text.toString())
            launch {
                if (status.status == RequestStatus.OK) {
                    binding.newMessageEditText.text.clear()
                } else {
                    Timber.e("Cannot send message ${status.message}")
                    showToast(getString(R.string.err_chat_message_failed, status.message))
                }
            }
        }
    }
}
