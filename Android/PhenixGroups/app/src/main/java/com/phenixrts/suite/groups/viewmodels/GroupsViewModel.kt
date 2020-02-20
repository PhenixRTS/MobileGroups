/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.viewmodels

import android.os.Build
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.cache.entities.ChatMessageItem
import com.phenixrts.suite.groups.cache.entities.RoomInfoItem
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch

class GroupsViewModel(private val cacheProvider: CacheProvider) : ViewModel() {
    var currentRoomId = "";
    val screenName : String = Build.MODEL
    val isVideoEnabled = MutableLiveData<Boolean>()
    val isMicrophoneEnabled = MutableLiveData<Boolean>()

    val chatList = MutableLiveData<List<ChatMessageItem>>()
    val roomList = MutableLiveData<List<RoomInfoItem>>()

    init {
        getRoomListItems()
        getChatListItems()
    }

    private fun getRoomListItems() = viewModelScope.launch {
        cacheProvider.cacheDao().getVisitedRooms().collect {
            roomList.value = it
        }
    }

    private fun getChatListItems()  = viewModelScope.launch {
        chatList.value = mutableListOf()
        cacheProvider.cacheDao().getChatMessages().collect { messages ->
            chatList.value = messages.filter { it.roomId == currentRoomId }
        }
    }
}
