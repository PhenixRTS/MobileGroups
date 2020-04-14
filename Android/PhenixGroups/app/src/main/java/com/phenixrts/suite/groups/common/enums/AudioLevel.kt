/*
 * Copyright 2020 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups.common.enums

import com.phenixrts.suite.groups.R

enum class AudioLevel(private val range: IntRange, val icon: Int) {
    VOLUME_0(Short.MIN_VALUE .. -70, R.drawable.ic_volume_0),
    VOLUME_1(-70 .. -60, R.drawable.ic_volume_1),
    VOLUME_2(-60 .. -50, R.drawable.ic_volume_2),
    VOLUME_3(-50 .. -45, R.drawable.ic_volume_3),
    VOLUME_4(-45 .. -40, R.drawable.ic_volume_4),
    VOLUME_5(-40 .. -35, R.drawable.ic_volume_5),
    VOLUME_6(-35 .. -30, R.drawable.ic_volume_6),
    VOLUME_7(-30 .. -25, R.drawable.ic_volume_7),
    VOLUME_8(-25 .. -20, R.drawable.ic_volume_8),
    VOLUME_9(-20 .. Short.MAX_VALUE, R.drawable.ic_volume_9);

    companion object {
        fun getVolume(decibels: Double): AudioLevel = values().find { decibels.toInt() in it.range } ?: VOLUME_0
    }

}
