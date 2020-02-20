/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.cache.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.phenixrts.suite.groups.cache.entities.ChatMessageItem
import com.phenixrts.suite.groups.cache.entities.RoomInfoItem
import kotlinx.coroutines.flow.Flow
import java.util.*

@Dao
interface CacheDao {

    @Query("SELECT * FROM room_item ORDER BY dateLeft DESC")
    fun getVisitedRooms(): Flow<List<RoomInfoItem>>

    @Query("SELECT * FROM chat_item ORDER BY date ASC")
    fun getChatMessages(): Flow<List<ChatMessageItem>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertRoom(roomInfoItem: RoomInfoItem)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertChatMessages(chatMessages: List<ChatMessageItem>)

    @Query("UPDATE room_item SET dateLeft = :dateLeft WHERE roomId = :roomId")
    fun updateRoomLeftDate(roomId: String, dateLeft: Date)

}
