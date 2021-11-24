/*
 * Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.phenixcore.repositories.models

enum class PhenixError(val message: String, var data: Any? = null) {
    // Phenix
    FAILED_TO_INITIALIZE("The PhenixCore failed to initialize. Check your network status and configuration."),
    NOT_INITIALIZED("The PhenixCore is not initialized. Please call .init() before using any other function."),
    ALREADY_INITIALIZING("The PhenixCore is already initializing."),
    ALREADY_INITIALIZED("The PhenixCore is already initialized."),

    // Channel
    CREATE_RENDERER_FAILED("Failed to create video renderer, check your configuration."),
    RENDERING_FAILED("Failed to render video, check your configuration."),
    CHANNEL_LIST_EMPTY("Failed to join channels from configuration, the list is empty."),

    // Room
    /**
     * Will hold [PhenixRoomConfiguration] as data
     */
    CREATE_ROOM_FAILED("Failed to create room."),
    /**
     * Will hold [PhenixRoomConfiguration] as data
     */
    JOIN_ROOM_FAILED("Failed to join room."),
    /**
     * Will hold [PhenixRoomConfiguration] as data
     */
    LEAVE_ROOM_FAILED("Failed to leave room."),
    /**
     * Will hold [PhenixRoomConfiguration] as data
     */
    ROOM_GONE("Room disconnected."),
    /**
     * Will hold [PhenixRoomConfiguration] as data
     */
    PUBLISH_ROOM_FAILED("Failed to publish media to room."),

    UPDATE_MEMBER_FAILED("Failed to update member."),
    SEND_MESSAGE_FAILED("Failed to send message."),
    CAMERA_FLIP_FAILED("Failed to flip camera."),
}
