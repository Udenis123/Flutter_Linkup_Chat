import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app/Pages/CallPage/AudioCallPage.dart';
import 'package:chat_app/Model/UserModel.dart';
import 'package:chat_app/Controller/ProfileController.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'call_channel',
          'Call Notifications',
          channelDescription: 'Channel for incoming call notifications',
          importance: Importance.max,
          priority: Priority.high,
          ticker: 'ticker',
        );
    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );
    await _localNotifications.show(
      0,
      message.notification?.title ?? 'Incoming Call',
      message.notification?.body ?? 'You have an incoming call',
      platformChannelSpecifics,
      payload: message.data['call_id'] ?? 'call',
    );
  }

  static Future<void> _navigateToCallScreen(String callId) async {
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
          await _navigateToCallScreen(payload);
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
      final callId = message.data['call_id'];
      if (callId != null && callId != 'call') {
        await _navigateToCallScreen(callId);
      }
    });
  }

  static Future<String?> getToken() async {
    return await _firebaseMessaging.getToken();
  }
}

class IncomingCallPage extends StatelessWidget {
  final Map<String, dynamic> callData;
  IncomingCallPage({required this.callData});

  @override
  Widget build(BuildContext context) {
    final callId = callData['id'];
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.call, color: Colors.green, size: 60),
            SizedBox(height: 16),
            Text(
              'Incoming call from \\${callData['callerName']}',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: Icon(Icons.call, color: Colors.white),
                  label: Text('Accept', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection("calls")
                        .doc(callId)
                        .update({'status': 'accepted'});
                    // Navigate to AudioCallPage
                    Get.off(
                      () => AudioCallPage(
                        target: UserModel(
                          id: callData['callerUid'],
                          name: callData['callerName'],
                          email: callData['callerEmail'],
                          profileImage: callData['callerPic'],
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(width: 24),
                ElevatedButton.icon(
                  icon: Icon(Icons.call_end, color: Colors.white),
                  label: Text('Decline', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection("calls")
                        .doc(callId)
                        .update({'status': 'ended'});
                    Get.back();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
