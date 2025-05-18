import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/Controller/GroupController.dart';
import 'package:chat_app/GroupChat/GroupChat.dart';
import 'package:chat_app/Groups/NewGroup/NewGroup.dart';
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

    // Ensure the groups are loaded when the page is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      groupController.getGroups();
    });

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Get.to(() => NewGroup());
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Icon(Icons.group_add, color: Colors.white),
      ),
      body: StreamBuilder<List<GroupModel>>(
        stream: groupController.groupListStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print("Error loading groups: ${snapshot.error}");
            return Center(child: Text("Error loading groups"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("No groups found"),
                  SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => groupController.getGroups(),
                    icon: Icon(Icons.refresh),
                    label: Text("Refresh"),
                  ),
                ],
              ),
            );
          }

          final groups = snapshot.data!;
          print("Found ${groups.length} groups for user $userId");

          return ListView(
            children:
                groups.map((group) {
                  String formattedTime = "00:00";
                  if (group.lastMessageTime != null) {
                    try {
                      final timestamp = DateTime.parse(group.lastMessageTime!);
                      formattedTime = DateFormat('hh:mm a').format(timestamp);
                    } catch (_) {
                      formattedTime = group.lastMessageTime!;
                    }
                  }

                  // Check if this group has the current user as a member
                  final isMember =
                      group.members?.any((m) => m.id == userId) ?? false;
                  if (!isMember) {
                    print("User $userId is not a member of group ${group.id}");
                    return SizedBox.shrink(); // Skip this group
                  }

                  // Determine if the current user should see an unread count
                  // Only show unread count if the current user is not the last sender
                  int displayUnreadCount = 0;
                  if (group.lastSenderId != userId && group.memberUnreadStatus != null) {
                    // Check if current user has unread messages
                    if (group.memberUnreadStatus!.containsKey(userId)) {
                      displayUnreadCount = 1; // Show indicator that there are unread messages
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
                      unreadCount: displayUnreadCount,
                    ),
                  );
                }).toList(),
          );
        },
      ),
    );
  }
}
