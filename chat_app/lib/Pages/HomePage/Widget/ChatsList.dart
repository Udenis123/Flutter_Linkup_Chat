import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/Pages/HomePage/Widget/ChatTile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatsList extends StatelessWidget {
  const ChatsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListView(
        children: [
          InkWell(
            onTap: () {
              Get.toNamed('/chatPage');
            },
            child: ChatTile(
              imageUrl: AssetsImage.girlPic,
              name: "Denis Uwihirwe",
              lastChat: "how are doing bro?",
              lastTime: "08:43 PM",
            ),
          ),
          ChatTile(
            imageUrl: AssetsImage.boyPic,
            name: "Ntwari Rogers",
            lastChat: "Hello, how are you?",
            lastTime: "8:44 PM",
          ),
          ChatTile(
            imageUrl: AssetsImage.girlPic,
            name: "Denis Uwihirwe",
            lastChat: "how are doing bro?",
            lastTime: "08:43 PM",
          ),
        ],
      ),
    );
  }
}
