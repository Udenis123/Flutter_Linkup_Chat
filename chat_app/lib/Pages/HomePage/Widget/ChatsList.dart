import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/Controller/ContactController.dart';
import 'package:chat_app/Pages/Chat/ChatPage.dart';
import 'package:chat_app/Pages/HomePage/Widget/ChatTile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatsList extends StatelessWidget {
  const ChatsList({super.key});

  @override
  Widget build(BuildContext context) {
    ContactController contactController = Get.put(ContactController());

    final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder(
      stream: contactController.chatRoomStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No chats yet"));
        }
        return ListView(
          children:
              snapshot.data!.map((e) {
                // Determine if the current user is the receiver of the last message
                bool isCurrentUserReceiver = e.receiver?.id == currentUserId;

                // Only show unread count if current user is the receiver
                int unreadCount =
                    isCurrentUserReceiver ? (e.unReadMessNo ?? 0) : 0;

                return InkWell(
                  onTap: () {
                    Get.to(
                      ChatPage(
                        userModel:
                            (e.receiver!.id == currentUserId
                                ? e.sender
                                : e.receiver)!,
                      ),
                    );
                  },
                  child: ChatTile(
                    imageUrl:
                        (e.receiver!.id == currentUserId
                            ? e.sender!.profileImage
                            : e.receiver!.profileImage) ??
                        AssetsImage.defaultImage,
                    name:
                        (e.receiver!.id == currentUserId
                            ? e.sender!.name
                            : e.receiver!.name)!,
                    lastChat: e.lastMessage ?? "Last Message",
                    lastTime: e.lastMessageTimestamp ?? "Last time",
                    userId:
                        (e.receiver!.id == currentUserId
                            ? e.sender!.id
                            : e.receiver!.id)!,
                    unreadCount: unreadCount,
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}
