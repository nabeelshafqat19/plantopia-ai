import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';
import 'package:flutter/material.dart';

class UserAuthController extends GetxController {
  final DatabaseHelper _db = DatabaseHelper();
  final RxString userName = ''.obs;
  final RxString userEmail = ''.obs;
  final RxBool isLoggedIn = false.obs;

  @override
  void onInit() {
    super.onInit();
    _db.init(); // Initialize the database
    checkLoginStatus();
  }

  Future<void> checkLoginStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      isLoggedIn.value = prefs.getBool('isLoggedIn') ?? false;

      if (isLoggedIn.value) {
        String? email = prefs.getString('userEmail');
        if (email != null) {
          var user = await _db.getUserByEmail(email);
          if (user != null) {
            userName.value = user['fullName'];
            userEmail.value = user['email'];
            print('Logged in user found: ${user['fullName']}');
          } else {
            print('No user found for email: $email');
            // If user not found in database, clear login state
            await logout();
          }
        } else {
          print('No email found in preferences');
          await logout();
        }
      } else {
        print('User not logged in');
      }
    } catch (e) {
      print('Error checking login status: $e');
      await logout();
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      bool isAuthenticated = await _db.authenticateUser(email, password);

      if (isAuthenticated) {
        var user = await _db.getUserByEmail(email);
        if (user != null) {
          userName.value = user['fullName'];
          userEmail.value = user['email'];
          isLoggedIn.value = true;

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);
          await prefs.setString('userEmail', email);
          print('User logged in successfully: ${user['fullName']}');

          return true;
        }
      }
      print('Authentication failed for email: $email');
      return false;
    } catch (e) {
      print('Error during login: $e');
      return false;
    }
  }

  Future<bool> register(String fullName, String email, String password) async {
    try {
      print('Starting registration for email: $email');

      // Check if email already exists
      var existingUser = await _db.getUserByEmail(email);
      print('Existing user check result: $existingUser');

      if (existingUser != null) {
        print('Email already exists: $email');
        Get.snackbar(
          'Error',
          'This email is already registered',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }

      // If email doesn't exist, proceed with registration
      await _db.insertUser({
        'fullName': fullName,
        'email': email,
        'password': password,
      });

      print('User registered successfully');

      // Auto login after successful registration
      return await login(email, password);
    } catch (e) {
      print('Error during registration: $e');
      String errorMessage = 'Registration failed';
      if (e.toString().contains('Email already exists')) {
        errorMessage = 'This email is already registered';
      }

      Get.snackbar(
        'Error',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }
  }

  Future<void> logout() async {
    try {
      userName.value = '';
      userEmail.value = '';
      isLoggedIn.value = false;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await prefs.remove('userEmail');
      print('User logged out successfully');

      Get.offAllNamed('/login');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  Future<bool> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      await _db.updateUserProfile(userEmail.value, updates);
      if (updates.containsKey('fullName')) {
        userName.value = updates['fullName'];
      }
      print('Profile updated successfully');
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      if (userEmail.isEmpty) return null;
      return await _db.getUserByEmail(userEmail.value);
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }
}
