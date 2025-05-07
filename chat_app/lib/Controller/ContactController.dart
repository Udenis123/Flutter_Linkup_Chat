import 'package:chat_app/Model/ChatRoomModel.dart';
import 'package:chat_app/Model/UserModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class ContactController extends GetxController {
  final db = FirebaseFirestore.instance;
  final auth = FirebaseAuth.instance;
  RxBool isLoading = false.obs;

  RxList<UserModel> userList = <UserModel>[].obs;
  RxList<ChatRoomModel> chatRoomList = <ChatRoomModel>[].obs;

  void onInit() async {
    super.onInit();
    await getUserList();
    await getChatRoomList();
  }

  Future<void> getUserList() async {
    isLoading.value = true;
    try {
      userList.clear();
      await db
          .collection("users")
          .get()
          .then(
            (value) => {
              userList.value =
                  value.docs.map((e) => UserModel.fromJson(e.data())).toList(),
            },
          );
      isLoading.value = false;
    } catch (ex) {
      Get.snackbar("Error", "Failed to fetch user data");
      print("Error fetching user data: $ex");
    }
    isLoading.value = false;
  }

  Future<void> getChatRoomList() async {
    List<ChatRoomModel> temChatRoomList = [];
    await db
        .collection('chats')
        .orderBy("timestamp", descending: true)
        .get()
        .then((value) {
          temChatRoomList =
              value.docs.map((e) => ChatRoomModel.fromJson(e.data())).toList();
        });
    chatRoomList.value =
        temChatRoomList
            .where((e) => e.id!.contains(auth.currentUser!.uid))
            .toList();
  }

  Future<void> saveContact(UserModel user) async {
    final currentUser = auth.currentUser;
    if (currentUser == null) {
      print("❤️❤️❤️❤️❤️❤️❤️No authenticated user.");
      return;
    }

    try {
      await db
          .collection("users")
          .doc(currentUser.uid)
          .collection("contact")
          .doc(user.id)
          .set(user.toJson());
    } catch (ex) {
      print("❤️❤️❤️❤️❤️❤️❤️Error while saving contact: ${ex.toString()}");
    }
  }

  Stream<List<UserModel>> getContants() {
    return db
        .collection("users")
        .doc(auth.currentUser!.uid)
        .collection("contact")
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((docs) => UserModel.fromJson(docs.data()))
                  .toList(),
        );
  }

  Stream<List<ChatRoomModel>> chatRoomStream() {
    return db
        .collection('chats')
        .orderBy("timestamp", descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => ChatRoomModel.fromJson(doc.data()))
                  .where((e) => e.id!.contains(auth.currentUser!.uid))
                  .toList(),
        );
  }

  // Add stream method for real-time updates
  Stream<List<UserModel>> getUsersStream() {
    return db.collection('chats').snapshots().asyncMap((chatSnapshot) async {
      // Get all users who are in active chats with current user
      Set<String> existingChatUserIds = {};
      for (var doc in chatSnapshot.docs) {
        var chatRoom = ChatRoomModel.fromJson(doc.data());
        if (chatRoom.id!.contains(auth.currentUser!.uid)) {
          if (chatRoom.sender?.id != auth.currentUser!.uid) {
            existingChatUserIds.add(chatRoom.sender?.id ?? '');
          }
          if (chatRoom.receiver?.id != auth.currentUser!.uid) {
            existingChatUserIds.add(chatRoom.receiver?.id ?? '');
          }
        }
      }

      // Get all users except current user and those in active chats
      final usersSnapshot =
          await db
              .collection("users")
              .where('id', isNotEqualTo: auth.currentUser!.uid)
              .get();

      return usersSnapshot.docs
          .map((doc) => UserModel.fromJson(doc.data()))
          .where((user) => !existingChatUserIds.contains(user.id))
          .toList();
    });
  }
}
