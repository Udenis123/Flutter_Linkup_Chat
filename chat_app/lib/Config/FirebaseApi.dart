import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app/Pages/CallPage/AudioCallPage.dart';
import 'package:chat_app/Pages/CallPage/VideoCallPage.dart';
import 'package:chat_app/Model/UserModel.dart';
import 'package:chat_app/Controller/ProfileController.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:chat_app/Pages/CallPage/IncomingCallPage.dart';
import 'package:chat_app/Pages/Chat/ChatPage.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Optionally handle background notification tap
}

class FirebaseApi {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _showNotification(message);
  }

  static void _showNotification(RemoteMessage message) async {
    final callType = message.data['call_type'] ?? 'voice';
    final callTypeText = callType == 'video' ? 'Video Call' : 'Voice Call';
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'call_channel',
          'Call Notifications',
          channelDescription: 'Channel for incoming call notifications',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
          fullScreenIntent: true,
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _localNotifications.show(
      0,
      message.notification?.title ?? 'Incoming Call',
      '${message.notification?.body ?? 'You have an incoming call'} ($callTypeText)',
      platformChannelSpecifics,
      payload: message.data['call_id'] ?? 'call',
    );
  }

  static Future<void> navigateToCallScreen(String callId) async {
    try {
      final callDoc =
          await FirebaseFirestore.instance
              .collection('calls')
              .doc(callId)
              .get();
      if (callDoc.exists) {
        final callData = callDoc.data()!;
        Get.to(() => IncomingCallPage(callData: callData));
      } else {
        Get.snackbar(
          'Call Not Found',
          'The call has already ended or does not exist.',
        );
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to open call: $e');
    }
  }

  static Future<void> navigateToChatPage(String roomId, String senderId) async {
    print('Navigating to chat page: roomId=$roomId, senderId=$senderId');
    // Fetch user info for ChatPage
    final userDoc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(senderId)
            .get();
    if (userDoc.exists) {
      final user = UserModel.fromJson(userDoc.data()!);
      print('User found, navigating to ChatPage for user: \\${user.name}');
      Get.to(() => ChatPage(userModel: user));
    } else {
      print('User not found for senderId: $senderId');
      Get.snackbar('User Not Found', 'Could not open chat.');
    }
  }

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Print FCM token for debugging
    final token = await _firebaseMessaging.getToken();
    print('❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️FCM Token: ' + (token ?? 'null'));
    // Local notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (
        NotificationResponse notificationResponse,
      ) async {
        final payload = notificationResponse.payload;
        if (payload != null && payload != 'call') {
          await navigateToCallScreen(payload);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );
    // FCM background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    // Request notification permissions
    await _firebaseMessaging.requestPermission();
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });
    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print('Notification tapped: \\${message.data}');
      if (message.data['type'] == 'chat' &&
          message.data['room_id'] != null &&
          message.data['sender_id'] != null) {
        await navigateToChatPage(
          message.data['room_id'],
          message.data['sender_id'],
        );
      } else if (message.data['call_id'] != null) {
        await navigateToCallScreen(message.data['call_id']);
      }
    });
  }

  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
