import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/Controller/ContactController.dart';
import 'package:chat_app/Controller/GroupController.dart';
import 'package:chat_app/Groups/NewGroup/GroupTitle.dart';
import 'package:chat_app/Groups/NewGroup/SelectedMemberList.dart';
import 'package:chat_app/Pages/HomePage/Widget/ChatTile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NewGroup extends StatelessWidget {
  const NewGroup({super.key});

  @override
  Widget build(BuildContext context) {
    ContactController contactController = Get.put(ContactController());
    GroupController groupController = Get.put(GroupController());
    return Scaffold(
      floatingActionButton: Obx(
        () => FloatingActionButton(
          backgroundColor:
              groupController.groupMembers.isEmpty
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.primary,
          onPressed: () {
            if (groupController.groupMembers.isEmpty) {
              Get.snackbar("", "Please select atleastOne Member");
            } else {
              Get.to(GroupTitle(), transition: Transition.rightToLeft);
            }
          },
          child: Icon(
            Icons.arrow_forward,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
      appBar: AppBar(title: Text("New Group")),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          children: [
            SelectedMembers(),
            SizedBox(height: 10),
            Row(
              children: [
                Text(
                  "All Contact",
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder(
                stream: contactController.getContants(),
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
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return InkWell(
                          splashColor: const Color.fromARGB(255, 101, 94, 94),
                          highlightColor: Colors.transparent,
                          onTap: () {
                            groupController.selectMember(snapshot.data![index]);
                          },
                          child: ChatTile(
                            userId: snapshot.data![index].id!,
                            lastChat: snapshot.data![index].about ?? "",
                            lastTime: "",
                            imageUrl:
                                snapshot.data![index].profileImage ??
                                AssetsImage.defaultImage,
                            name: snapshot.data![index].name!,
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
