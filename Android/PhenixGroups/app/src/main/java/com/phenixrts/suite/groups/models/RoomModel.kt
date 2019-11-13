/*
 * Copyright 2019 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.models

interface RoomModel {

    fun subscribe()
    fun unsubscribe()

    fun sendChatMessage(
        message: String,
        onSuccess: () -> Unit,
        onError: (error: Exception) -> Unit
    )

    fun addOnMembersEventListener(listener: OnMembersEventListener)
    fun addOnChatEventsListener(listener: OnChatEventsListener)
    fun addOnConnectionEventsListener(listener: OnConnectionEventsListener)
    fun removeListener(any: Any)

    interface OnMembersEventListener {
        fun onNewMember(participant: Participant)
        fun onMemberLeft(participant: Participant)
    }

    interface OnChatEventsListener {
        fun onNewChatMessage(message: Message)
    }

    interface OnConnectionEventsListener {
        fun onSubscribed()
        fun onError(error: Exception)
    }
}