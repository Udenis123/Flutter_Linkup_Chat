import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StatusController extends GetxController with WidgetsBindingObserver {
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> setOnline() async {
    await db.collection("users").doc(auth.currentUser!.uid).update({
      "status": "Online",
    });
  }

  Future<void> setOffline() async {
    await db.collection("users").doc(auth.currentUser!.uid).update({
      "status": "Offline",
      "lastOnlineStatus": DateTime.now().toString(),
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    print("❤️❤️❤️ Application state changed: $state");
    switch (state) {
      case AppLifecycleState.inactive:
        await setOffline();
        break;
      case AppLifecycleState.paused:
        await setOffline();
        break;
      case AppLifecycleState.resumed:
        await setOnline();
        break;
      case AppLifecycleState.detached:
        await setOffline();
        break;
      case AppLifecycleState.hidden:
        await setOffline();
        break;
    }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
