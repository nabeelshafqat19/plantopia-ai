import 'package:flutter/material.dart';
import 'dart:ui' show PointerDeviceKind;
import 'package:e_commerce_flutter/core/app_theme.dart';
import 'package:e_commerce_flutter/src/view/screen/main_screen.dart';
import 'package:e_commerce_flutter/src/view/screen/login_screen.dart';
import 'package:e_commerce_flutter/src/view/screen/signup_screen.dart';
import 'package:e_commerce_flutter/src/view/screen/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get/get.dart';
import 'package:e_commerce_flutter/src/controller/cart_controller.dart';
import 'package:e_commerce_flutter/src/controller/user_controller.dart';
import 'package:e_commerce_flutter/src/view/screen/profile_screen.dart';
import 'package:e_commerce_flutter/src/controller/user_auth_controller.dart';
import 'package:e_commerce_flutter/src/view/screen/register_screen.dart';
import 'package:e_commerce_flutter/src/controller/plant_controller.dart';
import 'package:e_commerce_flutter/src/view/screen/admin_screen.dart';
import 'package:e_commerce_flutter/src/view/screen/checkout_screen.dart';
import 'package:e_commerce_flutter/src/controller/theme_controller.dart';
import 'package:e_commerce_flutter/src/controller/order_controller.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize controllers
  final cartController = Get.put(CartController());
  await Get.putAsync(() => SharedPreferences.getInstance());
  Get.put(UserController());
  Get.put(UserAuthController());
  Get.put(PlantController());
  Get.put(ThemeController());
  Get.put(OrderController());

  // Get initial route
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
  final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final initialRoute =
      hasSeenOnboarding ? (isLoggedIn ? '/home' : '/login') : '/onboarding';

  runApp(
    GetMaterialApp(
      title: 'Plantstopia',
      theme: AppTheme.lightAppTheme,
      darkTheme: AppTheme.darkAppTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      getPages: [
        GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
        GetPage(name: '/login', page: () => const LoginScreen()),
        GetPage(name: '/register', page: () => const RegisterScreen()),
        GetPage(name: '/signup', page: () => const SignupScreen()),
        GetPage(name: '/home', page: () => const MainScreen()),
        GetPage(name: '/profile', page: () => const ProfileScreen()),
        GetPage(name: '/admin', page: () => const AdminScreen()),
        GetPage(name: '/checkout', page: () => const CheckoutScreen()),
      ],
    ),
  );
}
