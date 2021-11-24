/*
 * Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.phenixcore.repositories.models

enum class PhenixEvent(var data: Any? = null) {
    // Phenix
    PHENIX_CORE_INITIALIZED,

    // Room
    /**
     * Will hold [PhenixRoomConfiguration] as data
     */
    PHENIX_ROOM_JOINING,
    /**
     * Will hold [PhenixRoomConfiguration] as data
     */
    PHENIX_ROOM_JOINED,
    /**
     * Will hold [PhenixRoomConfiguration] as data
     */
    PHENIX_ROOM_CREATING,
    /**
     * Will hold [PhenixRoomConfiguration] as data
     */
    PHENIX_ROOM_CREATED,
    /**
     * Will hold [PhenixRoomConfiguration] as data
     */
    PHENIX_ROOM_PUBLISHING,
    /**
     * Will hold [PhenixRoomConfiguration] as data
     */
    PHENIX_ROOM_PUBLISHED,
    /**
     * Will hold [PhenixRoomConfiguration] as data
     */
    PHENIX_ROOM_LEFT,

    // General
    CAMERA_FLIPPED,
    MESSAGE_SENT,
}
