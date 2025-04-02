import 'package:chat_app/Config/Images.dart';
import 'package:chat_app/Controller/SplaceController.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SplacePage extends StatelessWidget {
  const SplacePage({super.key});
  @override
  Widget build(BuildContext context) {
    Splacecontroller splacecontroller = Get.put(Splacecontroller());
    return Scaffold(body: Center(child: Image.asset(AssetsImage.appIcon)));
  }
}
