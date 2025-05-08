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
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse notificationResponse) {
  // Optionally handle background notification tap
}

class FirebaseApi {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static const String _serverKey = 'YOUR_FCM_SERVER_KEY';

  static Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message,
  ) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // For incoming calls, show high-priority notification
    if (message.data['type'] == 'call' && message.data['call_id'] != null) {
      try {
        final callDoc =
            await FirebaseFirestore.instance
                .collection('calls')
                .doc(message.data['call_id'])
                .get();

        if (callDoc.exists && callDoc.data()?['status'] == 'calling') {
          // Use the platform channel to launch the native incoming call UI
          const platform = MethodChannel('app_channel');
          try {
            await platform.invokeMethod('launchIncomingCall', {
              'call_id': message.data['call_id'],
              'caller_name': message.data['caller_name'],
              'caller_pic': message.data['caller_pic'],
              'call_type': message.data['call_type'],
            });
          } catch (e) {
            print('Error launching incoming call UI: $e');
          }
          return;
        }
      } catch (e) {
        print('Error handling background call: $e');
      }
    }

    // For other notifications
    _showNotification(message);
  }

  static Future<void> _showNotification(RemoteMessage message) async {
    // Handle incoming call by launching native activity
    if (message.data['type'] == 'call' && message.data['call_id'] != null) {
      try {
        final callDoc =
            await FirebaseFirestore.instance
                .collection('calls')
                .doc(message.data['call_id'])
                .get();

        if (callDoc.exists && callDoc.data()?['status'] == 'calling') {
          const platform = MethodChannel('app_channel');
          try {
            await platform.invokeMethod('launchIncomingCall', {
              'call_id': message.data['call_id'],
              'caller_name': message.data['caller_name'] ?? 'Unknown',
              'caller_pic': message.data['caller_pic'] ?? '',
              'call_type': message.data['call_type'] ?? 'voice',
            });
          } catch (e) {
            print('Error launching incoming call UI: $e');
          }
          return;
        }
      } catch (e) {
        print('Error showing incoming call UI: $e');
      }
    }

    final senderImage = message.data['sender_image'];
    final senderName = message.data['sender_name'] ?? 'Someone';
    final notificationTitle = message.notification?.title ?? senderName;
    String notificationBody =
        message.notification?.body ?? 'You have a new message!';

    // Handle incoming call notifications differently
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

  static Future<String> _getPackageName() async {
    try {
      const platform = MethodChannel('app_channel');
      final packageName = await platform.invokeMethod('getPackageName');
      return packageName.toString();
    } catch (e) {
      print('Error getting package name: $e');
      return 'com.example.chat_app'; // Fallback package name
    }
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

    // Request all necessary permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
      criticalAlert: true,
      announcement: true,
      carPlay: true,
    );

    // Set foreground notification presentation options
    await _firebaseMessaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Create high-priority call notification channel
    final AndroidNotificationChannel callChannel = AndroidNotificationChannel(
      'call_channel',
      'Call Notifications',
      description: 'Channel for incoming call notifications',
      importance: Importance.max,
      enableLights: true,
      enableVibration: true,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('ringtone'),
      showBadge: true,
    );

    // Create the notification channels
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(callChannel);

    // Local notifications setup with full-screen intent permission
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
            final data = jsonDecode(notificationResponse.payload!);

            if (data['type'] == 'call') {
              // Handle incoming call notification tap
              final callDoc =
                  await FirebaseFirestore.instance
                      .collection('calls')
                      .doc(data['call_id'])
                      .get();

              if (callDoc.exists) {
                final callData = callDoc.data()!;
                if (callData['status'] != 'ended') {
                  Get.to(() => IncomingCallPage(callData: callData));
                } else {
                  // Call ended, go to call logs
                  Get.offAllNamed('/homePage', arguments: {'tabIndex': 2});
                }
              }
            } else if (data['type'] == 'chat') {
              // Handle chat notification tap
              await navigateToChatPage(data['room_id'], data['sender_id']);
            }
          } catch (e) {
            print('Error handling notification tap: $e');
            Get.offAllNamed('/homePage');
          }
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Print FCM token for debugging
    final token = await _firebaseMessaging.getToken();
    print('❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️❤️FCM Token: ' + (token ?? 'null'));

    // FCM background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

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

  static Future<String?> getDeviceToken(String userId) async {
    try {
      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      return userDoc.data()?['fcmToken'] as String?;
    } catch (e) {
      print('Error getting device token: $e');
      return null;
    }
  }

  static Future<void> sendPushNotification({
    required String token,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'ringtone.mp3',
            'android_channel_id': 'call_channel',
          },
          'data': data,
          'priority': 'high',
          'content_available': true,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to send FCM notification');
      }
    } catch (e) {
      print('Error sending push notification: $e');
    }
  }
}
