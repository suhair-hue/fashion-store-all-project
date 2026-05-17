import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';

class PayHereService {
  // Sandbox mode toggle
  final bool isSandbox;

  // Merchant configurations
  // Sandbox credentials: using PayHere's default sandbox Merchant ID: 1224446
  // (User can replace these with their own sandbox/live credentials)
  final String sandboxMerchantId = "1224446";
  final String liveMerchantId = "YOUR_LIVE_MERCHANT_ID";

  PayHereService({this.isSandbox = true});

  String get merchantId => isSandbox ? sandboxMerchantId : liveMerchantId;

  /// Starts the PayHere payment gateway process
  void startPayment({
    required String orderId,
    required double amount,
    required String itemDescription,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    required String deliveryAddress,
    required String deliveryCity,
    required Function(String paymentId) onSuccess,
    required Function(String errorMessage) onError,
    required Function() onDismissed,
  }) {
    // Parse first name and last name from full customerName
    final nameParts = customerName.trim().split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : "Customer";
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : "Store";

    // Build standard PayHere payment object
    final Map<String, dynamic> paymentObject = {
      "sandbox": isSandbox,
      "merchant_id": merchantId,
      "notify_url": "https://sandbox.payhere.lk/pay/checkout", // Callback webhook endpoint
      "order_id": orderId,
      "items": itemDescription,
      "amount": amount,
      "currency": "LKR",
      "first_name": firstName,
      "last_name": lastName,
      "email": customerEmail.isNotEmpty ? customerEmail : "customer@fashionstore.lk",
      "phone": customerPhone,
      "address": deliveryAddress,
      "city": deliveryCity,
      "country": "Sri Lanka",
      "delivery_address": deliveryAddress,
      "delivery_city": deliveryCity,
      "delivery_country": "Sri Lanka",
      "custom_1": "FashionStoreApp",
      "custom_2": "LKR_Payment"
    };

    // Execute payment via the native PayHere SDK
    PayHere.startPayment(
      paymentObject,
      (paymentId) {
        // Success Callback
        onSuccess(paymentId);
      },
      (error) {
        // Error/Failure Callback
        onError(error);
      },
      () {
        // Dismissed/Cancelled by User Callback
        onDismissed();
      },
    );
  }
}
