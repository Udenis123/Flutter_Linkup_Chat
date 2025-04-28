import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/Controller/GroupController.dart';
import 'package:chat_app/GroupChat/GroupChat.dart';
import 'package:chat_app/Pages/HomePage/Widget/ChatTile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroupPage extends StatelessWidget {
  const GroupPage({super.key});

  @override
  Widget build(BuildContext context) {
    GroupController groupController = Get.put(GroupController());
    return Obx(
      () => ListView(
        children:
            groupController.groupList
                .map(
                  (group) => InkWell(
                    onTap: () {
                      Get.to(GroupChatPage(groupModel: group));
                    },
                    child: ChatTile(
                      lastChat: "Last message",
                      lastTime: "last time",
                      imageUrl:
                          group.profileUrl == ""
                              ? AssetsImage.defaultImage
                              : group.profileUrl!,
                      name: group.name!,
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}
