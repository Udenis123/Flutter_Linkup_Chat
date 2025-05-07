import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/Controller/AuthController.dart';
import 'package:chat_app/Controller/GroupController.dart';
import 'package:chat_app/Controller/ImagePicker.dart';
import 'package:chat_app/Controller/ProfileController.dart';
import 'package:chat_app/Model/GroupsModel.dart';
import 'package:chat_app/Model/UserModel.dart';
import 'package:chat_app/Pages/Chat/ChatPage.dart';
import 'package:chat_app/Pages/GroupInfo/AddMembers.dart';
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

  void _showEditDialog(BuildContext context, GroupModel group, bool isAdmin) {
    final nameController = TextEditingController(text: group.name);
    final descController = TextEditingController(text: group.description);
    final formKey = GlobalKey<FormState>();

    Get.dialog(
      AlertDialog(
        title: Text('Edit Group Info'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Name is required';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Get.find<GroupController>().updateGroupInfo(
                  group.id!,
                  nameController.text,
                  descController.text,
                );
                Get.back();
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateGroupPhoto(String groupId) async {
    final imagePicker = Get.put(ImagePickerController());
    final source = await Get.dialog<ImageSource>(
      AlertDialog(
        title: Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.camera),
              title: Text('Camera'),
              onTap: () => Get.back(result: ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library),
              title: Text('Gallery'),
              onTap: () => Get.back(result: ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source != null) {
      final imagePath = await imagePicker.pickImage(source);
      if (imagePath.isNotEmpty) {
        await Get.find<GroupController>().updateGroupPhoto(groupId, imagePath);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupController = Get.put(GroupController());
    final authController = Get.put(AuthController());
    final currentUserId = authController.auth.currentUser!.uid;
    final theme = Theme.of(context);

    return StreamBuilder<GroupModel>(
      stream: groupController.getGroupStream(groupModel.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: Text("Loading...")),
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData || snapshot.data?.id == null) {
          // User is no longer a member or group doesn't exist
          Get.back(); // Return to previous screen
          return Container(); // Return empty container while navigating
        }

        final updatedGroup = snapshot.data!;
        final currentMember = updatedGroup.members!.firstWhere(
          (member) => member.id == currentUserId,
          orElse: () => UserModel(),
        );

        // If somehow we still have data but user is not a member, go back
        if (currentMember.id == null) {
          Get.back();
          return Container();
        }

        final isAdmin = currentMember.role == "admin";

        return Scaffold(
          appBar: AppBar(
            title: Text(updatedGroup.name ?? "Group Info"),
            actions: [
              if (isAdmin)
                IconButton(
                  onPressed:
                      () => Get.to(() => AddMembers(groupModel: updatedGroup)),
                  icon: Icon(Icons.person_add),
                  tooltip: "Add Members",
                ),
              PopupMenuButton(
                itemBuilder:
                    (context) => [
                      if (isAdmin) ...[
                        PopupMenuItem(
                          child: ListTile(
                            leading: Icon(Icons.edit),
                            title: Text("Edit Group"),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap:
                              () => Future.delayed(
                                Duration(milliseconds: 200),
                                () => _showEditDialog(
                                  context,
                                  updatedGroup,
                                  isAdmin,
                                ),
                              ),
                        ),
                        PopupMenuItem(
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text(
                              "Delete Group",
                              style: TextStyle(color: Colors.red),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: () async {
                            final confirm = await Get.dialog<bool>(
                              AlertDialog(
                                title: Text("Delete Group"),
                                content: Text(
                                  "Are you sure you want to delete this group?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(result: false),
                                    child: Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () => Get.back(result: true),
                                    child: Text(
                                      "Delete",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await groupController.deleteGroup(
                                updatedGroup.id!,
                              );
                              Get.back();
                            }
                          },
                        ),
                      ] else ...[
                        PopupMenuItem(
                          child: ListTile(
                            leading: Icon(Icons.exit_to_app, color: Colors.red),
                            title: Text(
                              "Leave Group",
                              style: TextStyle(color: Colors.red),
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          onTap: () async {
                            final confirm = await Get.dialog<bool>(
                              AlertDialog(
                                title: Text("Leave Group"),
                                content: Text(
                                  "Are you sure you want to leave this group?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Get.back(result: false),
                                    child: Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () => Get.back(result: true),
                                    child: Text(
                                      "Leave",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await groupController.leaveGroup(
                                updatedGroup.id!,
                              );
                              Get.back();
                            }
                          },
                        ),
                      ],
                    ],
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Image and Basic Info
                Center(
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.primary,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundImage: CachedNetworkImageProvider(
                            updatedGroup.profileUrl?.isNotEmpty == true
                                ? updatedGroup.profileUrl!
                                : AssetsImage.defaultImage,
                          ),
                        ),
                      ),
                      if (isAdmin)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.camera_alt,
                                size: 24,
                                color: Colors.white,
                              ),
                              onPressed:
                                  () => _updateGroupPhoto(updatedGroup.id!),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Center(
                  child: Text(
                    updatedGroup.name ?? "Group Name",
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (updatedGroup.description?.isNotEmpty == true) ...[
                  SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      updatedGroup.description!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withOpacity(
                          0.8,
                        ),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                SizedBox(height: 24),
                Text(
                  "Members (${updatedGroup.members?.length ?? 0})",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: updatedGroup.members?.length ?? 0,
                  itemBuilder: (context, index) {
                    final member = updatedGroup.members![index];
                    final isMemberAdmin = member.role == "admin";
                    final isCurrentUser = member.id == currentUserId;

                    return Card(
                      elevation: 0,
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(
                            member.profileImage?.isNotEmpty == true
                                ? member.profileImage!
                                : AssetsImage.defaultImage,
                          ),
                        ),
                        title: Text(
                          "${member.name ?? 'Unknown'}${isCurrentUser ? ' (You)' : ''}",
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          isMemberAdmin ? "Admin" : "Member",
                          style: TextStyle(
                            color:
                                isMemberAdmin
                                    ? theme.colorScheme.primary
                                    : null,
                          ),
                        ),
                        trailing:
                            isAdmin && !isCurrentUser
                                ? PopupMenuButton(
                                  icon: Icon(Icons.more_vert),
                                  itemBuilder:
                                      (context) => [
                                        if (!isMemberAdmin)
                                          PopupMenuItem(
                                            child: ListTile(
                                              leading: Icon(
                                                Icons.admin_panel_settings,
                                              ),
                                              title: Text("Make Admin"),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            onTap: () async {
                                              await groupController.makeAdmin(
                                                updatedGroup.id!,
                                                member,
                                              );
                                            },
                                          ),
                                        if (isMemberAdmin)
                                          PopupMenuItem(
                                            child: ListTile(
                                              leading: Icon(Icons.person),
                                              title: Text("Remove Admin"),
                                              contentPadding: EdgeInsets.zero,
                                            ),
                                            onTap: () async {
                                              await groupController.removeAdmin(
                                                updatedGroup.id!,
                                                member,
                                              );
                                            },
                                          ),
                                        PopupMenuItem(
                                          child: ListTile(
                                            leading: Icon(
                                              Icons.remove_circle,
                                              color: Colors.red,
                                            ),
                                            title: Text(
                                              "Remove",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                          onTap: () async {
                                            final confirm = await Get.dialog<
                                              bool
                                            >(
                                              AlertDialog(
                                                title: Text("Remove Member"),
                                                content: Text(
                                                  "Are you sure you want to remove ${member.name} from the group?",
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed:
                                                        () => Get.back(
                                                          result: false,
                                                        ),
                                                    child: Text("Cancel"),
                                                  ),
                                                  TextButton(
                                                    onPressed:
                                                        () => Get.back(
                                                          result: true,
                                                        ),
                                                    child: Text(
                                                      "Remove",
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await groupController
                                                  .removeMemberFromGroup(
                                                    updatedGroup.id!,
                                                    member,
                                                  );
                                            }
                                          },
                                        ),
                                      ],
                                )
                                : null,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
