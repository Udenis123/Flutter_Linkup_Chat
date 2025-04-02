import 'package:chat_app/Model/UserModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class ProfileController extends GetxController {
  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;

  Rx<UserModel> currentUser = UserModel().obs;

  void onInit() {
    super.onInit();
    if (auth.currentUser != null) {
      getUserDetails();
    }
  }

  Future<void> getUserDetails() async {
    try {
      await db
          .collection("users")
          .doc(auth.currentUser!.uid)
          .get()
          .then(
            (value) => {currentUser.value = UserModel.fromJson(value.data()!)},
          );
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch user data");
      print("Error fetching user data: $e");
    }
  }
}
