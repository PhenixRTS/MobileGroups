/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common.extensions

import android.view.inputmethod.InputMethodManager
import android.widget.Toast
import androidx.core.content.ContextCompat.getSystemService
import androidx.fragment.app.Fragment
import com.phenixrts.suite.groups.GroupsApplication
import com.phenixrts.suite.groups.ui.screens.fragments.BaseFragment
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.GlobalScope
import kotlinx.coroutines.launch

/**
 * Used to show simple toast with given message
 */
fun Fragment.showToast(message: String) {
    if (isAdded) {
        GlobalScope.launch(Dispatchers.Main) {
            Toast.makeText(activity, message, Toast.LENGTH_SHORT).show()
        }
    }
}

/**
 * Used to inject dagger dependencies
 */
fun BaseFragment.injectDependencies() {
    GroupsApplication.component.inject(this)
}

/**
 * Terminates the app with a message in case SDK failed to initializes
 */
fun BaseFragment.closeApp(message: String) {
    showToast(message)
    requireActivity().finish()
}

/**
 * Hides current active keyboard and clears focus
 */
fun BaseFragment.hideKeyboard() {
    val view = requireActivity().currentFocus ?: requireActivity().window.decorView
    val token = view.windowToken
    view.clearFocus()
    getSystemService(requireContext(), InputMethodManager::class.java)?.hideSoftInputFromWindow(token, 0)
}
