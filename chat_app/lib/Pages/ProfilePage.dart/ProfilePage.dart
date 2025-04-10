import 'dart:io';

import 'package:chat_app/Controller/AuthController.dart';
import 'package:chat_app/Controller/ImagePicker.dart';
import 'package:chat_app/Controller/ProfileController.dart';
import 'package:chat_app/Widget/PrimaryButton.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/get_state_manager.dart';

class Profilepage extends StatelessWidget {
  const Profilepage({super.key});

  @override
  Widget build(BuildContext context) {
    RxBool isEditing = false.obs;
    ProfileController profileController = Get.put(ProfileController());
    TextEditingController name = TextEditingController(
      text: profileController.currentUser.value.name,
    );
    TextEditingController email = TextEditingController(
      text: profileController.currentUser.value.email,
    );
    TextEditingController phone = TextEditingController(
      text: profileController.currentUser.value.phoneNumber,
    );
    TextEditingController about = TextEditingController(
      text: profileController.currentUser.value.about,
    );
    ImagePickerController imagePickerController = Get.put(
      ImagePickerController(),
    );

    RxString imagepath = "".obs;
    AuthController authController = Get.put(AuthController());

    return Scaffold(
      appBar: AppBar(
        title: Text("Profile"),
        actions: [
          IconButton(
            onPressed: () {
              authController.logoutUser();
            },
            icon: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(Icons.logout,size: 25,),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(10),
        child: ListView(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              //height: 300,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Obx(
                              () =>
                                  isEditing.value
                                      ? InkWell(
                                        onTap: () async {
                                          imagepath.value =
                                              await imagePickerController
                                                  .pickImage();

                                          print(
                                            "image picked: " + imagepath.value,
                                          );
                                        },
                                        child: Container(
                                          height: 200,
                                          width: 200,
                                          decoration: BoxDecoration(
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.surface,
                                            borderRadius: BorderRadius.circular(
                                              100,
                                            ),
                                          ),
                                          child:
                                              imagepath.value == ""
                                                  ? Icon(Icons.edit)
                                                  : ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          100,
                                                        ),
                                                    child: Image.file(
                                                      fit: BoxFit.cover,
                                                      File(imagepath.value),
                                                    ),
                                                  ),
                                        ),
                                      )
                                      : Container(
                                        height: 200,
                                        width: 200,
                                        decoration: BoxDecoration(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.surface,
                                          borderRadius: BorderRadius.circular(
                                            100,
                                          ),
                                        ),
                                        child:
                                            (profileController
                                                            .currentUser
                                                            .value
                                                            .profileImage ==
                                                        null ||
                                                    profileController
                                                            .currentUser
                                                            .value
                                                            .profileImage ==
                                                        "")
                                                ? Icon(Icons.image)
                                                : ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        100,
                                                      ),
                                                  child: Image.network(
                                                    profileController
                                                        .currentUser
                                                        .value
                                                        .profileImage!,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                      ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Obx(
                          () => TextField(
                            controller: name,
                            enabled: isEditing.value,
                            decoration: InputDecoration(
                              filled: isEditing.value,
                              hintText: "Username",
                              labelText: "Name",
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Obx(
                          () => TextField(
                            controller: about,
                            enabled: isEditing.value,
                            decoration: InputDecoration(
                              filled: isEditing.value,
                              hintText: "About you",
                              labelText: "About",
                              prefixIcon: Icon(Icons.info),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        TextField(
                          controller: email,
                          enabled: isEditing.value,
                          decoration: InputDecoration(
                            filled: false,
                            hintText: "your email",
                            labelText: "Email",
                            prefixIcon: Icon(Icons.alternate_email_rounded),
                          ),
                        ),
                        SizedBox(height: 10),
                        Obx(
                          () => TextField(
                            controller: phone,
                            enabled: isEditing.value,
                            decoration: InputDecoration(
                              filled: isEditing.value,
                              hintText: "phone number",
                              labelText: "Phone",
                              prefixIcon: Icon(Icons.phone),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        Obx(()=>profileController.isLoading.value?CircularProgressIndicator():Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Obx(
                              () =>
                                  isEditing.value
                                      ? PrimaryButton(
                                        btnName: "Save",
                                        icon: Icons.save,
                                        ontap: () async {
                                          await profileController.UpdateProfile(
                                            imagepath.value,
                                            about.text,
                                            name.text,
                                            phone.text,
                                          );
                                          isEditing.value = false;
                                          await profileController
                                              .getUserDetails();
                                        },
                                      )
                                      : PrimaryButton(
                                        btnName: "Edit",
                                        icon: Icons.edit,
                                        ontap: () {
                                          isEditing.value = true;
                                        },
                                      ),
                            ),
                          ],
                        ),),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
