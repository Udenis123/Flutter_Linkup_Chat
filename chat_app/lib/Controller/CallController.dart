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

class CallController extends GetxController {
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final uuid = Uuid().v4();

  Rx<AudioCallModel?> currentCall = Rx<AudioCallModel?>(null);
  RxString callStatus = ''.obs; // 'calling', 'ringing', 'accepted', 'ended'
  RxBool isCaller = false.obs;

  @override
  void onInit() {
    super.onInit();
    listenForIncomingCalls();
  }

  // Start a call (caller)
  Future<void> startCall(
    UserModel receiver,
    UserModel caller, {
    String callType = "voice",
  }) async {
    String callId = uuid;
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
      timestamp: DateTime.now(),
    );
    isCaller.value = true;
    currentCall.value = newCall;
    callStatus.value = 'calling';
    // Write to shared calls collection (for signaling/notifications)
    await db.collection("calls").doc(callId).set(newCall.toJson());
    // Write to both users' callLogs subcollections (for user-specific logs)
    await db
        .collection('users')
        .doc(caller.id)
        .collection('callLogs')
        .doc(callId)
        .set(newCall.toJson());
    await db
        .collection('users')
        .doc(receiver.id)
        .collection('callLogs')
        .doc(callId)
        .set(newCall.toJson());
    listenToCallStatus(callId);
  }

  // Listen for incoming calls (receiver)
  void listenForIncomingCalls() {
    print('listenForIncomingCalls called');
    if (auth.currentUser?.uid == null) {
      print(
        'CallController: Not authenticated, skipping listenForIncomingCalls',
      );
      return;
    }
    print('Listening for calls for uid: \\${auth.currentUser?.uid}');
    db
        .collection("calls")
        .where('receiverUid', isEqualTo: auth.currentUser?.uid)
        .where('status', isEqualTo: 'calling')
        .snapshots()
        .listen((snapshot) {
          print(
            'Firestore snapshot received. docs.length = \\${snapshot.docs.length}',
          );
          if (snapshot.docs.isNotEmpty) {
            print('Incoming call detected!');
            var call = AudioCallModel.fromJson(snapshot.docs.first.data());
            currentCall.value = call;
            callStatus.value = 'ringing';
            isCaller.value = false;
            print('Playing ringtone...');
            FlutterRingtonePlayer().playRingtone();
            // Show full-screen incoming call page if not already on it
            if (Get.currentRoute != '/incomingCall') {
              print('Navigating to IncomingCallPage');
              Get.to(
                () => IncomingCallPage(callData: snapshot.docs.first.data()),
                routeName: '/incomingCall',
              );
            }
            // Listen for call end (caller hangs up before accept)
            db.collection("calls").doc(call.id).snapshots().listen((doc) {
              print(
                'Call doc snapshot: exists=\\${doc.exists}, status=\\${doc.data()?['status']}',
              );
              if (!doc.exists || (doc.data()?['status'] == 'ended')) {
                print(
                  'Call ended or doc deleted. Stopping ringtone and closing page.',
                );
                FlutterRingtonePlayer().stop();
                callStatus.value = '';
                currentCall.value = null;
                // Close IncomingCallPage if open
                if (Get.currentRoute == '/incomingCall') {
                  Get.back();
                }
              }
            });
          } else {
            print('No incoming call. Stopping ringtone and resetting UI.');
            // No incoming call, ensure UI is reset
            FlutterRingtonePlayer().stop();
            callStatus.value = '';
            currentCall.value = null;
          }
        });
  }

  // Accept call (receiver)
  Future<void> acceptCall() async {
    if (currentCall.value == null) return;
    await db.collection("calls").doc(currentCall.value!.id).update({
      'status': 'accepted',
    });
    callStatus.value = 'accepted';
    FlutterRingtonePlayer().stop();
    // Both users will join the room when status is 'accepted'
  }

  // Decline call (receiver)
  Future<void> declineCall() async {
    if (currentCall.value == null) return;
    await db.collection("calls").doc(currentCall.value!.id).update({
      'status': 'ended',
    });
    callStatus.value = 'ended';
    FlutterRingtonePlayer().stop();
    currentCall.value = null;
  }

  // End call (either side)
  Future<void> endCall() async {
    if (currentCall.value == null) return;
    await db.collection("calls").doc(currentCall.value!.id).update({
      'status': 'ended',
    });
    callStatus.value = 'ended';
    FlutterRingtonePlayer().stop();
    currentCall.value = null;
  }

  // Listen to call status changes (for both caller and receiver)
  void listenToCallStatus(String callId) {
    db.collection("calls").doc(callId).snapshots().listen((doc) {
      if (!doc.exists) return;
      var call = AudioCallModel.fromJson(doc.data()!);
      currentCall.value = call;
      callStatus.value = call.status ?? '';
      if (call.status == 'accepted') {
        FlutterRingtonePlayer().stop();
        // Both users join the Zego room (handled in UI)
      } else if (call.status == 'ended') {
        FlutterRingtonePlayer().stop();
        currentCall.value = null;
        // Both users return to chat (handled in UI)
      }
    });
  }
}
