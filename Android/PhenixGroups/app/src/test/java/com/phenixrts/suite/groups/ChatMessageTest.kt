package com.phenixrts.suite.groups

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.phenixrts.suite.groups.common.extensions.elapsedTime
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
class ChatMessageTest {

    private lateinit var context: Context

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
    }

    @Test
    fun `Should return 'Now' when elapsed time is less then 1 minute`() = runBlockingTest {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.SECOND, - 10)
        assertEquals(context.getString(R.string.chat_time_now), calendar.time.elapsedTime())
    }

    @Test
    fun `Should return '1 min' when elapsed time is 60 seconds`() = runBlockingTest {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.SECOND, - 60)
        assertEquals(context.getString(R.string.chat_time_min, 1), calendar.time.elapsedTime())
    }

    @Test
    fun `Should return '59 mins' when elapsed time is less then 1 hour`() = runBlockingTest {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.MINUTE, - 59)
        assertEquals(context.getString(R.string.chat_time_mins, 59), calendar.time.elapsedTime())
    }

    @Test
    fun `Should return '1 hour' when elapsed time is 60 minutes`() = runBlockingTest {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.MINUTE, - 60)
        assertEquals(context.getString(R.string.chat_time_hour, 1), calendar.time.elapsedTime())
    }

    @Test
    fun `Should return '23 hours' when elapsed time is less then 1 day`() = runBlockingTest {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.HOUR, - 23)
        assertEquals(context.getString(R.string.chat_time_hours, 23), calendar.time.elapsedTime())
    }

    @Test
    fun `Should return '1 day' when elapsed time is 24 hours`() = runBlockingTest {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.HOUR, - 24)
        assertEquals(context.getString(R.string.chat_time_day, 1), calendar.time.elapsedTime())
    }

    @Test
    fun `Should return '29 days' when elapsed time is less then 1 month`() = runBlockingTest {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_MONTH, - 29)
        assertEquals(context.getString(R.string.chat_time_days, 29), calendar.time.elapsedTime())
    }

    @Test
    fun `Should return '1 month' when elapsed time is 30 days`() = runBlockingTest {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.DAY_OF_MONTH, - 30)
        assertEquals(context.getString(R.string.chat_time_month, 1), calendar.time.elapsedTime())
    }

    @Test
    fun `Should return '11 months' when elapsed time is less then 1 year`() = runBlockingTest {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.MONTH, - 11)
        assertEquals(context.getString(R.string.chat_time_months, 11), calendar.time.elapsedTime())
    }

    @Test
    fun `Should return '1 year' when elapsed time is 12 months`() = runBlockingTest {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.MONTH, - 12)
        assertEquals(context.getString(R.string.chat_time_year, 1), calendar.time.elapsedTime())
    }

    @Test
    fun `Should return '10 years' when elapsed time is 10 years`() = runBlockingTest {
        val calendar = Calendar.getInstance()
        calendar.add(Calendar.YEAR, - 10)
        assertEquals(context.getString(R.string.chat_time_years, 10), calendar.time.elapsedTime())
    }

}
