import 'dart:io';

import 'package:chat_app/Model/UserModel.dart';
import 'package:chat_app/UserProfile/UpdateProfile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:cloudinary_sdk/cloudinary_sdk.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

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
      final imageLink = await  uploadFileToCloudinaryUnsigned(imageUrl);
    
      final updatedUser = UserModel(
        id: auth.currentUser!.uid,
        email: auth.currentUser!.email,
        name: name,
        phoneNumber: number,
        about: about,
        profileImage: imageUrl == "" ? currentUser.value.profileImage : imageLink,
      );
      await db
          .collection("users")
          .doc(auth.currentUser!.uid)
          .set(updatedUser.toJson());
          
      print(imageLink);
    } catch (e) {
      print("Error: $e");
    }

    isLoading.value = false;
  }

  Future<String?> uploadFileToFirebase(String imagePath) async {
    if(imagePath.isEmpty||imagePath==""){ 
      return "";
    }
  try {
    final file = File(imagePath);
    final ref = store.ref().child("files/${DateTime.now().millisecondsSinceEpoch}.jpg");
    final uploadTask = await ref.putFile(file);
    final downloadImageUrl = await uploadTask.ref.getDownloadURL();
    return downloadImageUrl;
  } catch (ex) {
    print("Upload error: $ex");
    return "";
  }
}
 Future<String> uploadFileToCloudinaryUnsigned(String imagePath) async {
  if(!imagePath.isEmpty|| imagePath!=""){ 
 
  try {
    final uploadPreset = 'chat_app'; 
    final cloudName = 'dxxqpejtl'; 
    final file = File(imagePath);

    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        filename: path.basename(file.path),
      ));

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final secureUrl = RegExp(r'"secure_url":"(.*?)"').firstMatch(resBody)?.group(1);
      print('✅ Upload successful! URL: $secureUrl');
      return secureUrl!;
    } else {
      print('❌ Upload failed with status: ${response.statusCode}');
      print(resBody);
      return "";
    }
  } catch (e) {
    print('⚠️ Error uploading to Cloudinary: $e');
    return "";
  }
 }
 return "";
 }
 

}
