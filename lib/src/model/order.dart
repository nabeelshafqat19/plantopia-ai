import 'package:uuid/uuid.dart';
import 'cart_item.dart';

enum OrderStatus { pending, processing, shipped, delivered, cancelled }

class Order {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final List<CartItem> items;
  final double subtotal;
  final double shippingCost;
  final double total;
  final DateTime orderDate;
  OrderStatus status;

  Order({
    String? id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.items,
    required this.subtotal,
    required this.shippingCost,
    required this.total,
    DateTime? orderDate,
    this.status = OrderStatus.pending,
  })  : id = id ?? const Uuid().v4(),
        orderDate = orderDate ?? DateTime.now();

  // Create an Order from JSON
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userEmail: json['userEmail'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipCode: json['zipCode'] as String,
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      shippingCost: (json['shippingCost'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      orderDate: DateTime.parse(json['orderDate'] as String),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => OrderStatus.pending,
      ),
    );
  }

  // Convert Order to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'address': address,
      'city': city,
      'state': state,
      'zipCode': zipCode,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'shippingCost': shippingCost,
      'total': total,
      'orderDate': orderDate.toIso8601String(),
      'status': status.toString(),
    };
  }
}
