import 'package:get/get.dart';
import '../model/plant.dart';
import '../data/database_helper.dart';
import 'package:uuid/uuid.dart';

class PlantController extends GetxController {
  final RxList<Plant> plants = <Plant>[].obs;
  final RxString searchQuery = ''.obs;
  final RxList<String> categories = <String>[].obs;
  final RxString selectedCategory = 'All'.obs;
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void onInit() {
    super.onInit();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    try {
      final loadedPlants = await _dbHelper.getAllPlants();
      plants.value = loadedPlants;
      updateCategories();
      print('Successfully loaded ${loadedPlants.length} plants from database');
    } catch (e) {
      print('Error loading plants: $e');
    }
  }

  Future<bool> addPlant(Plant plant) async {
    try {
      await _dbHelper.insertPlant(plant);
      await _loadPlants(); // Reload plants from database
      print('Added new plant: ${plant.name}');
      return true;
    } catch (e) {
      print('Error adding plant: $e');
      return false;
    }
  }

  Future<bool> updatePlant(Plant plant) async {
    try {
      await _dbHelper.updatePlant(plant);
      await _loadPlants(); // Reload plants from database
      print('Updated plant: ${plant.name}');
      return true;
    } catch (e) {
      print('Error updating plant: $e');
      return false;
    }
  }

  Future<bool> deletePlant(String id) async {
    try {
      await _dbHelper.deletePlant(id);
      await _loadPlants(); // Reload plants from database
      print('Deleted plant with ID: $id');
      return true;
    } catch (e) {
      print('Error deleting plant: $e');
      return false;
    }
  }

  void toggleFavorite(String id) async {
    try {
      final index = plants.indexWhere((plant) => plant.id == id);
      if (index >= 0) {
        final plant = plants[index];
        await _dbHelper.updateFavorite(id, !plant.isFavorite);
        await _loadPlants(); // Reload plants from database
        print('Toggled favorite for plant: ${plant.name}');
      }
    } catch (e) {
      print('Error toggling favorite: $e');
    }
  }

  void updateCategories() {
    final Set<String> uniqueCategories =
        plants.map((plant) => plant.category).toSet();
    categories.value = ['All', ...uniqueCategories];
  }

  void updateSearchQuery(String query) {
    searchQuery.value = query;
  }

  void updateSelectedCategory(String category) {
    selectedCategory.value = category;
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
          plant.description.toLowerCase().contains(searchQuery.value.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }
}
