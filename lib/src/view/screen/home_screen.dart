import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:e_commerce_flutter/src/view/screen/product_detail_screen.dart';
import 'package:e_commerce_flutter/src/controller/user_auth_controller.dart';
import 'package:e_commerce_flutter/src/controller/plant_controller.dart';
import 'package:e_commerce_flutter/src/model/plant.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'package:e_commerce_flutter/src/controller/user_controller.dart';

class HomeScreen extends StatelessWidget {
  final PlantController plantController = Get.find<PlantController>();
  final UserController userController = Get.put(UserController());

  HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Initialize controllers in build method if not already initialized
    if (!Get.isRegistered<PlantController>()) {
      Get.put(PlantController());
    }
    if (!Get.isRegistered<UserAuthController>()) {
      Get.put(UserAuthController());
    }

    final userAuthController = Get.find<UserAuthController>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Container(
          height: 45,
          child: TextField(
            onChanged: (value) => plantController.updateSearchQuery(value),
            decoration: InputDecoration(
              hintText: 'Search plants...',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF184A2C)),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF184A2C)),
              ),
              suffixIcon: Obx(
                () => plantController.searchQuery.value.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          plantController.updateSearchQuery('');
                          FocusScope.of(context).unfocus();
                        },
                        color: const Color(0xFF184A2C),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () => Get.toNamed('/profile'),
              child: Obx(() {
                final imagePath = userController.userImage.value;
                return CircleAvatar(
                  backgroundColor: const Color(0xFF184A2C),
                  backgroundImage: imagePath.isNotEmpty
                      ? kIsWeb
                          ? NetworkImage(imagePath) as ImageProvider
                          : FileImage(File(imagePath))
                      : null,
                  child: imagePath.isEmpty
                      ? const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                );
              }),
            ),
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF7F5F8),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Let's find your plants!",
                          style: TextStyle(
                            color: Color(0xFF184A2C),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Obx(
                          () => Text(
                            "Welcome back, ${Get.find<UserAuthController>().userName}!",
                            style: const TextStyle(
                              color: Color(0xFF5F927A),
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildChip('All', plantController),
                _buildChip('Indoor', plantController),
                _buildChip('Outdoor', plantController),
                _buildChip('Garden', plantController),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Obx(() {
              final plants = plantController.filteredPlants;
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.68,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: plants.length,
                itemBuilder: (context, index) {
                  final plant = plants[index];
                  return _buildPlantCard(plant, context);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, PlantController controller) {
    return Obx(() {
      final isSelected = controller.selectedCategory.value == label;
      return GestureDetector(
        onTap: () => controller.updateSelectedCategory(label),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          child: Chip(
            label: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF184A2C),
              ),
            ),
            backgroundColor:
                isSelected ? const Color(0xFF184A2C) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        ),
      );
    });
  }

  Widget _buildPlantCard(Plant plant, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                ProductDetailScreen(
              name: plant.name,
              price: plant.price,
              image: plant.imageUrl,
              description: plant.description,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeOutCubic;
              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Expanded(
              flex: 5,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Image.network(
                  plant.imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plant.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF184A2C),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plant.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rs${plant.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF184A2C),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F3E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            plant.category,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF184A2C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
