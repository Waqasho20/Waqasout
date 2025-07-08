
package com.waqasout;

import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.IBinder;
import androidx.core.app.NotificationCompat;

public class LockService extends Service {

    public static final String CHANNEL_ID = "WaqasOutChannel";

    @Override
    public void onCreate() {
        super.onCreate();
        createNotificationChannel();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        String action = intent.getAction();
        if (action != null) {
            if ("com.waqasout.ACTION_LOCK_SCREEN".equals(action)) {
                NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CHANNEL_ID)
                        .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
                        .setContentTitle("Waqas Out")
                        .setContentText("Device is now locked.")
                        .setPriority(NotificationCompat.PRIORITY_HIGH);
                startForeground(1, builder.build());
            } else if ("com.waqasout.ACTION_UNLOCK_SCREEN".equals(action)) {
                NotificationCompat.Builder builder = new NotificationCompat.Builder(this, CHANNEL_ID)
                        .setSmallIcon(android.R.drawable.ic_lock_idle_open)
                        .setContentTitle("Waqas Out")
                        .setContentText("Scheduled lock period ended. You can now unlock your device.")
                        .setPriority(NotificationCompat.PRIORITY_HIGH);
                startForeground(1, builder.build());
            }
        }
        return START_NOT_STICKY;
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    private void createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel serviceChannel = new NotificationChannel(
                    CHANNEL_ID,
                    "Waqas Out Channel",
                    NotificationManager.IMPORTANCE_HIGH
            );
            NotificationManager manager = getSystemService(NotificationManager.class);
            manager.createNotificationChannel(serviceChannel);
        }
    }
}

