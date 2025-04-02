import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/Pages/Chat/Widget/ChatBubble.dart';
import 'package:flutter/material.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
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
                AssetsImage.girlPic,
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
              "Denis Uwihirwe",
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
            Icon(Icons.send, color: Colors.grey),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          padding: EdgeInsets.only(bottom: 100),
          children: [
            const Chatbubble(
              message: "Hello, how are you?",
              imageUrl: "",
              isComming: true,
              time: "12:00 PM",
              status: "read",
            ),

            const Chatbubble(
              message: "I'm good, thanks!",
              imageUrl: "",
              isComming: false,
              time: "12:01 PM",
              status: "sent",
            ),
            const Chatbubble(
              message: "I'm good, thanks!",
              imageUrl:
                  "https://th.bing.com/th/id/OIP.S9ys_hBZMdBZzIOurhMTOwHaEK?rs=1&pid=ImgDetMain",
              isComming: false,
              time: "12:01 PM",
              status: "sent",
            ),
            const Chatbubble(
              message: "I'm good, thanks!",
              imageUrl: "",
              isComming: true,
              time: "12:01 PM",
              status: "sent",
            ),
            const Chatbubble(
              message: "I'm good, thanks!",
              imageUrl:
                  "https://th.bing.com/th/id/OIP.S9ys_hBZMdBZzIOurhMTOwHaEK?rs=1&pid=ImgDetMain",
              isComming: true,
              time: "12:01 PM",
              status: "sent",
            ),
          ],
        ),
      ),
    );
  }
}
