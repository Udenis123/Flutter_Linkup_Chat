import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/ContactPage/Widget/ContactSearch.dart';
import 'package:chat_app/ContactPage/Widget/NewcontactTile.dart';
import 'package:chat_app/Controller/ChatController.dart';
import 'package:chat_app/Controller/ContactController.dart';
import 'package:chat_app/Pages/Chat/ChatPage.dart';
import 'package:chat_app/Pages/HomePage/Widget/ChatTile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class Contactpage extends StatelessWidget {
  const Contactpage({super.key});

  @override
  Widget build(BuildContext context) {
    ContactController contactController = Get.put(ContactController());
    RxBool isSearching = false.obs;
    ChatController chatController = Get.put(ChatController());
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Contact"),
        actions: [
          Obx(
            () => IconButton(
              onPressed: () {
                isSearching.value = !isSearching.value;
              },
              icon: isSearching.value ? Icon(Icons.close) : Icon(Icons.search),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: [
            Obx(() => isSearching.value ? ContactSearch() : SizedBox()),
            SizedBox(height: 10),
            NewContantTile(
              btnName: "New Contact",
              icon: Icons.person_add,
              ontap: () {},
            ),
            SizedBox(height: 10),
            NewContantTile(
              btnName: "New Group",
              icon: Icons.group_add,
              ontap: () {},
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text(
                  "Contact on Linkup",
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ],
            ),
            SizedBox(height: 10),
            Obx(
              () =>
                  contactController.isLoading.value
                      ? CircularProgressIndicator()
                      : Column(
                        children:
                            contactController.userList
                                .map(
                                  (e) => InkWell(
                                    onTap: () {
                                      Get.to((ChatPage(userModel: e)));
                                      String roomId = chatController.getRoomId(
                                        e.id!,
                                      );
                                      print("😍😍😍" + roomId);
                                    },
                                    child: ChatTile(
                                      imageUrl:
                                          e.profileImage ??
                                          AssetsImage.defaultImage,
                                      name: e.name ?? "user name",
                                      lastChat:
                                          e.about ??
                                          "Linkup is a social media app",
                                      lastTime:
                                          e.email ==
                                                  chatController
                                                      .auth
                                                      .currentUser!
                                                      .email
                                              ? "You"
                                              : "10:00",
                                    ),
                                  ),
                                )
                                .toList(),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
