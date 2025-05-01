import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../model/plant.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';
import 'dart:html' as html;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static SharedPreferences? _prefs;
  static const String _usersKey = 'users_data';
  static const String _storageKey = 'plant_store_data_v3';
  bool _initialized = false;
  static Database? _database;

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

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'planttopia.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE plants(
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        price REAL NOT NULL,
        imageUrl TEXT NOT NULL,
        category TEXT NOT NULL,
        isFavorite INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Insert default plants
    await db.insert('plants', {
      'id': '1',
      'name': 'Monstera Deliciosa',
      'description': 'Tropical plant with unique leaf patterns',
      'price': 49.99,
      'imageUrl':
          'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=500&q=80',
      'category': 'Indoor',
      'isFavorite': 0,
    });
  }

  Future<List<Plant>> getAllPlants() async {
    try {
      if (kIsWeb) {
        final data = html.window.localStorage[_storageKey];
        if (data != null && data.isNotEmpty) {
          final List<dynamic> jsonData = json.decode(data);
          return jsonData
              .map((item) => Plant.fromJson(Map<String, dynamic>.from(item)))
              .toList();
        }
      }
      return _getDefaultPlants();
    } catch (e) {
      print('Error getting plants: $e');
      return _getDefaultPlants();
    }
  }

  Future<void> insertPlant(Plant plant) async {
    try {
      if (kIsWeb) {
        final plants = await getAllPlants();
        plants.add(plant);
        await _savePlants(plants);
      }
    } catch (e) {
      print('Error inserting plant: $e');
      throw e;
    }
  }

  Future<void> updatePlant(Plant plant) async {
    try {
      if (kIsWeb) {
        final plants = await getAllPlants();
        final index = plants.indexWhere((p) => p.id == plant.id);
        if (index != -1) {
          plants[index] = plant;
          await _savePlants(plants);
        }
      }
    } catch (e) {
      print('Error updating plant: $e');
      throw e;
    }
  }

  Future<void> deletePlant(String id) async {
    try {
      if (kIsWeb) {
        final plants = await getAllPlants();
        plants.removeWhere((plant) => plant.id == id);
        await _savePlants(plants);
      }
    } catch (e) {
      print('Error deleting plant: $e');
      throw e;
    }
  }

  Future<void> updateFavorite(String id, bool isFavorite) async {
    try {
      if (kIsWeb) {
        final plants = await getAllPlants();
        final index = plants.indexWhere((p) => p.id == id);
        if (index != -1) {
          plants[index] = plants[index].copyWith(isFavorite: isFavorite);
          await _savePlants(plants);
        }
      }
    } catch (e) {
      print('Error updating favorite: $e');
      throw e;
    }
  }

  Future<void> _savePlants(List<Plant> plants) async {
    if (kIsWeb) {
      final jsonData =
          json.encode(plants.map((plant) => plant.toJson()).toList());
      html.window.localStorage[_storageKey] = jsonData;
    }
  }

  List<Plant> _getDefaultPlants() => [
        Plant(
          id: const Uuid().v4(),
          name: 'Monstera Deliciosa',
          description: 'Tropical plant with unique leaf patterns.',
          price: 49.99,
          imageUrl:
              'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=500&q=80',
          category: 'Indoor',
        ),
        Plant(
          id: const Uuid().v4(),
          name: 'Garden Rose',
          description: 'Beautiful flowering plant for your garden.',
          price: 24.99,
          imageUrl:
              'https://images.unsplash.com/photo-1589994160839-163cd867cfe8?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=500&q=80',
          category: 'Garden',
        ),
        Plant(
          id: const Uuid().v4(),
          name: 'Succulent Aloe Vera',
          description:
              'Known for its healing properties, great for indoor spaces.',
          price: 15.99,
          imageUrl:
              'https://images.unsplash.com/photo-1632380211596-b96123618ca8?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8YWxvZSUyMHZlcmF8ZW58MHx8MHx8fDA%3D',
          category: 'Indoor',
        ),
        Plant(
          id: const Uuid().v4(),
          name: 'Cactus',
          description: 'Low-maintenance desert plant perfect for sunny spots.',
          price: 9.99,
          imageUrl:
              'https://images.unsplash.com/photo-1459411552884-841db9b3cc2a?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Nnx8Q2FjdHVzfGVufDB8fDB8fHww',
          category: 'Indoor',
        ),
        Plant(
          id: const Uuid().v4(),
          name: 'Basil',
          description: 'A herbaceous plant that adds flavor to your dishes.',
          price: 4.99,
          imageUrl:
              'https://images.unsplash.com/photo-1610970884954-4d376ecba53f?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8QmFzaWx8ZW58MHx8MHx8fDA%3D',
          category: 'Indoor',
        ),
        Plant(
          id: const Uuid().v4(),
          name: 'Orchid',
          description: 'Elegant and exotic flowers that add color to any room.',
          price: 39.99,
          imageUrl:
              'https://images.unsplash.com/photo-1562133558-4a3906179c67?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Nnx8T3JjaGlkfGVufDB8fDB8fHww',
          category: 'Indoor',
        ),
        Plant(
          id: const Uuid().v4(),
          name: 'Lavender',
          description: 'Lavender is a fragrant plant with calming effects.',
          price: 19.99,
          imageUrl:
              'https://images.unsplash.com/photo-1477511801984-4ad318ed9846?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8TGF2ZW5kZXJ8ZW58MHx8MHx8fDA%3D',
          category: 'Garden',
        ),
        Plant(
          id: const Uuid().v4(),
          name: 'Spider Plant',
          description: 'An easy-care plant that purifies indoor air.',
          price: 14.99,
          imageUrl:
              'https://images.unsplash.com/photo-1668117653442-dd03862e957f?w=500&auto=format&fit=crop&q=60&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OHx8U3BpZGVyJTIwUGxhbnR8ZW58MHx8MHx8fDA%3D',
          category: 'Indoor',
        ),
      ];

  Future<List<Plant>> searchPlants(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'plants',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) {
      return Plant(
        id: maps[i]['id'],
        name: maps[i]['name'],
        description: maps[i]['description'],
        price: maps[i]['price'],
        imageUrl: maps[i]['imageUrl'],
        category: maps[i]['category'],
        isFavorite: maps[i]['isFavorite'] == 1,
      );
    });
  }

  Future<List<Plant>> getPlantsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'plants',
      where: 'category = ?',
      whereArgs: [category],
    );
    return List.generate(maps.length, (i) {
      return Plant(
        id: maps[i]['id'],
        name: maps[i]['name'],
        description: maps[i]['description'],
        price: maps[i]['price'],
        imageUrl: maps[i]['imageUrl'],
        category: maps[i]['category'],
        isFavorite: maps[i]['isFavorite'] == 1,
      );
    });
  }
}
