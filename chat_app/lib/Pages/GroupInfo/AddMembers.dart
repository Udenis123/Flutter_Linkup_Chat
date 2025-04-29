import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/Controller/ContactController.dart';
import 'package:chat_app/Controller/GroupController.dart';
import 'package:chat_app/Groups/NewGroup/SelectedMemberList.dart';
import 'package:chat_app/Model/GroupsModel.dart';
import 'package:chat_app/Pages/GroupInfo/GroupInfo.dart';
import 'package:chat_app/Pages/HomePage/Widget/ChatTile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddMembers extends StatelessWidget {
  final GroupModel groupModel;
  const AddMembers({super.key, required this.groupModel});

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
          onPressed: () async {
            if (groupController.groupMembers.isEmpty) {
              Get.snackbar("", "Please select at least one member");
            } else {
              for (var member in groupController.groupMembers) {
                await groupController.addMemberToGroup(groupModel.id!, member);
              }
              // Fetch updated group data
              final updatedGroup = await groupController.db
                  .collection('groups')
                  .doc(groupModel.id)
                  .get()
                  .then((doc) => GroupModel.fromJson(doc.data()!));

              // Navigate to updated GroupInfo
              Get.offAll(() => GroupInfo(groupModel: updatedGroup));
              Get.snackbar("Success", "Members added to group");
            }
          },
          child: Icon(
            Icons.add,
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
                    final groupMemberIds =
                        groupModel.members?.map((m) => m.id).toSet() ?? {};
                    final availableContacts =
                        snapshot.data!
                            .where(
                              (contact) => !groupMemberIds.contains(contact.id),
                            )
                            .toList();

                    return ListView.builder(
                      itemCount: availableContacts.length,
                      itemBuilder: (context, index) {
                        final contact = availableContacts[index];
                        return InkWell(
                          splashColor: const Color.fromARGB(255, 101, 94, 94),
                          highlightColor: Colors.transparent,
                          onTap: () {
                            groupController.selectMember(contact);
                          },
                          child: ChatTile(
                            userId: contact.id!,
                            lastChat: contact.about ?? "",
                            lastTime: "",
                            imageUrl:
                                contact.profileImage ??
                                AssetsImage.defaultImage,
                            name: contact.name!,
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
