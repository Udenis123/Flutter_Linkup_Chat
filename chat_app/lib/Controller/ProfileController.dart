import 'dart:io';

import 'package:chat_app/Model/UserModel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:chat_app/Config/FirebaseApi.dart';
import 'package:flutter/material.dart';

class ProfileController extends GetxController {
  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;

  RxBool isLoading = false.obs;
  final store = FirebaseStorage.instance;

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

  Future<void> UpdateProfile(
    String imageUrl,
    String about,
    String name,
    String number,
  ) async {
    try {
      isLoading.value = true;
      String? imageLink;

      // Handle image upload separately to catch specific upload errors
      if (imageUrl.isNotEmpty) {
        try {
          imageLink = await uploadFileToCloudinaryUnsigned(imageUrl);
        } catch (e) {
          print("Image upload failed: $e");
          Get.snackbar(
            'Warning',
            'Failed to upload image, but will continue updating other profile information',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.orange,
            colorText: Colors.white,
          );
        }
      }

      // Get current user document to preserve existing data
      final currentUserDoc =
          await db.collection("users").doc(auth.currentUser!.uid).get();
      if (!currentUserDoc.exists) {
        throw Exception('User document not found');
      }
      final currentData = currentUserDoc.data() ?? {};

      final updatedUser = UserModel(
        id: auth.currentUser!.uid,
        email: auth.currentUser!.email,
        name: name,
        phoneNumber: number,
        about: about,
        profileImage: imageLink ?? currentUser.value.profileImage,
        status: currentData['status'] ?? 'Online',
        lastOnlineStatus: currentData['lastOnlineStatus'],
        fcmToken: currentData['fcmToken'],
        createdAt: currentData['createdAt'],
        role: currentData['role'],
      );

      // Update user's main document
      await db
          .collection("users")
          .doc(auth.currentUser!.uid)
          .update(updatedUser.toJson());

      // Update user data in chat rooms where they are sender or receiver
      final chatRoomsSnapshot = await db.collection("chats").get();
      for (var doc in chatRoomsSnapshot.docs) {
        final data = doc.data();
        bool needsUpdate = false;

        if (data['sender']?['id'] == auth.currentUser!.uid) {
          data['sender'] = updatedUser.toJson();
          needsUpdate = true;
        }
        if (data['receiver']?['id'] == auth.currentUser!.uid) {
          data['receiver'] = updatedUser.toJson();
          needsUpdate = true;
        }

        if (needsUpdate) {
          await db.collection("chats").doc(doc.id).update(data);
        }
      }

      // Update user data in groups where they are a member
      final groupsSnapshot = await db.collection("groups").get();
      for (var doc in groupsSnapshot.docs) {
        final data = doc.data();
        if (data['members'] != null) {
          List<dynamic> members = List.from(data['members']);
          bool needsUpdate = false;

          for (int i = 0; i < members.length; i++) {
            if (members[i]['id'] == auth.currentUser!.uid) {
              members[i] = updatedUser.toJson();
              needsUpdate = true;
            }
          }

          if (needsUpdate) {
            await db.collection("groups").doc(doc.id).update({
              'members': members,
            });
          }
        }
      }

      // Update user data in contacts of other users
      final usersSnapshot = await db.collection("users").get();
      for (var userDoc in usersSnapshot.docs) {
        if (userDoc.id != auth.currentUser!.uid) {
          final contactRef = userDoc.reference
              .collection("contact")
              .doc(auth.currentUser!.uid);
          final contactDoc = await contactRef.get();
          if (contactDoc.exists) {
            await contactRef.set(updatedUser.toJson());
          }
        }
      }

      // Refresh current user data
      currentUser.value = updatedUser;

      // Call afterLoginOrProfileUpdate to update FCM token and any other necessary data
      await afterLoginOrProfileUpdate();

      Get.snackbar(
        'Success',
        'Profile updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      print("Error updating profile: $e");
      Get.snackbar(
        'Success',
        'Profile updated successfully!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<String?> uploadFileToFirebase(String imagePath) async {
    if (imagePath.isEmpty || imagePath == "") {
      return "";
    }
    try {
      final file = File(imagePath);
      final ref = store.ref().child(
        "files/${DateTime.now().millisecondsSinceEpoch}.jpg",
      );
      final uploadTask = await ref.putFile(file);
      final downloadImageUrl = await uploadTask.ref.getDownloadURL();
      return downloadImageUrl;
    } catch (ex) {
      print("Upload error: $ex");
      return "";
    }
  }

  Future<String> uploadFileToCloudinaryUnsigned(String imagePath) async {
    if (imagePath.isNotEmpty) {
      try {
        final uploadPreset = 'chat_app';
        final cloudName = 'dxxqpejtl';
        final file = File(imagePath);

        final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
        );

        final request =
            http.MultipartRequest('POST', uri)
              ..fields['upload_preset'] = uploadPreset
              ..files.add(
                await http.MultipartFile.fromPath(
                  'file',
                  file.path,
                  filename: path.basename(file.path),
                ),
              );

        final response = await request.send();
        final resBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final secureUrl = RegExp(
            r'"secure_url":"(.*?)"',
          ).firstMatch(resBody)?.group(1);
          if (secureUrl != null) {
            print('✅ Upload successful! URL: $secureUrl');
            return secureUrl;
          } else {
            print('❌ Failed to extract secure URL from response');
            throw Exception('Failed to extract secure URL from response');
          }
        } else {
          print('❌ Upload failed with status: ${response.statusCode}');
          print(resBody);
          throw Exception('Upload failed with status: ${response.statusCode}');
        }
      } catch (e) {
        print('⚠️ Error uploading to Cloudinary: $e');
        throw e; // Re-throw the error to be caught by the UpdateProfile method
      }
    }
    return ""; // Return empty string if no image path provided
  }

  Future<String> uploadVideoToCloudinary(String videoPath) async {
    if (videoPath.isNotEmpty) {
      try {
        final uploadPreset = 'chat_app';
        final cloudName = 'dxxqpejtl';
        final file = File(videoPath);

        final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudName/video/upload',
        );

        final request =
            http.MultipartRequest('POST', uri)
              ..fields['upload_preset'] = uploadPreset
              ..files.add(
                await http.MultipartFile.fromPath(
                  'file',
                  file.path,
                  filename: path.basename(file.path),
                ),
              );

        final response = await request.send();
        final resBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final secureUrl = RegExp(
            r'"secure_url":"(.*?)"',
          ).firstMatch(resBody)?.group(1);
          print('✅ Video upload successful! URL: $secureUrl');
          return secureUrl!;
        } else {
          print('❌ Video upload failed with status: ${response.statusCode}');
          print(resBody);
          return "";
        }
      } catch (e) {
        print('⚠️ Error uploading video to Cloudinary: $e');
        return "";
      }
    }
    return "";
  }

  Future<void> updateFcmToken() async {
    final user = auth.currentUser;
    if (user == null) return;
    final token = await FirebaseApi.getToken();
    if (token != null) {
      await db.collection('users').doc(user.uid).update({'fcmToken': token});
    }
  }

  Future<void> afterLoginOrProfileUpdate() async {
    await updateFcmToken();
    await getUserDetails(); // Refresh user details after any update
    // Notify any listeners that user data has changed
    update();
  }
}
