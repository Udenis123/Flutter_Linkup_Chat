import 'dart:async';
import 'package:chat_app/Model/AudioCallModel.dart';
import 'package:chat_app/Model/UserModel.dart';
import 'package:chat_app/Pages/CallPage/AudioCallPage.dart';
import 'package:chat_app/Pages/CallPage/IncomingCallPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:chat_app/Config/FirebaseApi.dart';
import 'package:chat_app/Pages/CallPage/IncomingCallScreen.dart';
import 'package:chat_app/Pages/CallPage/OutgoingCallScreen.dart';
import 'package:chat_app/Pages/CallPage/OutgoingCallPage.dart';
import 'package:chat_app/Pages/CallPage/VideoCallPage.dart';

class CallController extends GetxController with WidgetsBindingObserver {
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final uuid = Uuid().v4();

  Rx<AudioCallModel?> currentCall = Rx<AudioCallModel?>(null);
  RxString callStatus = ''.obs; // 'calling', 'ringing', 'accepted', 'ended'
  RxBool isCaller = false.obs;
  bool _isInitialized = false;
  StreamSubscription<DocumentSnapshot>? _callSubscription;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    initializeZegoServices();
    listenForIncomingCalls();
    initializeCallHandling();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _callSubscription?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    switch (state) {
      case AppLifecycleState.resumed:
        if (!_isInitialized) {
          initializeZegoServices();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Handle other lifecycle states if needed
        break;
    }
  }

  // Start a call (caller)
  Future<void> startCall(
    UserModel receiver,
    UserModel caller, {
    String callType = "voice",
  }) async {
    String callId = uuid;
    final now = DateTime.now();
    var newCall = AudioCallModel(
      id: callId,
      callerName: caller.name,
      callerPic: caller.profileImage,
      callerUid: caller.id,
      callerEmail: caller.email,
      receiverName: receiver.name,
      receiverPic: receiver.profileImage,
      receiverUid: receiver.id,
      receiverEmail: receiver.email,
      status: "calling",
      callType: callType,
      participants: [caller.id!, receiver.id!],
      timestamp: now,
    );
    isCaller.value = true;
    currentCall.value = newCall;
    callStatus.value = 'calling';

    // Write to shared calls collection (for signaling/notifications)
    final callData = newCall.toJson();
    callData['accepted'] = false; // Add accepted field to the data
    await db.collection("calls").doc(callId).set(callData);

    // Write to both users' callLogs subcollections (for user-specific logs)
    await db
        .collection('users')
        .doc(caller.id)
        .collection('callLogs')
        .doc(callId)
        .set(callData);
    await db
        .collection('users')
        .doc(receiver.id)
        .collection('callLogs')
        .doc(callId)
        .set(callData);

    // Navigate to OutgoingCallPage for caller
    Get.to(() => OutgoingCallPage(receiver: receiver, callType: callType));

    // Listen to call status changes
    listenToCallStatus(callId);
  }

  // Listen for incoming calls (receiver)
  void listenForIncomingCalls() {
    if (auth.currentUser?.uid == null) {
      print(
        'CallController: Not authenticated, skipping listenForIncomingCalls',
      );
      return;
    }

    db
        .collection("calls")
        .where('receiverUid', isEqualTo: auth.currentUser?.uid)
        .where('status', isEqualTo: 'calling')
        .snapshots()
        .listen((snapshot) async {
          if (snapshot.docs.isNotEmpty) {
            var call = AudioCallModel.fromJson(snapshot.docs.first.data());
            currentCall.value = call;
            callStatus.value = 'ringing';
            isCaller.value = false;

            // Create caller UserModel
            final caller = UserModel(
              id: call.callerUid,
              name: call.callerName,
              email: call.callerEmail,
              profileImage: call.callerPic,
            );

            // Show incoming call UI
            if (Get.currentRoute != '/incomingCall') {
              Get.to(
                () => IncomingCallPage(callData: snapshot.docs.first.data()),
                routeName: '/incomingCall',
              );
            }

            // Listen for call end
            db.collection("calls").doc(call.id).snapshots().listen((doc) {
              if (!doc.exists || doc.data()?['status'] == 'ended') {
                callStatus.value = '';
                currentCall.value = null;
                if (Get.currentRoute == '/incomingCall') {
                  Get.back();
                }
              } else if (doc.data()?['status'] == 'accepted') {
                // Navigate to appropriate call page based on call type
                final target =
                    isCaller.value
                        ? UserModel(
                          id: call.receiverUid,
                          name: call.receiverName,
                          email: call.receiverEmail,
                          profileImage: call.receiverPic,
                        )
                        : UserModel(
                          id: call.callerUid,
                          name: call.callerName,
                          email: call.callerEmail,
                          profileImage: call.callerPic,
                        );

                if (call.callType == 'video') {
                  Get.off(() => VideoCallPage(target: target));
                } else {
                  Get.off(() => AudioCallPage(target: target));
                }
              }
            });
          }
        });
  }

  // Accept call (receiver)
  Future<void> acceptCall() async {
    if (currentCall.value == null) return;

    try {
      final now = DateTime.now();
      final updateData = {
        'status': 'accepted',
        'accepted': true,
        'acceptedAt': now.toIso8601String(),
        'timestamp': now.toIso8601String(),
      };

      // Update main call document
      await db
          .collection("calls")
          .doc(currentCall.value!.id)
          .update(updateData);

      // Update call logs for both users
      await db
          .collection('users')
          .doc(currentCall.value!.callerUid)
          .collection('callLogs')
          .doc(currentCall.value!.id)
          .update(updateData);
      await db
          .collection('users')
          .doc(currentCall.value!.receiverUid)
          .collection('callLogs')
          .doc(currentCall.value!.id)
          .update(updateData);

      callStatus.value = 'accepted';
    } catch (e) {
      print("Error accepting call: $e");
      Get.snackbar(
        'Error',
        'Failed to accept call. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Decline call (receiver)
  Future<void> declineCall() async {
    if (currentCall.value == null) return;

    try {
      final now = DateTime.now();
      final updateData = {
        'status': 'ended',
        'accepted': false,
        'endedAt': now.toIso8601String(),
        'endReason': 'declined',
        'timestamp': now.toIso8601String(),
      };

      // Update main call document
      await db
          .collection("calls")
          .doc(currentCall.value!.id)
          .update(updateData);

      // Update call logs for both users
      await db
          .collection('users')
          .doc(currentCall.value!.callerUid)
          .collection('callLogs')
          .doc(currentCall.value!.id)
          .update(updateData);
      await db
          .collection('users')
          .doc(currentCall.value!.receiverUid)
          .collection('callLogs')
          .doc(currentCall.value!.id)
          .update(updateData);

      callStatus.value = 'ended';
      await FlutterRingtonePlayer().stop();
      currentCall.value = null;

      // Navigate back to home page
      Get.offAllNamed('/homePage', arguments: {'tabIndex': 2});
    } catch (e) {
      print("Error declining call: $e");
    }
  }

  // End call (either side)
  Future<void> endCall() async {
    if (currentCall.value == null) return;

    try {
      final now = DateTime.now();
      final updateData = {
        'status': 'ended',
        'endedAt': now.toIso8601String(),
        'endReason': isCaller.value ? 'ended_by_caller' : 'ended_by_receiver',
        'accepted':
            false, // Explicitly set accepted to false if call wasn't accepted
        'timestamp': now.toIso8601String(),
      };

      // Update main call document
      await db
          .collection("calls")
          .doc(currentCall.value!.id)
          .update(updateData);

      // Update call logs for both users
      await db
          .collection('users')
          .doc(currentCall.value!.callerUid)
          .collection('callLogs')
          .doc(currentCall.value!.id)
          .update(updateData);
      await db
          .collection('users')
          .doc(currentCall.value!.receiverUid)
          .collection('callLogs')
          .doc(currentCall.value!.id)
          .update(updateData);

      callStatus.value = 'ended';
      await FlutterRingtonePlayer().stop();
      currentCall.value = null;

      // Navigate to HomePage
      Get.offAllNamed('/homePage', arguments: {'tabIndex': 2});
    } catch (e) {
      print("Error ending call: $e");
    }
  }

  // Listen to call status changes (for both caller and receiver)
  void listenToCallStatus(String callId) {
    db.collection("calls").doc(callId).snapshots().listen((doc) {
      if (!doc.exists) return;
      var call = AudioCallModel.fromJson(doc.data()!);
      currentCall.value = call;
      callStatus.value = call.status ?? '';

      if (call.status == 'accepted') {
        // Navigate to appropriate call page
        final target =
            isCaller.value
                ? UserModel(
                  id: call.receiverUid,
                  name: call.receiverName,
                  email: call.receiverEmail,
                  profileImage: call.receiverPic,
                )
                : UserModel(
                  id: call.callerUid,
                  name: call.callerName,
                  email: call.callerEmail,
                  profileImage: call.callerPic,
                );

        if (call.callType == 'video') {
          Get.off(() => VideoCallPage(target: target));
        } else {
          Get.off(() => AudioCallPage(target: target));
        }
      } else if (call.status == 'ended') {
        currentCall.value = null;
        // Ensure both users exit call and return to HomePage
        Get.offAllNamed('/homePage', arguments: {'tabIndex': 2});
      }
    });
  }

  // Initialize Zego services
  Future<void> initializeZegoServices() async {
    if (_isInitialized) return;

    try {
      // Ensure we're in a valid lifecycle state before initializing
      await Future.delayed(Duration(milliseconds: 100));

      // Initialize your Zego services here
      // Add any necessary Zego initialization code

      _isInitialized = true;
    } catch (e) {
      print("Error initializing Zego services: $e");
      _isInitialized = false;
    }
  }

  Future<void> handleIncomingCall(
    String callId,
    String callerName,
    String callerPic,
    String callType,
  ) async {
    try {
      // Check if the call is still active
      final callDoc =
          await FirebaseFirestore.instance
              .collection('calls')
              .doc(callId)
              .get();

      if (!callDoc.exists || callDoc.data()?['status'] != 'calling') {
        return;
      }

      // Start playing ringtone
      await FlutterRingtonePlayer().play(
        android: AndroidSounds.ringtone,
        ios: IosSounds.glass,
        looping: true,
        volume: 1.0,
        asAlarm: true,
      );

      // Show the incoming call screen
      Get.to(
        () => IncomingCallScreen(
          callId: callId,
          callerName: callerName,
          callerPic: callerPic,
          callType: callType,
        ),
      );

      // Listen for call status changes
      _callSubscription = FirebaseFirestore.instance
          .collection('calls')
          .doc(callId)
          .snapshots()
          .listen((snapshot) async {
            if (!snapshot.exists || snapshot.data()?['status'] == 'ended') {
              // Stop ringtone and close incoming call screen
              await FlutterRingtonePlayer().stop();
              Get.back();
              _callSubscription?.cancel();
            }
          });
    } catch (e) {
      print('Error handling incoming call: $e');
    }
  }

  Future<void> initializeCallHandling() async {
    // Handle incoming call when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.data['type'] == 'call') {
        await handleIncomingCall(
          message.data['call_id'],
          message.data['caller_name'],
          message.data['caller_pic'],
          message.data['call_type'],
        );
      }
    });

    // Handle notification click when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
      if (message.data['type'] == 'call') {
        await handleIncomingCall(
          message.data['call_id'],
          message.data['caller_name'],
          message.data['caller_pic'],
          message.data['call_type'],
        );
      }
    });

    // Handle initial notification when app is terminated
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage?.data['type'] == 'call') {
      await handleIncomingCall(
        initialMessage!.data['call_id'],
        initialMessage.data['caller_name'],
        initialMessage.data['caller_pic'],
        initialMessage.data['call_type'],
      );
    }
  }

  // Call this method when making an outgoing call
  Future<void> makeCall(
    String receiverId,
    String receiverName,
    String receiverPic,
    String callType,
  ) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final callId = const Uuid().v4();
      final callData = {
        'call_id': callId,
        'caller_id': currentUser.uid,
        'caller_name': currentUser.displayName ?? 'Unknown',
        'caller_pic': currentUser.photoURL ?? '',
        'receiver_id': receiverId,
        'receiver_name': receiverName,
        'receiver_pic': receiverPic,
        'call_type': callType,
        'status': 'calling',
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Save call data to Firestore
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(callId)
          .set(callData);

      // Get receiver's FCM token and send notification
      final receiverToken = await FirebaseApi.getDeviceToken(receiverId);
      if (receiverToken != null) {
        await FirebaseApi.sendPushNotification(
          token: receiverToken,
          title: 'Incoming ${callType.capitalizeFirst ?? 'Voice'} Call',
          body: '${currentUser.displayName ?? 'Someone'} is calling...',
          data: {
            'type': 'call',
            'call_id': callId,
            'caller_name': currentUser.displayName ?? 'Unknown',
            'caller_pic': currentUser.photoURL ?? '',
            'call_type': callType,
          },
        );
      }

      // Navigate to outgoing call screen
      Get.to(
        () => OutgoingCallScreen(
          callId: callId,
          receiverName: receiverName,
          receiverPic: receiverPic,
          callType: callType,
        ),
      );

      // Listen for call status changes
      _callSubscription?.cancel(); // Cancel any existing subscription
      _callSubscription = FirebaseFirestore.instance
          .collection('calls')
          .doc(callId)
          .snapshots()
          .listen((snapshot) {
            if (!snapshot.exists || snapshot.data()?['status'] == 'ended') {
              Get.back();
              _callSubscription?.cancel();
            } else if (snapshot.data()?['status'] == 'accepted') {
              // Initialize call when accepted
              _initializeCall(callId, currentUser.uid);
            }
          });
    } catch (e) {
      print('Error making call: $e');
    }
  }

  Future<void> _initializeCall(String callId, String userId) async {
    try {
      // Initialize your call service here (e.g., Zego, Agora, etc.)
      // This is a placeholder - replace with your actual call initialization code
      print('Initializing call: $callId for user: $userId');

      // Example:
      // await zegoEngine.startPreview();
      // await zegoEngine.joinRoom(callId);
    } catch (e) {
      print('Error initializing call: $e');
    }
  }
}
