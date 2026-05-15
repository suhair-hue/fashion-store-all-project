import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../utils/app_theme.dart';
import '../utils/cart_provider.dart';
import '../widgets/custom_button.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  String? _size;
  String? _color;
  bool _fav = false;
  int _qty = 1;

  Product get p => widget.product;

  void _addToCart() {
    if (_size == null) {
      _showSnack('Please select a size');
      return;
    }
    if (_color == null) {
      _showSnack('Please select a color');
      return;
    }
    final cart = context.read<CartProvider>();
    for (int i = 0; i < _qty; i++) {
      cart.addToCart(p, _size!, _color!);
    }
    _showSnack('Added to cart!', success: true);
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      backgroundColor: success ? AppColors.success : AppColors.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Hero Image ─────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 400,
                pinned: true,
                backgroundColor: AppColors.surface,
                elevation: 0,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8)
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_rounded,
                          size: 18, color: AppColors.primary),
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: GestureDetector(
                      onTap: () => setState(() => _fav = !_fav),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8)
                          ],
                        ),
                        child: Icon(
                          _fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          color: _fav ? AppColors.accent : AppColors.textSecondary,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: CachedNetworkImage(
                    imageUrl: p.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.surfaceAlt),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.surfaceAlt,
                      child: const Icon(Icons.image_outlined,
                          size: 60, color: AppColors.textHint),
                    ),
                  ),
                ),
              ),

              // ── Details ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand + badges
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(p.brand,
                                style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ),
                          if (p.isOnSale) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                gradient: AppColors.gradientAccent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('-${p.discountPercent}% OFF',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(p.name,
                          style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              height: 1.2)),
                      const SizedBox(height: 12),
                      // Rating row
                      Row(
                        children: [
                          ...List.generate(5, (i) => Icon(
                            i < p.rating.floor()
                                ? Icons.star_rounded
                                : (i < p.rating
                                    ? Icons.star_half_rounded
                                    : Icons.star_border_rounded),
                            color: AppColors.star,
                            size: 18,
                          )),
                          const SizedBox(width: 8),
                          Text('${p.rating} (${p.reviewCount} reviews)',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Price + Qty
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (p.isOnSale)
                                Text('Rs.${p.originalPrice!.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        color: AppColors.textHint,
                                        decoration: TextDecoration.lineThrough)),
                              Text('Rs.${p.price.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.accent)),
                            ],
                          ),
                          const Spacer(),
                          // Qty control
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Row(
                              children: [
                                _QtyBtn(Icons.remove, () {
                                  if (_qty > 1) setState(() => _qty--);
                                }),
                                SizedBox(
                                  width: 36,
                                  child: Text('$_qty',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800)),
                                ),
                                _QtyBtn(Icons.add, () => setState(() => _qty++)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // Description
                      const Text('Description',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                      const SizedBox(height: 8),
                      Text(p.description,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              height: 1.7)),
                      const SizedBox(height: 28),
                      // Color picker
                      const Text('Color',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: p.colors.map((c) {
                          final sel = c == _color;
                          return GestureDetector(
                            onTap: () => setState(() => _color = c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: sel ? AppColors.gradientPrimary : null,
                                color: sel ? null : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: sel ? Colors.transparent : AppColors.divider),
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                            color: AppColors.primary.withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4))
                                      ]
                                    : [],
                              ),
                              child: Text(c,
                                  style: TextStyle(
                                      color: sel ? Colors.white : AppColors.primary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600)),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),
                      // Size picker
                      Row(
                        children: [
                          const Text('Size',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {},
                            child: const Text('Size Guide',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: p.sizes.map((s) {
                          final sel = s == _size;
                          return GestureDetector(
                            onTap: () => setState(() => _size = s),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 54,
                              height: 46,
                              decoration: BoxDecoration(
                                gradient: sel ? AppColors.gradientAccent : null,
                                color: sel ? null : AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: sel ? Colors.transparent : AppColors.divider),
                                boxShadow: sel
                                    ? [
                                        BoxShadow(
                                            color: AppColors.accent.withOpacity(0.35),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4))
                                      ]
                                    : [],
                              ),
                              child: Center(
                                child: Text(s,
                                    style: TextStyle(
                                        color: sel ? Colors.white : AppColors.primary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          // ── Sticky Bottom Bar ──────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -4))
                ],
              ),
              child: Row(
                children: [
                  // Wishlist button
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Icon(
                      _fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: _fav ? AppColors.accent : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Add to Cart · Rs.${(p.price * _qty).toStringAsFixed(2)}',
                      onPressed: _addToCart,
                      icon: Icons.shopping_bag_outlined,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}