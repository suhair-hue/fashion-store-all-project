import 'package:flutter/foundation.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  // ─── Getters ───────────────────────────────────────────────────────────────
  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  // Subtotal (sum of all items)
  double get subtotal {
    double total = 0;
    for (var item in _items) {
      total += item.totalPrice;
    }
    return total;
  }

  // Shipping cost
  double get shipping {
    if (subtotal == 0) return 0;

    // FREE shipping if subtotal >= 5000
    if (subtotal >= 5000) return 0;

    return 300; // flat shipping fee
  }

  // Final total
  double get total {
    return subtotal + shipping;
  }

  // ─── Add to Cart ───────────────────────────────────────────────────────────
  void addToCart(Product product, String size, String color) {
    final idx = _items.indexWhere((i) =>
        i.product.id == product.id &&
        i.selectedSize == size &&
        i.selectedColor == color);

    if (idx != -1) {
      _items[idx].quantity++;
    } else {
      _items.add(CartItem(
        product: product,
        selectedSize: size,
        selectedColor: color,
      ));
    }

    notifyListeners();
  }

  // ─── Remove from Cart ──────────────────────────────────────────────────────
  void removeFromCart(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  // ─── Update Quantity ───────────────────────────────────────────────────────
  void updateQuantity(int index, int qty) {
    if (qty < 1) {
      removeFromCart(index);
      return;
    }

    _items[index].quantity = qty;
    notifyListeners();
  }

  // ─── Clear Cart ────────────────────────────────────────────────────────────
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}