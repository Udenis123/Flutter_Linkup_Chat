import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:image_picker/image_picker.dart';

class ImagePickerController extends GetxController {
  final ImagePicker picker = ImagePicker();

  Future<String> pickImage(ImageSource source) async {
    final XFile? image = await picker.pickImage(source: source);
    if (image != null) {
      return image.path;
    } else {
      return "";
    }
  }
  Future<String> pickVideo(ImageSource source) async {
    final XFile? video = await picker.pickVideo(source: source);
    if (video != null) {
      return video.path;
    } else {
      return "";
    }
  }
}
