import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class Splacecontroller extends GetxController {
  final auth = FirebaseAuth.instance;

  void onInit() async {
    super.onInit();
    splaceHandle();
  }

  Future<void> splaceHandle() async {
    await Future.delayed(Duration(seconds: 1));
    if (auth.currentUser == null) {
      Get.toNamed("/welcomePage");
    } else {
      Get.toNamed("/homePage");
    }
  }
}
