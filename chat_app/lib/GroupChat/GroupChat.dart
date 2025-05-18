import 'dart:io';

import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/Controller/ChatController.dart';
import 'package:chat_app/Controller/GroupController.dart';

import 'package:chat_app/Controller/ProfileController.dart';
import 'package:chat_app/GroupChat/GroupChatBublle.dart';
import 'package:chat_app/GroupChat/GroupSystemMessage.dart';
import 'package:chat_app/GroupChat/GroupTypeMessage.dart';

import 'package:chat_app/Model/GroupsModel.dart';
import 'package:chat_app/Model/UserModel.dart';
import 'package:chat_app/Pages/Chat/Widget/ChatBubble.dart';
import 'package:chat_app/Pages/GroupInfo/GroupInfo.dart';

import 'package:chat_app/Widget/VideoPreviewWidget.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/instance_manager.dart';
import 'package:get/route_manager.dart';
import 'package:get/utils.dart';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

class GroupChatPage extends StatelessWidget {
  final GroupModel groupModel;
  const GroupChatPage({super.key, required this.groupModel});

  bool isSystemMessage(String message) {
    final systemMessages = [
      'joined the group',
      'left the group',
      'Group created',
      'added',
      'removed',
      'is now an admin',
      'is no longer an admin',
      'Group info updated',
      'Group photo updated',
    ];
    return systemMessages.any((sys) => message.contains(sys));
  }

  @override
  Widget build(BuildContext context) {
    ChatController chatController = Get.put(ChatController());
    GroupController groupController = Get.put(GroupController());
    ProfileController profileController = Get.put(ProfileController());

    // Reset unread count when the chat is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      groupController.resetGroupUnreadCount(groupModel.id!);
    });

    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Get.to(GroupInfo(groupModel: groupModel));
            groupController.getGroups();
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 5, left: 10, bottom: 5),
            child: Container(
              width: 50, // Adjust size
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1,
                ), // Ring border
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl:
                      groupModel.profileUrl == ""
                          ? AssetsImage.defaultImage
                          : groupModel.profileUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                ),
              ),
            ),
          ),
        ),
        title: InkWell(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onTap: () {
            Get.to(GroupInfo(groupModel: groupModel));
            groupController.getGroups();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                groupModel.name ?? "Group Name",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                "${groupModel.members?.length ?? 0} members",
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ),
        ),
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.phone))],
      ),

      body: Padding(
        padding: const EdgeInsets.only(
          bottom: 10,
          top: 10,
          left: 15,
          right: 15,
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  StreamBuilder(
                    stream: groupController.getGroupMessage(groupModel.id!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }
                      if (snapshot.data == null || snapshot.data!.isEmpty) {
                        return Center(child: Text("No messages yet"));
                      } else {
                        return ListView.builder(
                          reverse: true,
                          itemCount: snapshot.data!.length,
                          itemBuilder: (context, index) {
                            final message = snapshot.data![index];
                            DateTime timestamp = DateTime.parse(
                              message.timestamp!,
                            );
                            String formattedTime = DateFormat(
                              'hh:mm a',
                            ).format(timestamp);

                            // Check if this is a system message
                            if (isSystemMessage(message.message ?? "")) {
                              return GroupSystemMessage(
                                message: message.message ?? "",
                                time: formattedTime,
                              );
                            }

                            // Find sender in group members
                            final sender = groupModel.members!.firstWhere(
                              (member) => member.id == message.senderId,
                              orElse:
                                  () => UserModel(
                                    name: "Unknown",
                                    email: "",
                                    profileImage: "",
                                  ),
                            );

                            return GroupChatbubble(
                              message: message.message ?? "",
                              imageUrl: message.imageUrl ?? "",
                              videoUrl: message.videoUrl ?? "",
                              isComming:
                                  message.senderId !=
                                  profileController.currentUser.value.id,
                              time: formattedTime,
                              status: "read",
                              senderName: sender.name ?? "Unknown",
                              senderEmail: sender.email ?? "",
                              senderProfileImage: sender.profileImage ?? "",
                            );
                          },
                        );
                      }
                    },
                  ),
                  Obx(
                    () =>
                        (chatController.selectedImagePath.value != "" ||
                                chatController.selectedVideoPath.value != "")
                            ? Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    height: 300,
                                    child:
                                        chatController
                                                    .selectedImagePath
                                                    .value !=
                                                ""
                                            ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(15),
                                              child: Image.file(
                                                File(
                                                  chatController
                                                      .selectedImagePath
                                                      .value,
                                                ),
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                            : VideoPreviewWidget(
                                              videoPathOrUrl:
                                                  chatController
                                                      .selectedVideoPath
                                                      .value,
                                            ),
                                  ),
                                  Positioned(
                                    left: 0,
                                    child: IconButton(
                                      onPressed: () {
                                        chatController.selectedImagePath.value =
                                            "";
                                        chatController.selectedVideoPath.value =
                                            "";
                                      },
                                      icon: Icon(
                                        Icons.close,
                                        color: Colors.redAccent,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            : Container(),
                  ),
                ],
              ),
            ),

            GroupTypeMessage(groupModel: groupModel),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<GroupModel>('groupModel', groupModel));
  }
}
