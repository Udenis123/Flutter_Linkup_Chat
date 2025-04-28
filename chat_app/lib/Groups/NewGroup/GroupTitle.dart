import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Config/CustomMessage.dart';
import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/Controller/GroupController.dart';
import 'package:chat_app/Controller/ImagePicker.dart';
import 'package:chat_app/Pages/HomePage/Widget/ChatTile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

class GroupTitle extends StatelessWidget {
  const GroupTitle({super.key});

  @override
  Widget build(BuildContext context) {
    GroupController groupController = Get.put(GroupController());
    RxBool isEditing = false.obs;
    ImagePickerController imagePickerController = Get.put(
      ImagePickerController(),
    );

    RxString imagepath = "".obs;
    RxString groupName = "".obs;

    return Scaffold(
      appBar: AppBar(title: Text("New Group")),
      floatingActionButton: Obx(
        () => FloatingActionButton(
          backgroundColor:
              groupName.value == ""
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.primary,
          onPressed: () {
            if (groupName.isEmpty) {
              errorMessage("Please enter Group name");
            } else {
              groupController.createGroup(groupName.value, imagepath.value);
            }
          },
          child:
              groupController.isLoading.value
                  ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 4,
                  )
                  : Icon(
                    Icons.done,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
        ),
      ),

      body: Column(
        children: [
          SizedBox(height: 10),
          InkWell(
            onTap: () async {
              imagepath.value = await imagePickerController.pickImage(
                ImageSource.gallery,
              );
            },
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Obx(
                          () => Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child:
                                imagepath.value == ""
                                    ? Icon(Icons.group, size: 40)
                                    : ClipRRect(
                                      borderRadius: BorderRadius.circular(100),
                                      child: Image.file(
                                        fit: BoxFit.cover,
                                        File(imagepath.value),
                                      ),
                                    ),
                          ),
                        ),

                        SizedBox(height: 20),
                        TextFormField(
                          onChanged: (value) {
                            groupName.value = value;
                          },
                          decoration: InputDecoration(
                            hintText: "Group Name",
                            prefixIcon: Icon(Icons.group),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: Column(
              children:
                  groupController.groupMembers
                      .map(
                        (e) => ChatTile(
                          lastChat: e.about ?? "",
                          lastTime: "",
                          imageUrl: e.profileImage ?? AssetsImage.defaultImage,
                          name: e.name!,
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
