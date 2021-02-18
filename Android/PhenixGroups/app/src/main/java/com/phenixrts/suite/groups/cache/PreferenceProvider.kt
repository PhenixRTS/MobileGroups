/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.cache

import android.content.Context
import android.os.Build
import com.phenixrts.suite.groups.GroupsApplication

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

    companion object {
        private const val APP_PREFERENCES = "group_preferences"
        private const val DISPLAY_NAME = "display_name"
        private const val ROOM_ALIAS = "room_alias"
    }
}
