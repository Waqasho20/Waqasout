package com.screenlockapp.screen_lock_app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.util.Log
import java.util.*

/**
 * Manager class for handling scheduled screen lock/unlock functionality
 */
class ScheduleManager(private val context: Context) {
    
    companion object {
        private const val TAG = "ScheduleManager"
        private const val PREFS_NAME = "schedule_prefs"
        private const val KEY_SCHEDULES = "schedules"
        private const val KEY_NEXT_SCHEDULE_ID = "next_schedule_id"
    }

    private val alarmManager: AlarmManager = 
        context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
    private val prefs: SharedPreferences = 
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    data class Schedule(
        val id: Int,
        val hour: Int,
        val minute: Int,
        val durationMinutes: Int,
        var enabled: Boolean = true,
        val daysOfWeek: MutableSet<Int> = mutableSetOf()
    ) {
        init {
            // Default to all days if none specified
            if (daysOfWeek.isEmpty()) {
                for (i in 1..7) {
                    daysOfWeek.add(i)
                }
            }
        }

        fun getTimeString(): String {
            return String.format("%02d:%02d", hour, minute)
        }

        override fun toString(): String {
            return "Schedule $id: ${getTimeString()} for $durationMinutes minutes"
        }
    }

    /**
     * Add a new schedule
     */
    fun addSchedule(hour: Int, minute: Int, durationMinutes: Int): Schedule {
        val scheduleId = getNextScheduleId()
        val schedule = Schedule(scheduleId, hour, minute, durationMinutes)
        
        saveSchedule(schedule)
        scheduleNextAlarm(schedule)
        
        Log.i(TAG, "Added schedule: $schedule")
        return schedule
    }

    /**
     * Remove a schedule
     */
    fun removeSchedule(scheduleId: Int) {
        cancelScheduleAlarms(scheduleId)
        
        // Remove from preferences
        val schedules = prefs.getStringSet(KEY_SCHEDULES, mutableSetOf())?.toMutableSet() ?: mutableSetOf()
        schedules.removeAll { it.startsWith("$scheduleId|") }
        prefs.edit().putStringSet(KEY_SCHEDULES, schedules).apply()
        
        Log.i(TAG, "Removed schedule: $scheduleId")
    }

    /**
     * Enable or disable a schedule
     */
    fun setScheduleEnabled(scheduleId: Int, enabled: Boolean) {
        val schedule = getSchedule(scheduleId)
        if (schedule != null) {
            schedule.enabled = enabled
            saveSchedule(schedule)
            
            if (enabled) {
                scheduleNextAlarm(schedule)
            } else {
                cancelScheduleAlarms(scheduleId)
            }
            
            Log.i(TAG, "Schedule $scheduleId ${if (enabled) "enabled" else "disabled"}")
        }
    }

    /**
     * Get all schedules
     */
    fun getAllSchedules(): Set<Schedule> {
        val schedules = mutableSetOf<Schedule>()
        val scheduleStrings = prefs.getStringSet(KEY_SCHEDULES, mutableSetOf()) ?: mutableSetOf()
        
        for (scheduleString in scheduleStrings) {
            val schedule = parseSchedule(scheduleString)
            if (schedule != null) {
                schedules.add(schedule)
            }
        }
        
        return schedules
    }

    /**
     * Get a specific schedule by ID
     */
    fun getSchedule(scheduleId: Int): Schedule? {
        val scheduleStrings = prefs.getStringSet(KEY_SCHEDULES, mutableSetOf()) ?: mutableSetOf()
        
        for (scheduleString in scheduleStrings) {
            if (scheduleString.startsWith("$scheduleId|")) {
                return parseSchedule(scheduleString)
            }
        }
        
        return null
    }

    /**
     * Schedule the next alarm for a given schedule
     */
    private fun scheduleNextAlarm(schedule: Schedule) {
        if (!schedule.enabled) {
            return
        }

        val now = Calendar.getInstance()
        val nextAlarm = getNextAlarmTime(schedule, now)
        
        if (nextAlarm != null) {
            // Schedule lock alarm
            val lockIntent = Intent(context, AlarmReceiver::class.java)
            lockIntent.action = AlarmReceiver.ACTION_LOCK_SCREEN
            lockIntent.putExtra(AlarmReceiver.EXTRA_SCHEDULE_ID, schedule.id)
            
            val lockPendingIntent = PendingIntent.getBroadcast(
                context, 
                schedule.id * 2, // Use even numbers for lock alarms
                lockIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                nextAlarm.timeInMillis,
                lockPendingIntent
            )

            Log.i(TAG, "Scheduled lock alarm for $schedule at ${nextAlarm.time}")
        }
    }

    /**
     * Schedule unlock alarm for an active schedule
     */
    fun scheduleUnlockForActiveSchedule(scheduleId: Int) {
        val schedule = getSchedule(scheduleId)
        if (schedule != null) {
            val unlockTime = Calendar.getInstance()
            unlockTime.add(Calendar.MINUTE, schedule.durationMinutes)
            
            val unlockIntent = Intent(context, AlarmReceiver::class.java)
            unlockIntent.action = AlarmReceiver.ACTION_UNLOCK_SCREEN
            unlockIntent.putExtra(AlarmReceiver.EXTRA_SCHEDULE_ID, schedule.id)
            
            val unlockPendingIntent = PendingIntent.getBroadcast(
                context,
                schedule.id * 2 + 1, // Use odd numbers for unlock alarms
                unlockIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP,
                unlockTime.timeInMillis,
                unlockPendingIntent
            )

            Log.i(TAG, "Scheduled unlock alarm for $schedule at ${unlockTime.time}")
            
            // Schedule next occurrence of this schedule
            scheduleNextAlarm(schedule)
        }
    }

    /**
     * Cancel all alarms for a schedule
     */
    private fun cancelScheduleAlarms(scheduleId: Int) {
        // Cancel lock alarm
        val lockIntent = Intent(context, AlarmReceiver::class.java)
        lockIntent.action = AlarmReceiver.ACTION_LOCK_SCREEN
        val lockPendingIntent = PendingIntent.getBroadcast(
            context, 
            scheduleId * 2,
            lockIntent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(lockPendingIntent)

        // Cancel unlock alarm
        val unlockIntent = Intent(context, AlarmReceiver::class.java)
        unlockIntent.action = AlarmReceiver.ACTION_UNLOCK_SCREEN
        val unlockPendingIntent = PendingIntent.getBroadcast(
            context,
            scheduleId * 2 + 1,
            unlockIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(unlockPendingIntent)
        
        Log.i(TAG, "Cancelled alarms for schedule: $scheduleId")
    }

    /**
     * Restore all schedules after device boot
     */
    fun restoreSchedulesAfterBoot() {
        val schedules = getAllSchedules()
        for (schedule in schedules) {
            if (schedule.enabled) {
                scheduleNextAlarm(schedule)
            }
        }
        Log.i(TAG, "Restored ${schedules.size} schedules after boot")
    }

    /**
     * Get the next alarm time for a schedule
     */
    private fun getNextAlarmTime(schedule: Schedule, from: Calendar): Calendar? {
        val alarm = Calendar.getInstance()
        alarm.set(Calendar.HOUR_OF_DAY, schedule.hour)
        alarm.set(Calendar.MINUTE, schedule.minute)
        alarm.set(Calendar.SECOND, 0)
        alarm.set(Calendar.MILLISECOND, 0)

        // If the time has passed today, move to tomorrow
        if (alarm.before(from) || alarm == from) {
            alarm.add(Calendar.DAY_OF_YEAR, 1)
        }

        // Find the next day that matches the schedule
        var maxDays = 7 // Don't search more than a week
        while (maxDays > 0) {
            val dayOfWeek = alarm.get(Calendar.DAY_OF_WEEK)
            if (schedule.daysOfWeek.contains(dayOfWeek)) {
                return alarm
            }
            alarm.add(Calendar.DAY_OF_YEAR, 1)
            maxDays--
        }

        return null // No valid day found
    }

    /**
     * Save a schedule to preferences
     */
    private fun saveSchedule(schedule: Schedule) {
        val schedules = prefs.getStringSet(KEY_SCHEDULES, mutableSetOf())?.toMutableSet() ?: mutableSetOf()
        
        // Remove existing schedule with same ID
        schedules.removeAll { it.startsWith("${schedule.id}|") }
        
        // Add updated schedule
        val scheduleString = serializeSchedule(schedule)
        schedules.add(scheduleString)
        
        prefs.edit().putStringSet(KEY_SCHEDULES, schedules).apply()
    }

    /**
     * Serialize schedule to string
     */
    private fun serializeSchedule(schedule: Schedule): String {
        val sb = StringBuilder()
        sb.append(schedule.id).append("|")
        sb.append(schedule.hour).append("|")
        sb.append(schedule.minute).append("|")
        sb.append(schedule.durationMinutes).append("|")
        sb.append(schedule.enabled).append("|")
        
        // Serialize days of week
        for (day in schedule.daysOfWeek) {
            sb.append(day).append(",")
        }
        
        return sb.toString()
    }

    /**
     * Parse schedule from string
     */
    private fun parseSchedule(scheduleString: String): Schedule? {
        return try {
            val parts = scheduleString.split("|")
            if (parts.size < 5) return null
            
            val id = parts[0].toInt()
            val hour = parts[1].toInt()
            val minute = parts[2].toInt()
            val duration = parts[3].toInt()
            val enabled = parts[4].toBoolean()
            
            val schedule = Schedule(id, hour, minute, duration, enabled)
            
            // Parse days of week
            if (parts.size > 5 && parts[5].isNotEmpty()) {
                schedule.daysOfWeek.clear()
                val days = parts[5].split(",")
                for (day in days) {
                    if (day.isNotEmpty()) {
                        schedule.daysOfWeek.add(day.toInt())
                    }
                }
            }
            
            schedule
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse schedule: $scheduleString", e)
            null
        }
    }

    /**
     * Get next available schedule ID
     */
    private fun getNextScheduleId(): Int {
        val nextId = prefs.getInt(KEY_NEXT_SCHEDULE_ID, 1)
        prefs.edit().putInt(KEY_NEXT_SCHEDULE_ID, nextId + 1).apply()
        return nextId
    }
}

