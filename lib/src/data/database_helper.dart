import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static SharedPreferences? _prefs;
  static const String _usersKey = 'users_data';
  bool _initialized = false;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<void> init() async {
    if (_initialized) return;

    print('Initializing DatabaseHelper...');
    _prefs = await SharedPreferences.getInstance();

    if (!_prefs!.containsKey(_usersKey)) {
      print('No users found, initializing with default admin user');
      // Initialize with default admin user
      await _saveUsers([
        {
          'id': 1,
          'fullName': 'Admin User',
          'email': 'admin@admin.com',
          'password': 'admin@123',
          'createdAt': DateTime.now().toIso8601String(),
        }
      ]);
    } else {
      print('Existing users found in storage');
    }
    _initialized = true;
    print('DatabaseHelper initialized successfully');
  }

  List<Map<String, dynamic>> _getUsers() {
    final String? usersJson = _prefs?.getString(_usersKey);
    print('Retrieved users JSON: $usersJson');

    if (usersJson == null || usersJson.isEmpty) {
      print('No users found in storage');
      return [];
    }

    try {
      final List<dynamic> decoded = jsonDecode(usersJson);
      final users = List<Map<String, dynamic>>.from(decoded);
      print('Successfully parsed ${users.length} users');
      return users;
    } catch (e) {
      print('Error parsing users JSON: $e');
      return [];
    }
  }

  Future<void> _saveUsers(List<Map<String, dynamic>> users) async {
    try {
      final usersJson = jsonEncode(users);
      await _prefs?.setString(_usersKey, usersJson);
      print('Successfully saved ${users.length} users to storage');
    } catch (e) {
      print('Error saving users: $e');
      throw Exception('Failed to save users: $e');
    }
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    await init();
    print('Inserting new user with email: ${user['email']}');

    final users = _getUsers();

    // Check if email already exists
    if (users.any((u) => u['email'] == user['email'])) {
      print('Email ${user['email']} already exists');
      throw Exception('Email already exists');
    }

    // Add new user
    user['id'] = users.isEmpty ? 1 : (users.last['id'] as int) + 1;
    user['createdAt'] = DateTime.now().toIso8601String();
    users.add(user);

    await _saveUsers(users);
    print('User inserted successfully with ID: ${user['id']}');
    return user['id'];
  }

  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    await init();
    print('Looking up user by email: $email');

    final users = _getUsers();
    try {
      final user = users.firstWhere((user) => user['email'] == email);
      print('Found user: ${user['fullName']}');
      return user;
    } catch (e) {
      print('No user found with email: $email');
      return null;
    }
  }

  Future<bool> authenticateUser(String email, String password) async {
    await init();
    print('Authenticating user: $email');

    final users = _getUsers();
    final isAuthenticated = users
        .any((user) => user['email'] == email && user['password'] == password);

    print(isAuthenticated
        ? 'Authentication successful'
        : 'Authentication failed');
    return isAuthenticated;
  }

  Future<void> updateUserProfile(
      String email, Map<String, dynamic> updates) async {
    await init();
    print('Updating profile for user: $email');

    final users = _getUsers();
    final index = users.indexWhere((user) => user['email'] == email);

    if (index != -1) {
      users[index] = {...users[index], ...updates};
      await _saveUsers(users);
      print('Profile updated successfully');
    } else {
      print('User not found for update');
      throw Exception('User not found');
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    await init();
    return _getUsers();
  }

  Future<bool> deleteUser(String email) async {
    await init();
    print('Deleting user: $email');

    final users = _getUsers();
    final initialLength = users.length;
    users.removeWhere((user) => user['email'] == email);

    if (users.length < initialLength) {
      await _saveUsers(users);
      print('User deleted successfully');
      return true;
    }
    print('User not found for deletion');
    return false;
  }

  Future<bool> updateUser(Map<String, dynamic> user) async {
    await init();
    print('Updating user: ${user['email']}');

    final users = _getUsers();
    final index = users.indexWhere((u) => u['email'] == user['email']);

    if (index != -1) {
      users[index] = user;
      await _saveUsers(users);
      print('User updated successfully');
      return true;
    }
    print('User not found for update');
    return false;
  }
}
