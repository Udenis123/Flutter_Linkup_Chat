import 'package:chat_app/Controller/ChatController.dart';
import 'package:chat_app/Controller/ImagePicker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';


Future<dynamic> ImagePickerBottomSheet(
  BuildContext context,
  ChatController chatController,
  ImagePickerController imagePickerController,
) {
  return Get.bottomSheet(
    Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      height: 130,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          InkWell(
            onTap: () async {
              chatController.selectedImagePath.value =
                  await imagePickerController.pickImage(ImageSource.camera);
              Get.back();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(64, 0, 0, 0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    FontAwesomeIcons.camera,
                    size: 20,
                    color: Colors.amber,
                  ),
                ),
                SizedBox(height: 8),
                Text("Camera"),
              ],
            ),
          ),
          InkWell(
            onTap: () async {
              chatController.selectedImagePath.value =
                  await imagePickerController.pickImage(ImageSource.gallery);
              print(
                "😂😂😂😂😂😂😂😂❤️❤️" +
                    chatController.selectedImagePath.value!,
              );
               Get.back();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(64, 0, 0, 0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    FontAwesomeIcons.photoFilm,
                    size: 20,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 8),
                Text("Gallery"),
              ],
            ),
          ),
          InkWell(
            onTap: () async {
              chatController.selectedVideoPath.value =
                  await imagePickerController.pickVideo(ImageSource.gallery);
              print(
                "😂😂😂😂😂😂😂😂❤️❤️" +
                    chatController.selectedVideoPath.value!,
              );
              Get.back();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(64, 0, 0, 0),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    FontAwesomeIcons.photoFilm,
                    size: 20,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 8),
                Text("Video"),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
