import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../utils/dummy_data.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference get _productsRef => _db.collection('products');

  // Stream of all products from Firestore
  Stream<List<Product>> getProducts() {
    return _productsRef.snapshots().map((snapshot) {
      print('DEBUG: Fetched ${snapshot.docs.length} products from Firestore');
      return snapshot.docs.map((doc) {
        try {
          return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        } catch (e) {
          print('DEBUG: Error parsing product ${doc.id}: $e');
          rethrow;
        }
      }).toList();
    });
  }

  // Stream of products by category from Firestore
  Stream<List<Product>> getProductsByCategory(String category) {
    if (category == 'All') return getProducts();

    return _productsRef
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      print('DEBUG: Fetched ${snapshot.docs.length} products for category "$category"');
      return snapshot.docs.map((doc) {
        return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Stream of featured products from Firestore
  Stream<List<Product>> getFeaturedProducts() {
    return _productsRef
        .where('isFeatured', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Static method to upload dummy data to Firestore
  // This helps "link" the dummy_data.dart content to the Firebase Console
  static Future<void> uploadDummyData() async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    for (var product in DummyData.products) {
      final docRef = firestore.collection('products').doc(product.id);
      batch.set(docRef, product.toMap());
    }

    await batch.commit();
  }
}
