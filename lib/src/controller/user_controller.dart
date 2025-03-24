import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

class UserController extends GetxController {
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxString userPhone = ''.obs;
  final RxString userBio = ''.obs;
  final RxString userImage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadUserData();
  }

  Future<void> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      userName.value = prefs.getString('fullName') ?? '';
      userEmail.value = prefs.getString('email') ?? '';
      userPhone.value = prefs.getString('phone') ?? '';
      userBio.value = prefs.getString('bio') ?? '';
      userImage.value = prefs.getString('profileImage') ?? '';
      print('Loaded profile image path: ${userImage.value}'); // Debug print
    } catch (e) {
      print('Error loading user data: $e'); // Debug print
    }
  }

  Future<void> setUserName(String name) async {
    userName.value = name;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fullName', name);
  }

  Future<void> setUserEmail(String email) async {
    userEmail.value = email;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
  }

  Future<void> setUserPhone(String phone) async {
    userPhone.value = phone;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phone', phone);
  }

  Future<void> setUserBio(String bio) async {
    userBio.value = bio;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bio', bio);
  }

  Future<void> setUserImage(String imagePath) async {
    try {
      if (kIsWeb) {
        // For web, just store the data URL directly
        userImage.value = imagePath;
      } else {
        // For mobile, store the file path
        userImage.value = imagePath;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImage', userImage.value);
      print('Saved profile image: ${userImage.value}'); // Debug print
    } catch (e) {
      print('Error setting user image: $e'); // Debug print
    }
  }
}
