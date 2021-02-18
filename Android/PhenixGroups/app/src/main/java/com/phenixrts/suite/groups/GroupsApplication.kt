/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups

import android.app.Application
import android.content.res.Resources
import androidx.lifecycle.ViewModelStore
import androidx.lifecycle.ViewModelStoreOwner
import com.phenixrts.suite.phenixcommon.common.FileWriterDebugTree
import com.phenixrts.suite.groups.injection.DaggerInjectionComponent
import com.phenixrts.suite.groups.injection.InjectionComponent
import com.phenixrts.suite.groups.injection.InjectionModule
import timber.log.Timber
import javax.inject.Inject

class GroupsApplication: Application(), ViewModelStoreOwner {

    private val appViewModelStore: ViewModelStore by lazy {
        ViewModelStore()
    }

    @Inject
    lateinit var fileWriterTree: FileWriterDebugTree

    private val injectionModule = InjectionModule(this)

    override fun onCreate() {
        super.onCreate()

        module = injectionModule
        component = DaggerInjectionComponent.builder().injectionModule(injectionModule).build()
        component.inject(this)
        if (BuildConfig.DEBUG) {
            Timber.plant(fileWriterTree)
        }
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
