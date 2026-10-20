//*******************************************************
//
//           CodeGear Delphi Runtime Library
// Copyright(c) 2014-2024 Embarcadero Technologies, Inc.
//              All rights reserved
//
//*******************************************************

package com.embarcadero.services;

import android.app.Service;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Intent;
import android.content.res.Configuration;
import android.os.Build;
import android.os.IBinder;
import android.os.Binder;
import android.content.pm.ServiceInfo;
import android.util.Log;

import com.embarcadero.rtl.ProxyService;

public class ForegroundLocationService extends Service {
    private final String baseLibraryName = "ForegroundLocationService"; 
    private static final int FOREGROUND_NOTIFICATION_ID = 1001;
    private static final String FOREGROUND_CHANNEL_ID = "channel_id_foreground_location_tracking";
    private static final String ACTION_START_LOCATION_TRACKING =
        "com.embarcadero.intent.action.START_LOCATION_TRACKING";
    private String libraryName;

    // Binder given to clients
    public final IBinder mBinder = new LocalBinder();

    /**
     * Class used for the client Binder.  Because we know this service always
     * runs in the same process as its clients, we don't need to deal with IPC.
     */
    public class LocalBinder extends Binder {
        public long getService() {
            // Return the instance of the Delphi LocalService so clients can call public methods
            return ProxyService.getService(this, libraryName);            
        }
    }

    @Override
    public void onCreate() {
        libraryName = "lib" + baseLibraryName + ".so";
        super.onCreate();
        ProxyService.onCreate(this, libraryName);
    }

    @Override
    public void onDestroy() {
        ProxyService.onDestroy(this, libraryName);
        super.onDestroy();
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        // A sticky restart has no intent; normalize it before crossing JNI.
        android.content.SharedPreferences state = getSharedPreferences("worby_service_state", MODE_PRIVATE);
        if (intent == null) {
            String action = state.getString("last_action", null);
            if (action == null || action.endsWith("DISABLE_LOCATION_TRACKING") ||
                    action.endsWith("STOP_LOCATION_TRACKING")) {
                Log.i("WorbyRepresGPS", "Sticky restart ignored: tracking not requested");
                stopSelf(startId);
                return START_NOT_STICKY;
            }
            intent = new Intent(this, getClass()).setAction(action);
            Log.i("WorbyRepresGPS", "Sticky restart restoring action=" + action);
        } else {
            String action = intent.getAction();
            state.edit().putString("last_action", action == null ? ACTION_START_LOCATION_TRACKING : action).commit();
        }
        Log.i("WorbyRepresGPS", "Java onStartCommand action=" + intent.getAction());
        // Promote the service before loading the Delphi callback. This is
        // required when Android recreates a sticky service after task removal.
        ensureForegroundNotification();
        int result = ProxyService.onStartCommand(this, libraryName, intent, flags, startId);
        Log.i("WorbyRepresGPS", "Java onStartCommand result=" + result);
        return result;
    }

    private void ensureForegroundNotification() {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                NotificationChannel channel = new NotificationChannel(
                    FOREGROUND_CHANNEL_ID,
                    "WorbyRepres localizacao",
                    NotificationManager.IMPORTANCE_LOW);
                NotificationManager manager = (NotificationManager)getSystemService(NOTIFICATION_SERVICE);
                if (manager != null) {
                    manager.createNotificationChannel(channel);
                }
            }

            Notification.Builder builder;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                builder = new Notification.Builder(this, FOREGROUND_CHANNEL_ID);
            } else {
                builder = new Notification.Builder(this);
            }
            builder.setSmallIcon(getApplicationInfo().icon)
                   .setContentTitle("WorbyRepres localizacao")
                   .setContentText("Rastreamento em segundo plano ativo")
                   .setOngoing(true);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(FOREGROUND_NOTIFICATION_ID, builder.build(),
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_LOCATION);
            } else {
                startForeground(FOREGROUND_NOTIFICATION_ID, builder.build());
            }
        } catch (RuntimeException error) {
            Log.e("WorbyRepresGPS", "Foreground location promotion failed", error);
        }
    }

    @Override
    public void onTaskRemoved(Intent rootIntent) {
        // Re-submit the service when the application task is removed. The
            // Delphi side decides whether tracking is allowed by time and state.
        try {
            String action = getSharedPreferences("worby_service_state", MODE_PRIVATE)
                .getString("last_action", null);
            if (action == null || !ACTION_START_LOCATION_TRACKING.equals(action)) {
                ProxyService.onTaskRemoved(this, libraryName, rootIntent);
                super.onTaskRemoved(rootIntent);
                return;
            }
            Intent restartIntent = new Intent(this, getClass());
            restartIntent.setPackage(getPackageName());
            // Do not let START_STICKY redeliver a previous disable command.
            restartIntent.setAction(ACTION_START_LOCATION_TRACKING);
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(restartIntent);
            } else {
                startService(restartIntent);
            }
        } catch (RuntimeException error) {
            Log.e("WorbyRepresGPS", "Task removal restart failed", error);
        }
        ProxyService.onTaskRemoved(this, libraryName, rootIntent);
        super.onTaskRemoved(rootIntent);
    }

    @Override
    public IBinder onBind(Intent intent) {
        return ProxyService.onBind(this, libraryName, intent);
    }

    @Override
    public void onRebind(Intent intent) {
        ProxyService.onRebind(this, libraryName, intent);
    }

    @Override
    public boolean onUnbind(Intent intent) {
        return ProxyService.onUnbind(this, libraryName, intent);
    }

    @Override
    public void onConfigurationChanged(Configuration newConfig) {
        ProxyService.onConfigurationChanged(this, libraryName, newConfig);
    }

    @Override
    public void onLowMemory() {
        ProxyService.onLowMemory(this, libraryName);
    }

    @Override
    public void onTrimMemory(int level) {
        ProxyService.onTrimMemory(this, libraryName, level);
    }
}
