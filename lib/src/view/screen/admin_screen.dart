import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/user_auth_controller.dart';
import '../../controller/order_controller.dart';
import '../../controller/plant_controller.dart';
import '../../model/order.dart';
import '../../model/plant.dart';
import 'package:uuid/uuid.dart';
import '../../data/database_helper.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final UserAuthController _userController = Get.find<UserAuthController>();
  final OrderController _orderController = Get.find<OrderController>();
  final PlantController _plantController = Get.find<PlantController>();
  late TabController _tabController;
  final _dbHelper = DatabaseHelper();
  final RxBool isLoading = false.obs;
  final RxList<Map<String, dynamic>> users = <Map<String, dynamic>>[].obs;
  final RxInt currentTabIndex = 0.obs;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _plantNameController = TextEditingController();
  final _plantDescriptionController = TextEditingController();
  final _plantPriceController = TextEditingController();
  final _plantImageUrlController = TextEditingController();
  String _selectedCategory = 'Indoor';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      currentTabIndex.value = _tabController.index;
    });
    _loadUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _plantNameController.dispose();
    _plantDescriptionController.dispose();
    _plantPriceController.dispose();
    _plantImageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final loadedUsers = await _dbHelper.getAllUsers();
      users.assignAll(loadedUsers);
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load users: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // Order management methods
  Future<void> _updateOrderStatus(Order order, OrderStatus newStatus) async {
    try {
      final success =
          await _orderController.updateOrderStatus(order.id, newStatus);
      if (success) {
        Get.snackbar(
          'Success',
          'Order status updated successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        throw Exception('Failed to update order status');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update order status: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  // User management methods
  void _showAddUserDialog([Map<String, dynamic>? user]) {
    if (user != null) {
      _nameController.text = user['fullName'];
      _emailController.text = user['email'];
      _passwordController.text = user['password'];
    } else {
      _nameController.clear();
      _emailController.clear();
      _passwordController.text = '';
    }

    Get.dialog(
      AlertDialog(
        title: Text(user == null ? 'Add User' : 'Edit User'),
        content: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter an email';
                  if (!value!.contains('@'))
                    return 'Please enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Please enter a password';
                  if (value!.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final userData = {
                  'fullName': _nameController.text,
                  'email': _emailController.text,
                  'password': _passwordController.text,
                };

                try {
                  if (user == null) {
                    await _dbHelper.insertUser(userData);
                  } else {
                    await _dbHelper.updateUser(userData);
                  }
                  await _loadUsers();
                  Get.back();
                  Get.snackbar(
                    'Success',
                    user == null
                        ? 'User added successfully'
                        : 'User updated successfully',
                    backgroundColor: Colors.green,
                    colorText: Colors.white,
                  );
                } catch (e) {
                  Get.snackbar(
                    'Error',
                    'Failed to ${user == null ? 'add' : 'update'} user: $e',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              }
            },
            child: Text(user == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${user['fullName']}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbHelper.deleteUser(user['email']);
        await _loadUsers();
        Get.snackbar(
          'Success',
          'User deleted successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to delete user: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  // Item management methods
  void _showAddItemDialog([Plant? plant]) {
    if (plant != null) {
      _plantNameController.text = plant.name;
      _plantDescriptionController.text = plant.description;
      _plantPriceController.text = plant.price.toString();
      _plantImageUrlController.text = plant.imageUrl;
      _selectedCategory = plant.category;
    } else {
      _plantNameController.clear();
      _plantDescriptionController.clear();
      _plantPriceController.clear();
      _plantImageUrlController.clear();
      _selectedCategory = 'Indoor';
    }

    Get.dialog(
      AlertDialog(
        title: Text(plant == null ? 'Add Item' : 'Edit Item'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _plantNameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _plantDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter a description'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _plantPriceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    border: OutlineInputBorder(),
                    prefixText: 'Rs',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Please enter a price';
                    if (double.tryParse(value!) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _plantImageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter an image URL'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Indoor', 'Outdoor', 'Garden']
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _selectedCategory = value;
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF184A2C),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final newPlant = Plant(
                  id: plant?.id ?? const Uuid().v4(),
                  name: _plantNameController.text,
                  description: _plantDescriptionController.text,
                  price: double.parse(_plantPriceController.text),
                  imageUrl: _plantImageUrlController.text,
                  category: _selectedCategory,
                );

                try {
                  bool success;
                  if (plant == null) {
                    success = await _plantController.addPlant(newPlant);
                  } else {
                    success = await _plantController.updatePlant(newPlant);
                  }

                  if (success) {
                    Get.back();
                    Get.snackbar(
                      'Success',
                      plant == null
                          ? 'Item added successfully'
                          : 'Item updated successfully',
                      backgroundColor: Colors.green,
                      colorText: Colors.white,
                    );
                  } else {
                    throw Exception('Operation failed');
                  }
                } catch (e) {
                  Get.snackbar(
                    'Error',
                    'Failed to ${plant == null ? 'add' : 'update'} item: $e',
                    backgroundColor: Colors.red,
                    colorText: Colors.white,
                  );
                }
              }
            },
            child: Text(plant == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePlant(Plant plant) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${plant.name}?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final success = await _plantController.deletePlant(plant.id);
        if (success) {
          Get.snackbar(
            'Success',
            'Plant deleted successfully',
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
        } else {
          throw Exception('Failed to delete plant');
        }
      } catch (e) {
        Get.snackbar(
          'Error',
          'Failed to delete plant: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF184A2C),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Plants'),
            Tab(text: 'Users'),
            Tab(text: 'Orders'),
            Tab(text: 'Analytics'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
        ),
      ),
      floatingActionButton: Obx(() => currentTabIndex.value == 0
          ? FloatingActionButton(
              onPressed: () => _showAddItemDialog(),
              backgroundColor: const Color(0xFF184A2C),
              child: const Icon(Icons.add),
            )
          : const SizedBox.shrink()),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Plants Tab
          _buildPlantsTab(),
          // Users Tab
          _buildUsersTab(),
          // Orders Tab
          _buildOrdersTab(),
          // Analytics Tab
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildPlantsTab() {
    return Obx(() => GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.68,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: _plantController.plants.length,
          itemBuilder: (context, index) {
            final plant = _plantController.plants[index];
            return _buildPlantCard(plant);
          },
        ));
  }

  Widget _buildPlantCard(Plant plant) {
    return Card(
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
                        'Rs${plant.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF184A2C),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
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
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            onPressed: () => _showAddItemDialog(plant),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.delete, size: 20),
                            onPressed: () => _deletePlant(plant),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Manage Users',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF184A2C),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showAddUserDialog(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF184A2C),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add User'),
              ),
            ],
          ),
        ),
        Expanded(
          child: Obx(
            () => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return Card(
                  child: ListTile(
                    title: Text(user['fullName']),
                    subtitle: Text(user['email']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _showAddUserDialog(user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _deleteUser(user),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Text(
            'Manage Orders',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF184A2C),
            ),
          ),
        ),
        Expanded(
          child: Obx(
            () => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orderController.orders.length,
              itemBuilder: (context, index) {
                final order = _orderController.orders[index];
                return _buildOrderCard(order);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order #${order.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    order.status.toString().split('.').last.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Customer: ${order.userName}'),
            Text('Email: ${order.userEmail}'),
            Text(
                'Address: ${order.address}, ${order.city}, ${order.state} ${order.zipCode}'),
            const Divider(),
            ...order.items.map(
              (item) => ListTile(
                dense: true,
                title: Text(item.name),
                subtitle: Text(
                    '₨${item.price.toStringAsFixed(2)} x ${item.quantity}'),
                trailing: Text(
                  '₨${(item.price * item.quantity).toStringAsFixed(2)}',
                ),
              ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₨${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (order.status != OrderStatus.delivered &&
                    order.status != OrderStatus.cancelled)
                  ElevatedButton(
                    onPressed: () {
                      if (order.status == OrderStatus.pending) {
                        _updateOrderStatus(order, OrderStatus.processing);
                      } else if (order.status == OrderStatus.processing) {
                        _updateOrderStatus(order, OrderStatus.shipped);
                      } else if (order.status == OrderStatus.shipped) {
                        _updateOrderStatus(order, OrderStatus.delivered);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF184A2C),
                    ),
                    child: Text(
                      order.status == OrderStatus.pending
                          ? 'Process'
                          : order.status == OrderStatus.processing
                              ? 'Ship'
                              : 'Mark Delivered',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.shipped:
        return Colors.purple;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  Widget _buildAnalyticsTab() {
    // Implementation of _buildAnalyticsTab method
    return Container(); // Placeholder, actual implementation needed
  }
}
