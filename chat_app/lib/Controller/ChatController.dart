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
import 'package:connectivity_plus/connectivity_plus.dart';

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

    // Get current user ID for clarity
    String currentUserId = auth.currentUser!.uid;

    // Determine sender and receiver for the chat room
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

    // Check connectivity
    var connectivityResult = await Connectivity().checkConnectivity();
    String messageStatus =
        (connectivityResult == ConnectivityResult.none) ? 'pending' : 'sent';

    var newChat = ChatModel(
      id: chatId,
      message: message,
      imageUrl: imageUrl.value,
      videoUrl: mediaUrl.value,
      senderId: currentUserId,
      receiverId: targetUserId,
      senderName: profileController.currentUser.value.name,
      timestamp: DateTime.now().toString(),
      status: messageStatus,
      readStatus: 'unread',
    );

    // Get the current chat room data if it exists
    DocumentSnapshot? roomDoc;
    try {
      roomDoc = await db.collection("chats").doc(roomId).get();
    } catch (e) {
      print("Error getting chat room: $e");
    }

    // CRITICAL FIX: Always set unread count to 1 for new messages from current user to target
    // The unread count is for the target user (receiver of THIS message), not the current user
    int newUnreadCount = 1;

    // If the current user is sending a message to the target user,
    // the target user should see 1 unread message (or increment if there were previous unread)
    if (roomDoc != null && roomDoc.exists) {
      final roomData = roomDoc.data() as Map<String, dynamic>?;
      if (roomData != null) {
        // Check who the last sender was
        if (roomData['sender'] != null &&
            roomData['sender']['id'] == currentUserId) {
          // Current user was already the last sender, so increment the unread count
          int currentUnreadCount = roomData['unReadMessNo'] ?? 0;
          newUnreadCount = currentUnreadCount + 1;
        }
        // If the current user was previously the receiver, the count resets to 1
        // because we're now sending a new message to the other user
      }
    }

    var roomDetails = ChatRoomModel(
      id: roomId,
      lastMessage:
          imageUrl.value == "" && mediaUrl.value == ""
              ? message
              : imageUrl.value != ""
              ? "📷📷"
              : "🎥🎥",
      lastMessageTimestamp: nowTime,
      sender:
          profileController
              .currentUser
              .value, // Current user is always the sender of this message
      receiver:
          targetUser, // Target user is always the receiver of this message
      timestamp: DateTime.now().toString(),
      unReadMessNo: newUnreadCount,
    );

    try {
      if (messageStatus == 'sent') {
        await db
            .collection("chats")
            .doc(roomId)
            .collection("messages")
            .doc(chatId)
            .set(newChat.toJson());
        await db.collection("chats").doc(roomId).set(roomDetails.toJson());
        await contactController.saveContact(targetUser);
      } else {
        print('Message is pending due to no internet connection.');
      }
      selectedImagePath.value = "";
      selectedVideoPath.value = "";
    } catch (e) {
      print(e);
    }
    isLoading.value = false;
  }

  Stream<List<ChatModel>> getMessages(String targetUserId) {
    String roomId = getRoomId(targetUserId);

    markMessagesAsRead(roomId, targetUserId);

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

  Future<void> markMessagesAsRead(String roomId, String targetUserId) async {
    try {
      // First, update the unread count in the chat room document
      // Only reset the unread count if the current user is the receiver
      final roomDoc = await db.collection("chats").doc(roomId).get();
      if (roomDoc.exists) {
        final roomData = roomDoc.data() as Map<String, dynamic>?;
        if (roomData != null &&
            roomData['receiver'] != null &&
            roomData['receiver']['id'] == auth.currentUser!.uid) {
          // Only reset the unread count if the current user is the receiver
          await db.collection("chats").doc(roomId).update({'unReadMessNo': 0});

          // Also update the sender/receiver to reflect the current state
          // This is important for when the user replies
          await db.collection("chats").doc(roomId).update({
            'receiver': roomData['sender'],
            'sender': roomData['receiver'],
          });
        }
      }

      // Then, mark all unread messages as read where current user is the receiver
      final batch = db.batch();
      final messagesSnapshot =
          await db
              .collection("chats")
              .doc(roomId)
              .collection("messages")
              .where("receiverId", isEqualTo: auth.currentUser!.uid)
              .where("readStatus", isEqualTo: "unread")
              .get();

      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'readStatus': 'read', 'status': 'read'});
      }

      await batch.commit();
    } catch (e) {
      print("Error marking messages as read: $e");
    }
  }

  Future<void> markMessagesAsDelivered(String targetUserId) async {
    try {
      String roomId = getRoomId(targetUserId);

      final batch = db.batch();
      final messagesSnapshot =
          await db
              .collection("chats")
              .doc(roomId)
              .collection("messages")
              .where("receiverId", isEqualTo: auth.currentUser!.uid)
              .where("status", isEqualTo: "sent")
              .get();

      for (var doc in messagesSnapshot.docs) {
        batch.update(doc.reference, {'status': 'delivered'});
      }

      await batch.commit();
    } catch (e) {
      print("Error marking messages as delivered: $e");
    }
  }

  Stream<UserModel> getStatus(String uuid) {
    return db.collection('users').doc(uuid).snapshots().map((event) {
      return UserModel.fromJson(event.data()!);
    });
  }

  Future<void> setTypingStatus(bool isTyping) async {
    final user = auth.currentUser;
    if (user == null) return;
    await db.collection("users").doc(user.uid).update({
      "status": isTyping ? "is typing..." : "Online",
    });
  }
}
