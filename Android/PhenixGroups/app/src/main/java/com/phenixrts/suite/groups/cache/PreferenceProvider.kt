/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.cache

import android.content.Context
import android.os.Build
import com.google.gson.Gson
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.models.RoomExpressConfiguration

class PreferenceProvider(private val context: GroupsApplication) {

    fun saveDisplayName(displayName: String) {
        context.getSharedPreferences(APP_PREFERENCES, Context.MODE_PRIVATE).edit()
            .putString(DISPLAY_NAME, displayName)
            .apply()
    }

    fun getDisplayName(): String = context.getSharedPreferences(APP_PREFERENCES, Context.MODE_PRIVATE)
        .getString(DISPLAY_NAME, null) ?: Build.MODEL

    fun saveRoomAlias(displayName: String?) {
        context.getSharedPreferences(APP_PREFERENCES, Context.MODE_PRIVATE).edit()
            .putString(ROOM_ALIAS, displayName)
            .apply()
    }

    fun getRoomAlias(): String? = context.getSharedPreferences(APP_PREFERENCES, Context.MODE_PRIVATE)
        .getString(ROOM_ALIAS, null)

    fun saveConfiguration(configuration: RoomExpressConfiguration?) {
        context.getSharedPreferences(APP_PREFERENCES, Context.MODE_PRIVATE).edit()
            .putString(CONFIGURATION, Gson().toJson(configuration))
            .apply()
    }

    fun getConfiguration(): RoomExpressConfiguration? {
        var configuration: RoomExpressConfiguration? = null
        context.getSharedPreferences(APP_PREFERENCES, Context.MODE_PRIVATE).getString(CONFIGURATION, null)?.let { cache ->
            configuration = Gson().fromJson(cache, RoomExpressConfiguration::class.java)
        }
        return configuration
    }

    companion object {
        private const val APP_PREFERENCES = "group_preferences"
        private const val DISPLAY_NAME = "display_name"
        private const val CONFIGURATION = "configuration"
        private const val ROOM_ALIAS = "room_alias"
    }
}
