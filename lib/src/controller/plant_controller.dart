import 'package:get/get.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../model/plant.dart';
import 'package:uuid/uuid.dart';

class PlantController extends GetxController {
  final RxList<Plant> plants = <Plant>[].obs;
  final RxString searchQuery = ''.obs;
  final RxList<String> categories = <String>[].obs;
  final RxString selectedCategory = 'All'.obs;
  static const String _storageKey = 'plant_store_data_v3';
  bool _initialized = false;

  @override
  void onInit() {
    super.onInit();
    _initializeStorage();
  }

  void _initializeStorage() {
    if (_initialized) return;

    try {
      // Clear any corrupted data
      if (!_isValidStorageData()) {
        html.window.localStorage.remove(_storageKey);
      }

      _loadFromStorage();
      _initialized = true;

      // Set up listener for changes
      ever(plants, (_) {
        print('Plants list changed - saving to storage');
        _saveToStorage();
      });
    } catch (e) {
      print('Error initializing storage: $e');
      _loadDefaultPlants();
    }
  }

  bool _isValidStorageData() {
    try {
      final data = html.window.localStorage[_storageKey];
      if (data == null) return true;

      final decoded = json.decode(data);
      if (decoded is! List) return false;

      // Verify each plant object
      for (var item in decoded) {
        if (item is! Map<String, dynamic>) return false;
        if (!item.containsKey('id')) return false;
        if (!item.containsKey('name')) return false;
        if (!item.containsKey('price')) return false;
        if (!item.containsKey('category')) return false;
      }

      return true;
    } catch (e) {
      print('Invalid storage data: $e');
      return false;
    }
  }

  void _loadFromStorage() {
    try {
      final data = html.window.localStorage[_storageKey];
      print('Loading plants from storage...');

      if (data != null && data.isNotEmpty) {
        final List<dynamic> jsonData = json.decode(data);
        final loadedPlants = jsonData
            .map((item) => Plant.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        if (loadedPlants.isNotEmpty) {
          print(
              'Successfully loaded ${loadedPlants.length} plants from storage');
          plants.value = loadedPlants;
          updateCategories();
          return;
        }
      }

      _loadDefaultPlants();
    } catch (e) {
      print('Error loading from storage: $e');
      _loadDefaultPlants();
    }
  }

  void _loadDefaultPlants() {
    print('Loading default plants...');
    plants.value = _getDefaultPlants();
    updateCategories();
    _saveToStorage();
  }

  void _saveToStorage() {
    try {
      final jsonData =
          json.encode(plants.map((plant) => plant.toJson()).toList());
      html.window.localStorage[_storageKey] = jsonData;

      // Verify the save
      final savedData = html.window.localStorage[_storageKey];
      if (savedData == jsonData) {
        print('Successfully saved ${plants.length} plants to storage');
      } else {
        print('Warning: Storage verification failed');
      }
    } catch (e) {
      print('Error saving to storage: $e');
    }
  }

  List<Plant> _getDefaultPlants() => [
        Plant(
          id: const Uuid().v4(),
          name: 'Monstera Deliciosa',
          description: 'Tropical plant with unique leaf patterns',
          price: 49.99,
          imageUrl:
              'https://images.unsplash.com/photo-1614594975525-e45190c55d0b?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=500&q=80',
          category: 'Indoor',
        ),
        Plant(
          id: const Uuid().v4(),
          name: 'Garden Rose',
          description: 'Beautiful flowering plant for your garden',
          price: 24.99,
          imageUrl:
              'https://images.unsplash.com/photo-1589994160839-163cd867cfe8?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=500&q=80',
          category: 'Garden',
        ),
      ];

  Future<bool> addPlant(Plant plant) async {
    try {
      plants.add(plant);
      print('Added new plant: ${plant.name}');
      return true;
    } catch (e) {
      print('Error adding plant: $e');
      return false;
    }
  }

  Future<bool> updatePlant(Plant plant) async {
    try {
      final index = plants.indexWhere((p) => p.id == plant.id);
      if (index != -1) {
        plants[index] = plant;
        print('Updated plant: ${plant.name}');
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating plant: $e');
      return false;
    }
  }

  Future<bool> deletePlant(String id) async {
    try {
      plants.removeWhere((plant) => plant.id == id);
      print('Deleted plant with ID: $id');
      return true;
    } catch (e) {
      print('Error deleting plant: $e');
      return false;
    }
  }

  void toggleFavorite(int index) {
    if (index >= 0 && index < plants.length) {
      final plant = plants[index];
      plants[index] = plant.copyWith(isFavorite: !plant.isFavorite);
      print('Toggled favorite for plant: ${plant.name}');
    }
  }

  void updateCategories() {
    final Set<String> uniqueCategories =
        plants.map((plant) => plant.category).toSet();
    categories.value = ['All', ...uniqueCategories];
  }

  List<Plant> get filteredPlants {
    if (searchQuery.isEmpty && selectedCategory.value == 'All') {
      return plants;
    }
    return plants.where((plant) {
      bool matchesCategory = selectedCategory.value == 'All' ||
          plant.category == selectedCategory.value;
      bool matchesSearch = searchQuery.isEmpty ||
          plant.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          plant.description
              .toLowerCase()
              .contains(searchQuery.value.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void updateSelectedCategory(String category) {
    selectedCategory.value = category;
  }
}
