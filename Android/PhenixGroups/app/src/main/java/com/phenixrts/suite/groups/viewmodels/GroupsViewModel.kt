/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.viewmodels

import androidx.lifecycle.*
import com.phenixrts.common.RequestStatus
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.cache.PreferenceProvider
import com.phenixrts.suite.groups.cache.entities.RoomInfoItem
import com.phenixrts.suite.groups.common.SingleLiveEvent
import com.phenixrts.suite.groups.models.RoomStatus
import com.phenixrts.suite.groups.repository.RoomExpressRepository
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import timber.log.Timber

class GroupsViewModel(
    private val cacheProvider: CacheProvider,
    private val preferenceProvider: PreferenceProvider,
    private val roomExpressRepository: RoomExpressRepository,
    private val lifecycleOwner: LifecycleOwner
) : ViewModel(), LifecycleObserver {

    val displayName = MutableLiveData<String>()
    val isVideoEnabled = MutableLiveData<Boolean>()
    val isMicrophoneEnabled = MutableLiveData<Boolean>()
    val isInRoom = MutableLiveData<Boolean>()
    val isControlsEnabled = MutableLiveData<Boolean>()
    val roomList = MutableLiveData<List<RoomInfoItem>>()

    val onRoomJoined = SingleLiveEvent<RequestStatus>()
    val onRoomCreated = SingleLiveEvent<RoomStatus>()

    init {
        Timber.d("View model created")
        displayName.value = preferenceProvider.getDisplayName()
        displayName.observe(lifecycleOwner, Observer {
            preferenceProvider.saveDisplayName(it)
        })
        getRoomListItems()
    }

    private fun getRoomListItems() = viewModelScope.launch {
        cacheProvider.cacheDao().getVisitedRooms().collect {
            roomList.value = it
        }
    }

    fun joinRoomById(id: String, userScreenName: String) = viewModelScope.launch {
        onRoomJoined.value = roomExpressRepository.joinRoomById(id, userScreenName)
    }

    fun joinRoomByAlias(roomAlias: String, userScreenName: String) = viewModelScope.launch {
        onRoomJoined.value = roomExpressRepository.joinRoomByAlias(roomAlias, userScreenName)
    }

    fun createRoom() = viewModelScope.launch {
        onRoomCreated.value = roomExpressRepository.createRoom()
    }
}
