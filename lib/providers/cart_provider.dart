import 'package:flutter/foundation.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get shipping {
    if (subtotal == 0) return 0;
    if (subtotal >= 5000) return 0;
    return 300;
  }

  double get total => subtotal + shipping;

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
