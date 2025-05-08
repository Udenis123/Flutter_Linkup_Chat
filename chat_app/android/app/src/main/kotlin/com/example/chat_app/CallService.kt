package com.example.chat_app

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.app.NotificationManager
import android.app.NotificationChannel
import android.app.PendingIntent
import android.os.Build
import androidx.core.app.NotificationCompat
import android.content.Context
import android.os.PowerManager
import android.os.Handler
import android.os.Looper

class CallService : Service() {
    companion object {
        const val NOTIFICATION_CHANNEL_ID = "call_channel"
        const val NOTIFICATION_ID = 1
        private const val WAKELOCK_TIMEOUT = 10 * 60 * 1000L // 10 minutes
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun onCreate() {
        super.onCreate()
        createNotificationChannel()
        acquireWakeLock()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        // Show the incoming call notification
        showIncomingCallNotification(intent)
        
        // Broadcast the incoming call intent
        val broadcastIntent = Intent(CallReceiver.ACTION_INCOMING_CALL).apply {
            putExtras(intent?.extras ?: return START_NOT_STICKY)
        }
        sendBroadcast(broadcastIntent)

        // Schedule service stop after timeout
        handler.postDelayed({
            stopSelf()
        }, WAKELOCK_TIMEOUT)

        return START_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        releaseWakeLock()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Incoming Calls",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Channel for incoming call notifications"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }

            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showIncomingCallNotification(intent: Intent?) {
        val callId = intent?.getStringExtra("call_id") ?: return
        val callerName = intent.getStringExtra("caller_name") ?: "Unknown"
        val callType = intent.getStringExtra("call_type") ?: "voice"

        // Create intent for the incoming call activity
        val activityIntent = Intent(this, IncomingCallActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtras(intent)
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            activityIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Create and show the notification
        val notification = NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("Incoming ${callType.capitalize()} Call")
            .setContentText("from $callerName")
            .setSmallIcon(android.R.drawable.ic_notification_overlay)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setFullScreenIntent(pendingIntent, true)
            .setAutoCancel(false)
            .setOngoing(true)
            .build()

        startForeground(NOTIFICATION_ID, notification)

        // Try to show the incoming call screen immediately
        try {
            activityIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(activityIntent)
        } catch (e: Exception) {
            // Activity failed to start, notification is already showing
        }
    }

    private fun acquireWakeLock() {
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "ChatApp:CallService"
        ).apply {
            acquire(WAKELOCK_TIMEOUT)
        }
    }

    private fun releaseWakeLock() {
        wakeLock?.let {
            if (it.isHeld) {
                it.release()
            }
        }
        wakeLock = null
    }
} 