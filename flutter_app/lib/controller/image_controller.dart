import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';

class ImageController extends GetxController {
  Rx<ImageProvider?> selectedImage = Rx<ImageProvider?>(null); // ImageProvider로 수정

  void updateImage(ImageProvider image) {
    selectedImage.value = image;
  }
}