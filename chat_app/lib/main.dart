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
import 'package:flutter/services.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Create the call_channel notification channel at startup
const AndroidNotificationChannel callChannel = AndroidNotificationChannel(
  'call_channel', // id
  'Call Notifications', // name
  description: 'Channel for incoming call notifications',
  importance: Importance.max,
  playSound: true,
);

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(callChannel);

  await FirebaseApi.initialize();

  try {
    final callController = Get.put(CallController(), permanent: true);
    await callController.initializeZegoServices();
  } catch (e) {
    print("Error initializing call services: $e");
  }

  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

  runApp(MyApp());
  if (initialMessage != null) {
    print('Initial notification data: ${initialMessage.data}');
    await Future.delayed(Duration(seconds: 2));

    if (initialMessage.data['type'] == 'chat' &&
        initialMessage.data['room_id'] != null &&
        initialMessage.data['sender_id'] != null) {
      print('Navigating to chat from killed state');
      await FirebaseApi.navigateToChatPage(
        initialMessage.data['room_id'],
        initialMessage.data['sender_id'],
      );
    } else if (initialMessage.data['type'] == 'missed_call') {
      print('Navigating to calls tab from killed state');
      Get.offAllNamed('/homePage', arguments: {'tabIndex': 2});
    } else if (initialMessage.data['call_id'] != null &&
        initialMessage.data['type'] != 'missed_call') {
      print('Navigating to call screen from killed state');
      await FirebaseApi.navigateToCallScreen(initialMessage.data['call_id']);
    }
  }
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
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      home: SplacePage(),
    );
  }
}
