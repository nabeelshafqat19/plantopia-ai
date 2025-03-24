import 'package:flutter/material.dart';
import 'package:e_commerce_flutter/core/app_data.dart';
import 'package:e_commerce_flutter/core/app_color.dart';
import 'package:e_commerce_flutter/src/controller/product_controller.dart';
import 'package:e_commerce_flutter/src/view/widget/product_grid_view.dart';
import 'package:e_commerce_flutter/src/view/widget/list_item_selector.dart';
import 'package:get/get.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ProductController());
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _topCategoriesListView(),
            const SizedBox(height: 10),
            Expanded(
              child: Obx(() => ProductGridView(
                items: controller.filteredProducts,
                isPriceOff: controller.isPriceOff,
                likeButtonPressed: controller.isFavorite,
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topCategoriesListView() {
    final controller = Get.find<ProductController>();
    return SizedBox(
      height: 80,
      child: ListItemSelector(
        categories: controller.categories,
        onItemPressed: (index) => controller.filterItemsByCategory(index),
      ),
    );
  }
}