import 'package:chat_app/Model/UserModel.dart';
import 'package:chat_app/Pages/Auth/Widgets/AuthPageBody.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:chat_app/Controller/ProfileController.dart';

class AuthController extends GetxController {
  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;

  RxBool isLoading = false.obs;

  Future<bool> login(String email, String password) async {
    isLoading.value = true;
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);
      await ProfileController().afterLoginOrProfileUpdate();
      Get.offAllNamed("/homePage");
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Wrong password provided for that user.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format.';
      } else {
        errorMessage = 'Invalid email or password';
      }
      Get.snackbar('Error', errorMessage);
      return false;
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> createUser(String email, String password, String name) async {
    isLoading.value = true;
    try {
      await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await initUser(email, name);
      await ProfileController().afterLoginOrProfileUpdate();

      AuthPageBody.isLogin.value = true;
      Get.snackbar(
        'Success',
        'Account created successfully! Please login',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Signup failed';
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Invalid email format.';
      }
      Get.snackbar('Error', errorMessage);
      return false;
    } catch (e) {
      Get.snackbar('Error', 'An unexpected error occurred');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> logoutUser() async {
    await auth.signOut();
    Get.offAllNamed("/welcomePage");
  }

  Future<void> initUser(String email, String name) async {
    var newUser = UserModel(
      email: email,
      name: name,
      id: auth.currentUser!.uid,
    );
    try {
      await db
          .collection("users")
          .doc(auth.currentUser!.uid)
          .set(newUser.toJson());
    } catch (e) {
      print(e);
      Get.snackbar('Error', 'Failed to initialize user data');
    }
  }
}
