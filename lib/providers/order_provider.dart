import 'package:flutter/foundation.dart';
import '../models/order_model.dart';
import '../models/product.dart';

class OrderProvider extends ChangeNotifier {
  final List<Order> _orders = [];

  List<Order> get orders => List.unmodifiable(_orders.reversed.toList());

  int get orderCount => _orders.length;

  // ─── Place Order ───────────────────────────────────────────────────────────
  String placeOrder({
    required List<CartItem> cartItems,
    required String name,
    required String phone,
    required String address,
    required String city,
    required String zip,
    required String paymentMethod,
    required double subtotal,
    required double shipping,
    required double total,
  }) {
    final orderId =
        'ORD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final orderItems = cartItems
        .map((ci) => OrderItem(
              product: ci.product,
              selectedSize: ci.selectedSize,
              selectedColor: ci.selectedColor,
              quantity: ci.quantity,
              totalPrice: ci.totalPrice,
            ))
        .toList();

    final order = Order(
      id: orderId,
      items: orderItems,
      name: name,
      phone: phone,
      address: address,
      city: city,
      zip: zip,
      paymentMethod: paymentMethod,
      subtotal: subtotal,
      shipping: shipping,
      total: total,
      placedAt: DateTime.now(),
    );

    _orders.add(order);
    notifyListeners();
    return orderId;
  }
}
