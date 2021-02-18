/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.ui.screens.fragments

import android.os.Bundle
import androidx.fragment.app.Fragment
import androidx.transition.Fade
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.cache.CacheProvider
import com.phenixrts.suite.groups.cache.PreferenceProvider
import com.phenixrts.suite.groups.common.extensions.*
import com.phenixrts.suite.groups.repository.RepositoryProvider
import com.phenixrts.suite.groups.ui.viewmodels.GroupsViewModel
import javax.inject.Inject

abstract class BaseFragment : Fragment() {

    @Inject lateinit var repositoryProvider: RepositoryProvider
    @Inject lateinit var cacheProvider: CacheProvider
    @Inject lateinit var preferenceProvider: PreferenceProvider

    val viewModel: GroupsViewModel by lazyViewModel({ requireActivity().application as GroupsApplication }, {
        GroupsViewModel(cacheProvider, preferenceProvider, repositoryProvider)
    })

    open fun onBackPressed() {}

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        injectDependencies()
    }

    override fun getEnterTransition(): Any = Fade(Fade.MODE_IN).apply {
        duration = DEFAULT_ANIMATION_DURATION
    }

    override fun getReturnTransition(): Any = Fade(Fade.MODE_OUT).apply {
        duration = DEFAULT_ANIMATION_DURATION
    }

}
