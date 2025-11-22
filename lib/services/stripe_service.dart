// lib/services/stripe_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class StripeService {
  // ✅ FIXED: Changed from /api/auth to /api/payments
  static const String _baseUrl = 'http://10.0.2.2:5000/api/payments';

  // Initialize Stripe with your publishable key
  // Call this in main.dart before runApp()
  static Future<void> init() async {
    // ⚠️ REPLACE WITH YOUR ACTUAL PUBLISHABLE KEY FROM STRIPE DASHBOARD
    Stripe.publishableKey = 'pk_test_YOUR_PUBLISHABLE_KEY_HERE';
    await Stripe.instance.applySettings();
  }

  // Create payment intent on your backend
  static Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Convert amount to cents (Stripe uses smallest currency unit)
      final int amountInCents = (amount * 100).round();

      print('🔄 Creating payment intent for \$${amount.toStringAsFixed(2)}...');

      final response = await http.post(
        Uri.parse('$_baseUrl/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': amountInCents,
          'currency': currency,
          'metadata': metadata,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Payment intent created: ${data['paymentIntentId']}');
        return data;
      } else {
        print('❌ Server error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create payment intent: ${response.body}');
      }
    } catch (e) {
      print('❌ Network error: $e');
      throw Exception('Error creating payment intent: $e');
    }
  }

  // Initialize payment sheet
  static Future<void> initPaymentSheet({
    required String paymentIntentClientSecret,
    required String merchantDisplayName,
  }) async {
    try {
      print('🔄 Initializing payment sheet...');

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: merchantDisplayName,
          style: ThemeMode.light,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: const Color(0xFF5AB0FF),
            ),
          ),
        ),
      );

      print('✅ Payment sheet initialized');
    } catch (e) {
      print('❌ Error initializing payment sheet: $e');
      throw Exception('Error initializing payment sheet: $e');
    }
  }

  // Present payment sheet
  static Future<bool> presentPaymentSheet() async {
    try {
      print('🔄 Presenting payment sheet...');
      await Stripe.instance.presentPaymentSheet();
      print('✅ Payment successful!');
      return true;
    } on StripeException catch (e) {
      print('⚠️ Stripe exception: ${e.error.code}');

      if (e.error.code == FailureCode.Canceled) {
        // User cancelled - not an error
        print('ℹ️ Payment cancelled by user');
        return false;
      }

      print('❌ Payment failed: ${e.error.localizedMessage}');
      throw Exception('Payment failed: ${e.error.localizedMessage}');
    } catch (e) {
      print('❌ Error presenting payment sheet: $e');
      throw Exception('Error presenting payment sheet: $e');
    }
  }

  // Complete payment flow
  static Future<bool> makePayment({
    required double amount,
    required String currency,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      print('💳 Starting payment flow...');

      // 1. Create payment intent
      final paymentIntent = await createPaymentIntent(
        amount: amount,
        currency: currency,
        metadata: metadata,
      );

      // 2. Initialize payment sheet
      await initPaymentSheet(
        paymentIntentClientSecret: paymentIntent['clientSecret'],
        merchantDisplayName: 'WayGo Bus Service',
      );

      // 3. Present payment sheet (this shows the card input form)
      final success = await presentPaymentSheet();

      if (success) {
        print('🎉 Payment completed successfully!');
      }

      return success;
    } catch (e) {
      print('❌ Payment error: $e');
      rethrow; // Let the UI handle the error
    }
  }
}
