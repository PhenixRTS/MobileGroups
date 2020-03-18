/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups

import android.app.Application
import com.phenixrts.suite.groups.common.LineNumberDebugTree
import com.phenixrts.suite.groups.injection.DaggerInjectionComponent
import com.phenixrts.suite.groups.injection.InjectionComponent
import com.phenixrts.suite.groups.injection.InjectionModule
import timber.log.Timber

class GroupsApplication: Application() {

    override fun onCreate() {
        super.onCreate()

        if (BuildConfig.DEBUG) {
            Timber.plant(LineNumberDebugTree("PhenixApp"))
        }

        component = DaggerInjectionComponent.builder().injectionModule(InjectionModule(this)).build()
    }

    companion object {
        lateinit var component: InjectionComponent
            private set
    }
}