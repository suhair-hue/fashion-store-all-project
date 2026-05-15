// ─── Product Model ────────────────────────────────────────────────────────────
class Product {
  final String id;
  final String name;
  final String brand;
  final String category;
  final double price;
  final double? originalPrice; // for sale items
  final String imageUrl;
  final String description;
  final List<String> sizes;
  final List<String> colors;
  final double rating;
  final int reviewCount;
  final bool isFeatured;

  const Product({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.price,
    this.originalPrice,
    required this.imageUrl,
    required this.description,
    required this.sizes,
    required this.colors,
    this.rating = 4.5,
    this.reviewCount = 100,
    this.isFeatured = false,
  });

  bool get isOnSale => originalPrice != null && originalPrice! > price;
  int get discountPercent => isOnSale
      ? (((originalPrice! - price) / originalPrice!) * 100).round()
      : 0;

  factory Product.fromMap(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: (data['name'] ?? '').toString(),
      brand: (data['brand'] ?? '').toString(),
      category: (data['category'] ?? '').toString(),
      price: double.tryParse((data['price'] ?? 0).toString()) ?? 0.0,
      originalPrice: data['originalPrice'] != null
          ? double.tryParse(data['originalPrice'].toString())
          : null,
      imageUrl: (data['imageUrl'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      sizes: (data['sizes'] as List? ?? []).map((e) => e.toString()).toList(),
      colors: (data['colors'] as List? ?? []).map((e) => e.toString()).toList(),
      rating: double.tryParse((data['rating'] ?? 4.5).toString()) ?? 4.5,
      reviewCount: int.tryParse((data['reviewCount'] ?? 100).toString()) ?? 100,
      isFeatured: data['isFeatured'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'brand': brand,
      'category': category,
      'price': price,
      if (originalPrice != null) 'originalPrice': originalPrice,
      'imageUrl': imageUrl,
      'description': description,
      'sizes': sizes,
      'colors': colors,
      'rating': rating,
      'reviewCount': reviewCount,
      'isFeatured': isFeatured,
    };
  }
}

// ─── Cart Item ─────────────────────────────────────────────────────────────────
class CartItem {
  final Product product;
  String selectedSize;
  String selectedColor;
  int quantity;

  CartItem({
    required this.product,
    required this.selectedSize,
    required this.selectedColor,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;
}
