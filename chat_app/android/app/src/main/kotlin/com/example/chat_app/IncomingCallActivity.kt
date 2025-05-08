package com.example.chat_app

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import android.os.Build
import android.view.View
import android.app.KeyguardManager
import android.provider.Settings
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.NotificationChannel
import androidx.core.app.NotificationCompat

class IncomingCallActivity : FlutterActivity() {
    private val NOTIFICATION_ID = 1001
    private val CHANNEL_ID = "incoming_call_channel"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        try {
            // Try to show as overlay first
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
                setShowWhenLocked(true)
                setTurnScreenOn(true)
                val keyguardManager = getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager
                keyguardManager.requestDismissKeyguard(this, null)
            }

            window.addFlags(
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
            )

            // Try to set window type based on permissions
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                if (Settings.canDrawOverlays(this)) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        window.attributes.type = WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                    } else {
                        window.attributes.type = WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
                    }
                } else {
                    // If no overlay permission, show high-priority notification instead
                    showIncomingCallNotification()
                }
            }

            // Set additional window flags
            window.addFlags(
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or
                WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
            )

            // Make sure we're shown at full screen
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN)

        } catch (e: Exception) {
            // If we can't show as overlay, show notification
            showIncomingCallNotification()
        }
    }

    private fun showIncomingCallNotification() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Create notification channel for Android O and above
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
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

        // Create pending intent for notification
        val intent = Intent(this, IncomingCallActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtras(getIntent().extras ?: Bundle())
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Build and show notification
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(intent.getStringExtra("caller_name") ?: "Incoming Call")
            .setContentText("${intent.getStringExtra("call_type")?.capitalize() ?: "Voice"} Call")
            .setSmallIcon(android.R.drawable.ic_notification_overlay)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setFullScreenIntent(pendingIntent, true)
            .setAutoCancel(true)
            .build()

        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    companion object {
        fun start(context: Context, callId: String, callerName: String, callerPic: String, callType: String) {
            val intent = Intent(context, IncomingCallActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                        Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
                putExtra("call_id", callId)
                putExtra("caller_name", callerName)
                putExtra("caller_pic", callerPic)
                putExtra("call_type", callType)
            }
            context.startActivity(intent)
        }
    }
} 