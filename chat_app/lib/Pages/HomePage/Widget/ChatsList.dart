import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/Controller/ContactController.dart';
import 'package:chat_app/Controller/ProfileController.dart';
import 'package:chat_app/Pages/Chat/ChatPage.dart';
import 'package:chat_app/Pages/HomePage/Widget/ChatTile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatsList extends StatelessWidget {
  const ChatsList({super.key});

  @override
  Widget build(BuildContext context) {
    ContactController contactController = Get.put(ContactController());
    ProfileController profileController = Get.put(ProfileController());
    return Obx(
      () => ListView(
        children:
            contactController.chatRoomList
                .map(
                  (e) => InkWell(
                    onTap: () {
                      Get.to(
                        ChatPage(
                          userModel:
                              (e.receiver!.id ==
                                      profileController.currentUser.value.id
                                  ? e.sender
                                  : e.receiver)!,
                        ),
                      );
                    },
                    child: ChatTile(
                      imageUrl:
                          (e.receiver!.id ==
                                  profileController.currentUser.value.id
                              ? e.sender!.profileImage
                              : e.receiver!.profileImage) ??
                          AssetsImage.defaultImage,
                      name:
                          (e.receiver!.id ==
                                  profileController.currentUser.value.id
                              ? e.sender!.name
                              : e.receiver!.name)!,
                      lastChat: e.lastMessage ?? "Last Message",
                      lastTime: e.lastMessageTimestamp ?? "Last time",
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}
