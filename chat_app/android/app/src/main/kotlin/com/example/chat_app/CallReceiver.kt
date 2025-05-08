package com.example.chat_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.app.KeyguardManager
import android.app.PendingIntent
import android.app.NotificationManager
import android.app.NotificationChannel
import androidx.core.app.NotificationCompat
import android.os.PowerManager

class CallReceiver : BroadcastReceiver() {
    companion object {
        const val ACTION_INCOMING_CALL = "com.example.chat_app.INCOMING_CALL"
        const val NOTIFICATION_CHANNEL_ID = "incoming_calls"
        const val NOTIFICATION_ID = 1001
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_INCOMING_CALL) {
            val callId = intent.getStringExtra("call_id")
            val callerName = intent.getStringExtra("caller_name")
            val callerPic = intent.getStringExtra("caller_pic")
            val callType = intent.getStringExtra("call_type")

            // Wake up the device
            val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
            val wakeLock = powerManager.newWakeLock(
                PowerManager.FULL_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP or
                PowerManager.ON_AFTER_RELEASE,
                "chat_app:WakeLock"
            )
            wakeLock.acquire(10*60*1000L) // 10 minutes max

            // Create intent for the incoming call activity
            val activityIntent = Intent(context, IncomingCallActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra("call_id", callId)
                putExtra("caller_name", callerName)
                putExtra("caller_pic", callerPic)
                putExtra("call_type", callType)
            }

            // Start the service first to ensure we stay alive
            val serviceIntent = Intent(context, CallService::class.java).apply {
                putExtra("call_id", callId)
                putExtra("caller_name", callerName)
                putExtra("caller_pic", callerPic)
                putExtra("call_type", callType)
            }

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(serviceIntent)
            } else {
                context.startService(serviceIntent)
            }

            // Try to show the incoming call screen
            try {
                context.startActivity(activityIntent)
            } catch (e: Exception) {
                // If we can't start the activity, show a high-priority notification
                showIncomingCallNotification(context, callId, callerName, callerPic, callType)
            }

            // Release the wake lock
            wakeLock.release()
        }
    }

    private fun showIncomingCallNotification(
        context: Context,
        callId: String?,
        callerName: String?,
        callerPic: String?,
        callType: String?
    ) {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        // Create notification channel for Android O and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Incoming Calls",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Shows incoming call notifications"
                enableLights(true)
                enableVibration(true)
                setShowBadge(true)
            }
            notificationManager.createNotificationChannel(channel)
        }

        // Create full screen intent
        val fullScreenIntent = Intent(context, IncomingCallActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("call_id", callId)
            putExtra("caller_name", callerName)
            putExtra("caller_pic", callerPic)
            putExtra("call_type", callType)
        }

        val fullScreenPendingIntent = PendingIntent.getActivity(
            context,
            0,
            fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Build and show notification
        val notification = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
            .setContentTitle(callerName ?: "Incoming Call")
            .setContentText("${callType?.capitalize() ?: "Voice"} Call")
            .setSmallIcon(android.R.drawable.ic_notification_overlay)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setFullScreenIntent(fullScreenPendingIntent, true)
            .setAutoCancel(true)
            .setOngoing(true)
            .build()

        notificationManager.notify(NOTIFICATION_ID, notification)
    }
} 