import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import 'package:image_picker/image_picker.dart';

class ImagePickerController extends GetxController {
  final ImagePicker picker = ImagePicker();
  RxBool isPickerActive = false.obs;

  Future<String> pickImage(ImageSource source) async {
    if (isPickerActive.value) {
      return ""; // Return empty if picker is already active
    }

    try {
      isPickerActive.value = true;
      final XFile? image = await picker.pickImage(source: source);
      if (image != null) {
        return image.path;
      }
    } on PlatformException catch (e) {
      if (e.code == 'already_active') {
        Get.snackbar(
          'Please wait',
          'Image picker is already active',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to pick image: ${e.message}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isPickerActive.value = false;
    }
    return "";
  }

  Future<String> pickVideo(ImageSource source) async {
    if (isPickerActive.value) {
      return ""; // Return empty if picker is already active
    }

    try {
      isPickerActive.value = true;
      final XFile? video = await picker.pickVideo(source: source);
      if (video != null) {
        return video.path;
      }
    } on PlatformException catch (e) {
      if (e.code == 'already_active') {
        Get.snackbar(
          'Please wait',
          'Video picker is already active',
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to pick video: ${e.message}',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick video',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isPickerActive.value = false;
    }
    return "";
  }

  @override
  void onClose() {
    isPickerActive.value = false;
    super.onClose();
  }
}
