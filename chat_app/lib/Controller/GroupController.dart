import 'package:chat_app/Config/CustomMessage.dart';
import 'package:chat_app/Controller/ProfileController.dart';
import 'package:chat_app/Model/ChatModel.dart';
import 'package:chat_app/Model/GroupsModel.dart';
import 'package:chat_app/Model/UserModel.dart';
import 'package:chat_app/Pages/HomePage/HomePage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

class GroupController extends GetxController {
  RxList<UserModel> groupMembers = <UserModel>[].obs;

  RxList<GroupModel> groupList = <GroupModel>[].obs;
  ProfileController profileController = Get.put(ProfileController());

  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;

  RxBool isLoading = false.obs;

  void onInit() {
    super.onInit();
    getGroups();
  }

  void selectMember(UserModel user) {
    if (groupMembers.contains(user)) {
      groupMembers.remove(user);
    } else {
      groupMembers.add(user);
    }
  }

  Future<void> createGroup(String groupName, String imagePath) async {
    isLoading.value = true;
    String groupId = Uuid().v6();
    groupMembers.add(
      UserModel(
        id: auth.currentUser!.uid,
        name: profileController.currentUser.value.name,
        email: profileController.currentUser.value.email,
        profileImage: profileController.currentUser.value.profileImage,
        role: "admin",
      ),
    );

    try {
      String imageUrl = await profileController.uploadFileToCloudinaryUnsigned(
        imagePath,
      );

      await db.collection("groups").doc(groupId).set({
        "id": groupId,
        "name": groupName,
        "profileUrl": imageUrl,
        "members": groupMembers.map((e) => e.toJson()).toList(),
        "createdAt": DateTime.now().toString(),
        "createdBy": auth.currentUser!.uid,
        "timeStamp": DateTime.now().toString(),
      });
      getGroups();

      successMessage("Group create");
      isLoading.value = false;
      Get.offAll(Homepage());
    } catch (e) {
      print(e);
    }
  }

  Future<void> getGroups() async {
    isLoading.value = true;
    List<GroupModel> tempGroup = [];
    await db.collection('groups').get().then((value) {
      tempGroup = value.docs.map((e) => GroupModel.fromJson(e.data())).toList();
    });

    groupList.clear();
    groupList.value =
        tempGroup
            .where(
              (e) => e.members!.any(
                (element) => element.id == auth.currentUser!.uid,
              ),
            )
            .toList();

    isLoading.value = false;
  }

  Future<void> sendGroupMessage(
    String message,
    String groupId,
    String imagePath,
    String videoPath,
  ) async {
    var chatId = Uuid().v6();

    if (imagePath == "" && videoPath == "") {
      var groupDetails = GroupModel(
        lastMessageTime: DateTime.now().toString(),
        lastmessage: message,
      );
      var newChat = ChatModel(
        id: chatId,
        message: message,
        senderId: auth.currentUser!.uid,
        senderName: profileController.currentUser.value.name,
        timestamp: DateTime.now().toString(),
      );
      await db
          .collection("groups")
          .doc(groupId)
          .collection("messages")
          .doc(chatId)
          .set(newChat.toJson());
      await db.collection("groups").doc(groupId).update({
        "lastmessage": message,
        "lastMessageTime": DateTime.now().toString(),
        "lastMessageBy": profileController.currentUser.value.name,
      });
    } else if (imagePath.isNotEmpty && videoPath == "") {
      String imageUrl = await profileController.uploadFileToCloudinaryUnsigned(
        imagePath,
      );
      var newChat = ChatModel(
        id: chatId,
        message: message,
        imageUrl: imageUrl,
        senderId: auth.currentUser!.uid,
        senderName: profileController.currentUser.value.name,
        timestamp: DateTime.now().toString(),
      );
      await db
          .collection("groups")
          .doc(groupId)
          .collection("messages")
          .doc(chatId)
          .set(newChat.toJson());
      await db.collection("groups").doc(groupId).update({
        "lastmessage": "📷📷",
        "lastMessageTime": DateTime.now().toString(),
        "lastMessageBy": profileController.currentUser.value.name,
      });
    } else {
      String videoUrl = await profileController.uploadVideoToCloudinary(
        videoPath,
      );
      var newChat = ChatModel(
        id: chatId,
        message: message,
        videoUrl: videoUrl,
        senderId: auth.currentUser!.uid,
        senderName: profileController.currentUser.value.name,
        timestamp: DateTime.now().toString(),
      );
      await db
          .collection("groups")
          .doc(groupId)
          .collection("messages")
          .doc(chatId)
          .set(newChat.toJson());
      await db.collection("groups").doc(groupId).update({
        "lastmessage": "🎦🎦",
        "lastMessageTime": DateTime.now().toString(),
        "lastMessageBy": profileController.currentUser.value.name,
      });
    }
  }

  Stream<List<ChatModel>> getGroupMessage(String groupId) {
    return db
        .collection("groups")
        .doc(groupId)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatModel.fromJson(doc.data()))
                  .toList(),
        );
  }

  Future<void> deleteGroup(String groupId) async {
    await db.collection("groups").doc(groupId).delete();
    getGroups();
  }

  Future<void> leaveGroup(String groupId) async {
    await db.collection("groups").doc(groupId).update({
      "members": FieldValue.arrayRemove([
        {
          "id": auth.currentUser!.uid,
          "name": profileController.currentUser.value.name,
          "email": profileController.currentUser.value.email,
          "profileImage": profileController.currentUser.value.profileImage,
          "role": "member",
        },
      ]),
    });
    getGroups();
  }

  Future<void> addMemberToGroup(String groupId, UserModel user) async {
    isLoading.value = true;
    await db.collection("groups").doc(groupId).update({
      "members": FieldValue.arrayUnion([user.toJson()]),
    });
    getGroups();
    isLoading.value = false;
  }

  Future<void> removeMemberFromGroup(String groupId, UserModel user) async {
    await db.collection("groups").doc(groupId).update({
      "members": FieldValue.arrayRemove([user.toJson()]),
    });
    getGroups();
  }

  Stream<List<GroupModel>> groupListStream(String userId) {
    return db
        .collection('groups')
        .orderBy("lastMessageTime", descending: true)
        .snapshots()
        .map((snapshot) {
          var groups =
              snapshot.docs
                  .map((doc) => GroupModel.fromJson(doc.data()))
                  .where(
                    (group) =>
                        group.members != null &&
                        group.members!.any((member) => member.id == userId),
                  )
                  .toList();

          groups.sort((a, b) {
            if (a.lastMessageTime == null) return 1;
            if (b.lastMessageTime == null) return -1;
            return b.lastMessageTime!.compareTo(a.lastMessageTime!);
          });

          return groups;
        });
  }
}
