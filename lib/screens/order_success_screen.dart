import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../utils/app_theme.dart';
import '../widgets/bill_bottom_sheet.dart';

class OrderSuccessScreen extends StatefulWidget {
  final String orderId;
  final String paymentId;
  final double totalAmount;
  final String pdfPath;

  const OrderSuccessScreen({
    super.key,
    required this.orderId,
    required this.paymentId,
    required this.totalAmount,
    required this.pdfPath,
  });

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> with SingleTickerProviderStateMixin {
  bool _animateCheck = false;
  bool _showConfetti = false;
  late AnimationController _fadeCtrl;

  // Custom confetti particle definition
  final List<_ConfettiParticle> _particles = List.generate(40, (index) {
    final rand = Random();
    return _ConfettiParticle(
      color: [
        Colors.redAccent,
        Colors.blueAccent,
        Colors.greenAccent,
        Colors.amberAccent,
        Colors.purpleAccent,
        AppColors.accent
      ][rand.nextInt(6)],
      left: rand.nextDouble() * 360,
      top: rand.nextDouble() * 260,
      size: rand.nextDouble() * 10 + 6,
      angle: rand.nextDouble() * 360,
    );
  });

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Trigger micro-animations after build frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _animateCheck = true;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _showConfetti = true;
        });
        _fadeCtrl.forward();
      });
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _viewReceipt() async {
    final file = File(widget.pdfPath);
    if (await file.exists()) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => BillBottomSheet(
          pdfPath: widget.pdfPath,
          orderId: widget.orderId,
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Invoice file not found!"),
          backgroundColor: AppColors.accent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ─── CUSTOM CONFETTI PARTICLE CANVAS ─────────────────────────
          if (_showConfetti)
            ..._particles.map((p) => Positioned(
                  left: p.left,
                  top: p.top,
                  child: AnimatedOpacity(
                    opacity: _showConfetti ? 0.8 : 0.0,
                    duration: const Duration(seconds: 2),
                    child: Transform.rotate(
                      angle: p.angle * (pi / 180),
                      child: Container(
                        width: p.size,
                        height: p.size,
                        decoration: BoxDecoration(
                          color: p.color,
                          shape: p.angle % 2 == 0 ? BoxShape.rectangle : BoxShape.circle,
                          borderRadius: p.angle % 2 == 0 ? BorderRadius.circular(2) : null,
                        ),
                      ),
                    ),
                  ),
                )),

          // ─── MAIN CONTENT ────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),

                    // ── Animated Green Checkmark
                    AnimatedScale(
                      scale: _animateCheck ? 1.0 : 0.2,
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.shade50,
                          border: Border.all(color: Colors.green.shade500, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 70,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── Title
                    const Text(
                      'Order Placed Successfully!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Thank you for shopping with us.\nYour invoice has been compiled and saved locally.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32),

                    // ── Details Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
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
                        children: [
                          _buildDetailRow('Order ID', widget.orderId, isBoldValue: true),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            widget.paymentId == "COD" ? 'Payment' : 'PayHere Ref ID',
                            widget.paymentId == "COD" ? 'Cash on Delivery' : widget.paymentId,
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: AppColors.divider),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Paid',
                                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                              ),
                              Text(
                                'Rs. ${widget.totalAmount.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.accent,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // ── Buttons
                    ElevatedButton.icon(
                      onPressed: _viewReceipt,
                      icon: const Icon(Icons.receipt_long_rounded, color: Colors.white),
                      label: const Text(
                        'View & Print Receipt',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        // Navigate back home and clear checkout screen history
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/home',
                          (route) => false,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary, width: 1.5),
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Continue Shopping',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isBoldValue = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Text(
          value.length > 22 ? '${value.substring(0, 22)}...' : value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBoldValue ? FontWeight.w800 : FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _ConfettiParticle {
  final Color color;
  final double left;
  final double top;
  final double size;
  final double angle;

  _ConfettiParticle({
    required this.color,
    required this.left,
    required this.top,
    required this.size,
    required this.angle,
  });
}
