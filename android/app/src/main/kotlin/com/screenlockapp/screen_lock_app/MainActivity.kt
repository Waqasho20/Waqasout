package com.screenlockapp.screen_lock_app

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.screenlockapp.screen_lock_app/device_admin"
    private val REQUEST_ENABLE_ADMIN = 1001
    
    private lateinit var deviceAdminManager: DeviceAdminManager
    private lateinit var scheduleManager: ScheduleManager
    private var pendingResult: MethodChannel.Result? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        deviceAdminManager = DeviceAdminManager(this)
        scheduleManager = ScheduleManager(this)
        
        // Create notification channel
        NotificationHelper.createNotificationChannel(this)
        
        // Handle admin revoked intent
        handleAdminRevokedIntent()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAdminActive" -> {
                    result.success(deviceAdminManager.isAdminActive())
                }
                "requestAdminPermission" -> {
                    requestAdminPermission(result)
                }
                "removeAdmin" -> {
                    deviceAdminManager.removeAdmin()
                    result.success(true)
                }
                "lockScreen" -> {
                    val success = deviceAdminManager.lockScreen()
                    result.success(success)
                }
                "unlockScreen" -> {
                    val success = deviceAdminManager.unlockScreen()
                    result.success(success)
                }
                "addSchedule" -> {
                    val hour = call.argument<Int>("hour") ?: 0
                    val minute = call.argument<Int>("minute") ?: 0
                    val duration = call.argument<Int>("duration") ?: 0
                    
                    val schedule = scheduleManager.addSchedule(hour, minute, duration)
                    result.success(mapOf(
                        "id" to schedule.id,
                        "hour" to schedule.hour,
                        "minute" to schedule.minute,
                        "duration" to schedule.durationMinutes,
                        "enabled" to schedule.enabled
                    ))
                }
                "removeSchedule" -> {
                    val scheduleId = call.argument<Int>("scheduleId") ?: -1
                    scheduleManager.removeSchedule(scheduleId)
                    result.success(true)
                }
                "getAllSchedules" -> {
                    val schedules = scheduleManager.getAllSchedules()
                    val scheduleList = schedules.map { schedule ->
                        mapOf(
                            "id" to schedule.id,
                            "hour" to schedule.hour,
                            "minute" to schedule.minute,
                            "duration" to schedule.durationMinutes,
                            "enabled" to schedule.enabled
                        )
                    }
                    result.success(scheduleList)
                }
                "setScheduleEnabled" -> {
                    val scheduleId = call.argument<Int>("scheduleId") ?: -1
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    scheduleManager.setScheduleEnabled(scheduleId, enabled)
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun requestAdminPermission(result: MethodChannel.Result) {
        pendingResult = result
        val intent = deviceAdminManager.getEnableAdminIntent()
        startActivityForResult(intent, REQUEST_ENABLE_ADMIN)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (requestCode == REQUEST_ENABLE_ADMIN) {
            val success = resultCode == Activity.RESULT_OK && deviceAdminManager.isAdminActive()
            pendingResult?.success(success)
            pendingResult = null
        }
    }

    private fun handleAdminRevokedIntent() {
        val intent = intent
        if (intent != null && intent.getBooleanExtra("admin_revoked", false)) {
            // Handle admin revoked notification
            // This could trigger a Flutter method to show a dialog
        }
    }
}

