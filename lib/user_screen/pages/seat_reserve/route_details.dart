// lib/user_screen/pages/seat_reserve/route_details.dart

import 'package:flutter/material.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';
import 'package:waygo/services/reservation_service.dart';
import 'package:intl/intl.dart';
import 'widgets/seat_layout.dart';
import 'widgets/payment_popup.dart';
import '../etickets_page.dart';

class RouteDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> routeDetails;
  final DateTime? selectedDate;
  const RouteDetailsScreen({
    super.key,
    required this.routeDetails,
    this.selectedDate,
  });

  @override
  State<RouteDetailsScreen> createState() => _RouteDetailsScreenState();
}

class _RouteDetailsScreenState extends State<RouteDetailsScreen> {
  final ReservationService _reservationService = ReservationService();
  List<int> bookedSeats = [];
  List<int> selectedSeats = [];
  bool _isLoadingSeats = true;
  bool _isProcessing = false;
  String? _reservationId;

  @override
  void initState() {
    super.initState();
    _loadBookedSeats();
  }

  Future<void> _loadBookedSeats() async {
    setState(() => _isLoadingSeats = true);
    try {
      final routeId =
          widget.routeDetails['routeId'] ?? widget.routeDetails['_id'];
      final date = widget.selectedDate ?? DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      final booked = await _reservationService.getBookedSeats(routeId, dateStr);
      setState(() {
        bookedSeats = booked;
        _isLoadingSeats = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingSeats = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading seats: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onSeatSelectionChanged(List<int> seats) {
    setState(() => selectedSeats = seats);
  }

  void _openConfirmSheet() {
    if (selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one seat.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.35,
        minChildSize: 0.2,
        maxChildSize: 0.9,
        builder: (context, controller) => Container(
          padding: const EdgeInsets.all(18.0),
          decoration: BoxDecoration(
            color: AppColors.waygoDarkBlue,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20.0),
            ),
          ),
          child: ListView(
            controller: controller,
            children: [
              Text(
                'Confirm Reservation',
                style: AppTextStyles.heading.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8.0),
              Text(
                '${widget.routeDetails['start']} → ${widget.routeDetails['destination']}'
                ' • ${widget.routeDetails['departure']}',
                style: AppTextStyles.body.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: 12.0),
              Text(
                'Selected seats: ${selectedSeats.join(', ')}',
                style: AppTextStyles.subHeading.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 8.0),
              Text(
                'Total: \$${_calculateTotalAmount().toStringAsFixed(2)}',
                style: AppTextStyles.heading.copyWith(
                  color: AppColors.waygoLightBlue,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 18.0),

              // Confirm (No Payment)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.waygoLightBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: _isProcessing
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await _confirmReservation(false);
                      },
                child: Text(
                  'Confirm Reservation (No Payment)',
                  style: AppTextStyles.button.copyWith(color: Colors.white),
                ),
              ),
              const SizedBox(height: 12.0),

              // Purchase Ticket with Stripe
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF95959),
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
                onPressed: _isProcessing
                    ? null
                    : () async {
                        Navigator.pop(context);
                        await _handleStripePayment();
                      },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Purchase Ticket',
                      style: AppTextStyles.button.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10.0),

              // Close button
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: AppTextStyles.body.copyWith(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _calculateTotalAmount() {
    final dynamic rawPrice = widget.routeDetails['price'] ?? 0;
    final double pricePerSeat = (rawPrice is num)
        ? rawPrice.toDouble()
        : double.tryParse('$rawPrice') ?? 0.0;
    return pricePerSeat * selectedSeats.length;
  }

  Future<void> _handleStripePayment() async {
    final double amount = _calculateTotalAmount();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid amount for payment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => PaymentPopup(
        amount: amount,
        metadata: {
          'routeId':
              widget.routeDetails['routeId'] ?? widget.routeDetails['_id'],
          'seats': selectedSeats.join(','),
          'date': DateFormat(
            'yyyy-MM-dd',
          ).format(widget.selectedDate ?? DateTime.now()),
          'start': widget.routeDetails['start'] ?? '',
          'destination': widget.routeDetails['destination'] ?? '',
        },
      ),
    );

    if (result != null && result['success'] == true) {
      await _confirmReservation(true, paymentMethod: result['paymentMethod']);
    } else if (result != null && result['success'] == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment cancelled.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.routeDetails;
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image (Darkened)
          Image.asset(
            'assest/images4.jpg',
            fit: BoxFit.cover,
            color: Colors.black.withOpacity(0.6),
            colorBlendMode: BlendMode.darken,
          ),

          // Gradient Overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.waygoDarkBlue.withOpacity(0.8),
                  AppColors.waygoDarkBlue.withOpacity(0.0),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 0.9],
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 18.0,
                vertical: 0.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top route summary card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10.0,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${route['start']} → ${route['destination']}',
                                style: AppTextStyles.heading.copyWith(
                                  color: AppColors.waygoDarkBlue,
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              Text(
                                '${route['departure']} • ${route['arrival']} • ${route['duration']}',
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              Text(
                                route['bus'] ?? '',
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              Text(
                                '\$${route['price']?.toString() ?? '0'} per seat',
                                style: AppTextStyles.subHeading.copyWith(
                                  color: AppColors.waygoLightBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, size: 28.0),
                          color: AppColors.waygoDarkBlue,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18.0),

                  // Seats area
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Select Seats',
                                style: AppTextStyles.subHeading,
                              ),
                              if (selectedSeats.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.waygoLightBlue,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${selectedSeats.length} selected',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12.0),

                          // Seat layout widget
                          Expanded(
                            child: _isLoadingSeats
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : SeatLayout(
                                    totalSeats:
                                        widget.routeDetails['totalSeats'] ?? 40,
                                    bookedSeats: bookedSeats,
                                    onSelectionChanged: _onSeatSelectionChanged,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12.0),

                  // Footer action
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.waygoLightBlue,
                            padding: const EdgeInsets.symmetric(vertical: 14.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                          ),
                          onPressed: _isProcessing ? null : _openConfirmSheet,
                          child: _isProcessing
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  selectedSeats.isEmpty
                                      ? 'Select seats'
                                      : 'Continue (${selectedSeats.length})',
                                  style: AppTextStyles.button.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmReservation(
    bool withPayment, {
    String? paymentMethod,
  }) async {
    setState(() => _isProcessing = true);

    try {
      final routeId =
          widget.routeDetails['routeId'] ?? widget.routeDetails['_id'];
      final date = widget.selectedDate ?? DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      // First create reservation
      final reservationResult = await _reservationService.createReservation(
        routeId: routeId,
        seats: selectedSeats,
        date: dateStr,
      );

      final reservationId = reservationResult['reservation']['_id'];

      if (withPayment && paymentMethod != null) {
        // Confirm with payment
        final paymentResult = await _reservationService.confirmReservation(
          reservationId: reservationId,
          paymentMethod: paymentMethod,
          amount: _calculateTotalAmount(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Payment successful! Seats ${selectedSeats.join(', ')} reserved.',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );

          // Navigate to e-ticket page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => Etickets(reservationId: reservationId),
            ),
          );
        }
      } else {
        // Just reservation without payment
        setState(() => _reservationId = reservationId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Reservation created for seats ${selectedSeats.join(', ')}. Complete payment to get your ticket.',
              ),
              backgroundColor: AppColors.waygoLightBlue,
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
