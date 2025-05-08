import 'dart:async';
import 'package:chat_app/Config/Strings.dart';
import 'package:chat_app/Controller/ChatController.dart';
import 'package:chat_app/Controller/ProfileController.dart';
import 'package:chat_app/Model/UserModel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:chat_app/Controller/CallController.dart';

class VideoCallPage extends StatefulWidget {
  final UserModel target;
  const VideoCallPage({super.key, required this.target});

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  late CallController callController;
  StreamSubscription? _callSubscription;

  @override
  void initState() {
    super.initState();
    callController = Get.find<CallController>();
    _setupCallListener();
  }

  @override
  void dispose() {
    _callSubscription?.cancel();
    super.dispose();
  }

  void _setupCallListener() {
    if (callController.currentCall.value?.id != null) {
      _callSubscription = callController.db
          .collection("calls")
          .doc(callController.currentCall.value!.id)
          .snapshots()
          .listen((doc) {
            if (!doc.exists || doc.data()?['status'] == 'ended') {
              Get.offAllNamed('/homePage', arguments: {'tabIndex': 2});
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    ProfileController profileController = Get.put(ProfileController());
    ChatController chatController = Get.put(ChatController());
    var callId =
        callController.currentCall.value?.id ??
        chatController.getRoomId(widget.target.id!);

    return Stack(
      children: [
        ZegoUIKitPrebuiltCall(
          appID: ZegoCloudConfig.appId,
          appSign: ZegoCloudConfig.appSign,
          userID: profileController.currentUser.value.id ?? "root",
          userName: profileController.currentUser.value.name ?? "root",
          callID: callId,
          config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall(),
        ),
        Positioned(
          top: 40,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            backgroundColor: Colors.red,
            child: Icon(Icons.call_end, color: Colors.white),
            onPressed: () async {
              await callController.endCall();
            },
          ),
        ),
      ],
    );
  }
}
