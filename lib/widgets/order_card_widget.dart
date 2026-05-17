import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../utils/app_theme.dart';
import '../services/order_service.dart';
import 'cancel_dialog.dart';
import 'refund_dialog.dart';

class OrderCardWidget extends StatefulWidget {
  final Map<String, dynamic> orderData;

  const OrderCardWidget({super.key, required this.orderData});

  @override
  State<OrderCardWidget> createState() => _OrderCardWidgetState();
}

class _OrderCardWidgetState extends State<OrderCardWidget> {
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didUpdateWidget(covariant OrderCardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Restart timer if orderData shifts
    _timer?.cancel();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Calculates elapsed seconds and initiates periodic updates
  void _startCountdown() {
    final status = widget.orderData['status']?.toString() ?? 'Order Placed';
    
    // Only count down if order is still active/placed (Delivered/Cancelled cannot count down)
    if (status != 'Order Placed' && status != 'Processing') {
      setState(() => _remainingSeconds = 0);
      return;
    }

    final Timestamp? timestamp = widget.orderData['createdAt'] as Timestamp?;
    if (timestamp == null) {
      setState(() => _remainingSeconds = 0);
      return;
    }

    final DateTime createdAt = timestamp.toDate();
    final int elapsedSeconds = DateTime.now().difference(createdAt).inSeconds;
    
    // Strict 10 minutes limit (600 seconds)
    final int remaining = 600 - elapsedSeconds;

    if (remaining > 0) {
      setState(() {
        _remainingSeconds = remaining;
      });

      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        final int currentElapsed = DateTime.now().difference(createdAt).inSeconds;
        final int currentRemaining = 600 - currentElapsed;

        if (currentRemaining <= 0) {
          timer.cancel();
          setState(() {
            _remainingSeconds = 0;
          });
        } else {
          setState(() {
            _remainingSeconds = currentRemaining;
          });
        }
      });
    } else {
      setState(() {
        _remainingSeconds = 0;
      });
    }
  }

  String _formatTime(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Order Placed':
      case 'Processing':
        return Colors.blue;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return AppColors.textSecondary;
    }
  }

  void _triggerCancelFlow(double amount) async {
    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CancelDialog(),
    );

    if (reason != null && reason.isNotEmpty) {
      try {
        final orderId = widget.orderData['orderId'];
        await OrderService().cancelOrder(orderId, reason);

        if (!mounted) return;

        // SnackBar notification matching step 3
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Your order has been cancelled successfully"),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );

        // If card payment via PayHere was used
        final paymentMethod = widget.orderData['paymentMethod']?.toString() ?? '';
        if (paymentMethod.toLowerCase().contains('payhere')) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => RefundDialog(amount: amount),
          );
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Cancellation failed: $e"),
            backgroundColor: AppColors.accent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.orderData['status']?.toString() ?? 'Order Placed';
    final orderId = widget.orderData['orderId']?.toString() ?? 'ORDER';
    final shortOrderId = orderId.length > 8 ? orderId.substring(0, 8) : orderId;

    final Timestamp? timestamp = widget.orderData['createdAt'] as Timestamp?;
    final DateTime createdAt = timestamp?.toDate() ?? DateTime.now();
    final formattedDate = DateFormat('dd MMM yyyy, hh:mm a').format(createdAt);

    final double subtotal = (widget.orderData['subtotal'] as num?)?.toDouble() ?? 0.0;
    final double shipping = (widget.orderData['shipping'] as num?)?.toDouble() ?? 350.0;
    final double totalAmount = (widget.orderData['total'] as num?)?.toDouble() ?? (subtotal + shipping);

    final items = widget.orderData['items'] as List? ?? [];
    final bool isCancellable = _remainingSeconds > 0 && status != 'Cancelled' && status != 'Delivered';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── CARD HEADER ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order ID: #$shortOrderId',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formattedDate,
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                // Color-coded Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getStatusColor(status).withOpacity(0.2)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: _getStatusColor(status),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // ─── ITEMS LIST ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Items Ordered:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                ...items.map((item) {
                  final name = item['productName'] ?? item['name'] ?? 'Fashion Item';
                  final qty = item['quantity'] ?? 1;
                  final size = item['size'] ?? '';
                  final color = item['color'] ?? '';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$qty × ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accent)),
                        Expanded(
                          child: Text(
                            '$name ${size.isNotEmpty ? "($size / $color)" : ""}',
                            style: const TextStyle(fontSize: 12, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                
                // Cancellation details if Cancelled
                if (status == 'Cancelled') ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.15)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cancellation Reason:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.orderData['cancellationReason']?.toString() ?? 'Changed my mind',
                          style: const TextStyle(fontSize: 11, color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // ─── BOTTOM SECTION: PRICE & CANCELLATION ACTIONS ────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Amount', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    const SizedBox(height: 2),
                    Text(
                      'Rs. ${totalAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.accent,
                      ),
                    ),
                  ],
                ),
                
                // Cancellation timer & buttons
                if (isCancellable) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Countdown timer (MM:SS)
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 14, color: AppColors.accent),
                          const SizedBox(width: 4),
                          Text(
                            _formatTime(_remainingSeconds),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ElevatedButton(
                        onPressed: () => _triggerCancelFlow(totalAmount),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          minimumSize: const Size(120, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Cancel Order',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ] else if (status != 'Cancelled' && status != 'Delivered') ...[
                  // Grey "Cannot Cancel" notice
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Cannot Cancel',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ] else ...[
                  const SizedBox(),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
