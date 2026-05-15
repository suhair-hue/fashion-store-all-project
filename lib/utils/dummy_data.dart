import '../models/product.dart';

class DummyData {
  static const List<String> categories = [
    'All',
    'Men',
    'Women',
    'Kids',
    'Accessories',
    'Sale',
  ];

  static final List<Product> products = [
    const Product(
      id: '1',
      name: 'White T-shirt',
      brand: 'zara',
      category: 'Men',
      price: 999.99,
      originalPrice: 2999.99,
      imageUrl:
          'https://cdn.pixabay.com/photo/2024/04/29/04/21/tshirt-8726716_1280.jpg',
      description:
          'A timeless white t-shirt crafted from 100% premium organic cotton. Ultra-soft, breathable, and built to last through every season.',
      sizes: ['XS', 'S', 'M', 'L', 'XL', 'XXL'],
      colors: ['White', 'Black', 'Gray'],
      rating: 4.7,
      reviewCount: 245,
      isFeatured: true,
    ),
    const Product(
      id: '2',
      name: 'Floral Midi Dress',
      brand: 'Zara',
      category: 'Women',
      price: 2499.99,
      imageUrl:
          'https://images.pexels.com/photos/17901631/pexels-photo-17901631.jpeg',
      description:
          'An elegant floral midi dress with a flattering A-line silhouette. Perfect for brunch, garden parties, or a sophisticated day out.',
      sizes: ['XS', 'S', 'M', 'L', 'XL'],
      colors: ['Floral Pink', 'Floral Blue', 'Cream'],
      rating: 4.8,
      reviewCount: 189,
      isFeatured: true,
    ),
    const Product(
      id: '3',
      name: 'Slim Fit Chinos',
      brand: 'H&M',
      category: 'Men',
      price: 3999.99,
      originalPrice: 5999.99,
      imageUrl:
          'https://images.pexels.com/photos/29547631/pexels-photo-29547631.jpeg',
      description:
          'Modern slim-fit chinos from stretch cotton blend. Smart enough for the office, comfortable enough all day.',
      sizes: ['28', '30', '32', '34', '36', '38'],
      colors: ['Khaki', 'Navy', 'Olive', 'Black'],
      rating: 4.5,
      reviewCount: 312,
      isFeatured: true,
    ),
    const Product(
      id: '4',
      name: 'Oversized Blazer',
      brand: 'Mango',
      category: 'Women',
      price: 9999.99,
      imageUrl:
          'https://images.pexels.com/photos/32167488/pexels-photo-32167488.jpeg',
      description:
          'A bold oversized blazer that commands attention. Wear over a dress or with wide-leg trousers for effortless chic.',
      sizes: ['XS', 'S', 'M', 'L'],
      colors: ['Beige', 'Black', 'Plaid'],
      rating: 4.6,
      reviewCount: 97,
      isFeatured: true,
    ),
    const Product(
      id: '5',
      name: 'Kids Graphic Tee',
      brand: 'Gap Kids',
      category: 'Kids',
      price: 1599.99,
      originalPrice: 2999.99,
      imageUrl:
          'https://images.pexels.com/photos/33562772/pexels-photo-33562772.jpeg',
      description:
          'Fun colorful graphic tees for kids. Soft durable fabric easy to wash and built to last through every adventure.',
      sizes: ['2T', '3T', '4T', '5', '6', '7', '8'],
      colors: ['Blue', 'Red', 'Yellow', 'Green'],
      rating: 4.9,
      reviewCount: 156,
    ),
    const Product(
      id: '6',
      name: 'Leather Crossbody',
      brand: 'Coach',
      category: 'Accessories',
      price: 2499.99,
      imageUrl:
          'https://images.pexels.com/photos/26965805/pexels-photo-26965805.jpeg',
      description:
          'A compact leather crossbody bag with multiple compartments. Perfectly sized for your daily essentials.',
      sizes: ['One Size'],
      colors: ['Tan', 'Black', 'Brown'],
      rating: 4.7,
      reviewCount: 203,
    ),
    const Product(
      id: '7',
      name: 'Linen Summer Shirt',
      brand: 'Uniqlo',
      category: 'Men',
      price: 899.99,
      imageUrl:
          'https://images.pexels.com/photos/17739012/pexels-photo-17739012.jpeg',
      description:
          'Lightweight linen shirt for hot summer days. Breathable fabric keeps you cool and looking sharp.',
      sizes: ['S', 'M', 'L', 'XL', 'XXL'],
      colors: ['White', 'Blue', 'Sand', 'Olive'],
      rating: 4.4,
      reviewCount: 178,
    ),
    const Product(
      id: '8',
      name: 'High-Waist Jeans',
      brand: 'Levi\'s',
      category: 'Women',
      price: 4999.99,
      originalPrice: 6999.99,
      imageUrl:
          'https://images.pexels.com/photos/35272820/pexels-photo-35272820.jpeg',
      description:
          'Flattering high-waist jeans with stretchy denim blend. The ultimate everyday wardrobe essential.',
      sizes: ['24', '25', '26', '27', '28', '29', '30'],
      colors: ['Light Wash', 'Dark Wash', 'Black'],
      rating: 4.8,
      reviewCount: 421,
    ),
    const Product(
      id: '9',
      name: 'Silk Scarf',
      brand: 'Hermès-Style',
      category: 'Accessories',
      price: 1999.99,
      originalPrice: 2999.99,
      imageUrl:
          'https://images.pexels.com/photos/36455711/pexels-photo-36455711.jpeg',
      description:
          'Elegant silk scarf with beautiful print. Wear as a headband, neck scarf, or bag accessory.',
      sizes: ['One Size'],
      colors: ['Multicolor', 'Blue', 'Red'],
      rating: 4.5,
      reviewCount: 88,
    ),
    const Product(
      id: '10',
      name: 'Jogger Pants',
      brand: 'Nike',
      category: 'Men',
      price: 3499.99,
      imageUrl:
          'https://images.pexels.com/photos/12645601/pexels-photo-12645601.jpeg',
      description:
          'Premium jogger pants with tapered fit. Perfect for gym sessions, casual outings, or relaxed Sundays.',
      sizes: ['S', 'M', 'L', 'XL', 'XXL'],
      colors: ['Black', 'Gray', 'Navy'],
      rating: 4.6,
      reviewCount: 334,
    ),
  ];

  static List<Product> getByCategory(String category) {
    if (category == 'All') return products;
    if (category == 'Sale') return products.where((p) => p.isOnSale).toList();
    return products.where((p) => p.category == category).toList();
  }

  static List<Product> getAllProducts() => products;

  static List<Product> getFeatured() =>
      products.where((p) => p.isFeatured).toList();

  static List<Product> search(String query) {
    final q = query.toLowerCase();
    return products
        .where((p) =>
            p.name.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q))
        .toList();
  }
}
