package com.waqasout;

import androidx.appcompat.app.AppCompatActivity;
import android.app.admin.DevicePolicyManager;
import android.content.ComponentName;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.Toast;
import android.app.AlarmManager;
import android.app.PendingIntent;
import java.util.Calendar;

public class MainActivity extends AppCompatActivity {

    private static final int REQUEST_CODE_ENABLE_ADMIN = 1;
    private DevicePolicyManager devicePolicyManager;
    private ComponentName compName;

    private EditText timerDurationEditText;
    private Button startTimerButton;

    private EditText scheduledLockStartTimeEditText;
    private EditText scheduledLockEndTimeEditText;
    private Button setScheduledLockButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        devicePolicyManager = (DevicePolicyManager) getSystemService(DEVICE_POLICY_SERVICE);
        compName = new ComponentName(this, DeviceAdmin.class);

        timerDurationEditText = findViewById(R.id.timer_duration_edit_text);
        startTimerButton = findViewById(R.id.start_timer_button);

        scheduledLockStartTimeEditText = findViewById(R.id.scheduled_lock_start_time_edit_text);
        scheduledLockEndTimeEditText = findViewById(R.id.scheduled_lock_end_time_edit_text);
        setScheduledLockButton = findViewById(R.id.set_scheduled_lock_button);

        startTimerButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (devicePolicyManager.isAdminActive(compName)) {
                    String durationStr = timerDurationEditText.getText().toString();
                    if (!durationStr.isEmpty()) {
                        long duration = Long.parseLong(durationStr) * 1000; // Convert to milliseconds
                        devicePolicyManager.lockNow();
                        Toast.makeText(MainActivity.this, "Device locked for " + durationStr + " seconds", Toast.LENGTH_SHORT).show();

                        new Handler().postDelayed(new Runnable() {
                            @Override
                            public void run() {
                                Toast.makeText(MainActivity.this, "Timer ended. Device can now be unlocked.", Toast.LENGTH_LONG).show();
                            }
                        }, duration);
                    } else {
                        Toast.makeText(MainActivity.this, "Please enter a duration", Toast.LENGTH_SHORT).show();
                    }
                } else {
                    Intent intent = new Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN);
                    intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, compName);
                    intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Waqas Out needs Device Admin privileges to lock your screen.");
                    startActivityForResult(intent, REQUEST_CODE_ENABLE_ADMIN);
                }
            }
        });

        setScheduledLockButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (devicePolicyManager.isAdminActive(compName)) {
                    String startTimeStr = scheduledLockStartTimeEditText.getText().toString();
                    String endTimeStr = scheduledLockEndTimeEditText.getText().toString();

                    if (!startTimeStr.isEmpty() && !endTimeStr.isEmpty()) {
                        try {
                            // Parse start time
                            String[] startTimeParts = startTimeStr.split(":");
                            int startHour = Integer.parseInt(startTimeParts[0]);
                            int startMinute = Integer.parseInt(startTimeParts[1]);

                            // Parse end time
                            String[] endTimeParts = endTimeStr.split(":");
                            int endHour = Integer.parseInt(endTimeParts[0]);
                            int endMinute = Integer.parseInt(endTimeParts[1]);

                            // Set up AlarmManager for lock
                            Calendar lockCalendar = Calendar.getInstance();
                            lockCalendar.set(Calendar.HOUR_OF_DAY, startHour);
                            lockCalendar.set(Calendar.MINUTE, startMinute);
                            lockCalendar.set(Calendar.SECOND, 0);

                            Intent lockIntent = new Intent(MainActivity.this, AlarmReceiver.class);
                            lockIntent.setAction("com.waqasout.ACTION_LOCK_SCREEN");
                            PendingIntent lockPendingIntent = PendingIntent.getBroadcast(MainActivity.this, 0, lockIntent, PendingIntent.FLAG_UPDATE_CURRENT);

                            AlarmManager alarmManager = (AlarmManager) getSystemService(ALARM_SERVICE);
                            alarmManager.setRepeating(AlarmManager.RTC_WAKEUP, lockCalendar.getTimeInMillis(), AlarmManager.INTERVAL_DAY, lockPendingIntent);

                            // Set up AlarmManager for unlock
                            Calendar unlockCalendar = Calendar.getInstance();
                            unlockCalendar.set(Calendar.HOUR_OF_DAY, endHour);
                            unlockCalendar.set(Calendar.MINUTE, endMinute);
                            unlockCalendar.set(Calendar.SECOND, 0);

                            Intent unlockIntent = new Intent(MainActivity.this, AlarmReceiver.class);
                            unlockIntent.setAction("com.waqasout.ACTION_UNLOCK_SCREEN");
                            PendingIntent unlockPendingIntent = PendingIntent.getBroadcast(MainActivity.this, 1, unlockIntent, PendingIntent.FLAG_UPDATE_CURRENT);

                            alarmManager.setRepeating(AlarmManager.RTC_WAKEUP, unlockCalendar.getTimeInMillis(), AlarmManager.INTERVAL_DAY, unlockPendingIntent);

                            Toast.makeText(MainActivity.this, "Scheduled lock set from " + startTimeStr + " to " + endTimeStr, Toast.LENGTH_LONG).show();

                        } catch (Exception e) {
                            Toast.makeText(MainActivity.this, "Invalid time format. Use HH:MM", Toast.LENGTH_SHORT).show();
                        }
                    } else {
                        Toast.makeText(MainActivity.this, "Please enter both start and end times", Toast.LENGTH_SHORT).show();
                    }
                } else {
                    Intent intent = new Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN);
                    intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, compName);
                    intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Waqas Out needs Device Admin privileges to schedule screen locks.");
                    startActivityForResult(intent, REQUEST_CODE_ENABLE_ADMIN);
                }
            }
        });
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        super.onActivityResult(requestCode, resultCode, data);
        if (requestCode == REQUEST_CODE_ENABLE_ADMIN) {
            if (resultCode == RESULT_OK) {
                Toast.makeText(this, "Device Admin enabled", Toast.LENGTH_SHORT).show();
            } else {
                Toast.makeText(this, "Device Admin activation failed", Toast.LENGTH_SHORT).show();
            }
        }
    }
}

