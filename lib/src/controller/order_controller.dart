import 'package:get/get.dart';
import 'dart:convert';
import 'dart:html' as html;
import '../model/order.dart';

class OrderController extends GetxController {
  final RxList<Order> orders = <Order>[].obs;
  static const String _storageKey = 'orders_data';
  bool _initialized = false;

  @override
  void onInit() {
    super.onInit();
    _initializeStorage();
  }

  void _initializeStorage() {
    if (_initialized) return;

    try {
      _loadFromStorage();
      _initialized = true;

      // Set up listener for changes
      ever(orders, (_) {
        _saveToStorage();
      });
    } catch (e) {
      print('Error initializing orders storage: $e');
    }
  }

  void _loadFromStorage() {
    try {
      final data = html.window.localStorage[_storageKey];
      if (data != null) {
        final List<dynamic> decoded = json.decode(data);
        orders.assignAll(
          decoded.map((item) => Order.fromJson(item)).toList(),
        );
      }
    } catch (e) {
      print('Error loading orders from storage: $e');
    }
  }

  void _saveToStorage() {
    try {
      final String encoded =
          json.encode(orders.map((o) => o.toJson()).toList());
      html.window.localStorage[_storageKey] = encoded;
    } catch (e) {
      print('Error saving orders to storage: $e');
    }
  }

  Future<bool> addOrder(Order order) async {
    try {
      orders.add(order);
      return true;
    } catch (e) {
      print('Error adding order: $e');
      return false;
    }
  }

  Future<bool> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    try {
      final orderIndex = orders.indexWhere((o) => o.id == orderId);
      if (orderIndex != -1) {
        final order = orders[orderIndex];
        orders[orderIndex] = Order(
          id: order.id,
          userId: order.userId,
          userName: order.userName,
          userEmail: order.userEmail,
          address: order.address,
          city: order.city,
          state: order.state,
          zipCode: order.zipCode,
          items: order.items,
          subtotal: order.subtotal,
          shippingCost: order.shippingCost,
          total: order.total,
          orderDate: order.orderDate,
          status: newStatus,
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  List<Order> getOrdersByStatus(OrderStatus status) {
    return orders.where((order) => order.status == status).toList();
  }
}
