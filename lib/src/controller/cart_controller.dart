import 'package:get/get.dart';
import '../model/cart_item.dart';

class CartController extends GetxController {
  final RxList<CartItem> _items = <CartItem>[].obs;
  final RxDouble _shippingCost = 50.0.obs;

  List<CartItem> get items => _items.toList();
  double get shippingCost => _shippingCost.value;

  double get subtotal =>
      _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get total => subtotal + shippingCost;

  void addItem(CartItem item) {
    if (item.quantity <= 0) return;

    final existingIndex = _items.indexWhere((i) => i.name == item.name);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
      _items.refresh();
    } else {
      _items.add(item);
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
    }
  }

  void updateQuantity(int index, int quantity) {
    if (index >= 0 && index < _items.length && quantity > 0) {
      _items[index].quantity = quantity;
      _items.refresh();
    }
  }

  void clearCart() {
    _items.clear();
  }

  void addToCart(CartItem item) {
    _items.add(item);
  }

  void removeFromCart(int index) {
    _items.removeAt(index);
  }
}
