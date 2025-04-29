import 'package:chat_app/Controller/ContactController.dart';
import 'package:chat_app/Controller/ProfileController.dart';
import 'package:chat_app/Model/ChatModel.dart';
import 'package:chat_app/Model/ChatRoomModel.dart';
import 'package:chat_app/Model/UserModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/state_manager.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class ChatController extends GetxController {
  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;
  ProfileController profileController = Get.put(ProfileController());
  ContactController contactController = Get.put(ContactController());
  RxBool isLoading = false.obs;

  RxString selectedImagePath = "".obs;
  RxString selectedVideoPath = "".obs;

  String getRoomId(String targetUserId) {
    String currentUserId = auth.currentUser!.uid;
    if (currentUserId[0].codeUnitAt(0) > targetUserId[0].codeUnitAt(0)) {
      return currentUserId + targetUserId;
    } else {
      return targetUserId + currentUserId;
    }
  }

  UserModel getSender(UserModel currentUser, UserModel targetUser) {
    String currentUserId = currentUser.id!;
    String targetUserId = targetUser.id!;
    if (currentUserId[0].codeUnitAt(0) > targetUserId[0].codeUnitAt(0)) {
      return currentUser;
    } else {
      return targetUser;
    }
  }

  UserModel getReciver(UserModel currentUser, UserModel targetUser) {
    String currentUserId = currentUser.id!;
    String targetUserId = targetUser.id!;
    if (currentUserId[0].codeUnitAt(0) > targetUserId[0].codeUnitAt(0)) {
      return targetUser;
    } else {
      return currentUser;
    }
  }

  Future<void> sendMessage(
    String targetUserId,
    String message,
    UserModel targetUser,
  ) async {
    isLoading.value = true;
    String chatId = Uuid().v6();
    String roomId = getRoomId(targetUserId);
    DateTime timestamp = DateTime.now();
    String nowTime = DateFormat('hh:mm a').format(timestamp);
    UserModel sender = getSender(
      profileController.currentUser.value,
      targetUser,
    );
    UserModel receiver = getReciver(
      profileController.currentUser.value,
      targetUser,
    );

    RxString imageUrl = "".obs;
    RxString mediaUrl = "".obs;

    if (selectedImagePath.value.isNotEmpty) {
      imageUrl.value = await profileController.uploadFileToCloudinaryUnsigned(
        selectedImagePath.value,
      );
    } else if (selectedVideoPath.value.isNotEmpty) {
      mediaUrl.value = await profileController.uploadVideoToCloudinary(
        selectedVideoPath.value,
      );
    }

    var newChat = ChatModel(
      id: chatId,
      message: message,
      imageUrl: imageUrl.value,
      videoUrl: mediaUrl.value,
      senderId: auth.currentUser!.uid,
      receiverId: targetUserId,
      senderName: profileController.currentUser.value.name,
      timestamp: DateTime.now().toString(),
    );

    var roomDetails = ChatRoomModel(
      id: roomId,
      lastMessage:
          imageUrl.value == "" && mediaUrl.value == ""
              ? message
              : imageUrl.value != ""
              ? "📷📷"
              : "🎥🎥",
      lastMessageTimestamp: nowTime,
      sender: sender,
      receiver: receiver,
      timestamp: DateTime.now().toString(),
      unReadMessNo: 0,
    );

    try {
      await db
          .collection("chats")
          .doc(roomId)
          .collection("messages")
          .doc(chatId)
          .set(newChat.toJson());
      await db.collection("chats").doc(roomId).set(roomDetails.toJson());
      await contactController.saveContact(targetUser);
      selectedImagePath.value = "";
      selectedVideoPath.value = "";
    } catch (e) {
      print(e);
    }
    isLoading.value = false;
  }

  Stream<List<ChatModel>> getMessages(String targetUserId) {
    String roomId = getRoomId(targetUserId);
    return db
        .collection("chats")
        .doc(roomId)
        .collection("messages")
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((docs) => ChatModel.fromJson(docs.data()))
                  .toList(),
        );
  }

  Stream<UserModel> getStatus(String uuid) {
    return db.collection('users').doc(uuid).snapshots().map((event) {
      return UserModel.fromJson(event.data()!);
    });
  }

  // Set typing status for the current user
  Future<void> setTypingStatus(bool isTyping) async {
    final user = auth.currentUser;
    if (user == null) return;
    await db.collection("users").doc(user.uid).update({
      "status": isTyping ? "is typing..." : "Online",
    });
  }
}
