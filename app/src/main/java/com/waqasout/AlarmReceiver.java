package com.waqasout;

import android.app.admin.DevicePolicyManager;
import android.content.BroadcastReceiver;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.widget.Toast;

public class AlarmReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        DevicePolicyManager devicePolicyManager = (DevicePolicyManager) context.getSystemService(Context.DEVICE_POLICY_SERVICE);
        ComponentName compName = new ComponentName(context, DeviceAdmin.class);

        if (devicePolicyManager.isAdminActive(compName)) {
            String action = intent.getAction();
            if ("com.waqasout.ACTION_LOCK_SCREEN".equals(action)) {
                devicePolicyManager.lockNow();
                Toast.makeText(context, "Scheduled Lock Activated", Toast.LENGTH_SHORT).show();
                Intent serviceIntent = new Intent(context, LockService.class);
                serviceIntent.setAction("com.waqasout.ACTION_LOCK_SCREEN");
                context.startService(serviceIntent);
            } else if ("com.waqasout.ACTION_UNLOCK_SCREEN".equals(action)) {
                Toast.makeText(context, "Scheduled Lock Deactivated. You can now unlock your device.", Toast.LENGTH_LONG).show();
                Intent serviceIntent = new Intent(context, LockService.class);
                serviceIntent.setAction("com.waqasout.ACTION_UNLOCK_SCREEN");
                context.startService(serviceIntent);
            }
        } else {
            Toast.makeText(context, "Device Admin not active. Cannot perform scheduled lock/unlock.", Toast.LENGTH_LONG).show();
        }
    }
}

