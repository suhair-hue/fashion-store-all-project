import '../models/product.dart';

// ─── Order Status ─────────────────────────────────────────────────────────────
enum OrderStatus { processing, shipped, delivered, cancelled }

extension OrderStatusExt on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.processing: return 'Processing';
      case OrderStatus.shipped:    return 'Shipped';
      case OrderStatus.delivered:  return 'Delivered';
      case OrderStatus.cancelled:  return 'Cancelled';
    }
  }
}

// ─── Order Item ───────────────────────────────────────────────────────────────
class OrderItem {
  final Product product;
  final String selectedSize;
  final String selectedColor;
  final int quantity;
  final double totalPrice;

  OrderItem({
    required this.product,
    required this.selectedSize,
    required this.selectedColor,
    required this.quantity,
    required this.totalPrice,
  });
}

// ─── Order ────────────────────────────────────────────────────────────────────
class Order {
  final String id;
  final List<OrderItem> items;
  final String name;
  final String phone;
  final String address;
  final String city;
  final String zip;
  final String paymentMethod;
  final double subtotal;
  final double shipping;
  final double total;
  final DateTime placedAt;
  OrderStatus status;

  Order({
    required this.id,
    required this.items,
    required this.name,
    required this.phone,
    required this.address,
    required this.city,
    required this.zip,
    required this.paymentMethod,
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.placedAt,
    this.status = OrderStatus.processing,
  });
}
