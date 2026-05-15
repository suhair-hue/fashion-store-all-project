import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../models/order_model.dart';
import '../providers/order_provider.dart';

class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Orders'),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.arrow_back_ios_rounded,
                size: 16, color: AppColors.primary),
          ),
        ),
      ),
      body: Consumer<OrderProvider>(
        builder: (context, orderProvider, _) {
          final orders = orderProvider.orders;

          if (orders.isEmpty) {
            return _EmptyOrders();
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: orders.length,
            itemBuilder: (ctx, i) => _OrderCard(order: orders[i]),
          );
        },
      ),
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────
class _EmptyOrders extends StatelessWidget {
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
              gradient: AppColors.gradientPrimary,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 48, color: Colors.white),
          ),
          const SizedBox(height: 24),
          const Text('No orders yet',
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary)),
          const SizedBox(height: 8),
          const Text('Your order history will appear here',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 60),
            child: GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(context, '/home'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientAccent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.accent.withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: const Center(
                  child: Text('Start Shopping',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────────────────
class _OrderCard extends StatefulWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final statusColor = _statusColor(o.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AppDecorations.card(radius: 20),
      child: Column(
        children: [
          // ── Header row ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Order icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.receipt_rounded,
                      color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 14),
                // Order info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(o.id,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary)),
                      const SizedBox(height: 3),
                      Text(_formatDate(o.placedAt),
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(o.status.label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: statusColor)),
                ),
              ],
            ),
          ),

          // ── Divider ───────────────────────────────────────────────
          const Divider(height: 1, color: AppColors.divider),

          // ── Item thumbnails row ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Product images
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: Stack(
                      children: [
                        for (int i = 0; i < o.items.length && i < 4; i++)
                          Positioned(
                            left: i * 32.0,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: Colors.white, width: 2),
                                color: AppColors.surfaceAlt,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  o.items[i].product.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.image_outlined,
                                      size: 20,
                                      color: AppColors.textHint),
                                ),
                              ),
                            ),
                          ),
                        if (o.items.length > 4)
                          Positioned(
                            left: 4 * 32.0,
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              child: Center(
                                child: Text('+${o.items.length - 4}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Total
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textSecondary)),
                    Text('Rs.${o.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accent)),
                  ],
                ),
              ],
            ),
          ),

          // ── Expand toggle ─────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _expanded ? 'Hide Details' : 'View Details',
                    style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.accent, size: 18),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded detail panel ─────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _OrderDetail(order: o),
          ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus s) {
    switch (s) {
      case OrderStatus.processing:
        return AppColors.warning;
      case OrderStatus.shipped:
        return Colors.blue;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.accent;
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    final h = d.hour > 12 ? d.hour - 12 : d.hour;
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month]} ${d.year}  •  $h:$m $ampm';
  }
}

// ─── Order Detail Panel ───────────────────────────────────────────────────────
class _OrderDetail extends StatelessWidget {
  final Order order;
  const _OrderDetail({required this.order});

  @override
  Widget build(BuildContext context) {
    final o = order;
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status progress bar ──────────────────────────────────
          _StatusStepper(status: o.status),
          const SizedBox(height: 20),

          // ── Items list ───────────────────────────────────────────
          const Text('Items Ordered',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary)),
          const SizedBox(height: 12),
          ...o.items.map((item) => _ItemRow(item: item)),

          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),

          // ── Price breakdown ──────────────────────────────────────
          const Text('Price Breakdown',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary)),
          const SizedBox(height: 10),
          _PriceRow('Subtotal', 'Rs.${o.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 6),
          _PriceRow(
            'Shipping',
            o.shipping == 0 ? 'FREE' : 'Rs.${o.shipping.toStringAsFixed(2)}',
            valueColor: o.shipping == 0 ? AppColors.success : null,
          ),
          const SizedBox(height: 10),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 10),
          _PriceRow('Total', 'Rs.${o.total.toStringAsFixed(2)}', bold: true),

          const SizedBox(height: 16),
          const Divider(color: AppColors.divider),
          const SizedBox(height: 12),

          // ── Delivery info ────────────────────────────────────────
          const Text('Delivery Details',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary)),
          const SizedBox(height: 10),
          _InfoRow(Icons.person_outline, o.name),
          const SizedBox(height: 6),
          _InfoRow(Icons.phone_outlined, o.phone),
          const SizedBox(height: 6),
          _InfoRow(
              Icons.location_on_outlined, '${o.address}, ${o.city} ${o.zip}'),
          const SizedBox(height: 6),
          _InfoRow(Icons.payment_outlined, o.paymentMethod),
        ],
      ),
    );
  }
}

// ─── Status Stepper ───────────────────────────────────────────────────────────
class _StatusStepper extends StatelessWidget {
  final OrderStatus status;
  const _StatusStepper({required this.status});

  @override
  Widget build(BuildContext context) {
    final steps = [
      OrderStatus.processing,
      OrderStatus.shipped,
      OrderStatus.delivered,
    ];
    final isCancelled = status == OrderStatus.cancelled;
    final currentIdx = isCancelled ? -1 : steps.indexOf(status);

    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accent.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.accent, size: 18),
            SizedBox(width: 10),
            Text('Order Cancelled',
                style: TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.w700)),
          ],
        ),
      );
    }

    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // connector line
          final done = (i ~/ 2) < currentIdx;
          return Expanded(
            child: Container(
              height: 3,
              color: done ? AppColors.success : AppColors.divider,
            ),
          );
        }
        // step circle
        final idx = i ~/ 2;
        final done = idx <= currentIdx;
        final active = idx == currentIdx;
        return Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? (active ? AppColors.accent : AppColors.success)
                    : AppColors.surfaceAlt,
                border: Border.all(
                  color: done
                      ? (active ? AppColors.accent : AppColors.success)
                      : AppColors.divider,
                  width: 2,
                ),
              ),
              child: Icon(
                done
                    ? (active
                        ? Icons.radio_button_checked_rounded
                        : Icons.check_rounded)
                    : Icons.radio_button_unchecked_rounded,
                size: 16,
                color: done ? Colors.white : AppColors.textHint,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              steps[idx].label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────
class _ItemRow extends StatelessWidget {
  final OrderItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(item.product.imageUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(width: 56, height: 56, color: AppColors.divider)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text('${item.selectedSize} · ${item.selectedColor}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('x${item.quantity}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 2),
              Text('Rs.${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.accent)),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? valueColor;
  const _PriceRow(this.label, this.value, {this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                fontSize: bold ? 15 : 13,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
                color: bold ? AppColors.primary : AppColors.textSecondary)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: bold ? 18 : 13,
                fontWeight: FontWeight.w800,
                color: valueColor ??
                    (bold ? AppColors.accent : AppColors.primary))),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
            child: Text(text,
                style:
                    const TextStyle(fontSize: 13, color: AppColors.primary))),
      ],
    );
  }
}
