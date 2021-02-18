/*
 * Copyright 2021 Phenix Real Time Solutions, Inc. Confidential and Proprietary. All rights reserved.
 */

package com.phenixrts.suite.groups

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.phenixrts.suite.groups.common.extensions.*
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.runBlockingTest
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.util.*

@ExperimentalCoroutinesApi
@Config(manifest = Config.NONE, sdk = [21])
@RunWith(RobolectricTestRunner::class)
class DateFormatTest {

    private lateinit var context: Context

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
    }

    @Test
    fun `Should return 'Now' when elapsed time is less then 1 minute`() = runBlockingTest {
        val date = Date(System.currentTimeMillis() - SECOND_MILLIS * 59)
        assertEquals(context.getString(R.string.chat_time_now), date.elapsedTime())
    }

    @Test
    fun `Should return '1 min' when elapsed time is 60 seconds`() = runBlockingTest {
        val date = Date(System.currentTimeMillis() - SECOND_MILLIS * 60)
        assertEquals(context.getString(R.string.chat_time_min, 1), date.elapsedTime())
    }

    @Test
    fun `Should return '59 mins' when elapsed time is less then 1 hour`() = runBlockingTest {
        val date = Date(System.currentTimeMillis() - MINUTE_MILLIS * 59)
        assertEquals(context.getString(R.string.chat_time_mins, 59), date.elapsedTime())
    }

    @Test
    fun `Should return '1 hour' when elapsed time is 60 minutes`() = runBlockingTest {
        val date = Date(System.currentTimeMillis() - MINUTE_MILLIS * 60)
        assertEquals(context.getString(R.string.chat_time_hour, 1), date.elapsedTime())
    }

    @Test
    fun `Should return '23 hours' when elapsed time is less then 1 day`() = runBlockingTest {
        val date = Date(System.currentTimeMillis() - HOUR_MILLIS * 23)
        assertEquals(context.getString(R.string.chat_time_hours, 23), date.elapsedTime())
    }

    @Test
    fun `Should return '1 day' when elapsed time is 24 hours`() = runBlockingTest {
        val date = Date(System.currentTimeMillis() - HOUR_MILLIS * 24)
        assertEquals(context.getString(R.string.chat_time_day, 1), date.elapsedTime())
    }

    @Test
    fun `Should return '29 days' when elapsed time is less then 1 month`() = runBlockingTest {
        val date = Date(System.currentTimeMillis() - DAY_MILLIS * 29)
        assertEquals(context.getString(R.string.chat_time_days, 29), date.elapsedTime())
    }

    @Test
    fun `Should return '1 month' when elapsed time is 30 days`() = runBlockingTest {
        val date = Date(System.currentTimeMillis() - DAY_MILLIS * 30)
        assertEquals(context.getString(R.string.chat_time_month, 1), date.elapsedTime())
    }

    @Test
    fun `Should return '11 months' when elapsed time is less then 1 year`() = runBlockingTest {
        val date = Date(System.currentTimeMillis() - MONTH_MILLIS * 11)
        assertEquals(context.getString(R.string.chat_time_months, 11), date.elapsedTime())
    }

    @Test
    fun `Should return '1 year' when elapsed time is 12 months`() = runBlockingTest {
        val date = Date(System.currentTimeMillis() - MONTH_MILLIS * 12)
        assertEquals(context.getString(R.string.chat_time_year, 1), date.elapsedTime())
    }

    @Test
    fun `Should return '10 years' when elapsed time is 10 years`() = runBlockingTest {
        val date = Date(System.currentTimeMillis() - YEAR_MILLIS * 10)
        assertEquals(context.getString(R.string.chat_time_years, 10), date.elapsedTime())
    }

    @Test
    fun `Should return 'false' when elapsed time is less then 24 hours`() = runBlockingTest {
        val date = Date(System.currentTimeMillis() - HOUR_MILLIS * 23)
        assertEquals(false, date.isLongerThanDay())
    }

    @Test
    fun `Should return 'true' when elapsed time is more or equal then 24 hours`() = runBlockingTest {
        val date = Date(System.currentTimeMillis() - HOUR_MILLIS * 24)
        assertEquals(true, date.isLongerThanDay())
    }

}
