import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_theme.dart';
import '../utils/cart_provider.dart';
import '../providers/order_provider.dart';
import '../services/order_service.dart';
import '../widgets/custom_button.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _orderService = OrderService();

  int _step = 0;
  String _payment = 'Credit Card';
  bool _placing = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }

  void _placeOrder(CartProvider cart) async {
    setState(() => _placing = true);

    try {
      // ── 1. Save to Firebase Firestore ──────────────────────────────
      final firestoreOrderId = await _orderService.placeOrder(
        items: cart.items.toList(),
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        zip: _zipCtrl.text.trim(),
        paymentMethod: _payment,
        total: cart.total,
      );

      // ── 2. Also save to local OrderProvider (for Order History screen) ──
      if (!mounted) return;
      final orderProvider = context.read<OrderProvider>();
      orderProvider.placeOrder(
        cartItems: cart.items.toList(),
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        zip: _zipCtrl.text.trim(),
        paymentMethod: _payment,
        subtotal: cart.subtotal,
        shipping: cart.shipping,
        total: cart.total,
      );

      // ── 3. Clear the cart ──────────────────────────────────────────
      cart.clearCart();

      if (!mounted) return;
      setState(() => _placing = false);

      // ── 4. Show success dialog ─────────────────────────────────────
      _showSuccess(firestoreOrderId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);

      // Show error if Firebase save failed
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  void _showSuccess(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppColors.gradientAccent,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: AppColors.accent.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8))
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Order Placed!',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary)),
            const SizedBox(height: 6),
            Text(
              orderId.length > 20 ? '${orderId.substring(0, 20)}...' : orderId,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your order has been placed successfully and saved!',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Continue Shopping',
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/home');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout'),
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
      body: Stepper(
        currentStep: _step,
        type: StepperType.vertical,
        connectorColor: WidgetStateProperty.all(AppColors.divider),
        controlsBuilder: (ctx, details) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Row(
            children: [
              Expanded(
                child: _step < 2
                    ? PrimaryButton(
                        label: 'Continue',
                        onPressed: () {
                          if (_step == 0 &&
                              !_formKey.currentState!.validate()) {
                            return;
                          }
                          setState(() => _step++);
                        },
                      )
                    : PrimaryButton(
                        label: 'Place Order',
                        isLoading: _placing,
                        onPressed: () => _placeOrder(cart),
                        icon: Icons.check_rounded,
                      ),
              ),
              if (_step > 0) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: SecondaryButton(
                    label: 'Back',
                    onPressed: () => setState(() => _step--),
                  ),
                ),
              ],
            ],
          ),
        ),
        steps: [
          // ── Step 1: Delivery ────────────────────────────────────────
          Step(
            title: const Text('Delivery Details',
                style: TextStyle(fontWeight: FontWeight.w700)),
            isActive: _step >= 0,
            state: _step > 0 ? StepState.complete : StepState.indexed,
            content: Form(
              key: _formKey,
              child: Column(
                children: [
                  _tf(_nameCtrl, 'Full name', Icons.person_outline,
                      (v) => v!.length < 2 ? 'Enter your name' : null),
                  const SizedBox(height: 14),
                  _tf(_phoneCtrl, 'Phone number', Icons.phone_outlined,
                      (v) => v!.isEmpty ? 'Enter phone number' : null,
                      keyboard: TextInputType.phone),
                  const SizedBox(height: 14),
                  _tf(_addressCtrl, 'Street address', Icons.home_outlined,
                      (v) => v!.isEmpty ? 'Enter address' : null),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                          flex: 2,
                          child: _tf(
                              _cityCtrl,
                              'City',
                              Icons.location_city_outlined,
                              (v) => v!.isEmpty ? 'Required' : null)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _tf(_zipCtrl, 'ZIP', Icons.pin_outlined,
                              (v) => v!.isEmpty ? 'Required' : null,
                              keyboard: TextInputType.number)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Step 2: Payment ─────────────────────────────────────────
          Step(
            title: const Text('Payment',
                style: TextStyle(fontWeight: FontWeight.w700)),
            isActive: _step >= 1,
            state: _step > 1 ? StepState.complete : StepState.indexed,
            content: Column(
              children: [
                'Credit Card',
                'Debit Card',
                'PayPal',
                'Cash on Delivery'
              ].map((m) {
                final sel = m == _payment;
                return GestureDetector(
                  onTap: () => setState(() => _payment = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.accent.withOpacity(0.07)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: sel ? AppColors.accent : AppColors.divider,
                          width: sel ? 1.5 : 1),
                    ),
                    child: Row(
                      children: [
                        Icon(_payIcon(m),
                            color: sel
                                ? AppColors.accent
                                : AppColors.textSecondary,
                            size: 22),
                        const SizedBox(width: 12),
                        Text(m,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    sel ? FontWeight.w700 : FontWeight.w400,
                                color: sel
                                    ? AppColors.accent
                                    : AppColors.primary)),
                        const Spacer(),
                        if (sel)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.accent, size: 20),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Step 3: Review ──────────────────────────────────────────
          Step(
            title: const Text('Review Order',
                style: TextStyle(fontWeight: FontWeight.w700)),
            isActive: _step >= 2,
            state: StepState.indexed,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reviewRow(
                    Icons.home_outlined,
                    'Delivery',
                    _addressCtrl.text.isEmpty
                        ? 'Not filled'
                        : '${_addressCtrl.text}, ${_cityCtrl.text}'),
                const SizedBox(height: 10),
                _reviewRow(Icons.payment_outlined, 'Payment', _payment),
                const Divider(color: AppColors.divider, height: 28),
                ...cart.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Text('${item.quantity}×',
                              style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(item.product.name,
                                  style: const TextStyle(fontSize: 13))),
                          Text('Rs.${item.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    )),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Subtotal',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    const Spacer(),
                    Text('Rs.${cart.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Shipping',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textSecondary)),
                    const Spacer(),
                    Text(
                        cart.shipping == 0
                            ? 'FREE'
                            : 'Rs.${cart.shipping.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: cart.shipping == 0
                                ? AppColors.success
                                : AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    Text('Rs.${cart.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accent)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tf(
    TextEditingController ctrl,
    String hint,
    IconData icon,
    String? Function(String?) validator, {
    TextInputType keyboard = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration:
          InputDecoration(hintText: hint, prefixIcon: Icon(icon, size: 20)),
      validator: validator,
    );
  }

  Widget _reviewRow(IconData icon, String label, String val) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.textSecondary),
      const SizedBox(width: 8),
      Text('$label: ',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
      Expanded(
          child: Text(val,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
    ]);
  }

  IconData _payIcon(String m) {
    switch (m) {
      case 'Credit Card':
        return Icons.credit_card_rounded;
      case 'Debit Card':
        return Icons.credit_card_outlined;
      case 'PayPal':
        return Icons.account_balance_wallet_outlined;
      default:
        return Icons.payments_outlined;
    }
  }
}
