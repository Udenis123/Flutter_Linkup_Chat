import 'package:chat_app/Controller/AuthController.dart';
import 'package:chat_app/Controller/ProfileController.dart';
import 'package:chat_app/UserProfile/Widget/UserInfo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserProfilepage extends StatelessWidget {
  const UserProfilepage({super.key});

  @override
  Widget build(BuildContext context) {
    AuthController authController = Get.put(AuthController());
    ProfileController profileController = Get.put(ProfileController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        actions: [
          IconButton(
            onPressed: () {
              profileController.getUserDetails();

              Get.toNamed("/updateProfile");
            },
            icon: Icon(Icons.edit),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            LoginUserInfo(),
            Spacer(),
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(10),
              ),
              child: ElevatedButton(
                onPressed: () {
                  authController.logoutUser();
                },
                child: Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
