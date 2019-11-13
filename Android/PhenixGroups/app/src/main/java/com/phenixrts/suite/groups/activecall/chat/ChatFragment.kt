/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.activecall.chat

import android.os.Bundle
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Toast
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import com.phenixrts.suite.groups.databinding.GroupCallChatFragmentBinding
import com.phenixrts.suite.groups.viewmodels.ChatViewModel
import kotlinx.android.synthetic.main.group_call_chat_fragment.*

class ChatFragment : Fragment() {
    private val TAG = ChatFragment::class.java.simpleName

    private val chatViewModel: ChatViewModel by viewModels({ activity!! })
    private lateinit var binding: GroupCallChatFragmentBinding

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        binding = GroupCallChatFragmentBinding.inflate(inflater)
        binding.lifecycleOwner = this
        binding.chat = chatViewModel
        binding.chatHistory.adapter = ChatListAdapter(chatViewModel.chatHistory)
        binding.sendMessageCallback = object : ChatViewModel.OnSendMessageCallback {
            override fun onSuccess() {
                newMessageEditText?.text?.clear()
            }

            override fun onError(error: Exception) {
                Log.e(TAG, "Cannot send message", error)
                // TODO(YM): Remove stub
                Toast.makeText(activity, "Error. $error", Toast.LENGTH_SHORT).show()
            }

        }
        return binding.root
    }
}