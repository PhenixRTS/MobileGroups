/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups

import android.app.Application
import android.content.res.Resources
import androidx.lifecycle.ViewModelStore
import androidx.lifecycle.ViewModelStoreOwner
import com.phenixrts.suite.groups.injection.DaggerInjectionComponent
import com.phenixrts.suite.groups.injection.InjectionComponent
import com.phenixrts.suite.groups.injection.InjectionModule

class GroupsApplication: Application(), ViewModelStoreOwner {

    private val appViewModelStore: ViewModelStore by lazy {
        ViewModelStore()
    }

    private val injectionModule = InjectionModule(this)

    override fun onCreate() {
        super.onCreate()

        module = injectionModule
        component = DaggerInjectionComponent.builder().injectionModule(injectionModule).build()
        resourceContext = resources
    }

    override fun getViewModelStore() = appViewModelStore

    companion object {
        lateinit var component: InjectionComponent
            private set
        lateinit var module: InjectionModule
            private set

        private lateinit var resourceContext: Resources

        fun getString(id: Int, arguments: String = ""): String = resourceContext.getString(id, arguments)
    }
}
