import 'package:chat_app/Config/Strings.dart';
import 'package:chat_app/Controller/ChatController.dart';
import 'package:chat_app/Controller/ProfileController.dart';
import 'package:chat_app/Model/UserModel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:chat_app/Controller/CallController.dart';

class VideoCallPage extends StatelessWidget {
  final UserModel target;
  const VideoCallPage({super.key, required this.target});

  @override
  Widget build(BuildContext context) {
    ProfileController profileController = Get.put(ProfileController());
    ChatController chatController = Get.put(ChatController());
    var callId = chatController.getRoomId(target.id!);
    CallController callController = Get.find<CallController>();
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
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: FloatingActionButton(
              backgroundColor: Colors.red,
              child: Icon(Icons.call_end, color: Colors.white),
              onPressed: () async {
                await callController.endCall();
              },
            ),
          ),
        ),
      ],
    );
  }
}
