/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.receivers

import android.content.Context
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import timber.log.Timber

class CellularStateReceiver(context: Context) : PhoneStateListener() {

    private val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
    private var callback: OnCallStateChanged? = null
    private var currentState = telephonyManager.callState

    fun observeCellularState(callback: OnCallStateChanged) {
        this.callback = callback
        telephonyManager.listen(this, LISTEN_CALL_STATE)
    }

    fun unregister() {
        callback = null
        telephonyManager.listen(this, LISTEN_NONE)
    }

    fun isInCall() = telephonyManager.callState == TelephonyManager.CALL_STATE_OFFHOOK

    override fun onCallStateChanged(state: Int, phoneNumber: String?) {
        super.onCallStateChanged(state, phoneNumber)
        if (currentState != state) {
            currentState = state
            Timber.d("Call state changed: $state")
            when (state) {
                TelephonyManager.CALL_STATE_OFFHOOK -> callback?.onAnswered()
                TelephonyManager.CALL_STATE_IDLE -> callback?.onHungUp()
                TelephonyManager.CALL_STATE_RINGING -> { /* Ignored */ }
            }
        }
    }

    interface OnCallStateChanged {
        fun onAnswered()
        fun onHungUp()
    }
}
