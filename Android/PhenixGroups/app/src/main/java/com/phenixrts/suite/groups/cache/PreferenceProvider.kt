/*
 * Copyright 2022 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.cache

import android.content.Context
import com.phenixrts.suite.groups.GroupsApplication
import kotlin.properties.ReadWriteProperty
import kotlin.reflect.KProperty

class PreferenceProvider(private val context: GroupsApplication) {

    var displayName by stringPreference()
    var roomAlias by stringPreference()

    private val sharedPreferences by lazy { context.getSharedPreferences(APP_PREFERENCES, Context.MODE_PRIVATE) }

    private fun stringPreference() = object : ReadWriteProperty<Any?, String?> {
        override fun getValue(thisRef: Any?, property: KProperty<*>) = sharedPreferences.getString(property.name, null)

        override fun setValue(thisRef: Any?, property: KProperty<*>, value: String?) {
            sharedPreferences.edit().putString(property.name, value).apply()
        }
    }

    private companion object {
        private const val APP_PREFERENCES = "group_preferences"
    }
}
