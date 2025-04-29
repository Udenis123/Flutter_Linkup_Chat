import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/Controller/GroupController.dart';
import 'package:chat_app/GroupChat/GroupChat.dart';
import 'package:chat_app/Model/GroupsModel.dart';
import 'package:chat_app/Pages/HomePage/Widget/ChatTile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class GroupPage extends StatelessWidget {
  const GroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    GroupController groupController = Get.put(GroupController());
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return StreamBuilder<List<GroupModel>>(
      stream: groupController.groupListStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text("No groups found"));
        }
       

        return ListView(
          children:
              snapshot.data!.map((group) {
                String formattedTime = "00:00";
                if (group.lastMessageTime != null) {
                  try {
                    final timestamp = DateTime.parse(group.lastMessageTime!);
                    formattedTime = DateFormat('hh:mm a').format(timestamp);
                  } catch (_) {
                    formattedTime = group.lastMessageTime!;
                  }
                }
                return InkWell(
                  onTap: () {
                    Get.to(GroupChatPage(groupModel: group));
                  },
                  child: ChatTile(
                    userId: group.id!,
                    lastChat: group.lastmessage ?? "No message yet",
                    lastTime: formattedTime,
                    imageUrl:
                        group.profileUrl == ""
                            ? AssetsImage.defaultImage
                            : group.profileUrl!,
                    name: group.name!,
                  ),
                );
              }).toList(),
        );
      },
    );
  }
}
