import 'package:chat_app/Controller/AuthController.dart';
import 'package:chat_app/Widget/PrimaryButton.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/get_core.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

class SignupForm extends StatelessWidget {
  const SignupForm({super.key});

  @override
  Widget build(BuildContext context) {
    AuthController authController = Get.put(AuthController());
    TextEditingController fullName = TextEditingController();
    TextEditingController email = TextEditingController();
    TextEditingController password = TextEditingController();
    final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

    return Form(
      key: _formKey,
      child: Column(
        children: [
          SizedBox(height: 30),
          TextFormField(
            controller: fullName,
            decoration: InputDecoration(
              hintText: "Full Name",
              prefixIcon: Icon(Icons.person),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              if (value.length < 5) {
                return 'Fullname must be at least 5 characters';
              }
              return null;
            },
          ),
          SizedBox(height: 30),
          TextFormField(
            controller: email,
            decoration: InputDecoration(
              hintText: "Email",
              prefixIcon: Icon(Icons.alternate_email_rounded),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          SizedBox(height: 30),
          TextFormField(
            controller: password,
            decoration: InputDecoration(
              hintText: "Password",
              prefixIcon: Icon(Icons.password_outlined),
            ),
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          SizedBox(height: 60),
          Obx(
            () =>
                authController.isLoading.value
                    ? CircularProgressIndicator()
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PrimaryButton(
                          ontap: () {
                            if (_formKey.currentState!.validate()) {
                              authController.createUser(
                                email.text,
                                password.text,
                                fullName.text,
                              );
                            }
                          },
                          btnName: "SIGNUP",
                          icon: Icons.lock_open_outlined,
                        ),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}
