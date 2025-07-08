package com.screenlockapp.screen_lock_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Receiver for handling device boot events to restore scheduled locks
 */
class BootReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "BootReceiver"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "Received action: $action")

        when (action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_PACKAGE_REPLACED -> {
                // Restore scheduled locks after boot
                val scheduleManager = ScheduleManager(context)
                scheduleManager.restoreSchedulesAfterBoot()
                
                Log.i(TAG, "Schedules restored after boot")
            }
        }
    }
}

