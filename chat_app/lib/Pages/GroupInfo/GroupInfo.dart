import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/Controller/AuthController.dart';
import 'package:chat_app/Controller/GroupController.dart';
import 'package:chat_app/Controller/ImagePicker.dart';
import 'package:chat_app/Controller/ProfileController.dart';
import 'package:chat_app/Model/GroupsModel.dart';
import 'package:chat_app/Pages/Chat/ChatPage.dart';
import 'package:chat_app/Pages/GroupInfo/GroupMemberInfo.dart';
import 'package:chat_app/Pages/HomePage/Widget/ChatTile.dart';
import 'package:chat_app/UserProfile/Widget/UserInfo.dart';
import 'package:chat_app/Widget/PrimaryButton.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:image_picker/image_picker.dart';

class GroupInfo extends StatelessWidget {
  final GroupModel groupModel;
  const GroupInfo({super.key, required this.groupModel});

  @override
  Widget build(BuildContext context) {
    final groupController = Get.put(GroupController());

    return StreamBuilder(
      stream:
          groupController.db
              .collection('groups')
              .doc(groupModel.id)
              .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Scaffold(
            appBar: AppBar(title: Text("Group Info")),
            body: Center(child: Text("Group not found or you have exited.")),
          );
        }
        final updatedGroup = GroupModel.fromJson(snapshot.data!.data()!);

        AuthController authController = Get.put(AuthController());

        // Find the current user in the group members list
        final currentUser = updatedGroup.members!.firstWhere(
          (member) => member.id == authController.auth.currentUser!.uid,
          orElse: () => updatedGroup.members!.first,
        );

        return Scaffold(
          appBar: AppBar(
            title: Text(updatedGroup.name!),
            actions: [
              IconButton(
                onPressed: () {},
                icon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.more_vert, size: 25),
                ),
              ),
            ],
          ),

          body: Padding(
            padding: const EdgeInsets.all(10),
            child: ListView(
              children: [
                GroupMemberInfo(
                  profileImage:
                      updatedGroup.profileUrl == ""
                          ? AssetsImage.defaultImage
                          : updatedGroup.profileUrl!,
                  userName: updatedGroup.name!,
                  userEmail: updatedGroup.description ?? "No description",
                  groupId: updatedGroup.id!,
                  role: currentUser.role ?? "member",
                  groupModel: updatedGroup,
                ),
                SizedBox(height: 20),
                Text(
                  "Member of group",
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                SizedBox(height: 5),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children:
                        updatedGroup.members!.where((member) => member.id != currentUser.id).map((
                          member,
                        ) {
                          bool isAdmin = currentUser.role == "admin";
                          bool isSelf = member.id == currentUser.id;
                          bool memberIsAdmin = member.role == "admin";
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                member.profileImage ?? AssetsImage.defaultImage,
                              ),
                            ),
                            title: Text(member.name ?? "User Name"),
                            subtitle: Text(member.email ?? ""),
                            trailing:
                                isSelf
                                    ? null
                                    : isAdmin
                                    ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Promote to admin
                                        if (!memberIsAdmin)
                                          IconButton(
                                            icon: Icon(
                                              Icons.upgrade,
                                              color: Colors.green,
                                            ),
                                            tooltip: "Make Admin",
                                            onPressed: () async {
                                              bool? confirm = await showDialog(
                                                context: context,
                                                builder:
                                                    (context) => AlertDialog(
                                                      title: Text(
                                                        "Promote to Admin",
                                                      ),
                                                      content: Text(
                                                        "Are you sure you want to make ${member.name} an admin?",
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    false,
                                                                  ),
                                                          child: Text("Cancel"),
                                                        ),
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    true,
                                                                  ),
                                                          child: Text(
                                                            "Promote",
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                              );
                                              if (confirm == true) {
                                                final groupController = Get.put(
                                                  GroupController(),
                                                );
                                                final updatedMembers =
                                                    updatedGroup.members!.map((
                                                      m,
                                                    ) {
                                                      if (m.id == member.id) {
                                                        return m
                                                          ..role = "admin";
                                                      }
                                                      return m;
                                                    }).toList();
                                                await groupController.db
                                                    .collection('groups')
                                                    .doc(updatedGroup.id)
                                                    .update({
                                                      "members":
                                                          updatedMembers
                                                              .map(
                                                                (e) =>
                                                                    e.toJson(),
                                                              )
                                                              .toList(),
                                                    });
                                                await groupController
                                                    .sendGroupMessage(
                                                      "${member.name} was promoted to admin by ${currentUser.name}",
                                                      updatedGroup.id!,
                                                      "",
                                                      "",
                                                    );
                                              }
                                            },
                                          ),
                                        // Demote to member
                                        if (memberIsAdmin)
                                          IconButton(
                                            icon: Icon(
                                              Icons.arrow_downward,
                                              color: Colors.orange,
                                            ),
                                            tooltip: "Remove Admin",
                                            onPressed: () async {
                                              bool? confirm = await showDialog(
                                                context: context,
                                                builder:
                                                    (context) => AlertDialog(
                                                      title: Text(
                                                        "Remove Admin",
                                                      ),
                                                      content: Text(
                                                        "Are you sure you want to remove admin rights from ${member.name}?",
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    false,
                                                                  ),
                                                          child: Text("Cancel"),
                                                        ),
                                                        TextButton(
                                                          onPressed:
                                                              () =>
                                                                  Navigator.pop(
                                                                    context,
                                                                    true,
                                                                  ),
                                                          child: Text("Remove"),
                                                        ),
                                                      ],
                                                    ),
                                              );
                                              if (confirm == true) {
                                                final groupController = Get.put(
                                                  GroupController(),
                                                );
                                                final updatedMembers =
                                                    updatedGroup.members!.map((
                                                      m,
                                                    ) {
                                                      if (m.id == member.id) {
                                                        return m
                                                          ..role = "member";
                                                      }
                                                      return m;
                                                    }).toList();
                                                await groupController.db
                                                    .collection('groups')
                                                    .doc(updatedGroup.id)
                                                    .update({
                                                      "members":
                                                          updatedMembers
                                                              .map(
                                                                (e) =>
                                                                    e.toJson(),
                                                              )
                                                              .toList(),
                                                    });
                                                await groupController
                                                    .sendGroupMessage(
                                                      "${member.name} was demoted to member by ${currentUser.name}",
                                                      updatedGroup.id!,
                                                      "",
                                                      "",
                                                    );
                                              }
                                            },
                                          ),
                                        // Remove member (only if not self)
                                        IconButton(
                                          icon: Icon(
                                            Icons.remove_circle,
                                            color: Colors.red,
                                          ),
                                          tooltip: "Remove Member",
                                          onPressed: () async {
                                            bool? confirm = await showDialog(
                                              context: context,
                                              builder:
                                                  (context) => AlertDialog(
                                                    title: Text(
                                                      "Remove Member",
                                                    ),
                                                    content: Text(
                                                      "Are you sure you want to remove ${member.name}?",
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              false,
                                                            ),
                                                        child: Text("Cancel"),
                                                      ),
                                                      TextButton(
                                                        onPressed:
                                                            () => Navigator.pop(
                                                              context,
                                                              true,
                                                            ),
                                                        child: Text("Remove"),
                                                      ),
                                                    ],
                                                  ),
                                            );
                                            if (confirm == true) {
                                              final groupController = Get.put(
                                                GroupController(),
                                              );
                                              await groupController
                                                  .removeMemberFromGroup(
                                                    updatedGroup.id!,
                                                    member,
                                                  );
                                              await groupController
                                                  .sendGroupMessage(
                                                    "${member.name} was removed from the group by ${currentUser.name}",
                                                    updatedGroup.id!,
                                                    "",
                                                    "",
                                                  );
                                            }
                                          },
                                        ),
                                      ],
                                    )
                                    : memberIsAdmin
                                    ? Text(
                                      "Admin",
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                    : null,
                            onTap: () {
                              if (member.id != currentUser.id) {
                                Get.to(() => ChatPage(userModel: member));
                              }
                            },
                          );
                        }).toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
