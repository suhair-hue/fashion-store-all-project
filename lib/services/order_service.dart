import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? '';

  // ─── Get Orders Stream ─────────────────────────────────────────────────────
  /// Returns a real-time stream of all orders placed by the current authenticated user,
  /// sorted by creation time descending.
  Stream<QuerySnapshot<Map<String, dynamic>>> getOrdersStream() {
    if (_uid.isEmpty) {
      return const Stream.empty();
    }
    return _db
        .collection('orders')
        .where('userId', isEqualTo: _uid)
        .snapshots();
  }

  // ─── Cancel Order ──────────────────────────────────────────────────────────
  /// Updates the order document to a "Cancelled" status with audit timestamps
  /// and cancellation reason.
  Future<void> cancelOrder(String orderId, String reason) async {
    await _db.collection('orders').doc(orderId).update({
      'status': 'Cancelled',
      'cancelledAt': FieldValue.serverTimestamp(),
      'cancellationReason': reason,
      'paymentStatus': 'refunded_pending', // Standard audit state update
    });
  }

  // ─── Place Order → saves to Firebase Firestore ────────────────────────────
  Future<String> placeOrder({
    required List<CartItem> items,
    required String name,
    required String phone,
    required String address,
    required String city,
    required String zip,
    required String paymentMethod,
    required double total,
  }) async {
    // Calculate subtotal and shipping from items
    final subtotal = items.fold(0.0, (sum, item) => sum + item.totalPrice);
    final shipping = total - subtotal;

    final orderRef = _db.collection('orders').doc();

    final orderData = {
      'orderId': orderRef.id,
      'userId': _uid,
      'items': items
          .map((item) => {
                'productId':    item.product.id,
                'productName':  item.product.name,
                'productImage': item.product.imageUrl,
                'price':        item.product.price,
                'quantity':     item.quantity,
                'size':         item.selectedSize,
                'color':        item.selectedColor,
                'subtotal':     item.totalPrice,
              })
          .toList(),
      'deliveryDetails': {
        'name':    name,
        'phone':   phone,
        'address': address,
        'city':    city,
        'zip':     zip,
      },
      'paymentMethod': paymentMethod,
      'subtotal':      subtotal,
      'shipping':      shipping,
      'total':         total,
      'status':        'Order Placed', // Realigned to standard 'Order Placed' status
      'createdAt':     FieldValue.serverTimestamp(),
      'cancelledAt':   null,
      'cancellationReason': null,
    };

    await orderRef.set(orderData);
    return orderRef.id;
  }
}
