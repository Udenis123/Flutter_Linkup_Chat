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
}
