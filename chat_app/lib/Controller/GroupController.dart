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

      final groupData = {
        "id": groupId,
        "name": groupName,
        "profileUrl": imageUrl,
        "members": groupMembers.map((e) => e.toJson()).toList(),
        "createdAt": DateTime.now().toString(),
        "createdBy": auth.currentUser!.uid,
        "timeStamp": DateTime.now().toString(),
        "lastMessageTime": DateTime.now().toString(),
        "lastmessage": "Group created",
        "lastMessageBy": profileController.currentUser.value.name,
        "description": "Welcome to $groupName",
      };

      await db.collection("groups").doc(groupId).set(groupData);

      await sendGroupMessage(
        "Group created by ${profileController.currentUser.value.name}",
        groupId,
        "",
        "",
      );

      await getGroups();

      successMessage("Group created successfully");
      isLoading.value = false;
      Get.offAll(() => Homepage());
    } catch (e) {
      errorMessage("Error creating group: ${e.toString()}");
      isLoading.value = false;
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
    final currentUserId = auth.currentUser!.uid;

    // Get current group data to update unread count
    final groupDoc = await db.collection("groups").doc(groupId).get();
    if (!groupDoc.exists) return;

    final group = GroupModel.fromJson(groupDoc.data()!);

    // Create a map to track unread status for each member
    Map<String, dynamic> memberUnreadStatus = {};

    // Set unread status for each member except the sender
    for (var member in group.members ?? []) {
      if (member.id != currentUserId) {
        memberUnreadStatus[member.id!] = true;
      }
    }

    // Count members who need to see unread message (everyone except sender)
    final unreadCount =
        (group.members?.length ?? 0) > 0 ? (group.members!.length - 1) : 0;

    if (imagePath == "" && videoPath == "") {
      var newChat = ChatModel(
        id: chatId,
        message: message,
        senderId: currentUserId,
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
        "unReadCount": unreadCount,
        "memberUnreadStatus": memberUnreadStatus,
        "lastSenderId": currentUserId,
      });
    } else if (imagePath.isNotEmpty && videoPath == "") {
      String imageUrl = await profileController.uploadFileToCloudinaryUnsigned(
        imagePath,
      );
      var newChat = ChatModel(
        id: chatId,
        message: message,
        imageUrl: imageUrl,
        senderId: currentUserId,
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
        "unReadCount": unreadCount,
        "memberUnreadStatus": memberUnreadStatus,
        "lastSenderId": currentUserId,
      });
    } else {
      String videoUrl = await profileController.uploadVideoToCloudinary(
        videoPath,
      );
      var newChat = ChatModel(
        id: chatId,
        message: message,
        videoUrl: videoUrl,
        senderId: currentUserId,
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
        "unReadCount": unreadCount,
        "memberUnreadStatus": memberUnreadStatus,
        "lastSenderId": currentUserId,
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
    try {
      // Send notification before deleting
      await sendGroupMessage(
        "${profileController.currentUser.value.name} deleted the group",
        groupId,
        "",
        "",
      );

      await db.collection("groups").doc(groupId).delete();
      getGroups();
    } catch (e) {
      print("Error deleting group: $e");
    }
  }

  Future<void> leaveGroup(String groupId) async {
    try {
      // Get current user details
      final currentUser = UserModel(
        id: auth.currentUser!.uid,
        name: profileController.currentUser.value.name,
        email: profileController.currentUser.value.email,
        profileImage: profileController.currentUser.value.profileImage,
        role: "member", // Add role to match the stored data
      );

      // Get the current group data
      final groupDoc = await db.collection("groups").doc(groupId).get();
      if (!groupDoc.exists) return;

      final group = GroupModel.fromJson(groupDoc.data()!);

      // Remove the current user from members list
      final updatedMembers =
          group.members!
              .where((member) => member.id != currentUser.id)
              .toList();

      // First send a message to the group
      await sendGroupMessage(
        "${currentUser.name} left the group",
        groupId,
        "",
        "",
      );

      // Update the group with the new members list
      await db.collection("groups").doc(groupId).update({
        "members": updatedMembers.map((e) => e.toJson()).toList(),
      });

      // If no members left, delete the group
      if (updatedMembers.isEmpty) {
        await deleteGroup(groupId);
      }

      // Navigate back after leaving
      Get.back();
    } catch (e) {
      print("Error leaving group: $e");
    }
  }

  Future<void> addMemberToGroup(String groupId, UserModel user) async {
    try {
      isLoading.value = true;

      // Add member to the group
      await db.collection("groups").doc(groupId).update({
        "members": FieldValue.arrayUnion([user.toJson()]),
      });

      // Send notification message
      await sendGroupMessage(
        "${profileController.currentUser.value.name} added ${user.name} to the group",
        groupId,
        "",
        "",
      );

      getGroups();
      isLoading.value = false;
    } catch (e) {
      print("Error adding member: $e");
      isLoading.value = false;
    }
  }

  Future<void> removeMemberFromGroup(String groupId, UserModel user) async {
    try {
      // Send notification before removing the member
      await sendGroupMessage(
        "${profileController.currentUser.value.name} removed ${user.name} from the group",
        groupId,
        "",
        "",
      );

      // Remove member from the group
      await db.collection("groups").doc(groupId).update({
        "members": FieldValue.arrayRemove([user.toJson()]),
      });

      getGroups();
    } catch (e) {
      print("Error removing member: $e");
    }
  }

  Stream<List<GroupModel>> groupListStream(String userId) {
    return db.collection('groups').snapshots().map((snapshot) {
      var groups =
          snapshot.docs
              .map((doc) => GroupModel.fromJson(doc.data()))
              .where(
                (group) =>
                    group.members != null &&
                    group.members!.any((member) => member.id == userId),
              )
              .toList();

      // Sort by lastMessageTime if available, otherwise by createdAt
      groups.sort((a, b) {
        final aTime = a.lastMessageTime ?? a.createdAt ?? '';
        final bTime = b.lastMessageTime ?? b.createdAt ?? '';
        if (aTime.isEmpty) return 1;
        if (bTime.isEmpty) return -1;
        return bTime.compareTo(aTime);
      });

      return groups;
    });
  }

  // Get single group stream with member check
  Stream<GroupModel> getGroupStream(String groupId) {
    return db.collection('groups').doc(groupId).snapshots().map((doc) {
      if (!doc.exists) return GroupModel();

      final group = GroupModel.fromJson(doc.data()!);

      // Check if current user is still a member
      final isMember =
          group.members?.any((member) => member.id == auth.currentUser?.uid) ??
          false;

      // Return empty group if user is not a member
      return isMember ? group : GroupModel();
    });
  }

  // Make a member an admin
  Future<void> makeAdmin(String groupId, UserModel member) async {
    try {
      final groupDoc = await db.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) return;

      final group = GroupModel.fromJson(groupDoc.data()!);
      final updatedMembers =
          group.members!.map((m) {
            if (m.id == member.id) {
              return m..role = "admin";
            }
            return m;
          }).toList();

      await db.collection('groups').doc(groupId).update({
        "members": updatedMembers.map((e) => e.toJson()).toList(),
      });

      await sendGroupMessage("${member.name} is now an admin", groupId, "", "");
    } catch (e) {
      print("Error making admin: $e");
    }
  }

  // Remove admin status from a member
  Future<void> removeAdmin(String groupId, UserModel member) async {
    try {
      final groupDoc = await db.collection('groups').doc(groupId).get();
      if (!groupDoc.exists) return;

      final group = GroupModel.fromJson(groupDoc.data()!);
      final updatedMembers =
          group.members!.map((m) {
            if (m.id == member.id) {
              return m..role = "member";
            }
            return m;
          }).toList();

      await db.collection('groups').doc(groupId).update({
        "members": updatedMembers.map((e) => e.toJson()).toList(),
      });

      await sendGroupMessage(
        "${member.name} is no longer an admin",
        groupId,
        "",
        "",
      );
    } catch (e) {
      print("Error removing admin: $e");
    }
  }

  // Update group information
  Future<void> updateGroupInfo(
    String groupId,
    String name,
    String description,
  ) async {
    try {
      await db.collection("groups").doc(groupId).update({
        "name": name,
        "description": description,
      });

      await sendGroupMessage("Group info updated", groupId, "", "");
    } catch (e) {
      print("Error updating group info: $e");
    }
  }

  // Update group photo
  Future<void> updateGroupPhoto(String groupId, String imagePath) async {
    try {
      String imageUrl = await profileController.uploadFileToCloudinaryUnsigned(
        imagePath,
      );

      await db.collection("groups").doc(groupId).update({
        "profileUrl": imageUrl,
      });

      await sendGroupMessage("Group photo updated", groupId, "", "");
    } catch (e) {
      print("Error updating group photo: $e");
    }
  }

  // Reset unread message count when a user opens a group chat
  Future<void> resetGroupUnreadCount(String groupId) async {
    try {
      final currentUserId = auth.currentUser!.uid;

      // Get current group data
      final groupDoc = await db.collection("groups").doc(groupId).get();
      if (!groupDoc.exists) return;

      final group = GroupModel.fromJson(groupDoc.data()!);

      // If the current user is the last sender, no need to update anything
      if (group.lastSenderId == currentUserId) return;

      // Get the current memberUnreadStatus map
      Map<String, dynamic> memberUnreadStatus = group.memberUnreadStatus ?? {};

      // Remove the current user from the unread status map
      memberUnreadStatus.remove(currentUserId);

      // Calculate new unread count based on remaining members with unread status
      final newUnreadCount = memberUnreadStatus.length;

      // Update the group document
      await db.collection("groups").doc(groupId).update({
        "memberUnreadStatus": memberUnreadStatus,
        "unReadCount": newUnreadCount,
      });
    } catch (e) {
      print("Error resetting unread count: $e");
    }
  }
}
