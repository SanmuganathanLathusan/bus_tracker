// lib/user_screen/pages/seat_reserve/widgets/payment_popup.dart
import 'package:flutter/material.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';
import 'package:waygo/services/stripe_service.dart';

class PaymentPopup extends StatefulWidget {
  final double amount;
  final Map<String, dynamic>? metadata;

  const PaymentPopup({super.key, this.amount = 0.0, this.metadata});

  @override
  State<PaymentPopup> createState() => _PaymentPopupState();
}

class _PaymentPopupState extends State<PaymentPopup> {
  bool _processing = false;

  Future<void> _processPayment() async {
    setState(() => _processing = true);

    try {
      // Call Stripe payment with LKR amount from backend/database
      final success = await StripeService.makePayment(
        amount: widget.amount,
        currency: 'lkr',
        metadata: widget.metadata,
      );

      if (!mounted) return;

      if (success) {
        // Payment successful
        Navigator.of(context).pop({'success': true, 'paymentMethod': 'stripe'});
      } else {
        // Payment cancelled by user
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _processing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Payment icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.waygoLightBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.payment,
                size: 48,
                color: AppColors.waygoLightBlue,
              ),
            ),
            const SizedBox(height: 20),

            Text('Complete Payment', style: AppTextStyles.heading),
            const SizedBox(height: 8),

            if (widget.amount > 0) ...[
              Text(
                'LKR ${widget.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.waygoLightBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Secure payment powered by Stripe',
                style: AppTextStyles.body.copyWith(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Pay button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.waygoLightBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _processing ? null : _processPayment,
                child: _processing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Pay Now',
                        style: AppTextStyles.button.copyWith(fontSize: 16),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // Cancel button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                onPressed: _processing
                    ? null
                    : () => Navigator.of(context).pop({'success': false}),
                child: const Text('Cancel'),
              ),
            ),

            const SizedBox(height: 16),

            // Security badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Secured by 256-bit SSL encryption',
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
