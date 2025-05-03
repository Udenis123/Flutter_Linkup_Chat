import 'package:chat_app/Model/AudioCallModel.dart';
import 'package:chat_app/Model/UserModel.dart';
import 'package:chat_app/Pages/CallPage/AudioCallPage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';
class CallController extends GetxController {
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  final uuid = Uuid().v4();

  void onInit() {
    super.onInit();

    getCallsNotification().listen((List<AudioCallModel> callList) {
      if (callList.isNotEmpty) {
        var callData = callList[0];
        Get.snackbar(
          duration: Duration(days: 1),
          barBlur: 0,
          backgroundColor: Colors.grey[900]!,
          isDismissible: false,
          icon: Icon(Icons.call),
          onTap: (snack) {
            Get.back();
            Get.to(
              AudioCallPage(
                target: UserModel(
                  id: callData.callerUid,
                  name: callData.callerName,
                  email: callData.callerEmail,
                  profileImage: callData.callerPic,
                ),
              ),
            );
          },
          callData.callerName!,
          "Incoming Call",
          mainButton: TextButton(
            onPressed: () {
              endCall(callData);
              Get.back();
            },
            child: Text("End Call"),
          ),
        );
      }
    });
  }

  Future<void> callAction(UserModel reciver, UserModel caller) async {
    String id = uuid;
    var newCall = AudioCallModel(
      id: id,
      callerName: caller.name,
      callerPic: caller.profileImage,
      callerUid: caller.id,
      callerEmail: caller.email,
      receiverName: reciver.name,
      receiverPic: reciver.profileImage,
      receiverUid: reciver.id,
      receiverEmail: reciver.email,
      status: "dialing",
    );

    try {
      await db
          .collection("notification")
          .doc(reciver.id)
          .collection("call")
          .doc(id)
          .set(newCall.toJson());
      await db
          .collection("users")
          .doc(auth.currentUser!.uid)
          .collection("calls")
          .doc(id)
          .set(newCall.toJson());
      await db
          .collection("users")
          .doc(reciver.id)
          .collection("calls")
          .doc(id)
          .set(newCall.toJson());
      Future.delayed(Duration(seconds: 20), () {
        endCall(newCall);
      });
    } catch (e) {
      print(e);
    }
  }

  Stream<List<AudioCallModel>> getCallsNotification() {
    return FirebaseFirestore.instance
        .collection("notification")
        .doc(auth.currentUser!.uid)
        .collection("call")
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AudioCallModel.fromJson(doc.data()))
            .toList());
  }

  Future<void> endCall(AudioCallModel call) async {
    try {
      await db
          .collection("notification")
          .doc(call.receiverUid)
          .collection("call")
          .doc(call.id)
          .delete();
    } catch (e) {
      print(e);
    }
  }


}