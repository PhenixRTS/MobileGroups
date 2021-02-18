/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.cache.entities

import androidx.room.Entity
import androidx.room.PrimaryKey
import java.util.*

@Entity(tableName = "room_item")
data class RoomInfoItem(
    @PrimaryKey
    val roomId: String,
    val alias: String,
    val backendUri: String,
    var dateLeft: Date = Date()
)
