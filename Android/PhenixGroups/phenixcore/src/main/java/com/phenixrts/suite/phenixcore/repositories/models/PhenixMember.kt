/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

@file:Suppress("MemberVisibilityCanBePrivate")

package com.phenixrts.suite.phenixcore.repositories.models

import com.phenixrts.room.MemberRole

data class PhenixMember(
    val id: String,
    val name: String,
    val role: MemberRole,
    val volume: Int,
    val isAudioEnabled: Boolean,
    val isVideoEnabled: Boolean,
    val isSelected: Boolean,
    val isSelf: Boolean,
    val isDataLost: Boolean,
    val hasRaisedHand: Boolean
) {
    val isModerator = role == MemberRole.MODERATOR

    override fun toString(): String {
        return "PhenixMember(id='$id', name='$name', role=$role, isAudioEnabled=$isAudioEnabled, " +
                "isVideoEnabled=$isVideoEnabled, isSelected=$isSelected, volume=$volume, " +
                "isSelf=$isSelf, hasRaisedHand=$hasRaisedHand, isModerator=$isModerator, isDataLost=$isDataLost)"
    }
}
