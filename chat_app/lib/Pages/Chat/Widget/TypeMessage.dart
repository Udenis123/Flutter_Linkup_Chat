import 'package:chat_app/Controller/ChatController.dart';
import 'package:chat_app/Controller/ImagePicker.dart';
import 'package:chat_app/Model/UserModel.dart';
import 'package:chat_app/Widget/ImagepickerBottomSheet.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'dart:async';

class TypeMessage extends StatefulWidget {
  final UserModel userModel;
  const TypeMessage({super.key, required this.userModel});

  @override
  State<TypeMessage> createState() => _TypeMessageState();
}

class _TypeMessageState extends State<TypeMessage> {
  final TextEditingController messageController = TextEditingController();
  final ChatController chatController = Get.put(ChatController());
  final ImagePickerController imagePickerController = Get.put(
    ImagePickerController(),
  );
  final RxString message = "".obs;
  Timer? _typingTimer;

  void _onChanged(String value) {
    message.value = value;
    _typingTimer?.cancel();
    if (value.isNotEmpty) {
      chatController.setTypingStatus(true);
      _typingTimer = Timer(const Duration(seconds: 2), () {
        chatController.setTypingStatus(false);
      });
    } else {
      chatController.setTypingStatus(false);
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    chatController.setTypingStatus(false);
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: _onChanged,
              controller: messageController,
              style: TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: false,
                hintText: "Type a message",
                border: InputBorder.none,
              ),
            ),
          ),
          Obx(
            () =>
                chatController.selectedImagePath.value == "" ||
                        chatController.selectedVideoPath.value == ""
                    ? InkWell(
                      onTap: () {
                        ImagePickerBottomSheet(
                          context,
                          chatController,
                          imagePickerController,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Icon(
                          FontAwesomeIcons.paperclip,
                          color: Colors.white,
                          size: 15,
                        ),
                      ),
                    )
                    : SizedBox(),
          ),
          Obx(
            () => Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon:
                      chatController.isLoading.value
                          ? CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          )
                          : Icon(
                            message.value != "" ||
                                    chatController.selectedImagePath.value !=
                                        "" ||
                                    chatController.selectedVideoPath.value != ""
                                ? Icons.send
                                : Icons.mic,
                            color: Colors.white,
                            size: 20,
                          ),
                  onPressed: () {
                    if (message.value != "" ||
                        chatController.selectedImagePath.value != "" ||
                        chatController.selectedVideoPath.value != "") {
                      chatController.sendMessage(
                        widget.userModel.id!,
                        messageController.text,
                        widget.userModel,
                      );
                      chatController.setTypingStatus(false);
                      messageController.clear();
                      message.value = "";
                      _typingTimer?.cancel();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
