import 'dart:io';

import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/Controller/ChatController.dart';
import 'package:chat_app/Controller/ContactController.dart';
import 'package:chat_app/Controller/ProfileController.dart';
import 'package:chat_app/Model/ChatModel.dart';
import 'package:chat_app/Model/UserModel.dart';
import 'package:chat_app/Pages/Chat/Widget/ChatBubble.dart';
import 'package:chat_app/Pages/Chat/Widget/TypeMessage.dart';
import 'package:chat_app/UserProfile/ProfilePage.dart';
import 'package:chat_app/Widget/VideoPreviewWidget.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/instance_manager.dart';
import 'package:get/route_manager.dart';
import 'package:get/utils.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatPage extends StatelessWidget {
  final UserModel userModel;
  const ChatPage({super.key, required this.userModel});

  @override
  Widget build(BuildContext context) {
    ChatController chatController = Get.put(ChatController());
    ProfileController profileController = Get.put(ProfileController());

    return Scaffold(
      appBar: AppBar(
        leading: InkWell(
          onTap: () {
            Get.to(UserProfilepage(userModel: userModel));
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
                  imageUrl: userModel.profileImage ?? AssetsImage.defaultImage,
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
            Get.to(UserProfilepage(userModel: userModel));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                userModel.name ?? "User Name",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              StreamBuilder<UserModel>(
                stream: chatController.getStatus(userModel.id!),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text("Loading...");
                  }
                  if (snapshot.hasError) {
                    return Text(
                      "No connection",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    );
                  }
                  if (!snapshot.hasData || snapshot.data == null) {
                    return Text("Offline");
                  }
                  final status = snapshot.data!.status ?? "Offline";
                  if (status == "is typing...") {
                    return Text(
                      "is typing...",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  } else if (status == "Online") {
                    return Text(
                      "Online",
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    );
                  } else {
                    // Parse lastOnlineStatus
                    String? lastOnlineStr = snapshot.data!.lastOnlineStatus;
                    if (lastOnlineStr == null) {
                      return Text(
                        "Offline",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      );
                    }
                    DateTime lastOnline;
                    try {
                      lastOnline = DateTime.parse(lastOnlineStr);
                    } catch (e) {
                      return Text(
                        "Offline",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      );
                    }
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final lastOnlineDay = DateTime(
                      lastOnline.year,
                      lastOnline.month,
                      lastOnline.day,
                    );
                    final difference = today.difference(lastOnlineDay).inDays;

                    String lastSeenText;
                    if (difference == 0) {
                      lastSeenText =
                          "last seen at ${DateFormat('hh:mm a').format(lastOnline)}";
                    } else if (difference == 1) {
                      lastSeenText = "last seen yesterday";
                    } else {
                      lastSeenText =
                          "last seen on ${DateFormat('yyyy-MM-dd').format(lastOnline)}";
                    }
                    return Text(
                      lastSeenText,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    );
                  }
                },
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
                    stream: chatController.getMessages(userModel.id!),
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
                            DateTime timestamp = DateTime.parse(
                              snapshot.data![index].timestamp!,
                            );
                            String formattedTime = DateFormat(
                              'hh:mm a',
                            ).format(timestamp);
                            return Chatbubble(
                              message: snapshot.data![index].message!,
                              imageUrl: snapshot.data![index].imageUrl ?? "",
                              videoUrl: snapshot.data![index].videoUrl ?? "",
                              isComming:
                                  snapshot.data![index].senderId !=
                                  profileController.currentUser.value.id,
                              time: formattedTime,
                              status: "read",
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

            TypeMessage(userModel: userModel),
          ],
        ),
      ),
    );
  }
}
