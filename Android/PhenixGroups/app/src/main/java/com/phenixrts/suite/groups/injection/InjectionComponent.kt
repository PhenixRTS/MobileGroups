/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.injection

import com.phenixrts.suite.groups.ui.MainActivity
import com.phenixrts.suite.groups.ui.screens.fragments.BaseFragment
import dagger.Component
import javax.inject.Singleton

@Singleton
@Component(modules = [InjectionModule::class])
interface InjectionComponent {
    fun inject(target: BaseFragment)
    fun inject(target: MainActivity)
}
