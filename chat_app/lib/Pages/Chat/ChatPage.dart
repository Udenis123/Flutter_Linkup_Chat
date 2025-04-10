import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/Controller/ChatController.dart';
import 'package:chat_app/Controller/ProfileController.dart';
import 'package:chat_app/Model/ChatModel.dart';
import 'package:chat_app/Model/UserModel.dart';
import 'package:chat_app/Pages/Chat/Widget/ChatBubble.dart';
import 'package:flutter/material.dart';
import 'package:get/instance_manager.dart';
import 'package:get/utils.dart';
import 'package:intl/intl.dart';

class ChatPage extends StatelessWidget {
  final UserModel userModel;
  const ChatPage({super.key, required this.userModel});

  @override
  Widget build(BuildContext context) {
    ChatController chatController = Get.put(ChatController());
    TextEditingController messageController = TextEditingController();
    ProfileController profileController = Get.put(ProfileController());
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
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
              child: Image.asset(
                AssetsImage.boyPic,
                width: 35,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userModel.name ?? "User Name",
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text("Online", style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.phone))],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: EdgeInsets.all(10),
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
            Icon(Icons.mic, color: Colors.grey),
            SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: messageController,
                style: TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: false,
                  hintText: "Type a message",
                ),
              ),
            ),
            SizedBox(height: 10),
            Icon(Icons.image, color: Colors.grey),
            SizedBox(height: 20),
            InkWell(
              onTap: () {
                if (messageController.text.isNotEmpty) {
                  chatController.SendMessage(
                    userModel.id!,
                    messageController.text,
                  );
                  messageController.clear();
                }
              },
              child: Icon(Icons.send, color: Colors.grey),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(bottom: 100, top: 10,left: 15,right: 15),
        child: StreamBuilder(
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
                   DateTime timestamp =DateTime.parse(snapshot.data![index].timestamp!);
                    String formattedTime = DateFormat('hh:mm a').format(timestamp);
                  return Chatbubble(
                    message: snapshot.data![index].message!,
                    imageUrl: snapshot.data![index].imageUrl ?? "",
                    isComming: snapshot.data![index].receiverId == profileController.currentUser.value.id,
                    time: formattedTime,
                    status: "read",
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
