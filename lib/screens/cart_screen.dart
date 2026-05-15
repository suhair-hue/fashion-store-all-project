import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../utils/cart_provider.dart';
import '../widgets/custom_button.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  final bool standalone;
  const CartScreen({super.key, this.standalone = true});

  @override
  Widget build(BuildContext context) {
    final body = Consumer<CartProvider>(
      builder: (ctx, cart, _) {
        if (cart.items.isEmpty) return const _EmptyCart();
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: cart.items.length,
                itemBuilder: (_, i) =>
                    _CartItemCard(item: cart.items[i], index: i),
              ),
            ),
            // Summary card
            Container(
              padding: EdgeInsets.fromLTRB(
                  20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 20,
                      offset: const Offset(0, -4))
                ],
              ),
              child: Column(
                children: [
                  _Row('Subtotal', 'Rs.${cart.subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _Row(
                    'Shipping',
                    cart.shipping == 0 ? 'FREE' : 'Rs.${cart.shipping.toStringAsFixed(2)}',
                    valueColor: cart.shipping == 0 ? AppColors.success : null,
                  ),
                  if (cart.shipping == 0)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('You qualify for free shipping!',
                            style: TextStyle(
                                fontSize: 11, color: AppColors.success,
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 14),
                  _Row('Total', 'Rs.${cart.total.toStringAsFixed(2)}', bold: true),
                  const SizedBox(height: 18),
                  PrimaryButton(
                    label: 'Checkout · Rs.${cart.total.toStringAsFixed(2)}',
                    icon: Icons.arrow_forward_rounded,
                    onPressed: () => Navigator.push(ctx,
                        MaterialPageRoute(builder: (_) => const CheckoutScreen())),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    if (!standalone) return body;
    return Scaffold(
      appBar: AppBar(
        title: Consumer<CartProvider>(
            builder: (_, cart, __) => Text('Cart (${cart.itemCount})')),
        actions: [
          Consumer<CartProvider>(
            builder: (ctx, cart, _) => cart.items.isNotEmpty
                ? TextButton(
                    onPressed: () => _confirmClear(ctx, cart),
                    child: const Text('Clear',
                        style: TextStyle(color: AppColors.accent)))
                : const SizedBox(),
          ),
        ],
      ),
      body: body,
    );
  }

  void _confirmClear(BuildContext ctx, CartProvider cart) {
    showDialog(
      context: ctx,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear cart?'),
        content: const Text('All items will be removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          TextButton(
              onPressed: () {
                cart.clearCart();
                Navigator.pop(c);
              },
              child: const Text('Clear',
                  style: TextStyle(color: AppColors.accent))),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final dynamic item;
  final int index;
  const _CartItemCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartProvider>();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.card(radius: 16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(item.product.imageUrl,
                width: 88, height: 88, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(width: 88, height: 88, color: AppColors.surfaceAlt)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('${item.selectedSize} · ${item.selectedColor}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('Rs.${item.totalPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.accent)),
                    const Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () =>
                                cart.updateQuantity(index, item.quantity - 1),
                            child: const Padding(
                              padding: EdgeInsets.all(7),
                              child: Icon(Icons.remove, size: 14, color: AppColors.primary),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text('${item.quantity}',
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w800)),
                          ),
                          GestureDetector(
                            onTap: () =>
                                cart.updateQuantity(index, item.quantity + 1),
                            child: const Padding(
                              padding: EdgeInsets.all(7),
                              child: Icon(Icons.add, size: 14, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => cart.removeFromCart(index),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.accent, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? valueColor;
  const _Row(this.label, this.value, {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: bold ? 16 : 14,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
                color: bold ? AppColors.primary : AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 20 : 14,
                fontWeight: FontWeight.w800,
                color: valueColor ?? (bold ? AppColors.accent : AppColors.primary))),
      ],
    );
  }
}

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              gradient: AppColors.gradientAccent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppColors.accent.withOpacity(0.3),
                    blurRadius: 24, offset: const Offset(0, 8))
              ],
            ),
            child: const Icon(Icons.shopping_bag_outlined,
                size: 50, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text('Your cart is empty',
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 8),
          const Text('Add items to get started',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: PrimaryButton(
              label: 'Start Shopping',
              onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            ),
          ),
        ],
      ),
    );
  }
}