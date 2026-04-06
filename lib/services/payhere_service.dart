import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';

class PayHereService {
  final String _merchantId = "1228224"; // Or appropriate Merchant ID
  final String _hashGenerationUrl =
      "https://ceylondash-backend.vercel.app/api/payhere/generate-hash";
  final String _webhookUrl =
      "https://ceylondash-backend.vercel.app/api/payhere/webhook";

  Future<void> startCheckout({
    required BuildContext context,
    required String orderId,
    required double amount,
    required String customerName,
    required String customerPhone,
    String customerEmail = "test@example.com",
    String customerAddress = "Colombo",
    String customerCity = "Colombo",
    String customerCountry = "Sri Lanka",
    required Function(String) onCompleted,
    required Function(String) onError,
    required Function() onCanceled,
  }) async {
    try {
      // Step A: Fetch Hash
      final response = await http.post(
        Uri.parse(_hashGenerationUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'order_id': orderId,
          'amount': amount,
          'currency': 'LKR',
        }),
      );

      if (response.statusCode != 200) {
        throw Exception("Failed to generate payment hash");
      }

      final responseData = jsonDecode(response.body);
      final String hash = responseData['hash'];
      final String merchantIdFromBackend =
          responseData['merchant_id'] ?? _merchantId;

      // Step B: Map parameters
      Map<String, dynamic> paymentObject = {
        "sandbox": true, // Change to false for production
        "merchant_id": merchantIdFromBackend,
        "notify_url": _webhookUrl,
        "order_id": orderId,
        "items": "Order $orderId",
        "amount": amount,
        "currency": "LKR",
        "first_name": customerName,
        "last_name": "",
        "email": customerEmail,
        "phone": customerPhone,
        "address": customerAddress,
        "city": customerCity,
        "country": customerCountry,
        "hash": hash,
      };

      // Step C: Start payment
      PayHere.startPayment(
        paymentObject,
        (paymentId) => onCompleted(paymentId),
        (error) => onError(error),
        () => onCanceled(),
      );
    } catch (e) {
      debugPrint("PayHere Checkout Error: $e");
      onError(e.toString());
    }
  }
}
