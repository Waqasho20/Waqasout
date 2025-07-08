package com.screenlockapp.screen_lock_app

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * Utility class for managing device administrator functionality
 */
class DeviceAdminManager(private val context: Context) {
    
    companion object {
        private const val TAG = "DeviceAdminManager"
    }
    
    private val devicePolicyManager: DevicePolicyManager = 
        context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
    private val adminComponent: ComponentName = 
        ComponentName(context, DeviceAdminReceiver::class.java)

    /**
     * Check if device administrator is enabled
     */
    fun isAdminActive(): Boolean {
        return devicePolicyManager.isAdminActive(adminComponent)
    }

    /**
     * Request device administrator privileges
     */
    fun getEnableAdminIntent(): Intent {
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, adminComponent)
        intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, 
            "Allow this app to lock and unlock your screen automatically")
        return intent
    }

    /**
     * Lock the device screen immediately
     */
    fun lockScreen(): Boolean {
        if (!isAdminActive()) {
            Log.w(TAG, "Device admin not active, cannot lock screen")
            return false
        }

        return try {
            devicePolicyManager.lockNow()
            Log.i(TAG, "Screen locked successfully")
            true
        } catch (e: SecurityException) {
            Log.e(TAG, "Failed to lock screen: ${e.message}")
            false
        }
    }

    /**
     * Unlock the device by removing the password
     * Note: This will remove any existing password/PIN/pattern
     */
    fun unlockScreen(): Boolean {
        if (!isAdminActive()) {
            Log.w(TAG, "Device admin not active, cannot unlock screen")
            return false
        }

        return try {
            // Reset password to empty string to unlock
            val success = devicePolicyManager.resetPassword("", 0)
            if (success) {
                Log.i(TAG, "Screen unlocked successfully")
            } else {
                Log.w(TAG, "Failed to unlock screen - resetPassword returned false")
            }
            success
        } catch (e: SecurityException) {
            Log.e(TAG, "Failed to unlock screen: ${e.message}")
            false
        }
    }

    /**
     * Set password quality requirements
     */
    fun setPasswordQuality(quality: Int) {
        if (isAdminActive()) {
            devicePolicyManager.setPasswordQuality(adminComponent, quality)
        }
    }

    /**
     * Set minimum password length
     */
    fun setPasswordMinimumLength(length: Int) {
        if (isAdminActive()) {
            devicePolicyManager.setPasswordMinimumLength(adminComponent, length)
        }
    }

    /**
     * Set maximum time to lock (in milliseconds)
     */
    fun setMaxTimeToLock(timeMs: Long) {
        if (isAdminActive()) {
            devicePolicyManager.setMaximumTimeToLock(adminComponent, timeMs)
        }
    }

    /**
     * Disable keyguard features
     */
    fun setKeyguardDisabledFeatures(features: Int) {
        if (isAdminActive()) {
            try {
                devicePolicyManager.setKeyguardDisabledFeatures(adminComponent, features)
            } catch (e: SecurityException) {
                Log.e(TAG, "Failed to set keyguard disabled features: ${e.message}")
            }
        }
    }

    /**
     * Remove device administrator privileges
     */
    fun removeAdmin() {
        if (isAdminActive()) {
            devicePolicyManager.removeActiveAdmin(adminComponent)
        }
    }

    /**
     * Get device policy manager instance
     */
    fun getDevicePolicyManager(): DevicePolicyManager {
        return devicePolicyManager
    }

    /**
     * Get admin component
     */
    fun getAdminComponent(): ComponentName {
        return adminComponent
    }
}

