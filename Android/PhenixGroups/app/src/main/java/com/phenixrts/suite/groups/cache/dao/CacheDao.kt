/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.cache.dao

import androidx.room.*
import com.phenixrts.suite.groups.cache.entities.RoomInfoItem
import kotlinx.coroutines.flow.Flow
import java.util.*

@Dao
interface CacheDao {

    @Query("SELECT * FROM room_item ORDER BY dateLeft DESC")
    fun getVisitedRooms(): Flow<List<RoomInfoItem>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    fun insertRoom(roomInfoItem: RoomInfoItem)

    @Query("UPDATE room_item SET dateLeft = :dateLeft WHERE roomId = :roomId")
    fun updateRoomLeftDate(roomId: String, dateLeft: Date)

    @Query("DELETE FROM room_item WHERE dateLeft < :expirationDate")
    fun expireOldRooms(expirationDate: Date)

}
