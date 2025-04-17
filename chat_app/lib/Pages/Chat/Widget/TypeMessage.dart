import 'package:chat_app/Controller/ChatController.dart';
import 'package:chat_app/Controller/ImagePicker.dart';
import 'package:chat_app/Model/UserModel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TypeMessage extends StatelessWidget {
  final UserModel userModel;
  const TypeMessage({super.key, required this.userModel});

  @override
  Widget build(BuildContext context) {
    TextEditingController messageController = TextEditingController();
    ChatController chatController = Get.put(ChatController());
    ImagePickerController imagePickerController = Get.put(
      ImagePickerController(),
    );
    RxString message = "".obs;
    return Container(
      margin: EdgeInsets.all(5),
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.all(Radius.circular(100)),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () {},
            child: Icon(Icons.emoji_emotions, size: 25, color: Colors.green),
          ),
          SizedBox(height: 20),
          Expanded(
            child: TextField(
              onChanged: (value) {
                message.value = value;
              },
              controller: messageController,
              style: TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: false,
                hintText: "Type a message",
              ),
            ),
          ),
          SizedBox(height: 10),
          Obx(
            () =>
                chatController.selectedImagePath.value == ""
                    ? InkWell(
                      onTap: () async {
                        chatController.selectedImagePath.value =
                            await imagePickerController.pickImage();
                      },
                      child: Icon(Icons.image, color: Colors.white),
                    )
                    : SizedBox(),
          ),
          SizedBox(height: 30),
          Obx(
            () =>
                message.value != "" ||
                        chatController.selectedImagePath.value != ""
                    ? InkWell(
                      onTap: () {
                        if (messageController.text.isNotEmpty ||
                            chatController.selectedImagePath.value.isNotEmpty) {
                          chatController.sendMessage(
                            userModel.id!,
                            messageController.text,
                            userModel,
                          );
                          messageController.clear();
                          message.value = "";
                        }
                        // contactController.getChatRoomList();
                      },
                      child: Obx(
                        () =>
                            chatController.isLoading.value
                                ? CircularProgressIndicator()
                                : Icon(
                                  Icons.send,
                                  color: const Color.fromARGB(255, 34, 172, 57),
                                  size: 25,
                                ),
                      ),
                    )
                    : Icon(Icons.mic, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
