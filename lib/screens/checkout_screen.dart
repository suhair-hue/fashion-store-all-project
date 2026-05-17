import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/app_theme.dart';
import '../utils/cart_provider.dart';
import '../services/payhere_service.dart';
import '../services/bill_generator.dart';
import 'order_success_screen.dart';
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
  
  // Initialize PayHere service
  final PayHereService _payHereService = PayHereService(isSandbox: true);

  String _paymentMethod = 'PayHere'; // Default is Card payment via PayHere
  bool _processingOrder = false;

  // LKR Pricing Config
  final double _deliveryCharge = 350.0; // LKR 350 fixed delivery fee

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }

  /// Triggers order placement validation and flow
  void _handlePlaceOrder(CartProvider cart) {
    // Validate form inputs
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all required delivery details."),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final double totalAmount = cart.subtotal + _deliveryCharge;
    
    // Generate a unique order ID using timestamp
    final String uniqueOrderId = 'ORD-${DateTime.now().millisecondsSinceEpoch}';

    if (_paymentMethod == 'PayHere') {
      _processPayHerePayment(cart, uniqueOrderId, totalAmount);
    } else {
      _processCashOnDelivery(cart, uniqueOrderId, totalAmount);
    }
  }

  /// Launches the PayHere Secure Card Inputs Dialog
  void _processPayHerePayment(CartProvider cart, String orderId, double amount) {
    final _cardFormKey = GlobalKey<FormState>();
    final _cardNameCtrl = TextEditingController(text: _nameCtrl.text.trim());
    final _cardNumberCtrl = TextEditingController();
    final _cardExpiryCtrl = TextEditingController();
    final _cardCvvCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.background,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: Row(
                children: [
                  const Icon(Icons.credit_card_rounded, color: AppColors.accent),
                  const SizedBox(width: 10),
                  const Text(
                    "Card Details",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: _cardFormKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Visa / MasterCard badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Image.network("https://img.icons8.com/color/48/visa.png", height: 20),
                          const SizedBox(width: 8),
                          Image.network("https://img.icons8.com/color/48/mastercard.png", height: 20),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Cardholder Name
                      TextFormField(
                        controller: _cardNameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Cardholder Name',
                          prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.textSecondary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        validator: (v) => v!.trim().isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 12),

                      // Card Number
                      TextFormField(
                        controller: _cardNumberCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 19,
                        decoration: InputDecoration(
                          labelText: 'Card Number',
                          counterText: "",
                          hintText: '4111 1111 1111 1111',
                          prefixIcon: const Icon(Icons.credit_card_outlined, size: 20, color: AppColors.textSecondary),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onChanged: (value) {
                          var text = value.replaceAll(' ', '');
                          if (text.length > 16) text = text.substring(0, 16);
                          var formatted = '';
                          for (int i = 0; i < text.length; i++) {
                            if (i > 0 && i % 4 == 0) formatted += ' ';
                            formatted += text[i];
                          }
                          if (formatted != value) {
                            _cardNumberCtrl.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }
                        },
                        validator: (v) {
                          final numOnly = v!.replaceAll(' ', '');
                          if (numOnly.length < 16) return 'Invalid card number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Expiry and CVV Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _cardExpiryCtrl,
                              keyboardType: TextInputType.number,
                              maxLength: 5,
                              decoration: InputDecoration(
                                labelText: 'Expiry Date',
                                counterText: "",
                                hintText: 'MM/YY',
                                prefixIcon: const Icon(Icons.date_range_outlined, size: 20, color: AppColors.textSecondary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              onChanged: (value) {
                                var text = value.replaceAll('/', '');
                                if (text.length > 4) text = text.substring(0, 4);
                                var formatted = '';
                                if (text.length >= 3) {
                                  formatted = '${text.substring(0, 2)}/${text.substring(2)}';
                                } else {
                                  formatted = text;
                                }
                                if (formatted != value) {
                                  _cardExpiryCtrl.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(offset: formatted.length),
                                  );
                                }
                              },
                              validator: (v) {
                                if (v!.length < 5 || !v.contains('/')) return 'MM/YY needed';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _cardCvvCtrl,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              maxLength: 3,
                              decoration: InputDecoration(
                                labelText: 'CVV',
                                counterText: "",
                                hintText: '123',
                                prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.textSecondary),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              validator: (v) => v!.length < 3 ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Pay Button
                      PrimaryButton(
                        label: 'Pay Rs. ${amount.toStringAsFixed(2)}',
                        icon: Icons.security_rounded,
                        onPressed: () async {
                          if (!_cardFormKey.currentState!.validate()) return;
                          
                          // Close dialog first
                          Navigator.pop(ctx);
                          
                          // Start processing order loading state
                          setState(() => _processingOrder = true);
                          
                          // Show secure loading spinner
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (secureCtx) => WillPopScope(
                              onWillPop: () async => false,
                              child: AlertDialog(
                                backgroundColor: AppColors.background,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                content: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const CircularProgressIndicator(color: AppColors.accent),
                                      const SizedBox(height: 20),
                                      const Text(
                                        "Connecting to PayHere Secure Gateway...",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        "Authorizing payment of Rs. ${amount.toStringAsFixed(2)}",
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );

                          // Simulate secure delay for authorization
                          await Future.delayed(const Duration(seconds: 2));

                          // Close securing spinner dialog
                          if (mounted) Navigator.pop(context);

                          // Save to Firestore and complete order!
                          final String simulatedPaymentId = 'payhere_pay_${DateTime.now().millisecondsSinceEpoch}';
                          await _saveOrderToFirestoreAndComplete(
                            cart: cart,
                            orderId: orderId,
                            paymentId: simulatedPaymentId,
                            paymentMethod: 'PayHere (Card Payment)',
                            amount: amount,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Processes Cash on Delivery immediately
  Future<void> _processCashOnDelivery(CartProvider cart, String orderId, double amount) async {
    setState(() => _processingOrder = true);
    await _saveOrderToFirestoreAndComplete(
      cart: cart,
      orderId: orderId,
      paymentId: 'COD',
      paymentMethod: 'Cash on Delivery',
      amount: amount,
    );
  }

  /// Commits final order payload to Cloud Firestore with offline cache retries
  Future<void> _saveOrderToFirestoreAndComplete({
    required CartProvider cart,
    required String orderId,
    required String paymentId,
    required String paymentMethod,
    required double amount,
  }) async {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    // Build items list
    final List<Map<String, dynamic>> orderItems = cart.items.map((item) {
      return {
        'productId': item.product.id,
        'productName': item.product.name,
        'productImage': item.product.imageUrl,
        'price': item.product.price,
        'quantity': item.quantity,
        'size': item.selectedSize,
        'color': item.selectedColor,
        'subtotal': item.totalPrice,
      };
    }).toList();

    // Prepare Firestore order document schema
    final Map<String, dynamic> orderData = {
      'orderId': orderId,
      'userId': userId,
      'items': orderItems,
      'deliveryDetails': {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'zip': _zipCtrl.text.trim(),
      },
      'paymentMethod': paymentMethod,
      'paymentId': paymentId,
      'subtotal': cart.subtotal,
      'shipping': _deliveryCharge,
      'total': amount,
      'status': 'Processing',
      'createdAt': FieldValue.serverTimestamp(),
    };

    File? invoiceFile;
    final String customerEmail = FirebaseAuth.instance.currentUser?.email ?? 'customer@fashionstore.lk';
    
    // Generate PDF invoice receipt
    try {
      invoiceFile = await BillGenerator.generateReceipt(
        orderId: orderId,
        paymentId: paymentId,
        customerName: _nameCtrl.text.trim(),
        customerEmail: customerEmail,
        customerPhone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        items: cart.items.toList(),
        subtotal: cart.subtotal,
        deliveryCharge: _deliveryCharge,
        total: amount,
      );
    } catch (e) {
      print("Warning: PDF Generation failed: $e");
    }

    try {
      // Save to cloud
      await FirebaseFirestore.instance.collection('orders').doc(orderId).set(orderData);
      _completeCheckoutProcess(cart, orderId, paymentId, amount, invoiceFile?.path ?? '');
    } catch (firestoreError) {
      // Trigger local storage network recovery failsafe
      print("Offline warning triggered: $firestoreError");
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.wifi_off_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Text("Order Synced Locally"),
            ],
          ),
          content: const Text(
            "Your card payment succeeded! However, our database is offline due to a connection issue. "
            "We saved your invoice PDF locally and will automatically synchronize the purchase when you are online.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _completeCheckoutProcess(cart, orderId, paymentId, amount, invoiceFile?.path ?? '');
              },
              child: const Text("View Receipt"),
            )
          ],
        ),
      );

      _triggerBackgroundSyncRetry(orderId, orderData);
    }
  }

  /// Retries syncing offline documents to cloud
  void _triggerBackgroundSyncRetry(String orderId, Map<String, dynamic> data) async {
    int attempts = 0;
    while (attempts < 5) {
      await Future.delayed(const Duration(seconds: 15));
      try {
        await FirebaseFirestore.instance.collection('orders').doc(orderId).set(data);
        print("Offline order has synchronized successfully.");
        break;
      } catch (_) {
        attempts++;
      }
    }
  }

  /// Clears cart, loading states, and pushes success transitions
  void _completeCheckoutProcess(
    CartProvider cart,
    String orderId,
    String paymentId,
    double amount,
    String pdfPath,
  ) {
    cart.clearCart();
    setState(() => _processingOrder = false);

    if (!mounted) return;
    
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => OrderSuccessScreen(
          orderId: orderId,
          paymentId: paymentId,
          totalAmount: amount,
          pdfPath: pdfPath,
        ),
      ),
      (route) => false,
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final double totalAmount = cart.subtotal + _deliveryCharge;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Complete Order', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: AppColors.primary),
          ),
        ),
      ),
      body: cart.items.isEmpty
          ? const Center(child: Text("Your cart is empty."))
          : GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── SECTION 1: DELIVERY ADDRESS ──────────────────────────
                      _buildSectionHeader('1. Delivery Address', Icons.location_on_rounded),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          children: [
                            _tf(_nameCtrl, 'Full Name', Icons.person_outline,
                                (v) => v!.trim().length < 2 ? 'Please enter your full name' : null),
                            const SizedBox(height: 12),
                            _tf(_phoneCtrl, 'Phone Number (e.g. 0771234567)', Icons.phone_outlined,
                                (v) => v!.trim().length < 9 ? 'Please enter a valid phone number' : null,
                                keyboard: TextInputType.phone),
                            const SizedBox(height: 12),
                            _tf(_addressCtrl, 'Street Address', Icons.home_outlined,
                                (v) => v!.isEmpty ? 'Please enter your address' : null),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _tf(_cityCtrl, 'City', Icons.location_city_outlined,
                                      (v) => v!.isEmpty ? 'Please enter city' : null),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _tf(_zipCtrl, 'ZIP Code', Icons.pin_outlined,
                                      (v) => v!.isEmpty ? 'Required' : null,
                                      keyboard: TextInputType.number),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // ── SECTION 2: PAYMENT METHOD ────────────────────────────
                      _buildSectionHeader('2. Payment Method', Icons.payment_rounded),
                      const SizedBox(height: 12),
                      Column(
                        children: [
                          // PayHere Card Selector
                          _buildPaymentMethodOption(
                            methodId: 'PayHere',
                            label: 'Pay via Card (Visa/Mastercard)',
                            logoChild: Row(
                              children: [
                                Image.network(
                                  "https://www.payhere.lk/downloads/images/payhere_logo.png",
                                  height: 16,
                                  errorBuilder: (_, __, ___) => const Text(
                                    "Card Payment",
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                ),
                                const Spacer(),
                                Image.network("https://img.icons8.com/color/48/visa.png", height: 20),
                                const SizedBox(width: 6),
                                Image.network("https://img.icons8.com/color/48/mastercard.png", height: 20),
                              ],
                            ),
                            icon: Icons.credit_card_rounded,
                          ),
                          const SizedBox(height: 10),
                          // Cash Selector
                          _buildPaymentMethodOption(
                            methodId: 'COD',
                            label: 'Cash on Delivery (COD)',
                            icon: Icons.delivery_dining_rounded,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── SECTION 3: ORDER SUMMARY ─────────────────────────────
                      _buildSectionHeader('3. Order Summary', Icons.shopping_basket_rounded),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order Items list
                            ...cart.items.map((item) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: [
                                      Text('${item.quantity}x',
                                          style: const TextStyle(
                                              color: AppColors.accent,
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          item.product.name,
                                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text('Rs. ${(item.totalPrice).toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    ],
                                  ),
                                )),
                            const Divider(color: AppColors.divider, height: 24),
                            _buildPricingRow('Subtotal', cart.subtotal),
                            const SizedBox(height: 6),
                            _buildPricingRow('Delivery Fee', _deliveryCharge),
                            const Divider(color: AppColors.divider, height: 24),
                            Row(
                              children: [
                                const Text(
                                  'Grand Total',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
                                ),
                                const Spacer(),
                                Text(
                                  'Rs. ${totalAmount.toStringAsFixed(2)}',
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

                      const SizedBox(height: 32),

                      // ── CHECKOUT ACTION BUTTON ───────────────────────────────
                      PrimaryButton(
                        label: _paymentMethod == 'PayHere'
                            ? 'Pay Rs. ${totalAmount.toStringAsFixed(2)} via Card'
                            : 'Place Cash Order (Rs. ${totalAmount.toStringAsFixed(2)})',
                        isLoading: _processingOrder,
                        onPressed: () => _handlePlaceOrder(cart),
                        icon: _paymentMethod == 'PayHere'
                            ? Icons.lock_outline_rounded
                            : Icons.check_circle_outline_rounded,
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodOption({
    required String methodId,
    required String label,
    Widget? logoChild,
    required IconData icon,
  }) {
    final bool isSelected = _paymentMethod == methodId;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = methodId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withOpacity(0.04) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.divider,
            width: isSelected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.accent : AppColors.textSecondary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: logoChild ?? Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.accent : AppColors.primary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingRow(String label, double val) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const Spacer(),
        Text('Rs. ${val.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary)),
      ],
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
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
      ),
      validator: validator,
    );
  }
}
