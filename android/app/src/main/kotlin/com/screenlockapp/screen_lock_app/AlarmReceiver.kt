package com.screenlockapp.screen_lock_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Receiver for handling scheduled lock/unlock alarms
 */
class AlarmReceiver : BroadcastReceiver() {
    
    companion object {
        private const val TAG = "AlarmReceiver"
        const val ACTION_LOCK_SCREEN = "com.screenlockapp.ACTION_LOCK_SCREEN"
        const val ACTION_UNLOCK_SCREEN = "com.screenlockapp.ACTION_UNLOCK_SCREEN"
        const val EXTRA_SCHEDULE_ID = "schedule_id"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action
        Log.d(TAG, "Received action: $action")

        val deviceAdminManager = DeviceAdminManager(context)
        
        when (action) {
            ACTION_LOCK_SCREEN -> handleLockScreen(context, intent, deviceAdminManager)
            ACTION_UNLOCK_SCREEN -> handleUnlockScreen(context, intent, deviceAdminManager)
        }
    }

    private fun handleLockScreen(context: Context, intent: Intent, adminManager: DeviceAdminManager) {
        Log.i(TAG, "Handling scheduled lock screen")
        
        if (adminManager.isAdminActive()) {
            val success = adminManager.lockScreen()
            if (success) {
                // Show notification that screen is locked
                NotificationHelper.showLockNotification(context)
                
                // Schedule unlock if duration is specified
                val scheduleId = intent.getIntExtra(EXTRA_SCHEDULE_ID, -1)
                if (scheduleId != -1) {
                    val scheduleManager = ScheduleManager(context)
                    scheduleManager.scheduleUnlockForActiveSchedule(scheduleId)
                }
            }
        } else {
            Log.w(TAG, "Device admin not active, cannot lock screen")
        }
    }

    private fun handleUnlockScreen(context: Context, intent: Intent, adminManager: DeviceAdminManager) {
        Log.i(TAG, "Handling scheduled unlock screen")
        
        if (adminManager.isAdminActive()) {
            val success = adminManager.unlockScreen()
            if (success) {
                // Show notification that screen is unlocked
                NotificationHelper.showUnlockNotification(context)
            }
        } else {
            Log.w(TAG, "Device admin not active, cannot unlock screen")
        }
    }
}

