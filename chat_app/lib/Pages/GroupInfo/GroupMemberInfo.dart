import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/Controller/ProfileController.dart';
import 'package:chat_app/Groups/GroupPage.dart';
import 'package:chat_app/Model/GroupsModel.dart';
import 'package:chat_app/Pages/GroupInfo/AddMembers.dart';
import 'package:chat_app/Pages/HomePage/HomePage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chat_app/Controller/GroupController.dart';

class GroupMemberInfo extends StatelessWidget {
  final String profileImage;
  final String userName;
  final String userEmail;
  final String groupId;
  final String role;
  final GroupModel groupModel;
  const GroupMemberInfo({
    super.key,
    required this.profileImage,
    required this.userName,
    required this.userEmail,
    required this.groupId,
    required this.role,
    required this.groupModel,
  });

  void _showFullImage(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InteractiveViewer(
                    child: CachedNetworkImage(
                      imageUrl: profileImage,
                      fit: BoxFit.cover,
                      placeholder:
                          (context, url) => CircularProgressIndicator(),
                      errorWidget: (context, url, error) => Icon(Icons.error),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ProfileController profileController = Get.put(ProfileController());

    return Container(
      padding: EdgeInsets.all(20),
      //height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60, // Adjust size
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 1,
                        ), // Ring border
                      ),
                      child: GestureDetector(
                        onTap: () => _showFullImage(context),
                        child: ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: profileImage,
                            fit: BoxFit.cover,
                            placeholder:
                                (context, url) => CircularProgressIndicator(),
                            errorWidget:
                                (context, url, error) => Icon(Icons.error),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userName ?? "User Full name",
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userEmail ?? "user@example.com",
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.phone, size: 20, color: Colors.green),
                          SizedBox(width: 5),
                          Text("Call", style: TextStyle(color: Colors.green)),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.videocam,
                            size: 20,
                            color: const Color.fromARGB(255, 250, 225, 0),
                          ),
                          SizedBox(width: 5),
                          Text(
                            "Video",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 255, 230, 0),
                            ),
                          ),
                        ],
                      ),
                    ),
                    role == "admin"
                        ? InkWell(
                          onTap: () {
                            Get.to(AddMembers(groupModel: groupModel));
                          },
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Theme.of(context).colorScheme.surface,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_add,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  "Add",
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ],
                            ),
                          ),
                        )
                        : InkWell(
                          onTap: () async {
                            final groupController = Get.put(GroupController());
                            final profileController = Get.put(
                              ProfileController(),
                            );
                            final user = profileController.currentUser.value;

                            await groupController.removeMemberFromGroup(
                              groupId,
                              user,
                            );

                            final now = DateTime.now();
                            final formattedDate =
                                "${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}";
                            final exitMessage =
                                "${user.name} exited the group at $formattedDate";
                            await groupController.sendGroupMessage(
                              exitMessage,
                              groupId,
                              "",
                              "",
                            );
                            groupController.getGroups();
                            Get.snackbar("Exited", "You have exited the group");
                            Get.to(() => Homepage());
                          },
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Theme.of(context).colorScheme.surface,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person_remove,
                                  size: 20,
                                  color: Colors.blue,
                                ),
                                SizedBox(width: 2),
                                Text(
                                  "Exit",
                                  style: TextStyle(color: Colors.blue),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
