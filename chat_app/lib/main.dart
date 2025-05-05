import 'package:chat_app/Config/PagePath.dart';
import 'package:chat_app/Config/Themes.dart';
import 'package:chat_app/Pages/SplacePage/SplacePage.dart';
import 'package:chat_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/route_manager.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:chat_app/Config/FirebaseApi.dart';
import 'package:chat_app/Controller/CallController.dart';
import 'package:get/get.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message (show notification, etc.)
  _showNotification(message);
}

void _showNotification(RemoteMessage message) async {
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
  await flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title ?? 'Incoming Call',
    message.notification?.body ?? 'You have an incoming call',
    platformChannelSpecifics,
    payload: 'call',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseApi.initialize();
  Get.put(CallController(), permanent: true);
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    print('Initial notification: \\${initialMessage.data}');
    if (initialMessage.data['type'] == 'chat' &&
        initialMessage.data['room_id'] != null &&
        initialMessage.data['sender_id'] != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        print('Navigating to chat page from killed state');
        await FirebaseApi.navigateToChatPage(
          initialMessage.data['room_id'],
          initialMessage.data['sender_id'],
        );
      });
    } else if (initialMessage.data['call_id'] != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        print('Navigating to call page from killed state');
        await FirebaseApi.navigateToCallScreen(initialMessage.data['call_id']);
      });
    }
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      builder: FToastBuilder(),
      title: 'LinkUp',
      theme: lightTheme,
      getPages: pagePath,
      darkTheme: darkTheme,
      themeMode: ThemeMode.dark,
      home: SplacePage(),
    );
  }
}
