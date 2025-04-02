import 'package:chat_app/Pages/Auth/Widgets/LoginForm.dart';
import 'package:chat_app/Pages/Auth/Widgets/SignupForm.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';

class AuthPageBody extends StatelessWidget {
  const AuthPageBody({super.key});
  static RxBool isLogin = true.obs;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      //height: 400,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,

                    children: [
                      InkWell(
                        onTap: () {
                          isLogin.value = true;
                        },
                        child: Column(
                          children: [
                            Text(
                              "Login",
                              style:
                                  isLogin.value
                                      ? Theme.of(context).textTheme.bodyLarge
                                      : Theme.of(context).textTheme.labelLarge,
                            ),
                            SizedBox(height: 5),
                            AnimatedContainer(
                              duration: Duration(milliseconds: 100),
                              height: 3,
                              width: isLogin.value ? 100 : 0,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          isLogin.value = false;
                        },
                        child: Column(
                          children: [
                            Text(
                              "SignUp",
                              style:
                                  isLogin.value
                                      ? Theme.of(context).textTheme.labelLarge
                                      : Theme.of(context).textTheme.bodyLarge,
                            ),
                            SizedBox(height: 5),
                            AnimatedContainer(
                              duration: Duration(milliseconds: 100),
                              height: 3,
                              width: isLogin.value ? 0 : 100,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(() => isLogin.value ? LoginForm() : SignupForm()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
