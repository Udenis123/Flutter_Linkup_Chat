package com.example.chat_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.app.Activity
import android.content.Context
import android.app.AppOpsManager
import android.os.Process
import android.content.ComponentName
import android.app.role.RoleManager
import android.telecom.TelecomManager

class MainActivity: FlutterActivity() {
    private val CHANNEL = "app_channel"
    private val OVERLAY_PERMISSION_REQ_CODE = 1234
    private val ROLE_CALL_SCREENING = 1235

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "requestOverlayPermission" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            // First try the standard overlay permission
                            if (!Settings.canDrawOverlays(this)) {
                                // Try multiple approaches
                                when {
                                    Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q -> {
                                        // For Android 10+, try to request role
                                        val roleManager = getSystemService(Context.ROLE_SERVICE) as RoleManager
                                        if (roleManager.isRoleAvailable(RoleManager.ROLE_CALL_SCREENING)) {
                                            startActivityForResult(
                                                roleManager.createRequestRoleIntent(RoleManager.ROLE_CALL_SCREENING),
                                                ROLE_CALL_SCREENING
                                            )
                                        } else {
                                            // Fallback to direct settings
                                            openOverlaySettings()
                                        }
                                    }
                                    else -> {
                                        // For older versions
                                        openOverlaySettings()
                                    }
                                }
                                result.success(false)
                            } else {
                                result.success(true)
                            }
                        } else {
                            result.success(true)
                        }
                    } catch (e: Exception) {
                        // If standard approach fails, try alternative
                        try {
                            openAppSettings()
                            result.success(false)
                        } catch (e2: Exception) {
                            result.error("PERMISSION_ERROR", e2.message, null)
                        }
                    }
                }
                "launchIncomingCall" -> {
                    try {
                        val callId = call.argument<String>("call_id")
                        val callerName = call.argument<String>("caller_name")
                        val callerPic = call.argument<String>("caller_pic")
                        val callType = call.argument<String>("call_type")

                        // Try multiple approaches to show the incoming call UI
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && !Settings.canDrawOverlays(this)) {
                            // If no overlay permission, try alternative approach
                            val intent = Intent(this, IncomingCallActivity::class.java).apply {
                                flags = Intent.FLAG_ACTIVITY_NEW_TASK or
                                        Intent.FLAG_ACTIVITY_CLEAR_TOP or
                                        Intent.FLAG_ACTIVITY_SINGLE_TOP or
                                        Intent.FLAG_ACTIVITY_EXCLUDE_FROM_RECENTS
                                putExtra("call_id", callId)
                                putExtra("caller_name", callerName)
                                putExtra("caller_pic", callerPic)
                                putExtra("call_type", callType)
                            }
                            startActivity(intent)
                        } else {
                            // With overlay permission, use the service
                            val serviceIntent = Intent(this, CallService::class.java).apply {
                                putExtra("call_id", callId)
                                putExtra("caller_name", callerName)
                                putExtra("caller_pic", callerPic)
                                putExtra("call_type", callType)
                            }

                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                                startForegroundService(serviceIntent)
                            } else {
                                startService(serviceIntent)
                            }
                        }

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getPackageName" -> {
                    result.success(packageName)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun openOverlaySettings() {
        val intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            Uri.parse("package:$packageName")
        )
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivityForResult(intent, OVERLAY_PERMISSION_REQ_CODE)
    }

    private fun openAppSettings() {
        val intent = Intent(
            Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
            Uri.parse("package:$packageName")
        )
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            OVERLAY_PERMISSION_REQ_CODE -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M && Settings.canDrawOverlays(this)) {
                    // Permission granted, retry the last incoming call if any
                    val lastCallIntent = Intent(this, IncomingCallActivity::class.java)
                    if (intent?.extras != null) {
                        lastCallIntent.putExtras(intent.extras!!)
                        startActivity(lastCallIntent)
                    }
                }
            }
            ROLE_CALL_SCREENING -> {
                if (resultCode == Activity.RESULT_OK) {
                    // Role granted, try to show call UI
                    val lastCallIntent = Intent(this, IncomingCallActivity::class.java)
                    if (intent?.extras != null) {
                        lastCallIntent.putExtras(intent.extras!!)
                        startActivity(lastCallIntent)
                    }
                }
            }
        }
    }
}
