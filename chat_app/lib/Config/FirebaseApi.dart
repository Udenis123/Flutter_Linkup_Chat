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
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

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

  static Future<void> _showNotification(RemoteMessage message) async {
    final senderImage = message.data['sender_image'];
    final senderName = message.data['sender_name'] ?? 'Someone';
    final notificationTitle = message.notification?.title ?? senderName;
    String notificationBody =
        message.notification?.body ?? 'You have a new message!';

    // Only append call type for call notifications, not chat
    if (message.data['call_type'] != null && message.data['type'] != 'chat') {
      final callType = message.data['call_type'] ?? 'voice';
      final callTypeText = callType == 'video' ? 'Video Call' : 'Voice Call';
      notificationBody = '{$notificationBody} ($callTypeText)';
    }

    AndroidNotificationDetails androidDetails;

    if (message.data['type'] == 'missed_call') {
      // Use sender image as small icon, missed call icon as big image
      String? missedCallIconPath;
      try {
        final directory = await getTemporaryDirectory();
        missedCallIconPath = '${directory.path}/missed_call.png';
        final byteData = await rootBundle.load('assets/missed_call.png');
        final file = File(missedCallIconPath);
        await file.writeAsBytes(byteData.buffer.asUint8List());
      } catch (e) {
        missedCallIconPath = null;
      }

      String? senderImagePath;
      if (senderImage != null && senderImage.isNotEmpty) {
        try {
          final directory = await getTemporaryDirectory();
          senderImagePath = '${directory.path}/sender_image.png';
          final response = await http.get(Uri.parse(senderImage));
          final file = File(senderImagePath);
          await file.writeAsBytes(response.bodyBytes);
        } catch (e) {
          senderImagePath = null;
        }
      }

      androidDetails = AndroidNotificationDetails(
        'call_channel',
        'Call Notifications',
        channelDescription: 'Channel for call notifications',
        styleInformation:
            missedCallIconPath != null
                ? BigPictureStyleInformation(
                  FilePathAndroidBitmap(missedCallIconPath),
                  contentTitle: notificationTitle,
                  summaryText: notificationBody,
                )
                : null,
        largeIcon:
            senderImagePath != null
                ? FilePathAndroidBitmap(senderImagePath)
                : DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        importance: Importance.max,
        priority: Priority.high,
      );
    } else if (senderImage != null && senderImage.isNotEmpty) {
      // Only show sender image as small icon, no big image
      try {
        final directory = await getTemporaryDirectory();
        final filePath = '${directory.path}/sender_image.png';
        final response = await http.get(Uri.parse(senderImage));
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        androidDetails = AndroidNotificationDetails(
          'message_channel',
          'Messages',
          channelDescription: 'Channel for chat messages',
          largeIcon: FilePathAndroidBitmap(filePath),
          importance: Importance.max,
          priority: Priority.high,
        );
      } catch (e) {
        // Fallback to app icon if image download fails
        androidDetails = AndroidNotificationDetails(
          'message_channel',
          'Messages',
          channelDescription: 'Channel for chat messages',
          color: Colors.black,
          largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          importance: Importance.max,
          priority: Priority.high,
        );
      }
    } else {
      // Use app icon and black background
      androidDetails = AndroidNotificationDetails(
        'message_channel',
        'Messages',
        channelDescription: 'Channel for chat messages',
        color: Colors.black,
        largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
        importance: Importance.max,
        priority: Priority.high,
      );
    }

    final notificationDetails = NotificationDetails(android: androidDetails);

    // Determine payload for notification tap
    String payload = '';
    if (message.data['type'] == 'missed_call') {
      payload = 'missed_call';
    } else if (message.data['type'] == 'chat' &&
        message.data['room_id'] != null &&
        message.data['sender_id'] != null) {
      payload = jsonEncode({
        'type': 'chat',
        'room_id': message.data['room_id'],
        'sender_id': message.data['sender_id'],
      });
    } else if (message.data['call_id'] != null &&
        message.data['call_id'].toString().isNotEmpty) {
      payload = message.data['call_id'];
    }

    await _localNotifications.show(
      0,
      notificationTitle,
      notificationBody,
      notificationDetails,
      payload: payload,
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
        // If call doesn't exist, navigate to call logs tab
        Get.offAllNamed('/homePage', arguments: {'tabIndex': 2});
      }
    } catch (e) {
      print('Error navigating to call screen: $e');
      // On error, navigate to call logs tab
      Get.offAllNamed('/homePage', arguments: {'tabIndex': 2});
    }
  }

  static Future<void> navigateToChatPage(String roomId, String senderId) async {
    print('Navigating to chat page: roomId=$roomId, senderId=$senderId');
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(senderId)
              .get();
      if (userDoc.exists) {
        final user = UserModel.fromJson(userDoc.data()!);
        print('User found, navigating to ChatPage for user: ${user.name}');

        // If app is in foreground, use Get.to
        // If app is in background/killed, use Get.offAll to ensure proper navigation stack
        if (Get.currentRoute == '/homePage' || Get.currentRoute == '/') {
          Get.offAll(() => ChatPage(userModel: user));
        } else {
          Get.to(() => ChatPage(userModel: user));
        }
      } else {
        print('User not found for senderId: $senderId');
        Get.snackbar('Error', 'Could not open chat - user not found');
        Get.offAllNamed('/homePage');
      }
    } catch (e) {
      print('Error navigating to chat page: $e');
      Get.snackbar('Error', 'Could not open chat');
      Get.offAllNamed('/homePage');
    }
  }

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Print FCM token for debugging
    final token = await _firebaseMessaging.getToken();
    print('❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️FCM Token: ' + (token ?? 'null'));

    // Local notifications setup
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (
        NotificationResponse notificationResponse,
      ) async {
        print(
          '🔥🔥🔥 onDidReceiveNotificationResponse: payload = ${notificationResponse.payload}',
        );

        if (notificationResponse.payload != null) {
          try {
            if (notificationResponse.payload == 'missed_call') {
              // For missed calls, always navigate to call logs tab
              Get.offAllNamed('/homePage', arguments: {'tabIndex': 2});
              return;
            }

            final data = jsonDecode(notificationResponse.payload!);
            if (data['type'] == 'chat' &&
                data['room_id'] != null &&
                data['sender_id'] != null) {
              await navigateToChatPage(data['room_id'], data['sender_id']);
              return;
            }

            // Handle call ID payload (for active calls)
            final uuidRegex = RegExp(r'^[0-9a-fA-F-]{36}$');
            if (uuidRegex.hasMatch(notificationResponse.payload!)) {
              await navigateToCallScreen(notificationResponse.payload!);
            }
          } catch (e) {
            print('Error handling notification tap: $e');
            // Default to home page on error
            Get.offAllNamed('/homePage');
          }
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // FCM background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request notification permissions
    await _firebaseMessaging.requestPermission();

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotification(message);
    });

    // Handle notification tap when app is in background/terminated
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      print('😍😍😍😍😍❤️❤️❤️❤️❤️❤️❤️❤️Notification tapped: ${message.data}');

      if (message.data['type'] == 'chat' &&
          message.data['room_id'] != null &&
          message.data['sender_id'] != null) {
        await navigateToChatPage(
          message.data['room_id'],
          message.data['sender_id'],
        );
      } else if (message.data['type'] == 'missed_call') {
        Get.offAllNamed('/homePage', arguments: {'tabIndex': 2});
      } else if (message.data['call_id'] != null &&
          message.data['type'] != 'missed_call') {
        await navigateToCallScreen(message.data['call_id']);
      }
    });
  }

  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}
