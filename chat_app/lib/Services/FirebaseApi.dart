import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class FirebaseApi {
  static final _firebaseMessaging = FirebaseMessaging.instance;
  static const String _serverKey =
      'YOUR_FCM_SERVER_KEY'; // Replace with your FCM server key

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

  static Future<void> updateDeviceToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      if (token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser?.uid)
            .update({'fcmToken': token});
      }
    } catch (e) {
      print('Error updating device token: $e');
    }
  }
}
 