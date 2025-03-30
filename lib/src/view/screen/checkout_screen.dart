import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:e_commerce_flutter/src/controller/cart_controller.dart';
import 'package:e_commerce_flutter/src/controller/user_auth_controller.dart';
import 'package:e_commerce_flutter/src/controller/order_controller.dart';
import 'package:e_commerce_flutter/src/model/order.dart';
import 'dart:html' as html;

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({Key? key}) : super(key: key);

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final CartController cartController = Get.find<CartController>();
  final UserAuthController userController = Get.find<UserAuthController>();
  final OrderController orderController = Get.find<OrderController>();
  bool _isProcessing = false;

  void _sendEmailViaMailto() {
    final orderItems = cartController.items.map((item) {
      return '''
${item.name} x ${item.quantity}
Price per item: ₨${item.price}
Subtotal: ₨${(item.price * item.quantity).toStringAsFixed(2)}''';
    }).join('\n');

    final body = '''
Order Details:

Customer Information:
Name: ${userController.userName.value}

Shipping Address:
${_addressController.text}
${_cityController.text}, ${_stateController.text} ${_zipController.text}

Order Summary:
$orderItems

Shipping Cost: ₨${cartController.shippingCost}
Total Amount: ₨${cartController.total.toStringAsFixed(2)}
''';

    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'hopnesscrew@gmail.com',
      query: encodeQueryParameters(<String, String>{
        'subject': 'New Order from ${userController.userName.value}',
        'body': body,
      }),
    );

    html.window.location.href = emailLaunchUri.toString();
  }

  String? encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
            '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  Future<void> _processCheckout() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      // Create new order
      final order = Order(
        userId: userController.userEmail.value,
        userName: userController.userName.value,
        userEmail: userController.userEmail.value,
        address: _addressController.text,
        city: _cityController.text,
        state: _stateController.text,
        zipCode: _zipController.text,
        items: cartController.items,
        subtotal: cartController.subtotal,
        shippingCost: cartController.shippingCost,
        total: cartController.total,
      );

      // Add order to storage
      final success = await orderController.addOrder(order);

      if (success) {
        // Show success message
        Get.snackbar(
          'Order Placed',
          'Your order has been placed successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: const Duration(seconds: 5),
        );

        // Clear cart and navigate home after delay
        Future.delayed(const Duration(seconds: 2), () {
          cartController.clearCart();
          Get.offNamed('/home');
        });
      } else {
        throw Exception('Failed to place order');
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to process checkout: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Shipping Address',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: 'Street Address',
                  labelStyle: const TextStyle(color: Color(0xFF184A2C)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF184A2C)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF184A2C)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF184A2C), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your street address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  labelStyle: const TextStyle(color: Color(0xFF184A2C)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF184A2C)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF184A2C)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF184A2C), width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your city';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _stateController,
                      decoration: InputDecoration(
                        labelText: 'State',
                        labelStyle: const TextStyle(color: Color(0xFF184A2C)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF184A2C)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF184A2C)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF184A2C), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your state';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _zipController,
                      decoration: InputDecoration(
                        labelText: 'ZIP Code',
                        labelStyle: const TextStyle(color: Color(0xFF184A2C)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF184A2C)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFF184A2C)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFF184A2C), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter ZIP code';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Obx(() => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...cartController.items
                          .map((item) => ListTile(
                                title: Text(item.name),
                                subtitle:
                                    Text('${item.quantity}x @ ₨${item.price}'),
                                trailing: Text(
                                    '₨${(item.price * item.quantity).toStringAsFixed(2)}'),
                              ))
                          .toList(),
                      const Divider(),
                      ListTile(
                        title: const Text('Shipping'),
                        trailing: Text('₨${cartController.shippingCost}'),
                      ),
                      ListTile(
                        title: const Text(
                          'Total',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Text(
                          '₨${cartController.total.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  )),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isProcessing ? null : _processCheckout,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: const Color(0xFF184A2C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Place Order',
                        style: TextStyle(fontSize: 18),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }
}
