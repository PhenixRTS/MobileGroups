/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.phenix

import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.lifecycle.MutableLiveData
import androidx.lifecycle.Transformations
import com.phenixrts.chat.ChatMessage
import com.phenixrts.chat.RoomChatService
import com.phenixrts.chat.RoomChatServiceFactory
import com.phenixrts.common.Disposable
import com.phenixrts.common.Observable.OnChangedHandler
import com.phenixrts.common.RequestStatus
import com.phenixrts.express.RoomExpress
import com.phenixrts.express.RoomExpressFactory
import com.phenixrts.room.Member
import com.phenixrts.room.RoomService
import com.phenixrts.room.TrackState
import com.phenixrts.suite.groups.models.Message
import com.phenixrts.suite.groups.models.Participant
import com.phenixrts.suite.groups.models.RoomModel
import com.phenixrts.suite.groups.models.RoomModel.*
import com.phenixrts.suite.groups.viewmodels.CallSettingsViewModel


class PhenixRoomAdapter(
    private val roomExpress: RoomExpress,
    private val callSettings: CallSettingsViewModel
) : RoomModel {
    private val TAG = PhenixRoomAdapter::class.java.simpleName

    private val CHAT_MESSAGE_HISTORY_REQUEST = 1

    private val mainThreadHandler by lazy { Handler(Looper.getMainLooper()) }
    private val membersCache = arrayListOf<Participant>()
    private val chatMessagesCache = arrayListOf<ChatMessage>()

    // Strong reference storage is required by Phenix API
    private var roomService: RoomService? = null
    private var chatService: RoomChatService? = null // TODO(YM): check if required

    private var onConnectionEventsListener = arrayListOf<OnConnectionEventsListener>()
    private var onChatEventsListener = arrayListOf<OnChatEventsListener>()
    private var onMembersEventListener = arrayListOf<OnMembersEventListener>()

    // Keeps disposable as a workaround to keep active observables
    private val strongRefDisposable = mutableListOf<Disposable?>()

    override fun subscribe() {
        val joinRoomOptions = RoomExpressFactory.createJoinRoomOptionsBuilder()
            .withRoomAlias(callSettings.roomName.value)
            .withScreenName(callSettings.nickname.value)
            .buildJoinRoomOptions()

        roomExpress.joinRoom(joinRoomOptions) { status: RequestStatus, roomService ->
            Log.d(TAG, "Room.join() status: $status")
            mainThreadHandler.post {
                when (status) {
                    RequestStatus.OK -> {
                        Log.d(TAG, "Room joined")
                        this.roomService = roomService

                        subscribeToChat(roomService)
                        subscribeToMembers(roomService)

                        onConnectionEventsListener.forEach { it.onSubscribed() }
                    }
                    else -> {
                        Log.e(TAG, "Join room error: $status")
                        onConnectionEventsListener.forEach { it.onError(PhenixException(status)) }
                    }
                }
            }
        }
    }

    private fun subscribeToMembers(roomService: RoomService) {
        Log.d(TAG, "Subscribing to Members events")
        roomService.observableActiveRoom.value.observableMembers.fixedSubscribe(OnChangedHandler { currentMembers ->
            Log.d(TAG, "Room member event")
            val activeMembers = currentMembers.map { it.toParticipant() }

            // calculate event
            val newMembers = activeMembers.toMutableList().apply { removeAll(membersCache) }
            val leftMembers = membersCache.toMutableList().apply { removeAll(activeMembers) }

            // fire events
            Log.d(TAG, "New members count: ${newMembers.size}")
            newMembers.forEach { newMember ->
                mainThreadHandler.post {
                    onMembersEventListener.forEach { it.onNewMember(newMember) }
                }
            }
            Log.d(TAG, "Left members count: ${leftMembers.size}")
            leftMembers.forEach { leftMember ->
                mainThreadHandler.post {
                    onMembersEventListener.forEach { it.onMemberLeft(leftMember) }
                }
            }

            // update cache
            membersCache.clear()
            membersCache.addAll(activeMembers)
        }).run { strongRefDisposable.add(this) }
    }

    private fun subscribeToChat(roomService: RoomService) {
        Log.d(TAG, "Subscribing to Chat Service")
        chatService =
            RoomChatServiceFactory.createRoomChatService(roomService, CHAT_MESSAGE_HISTORY_REQUEST)
        chatService?.observableChatMessages?.fixedSubscribe(OnChangedHandler { allMessages ->
            Log.d(TAG, "New chat messages list received. Size: ${allMessages.size}")

            Log.d(TAG, "Messages count from last event: ${chatMessagesCache.size}")
            val newMessages = allMessages.toMutableList().apply { removeAll(chatMessagesCache) }
            Log.d(TAG, "New messages received: ${newMessages.size}")
            newMessages.map { it.toMessage() }.forEach { message ->
                mainThreadHandler.post {
                    onChatEventsListener.forEach { it.onNewChatMessage(message) }
                }
            }
        }).run { strongRefDisposable.add(this) }
    }

    override fun unsubscribe() = clean()

    override fun sendChatMessage(
        message: String,
        onSuccess: () -> Unit,
        onError: (error: Exception) -> Unit
    ) {
        Log.d(TAG, "Sending message: $message")
        chatService?.sendMessageToRoom(message) { status, errorMessage ->
            mainThreadHandler.post {
                when (status) {
                    RequestStatus.OK -> {
                        Log.d(TAG, "Message sent: $message")
                        onSuccess()
                    }
                    else -> {
                        Log.w(TAG, "Message is not set")
                        onError(Exception("Status: $status; Message: $errorMessage"))
                    }
                }
            }
        } ?: onError(IllegalStateException("Chat service is not available"))
    }

    override fun addOnMembersEventListener(listener: OnMembersEventListener) {
        onMembersEventListener.add(listener)
    }

    override fun addOnChatEventsListener(listener: OnChatEventsListener) {
        onChatEventsListener.add(listener)
    }

    override fun addOnConnectionEventsListener(listener: OnConnectionEventsListener) {
        onConnectionEventsListener.add(listener)
    }

    override fun removeListener(any: Any) {
        onConnectionEventsListener.remove(any)
        onChatEventsListener.remove(any)
        onMembersEventListener.remove(any)
    }

    private fun clean() {
        strongRefDisposable.forEach { it?.dispose() }
        strongRefDisposable.clear()

        membersCache.clear()

        chatService?.dispose()
        chatService = null
        chatMessagesCache.clear()

        roomService?.leaveRoom { _, _ ->
            Log.i(TAG, "Room left")
        }
        roomService?.dispose()
        roomService = null
    }

    private fun ChatMessage.toMessage() = Message(
        MutableLiveData(observableFrom.value.observableScreenName.value),
        observableMessage.value,
        observableTimeStamp.value,
        observableFrom.value.sessionId == roomService?.self?.sessionId
    )

    private fun Member.toParticipant(): Participant {
        return Participant(
            observableScreenName.toMutableLiveData(),
            Transformations.map(observableStreams.value.first().observableVideoState.toMutableLiveData()) { it == TrackState.ENABLED },
            Transformations.map(observableStreams.value.first().observableAudioState.toMutableLiveData()) { it == TrackState.ENABLED },
            this == roomService?.self
        )
    }
}