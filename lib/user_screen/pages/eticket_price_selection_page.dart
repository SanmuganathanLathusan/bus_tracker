import 'package:flutter/material.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';
import 'package:waygo/services/reservation_service.dart';
import 'etickets_page.dart';
import 'seat_reserve/widgets/payment_popup.dart';
import 'package:intl/intl.dart';

/// E-Ticket Price Selection Page
/// Shows prices for Normal, Semi-Luxury, and Luxury bus types
/// After selecting a type, navigates to seat selection
class EticketPriceSelectionPage extends StatefulWidget {
  final Map<String, dynamic> routeDetails;
  final DateTime? selectedDate;

  const EticketPriceSelectionPage({
    super.key,
    required this.routeDetails,
    this.selectedDate,
  });

  @override
  State<EticketPriceSelectionPage> createState() =>
      _EticketPriceSelectionPageState();
}

class _EticketPriceSelectionPageState extends State<EticketPriceSelectionPage> {
  String? _selectedBusType;
  double? _selectedPrice;
  int _seatCount = 1;
  bool _isProcessing = false;

  final ReservationService _reservationService = ReservationService();

  @override
  void initState() {
    super.initState();
    // Default to normal type if available
    final normalPrice = widget.routeDetails['price'] ?? 0;
    if (normalPrice != null && normalPrice > 0) {
      _selectedBusType = 'normal';
      _selectedPrice = (normalPrice as num).toDouble();
    }
  }

  double get _normalPrice => widget.routeDetails['price'] != null
      ? (widget.routeDetails['price'] as num).toDouble()
      : 0.0;

  double? get _semiLuxuryPrice => widget.routeDetails['priceDeluxe'] != null
      ? (widget.routeDetails['priceDeluxe'] as num).toDouble()
      : null;

  double? get _luxuryPrice => widget.routeDetails['priceLuxury'] != null
      ? (widget.routeDetails['priceLuxury'] as num).toDouble()
      : null;

  String get _routeName =>
      '${widget.routeDetails['start'] ?? ''} - ${widget.routeDetails['destination'] ?? ''}';

  void _selectBusType(String type, double price) {
    setState(() {
      _selectedBusType = type;
      _selectedPrice = price;
    });
  }

  int get _totalSeats {
    final raw = widget.routeDetails['totalSeats'];
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 40;
  }

  double get _totalPrice => (_selectedPrice ?? 0) * _seatCount;

  List<int> _autoAssignSeats(int count, List<int> booked, int totalSeats) {
    final picked = <int>[];
    for (int i = 1; i <= totalSeats && picked.length < count; i++) {
      if (!booked.contains(i)) picked.add(i);
    }
    return picked;
  }

  Future<void> _confirmAndPay() async {
    if (_selectedBusType == null || _selectedPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a bus type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_totalPrice <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid amount for payment'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show payment popup
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (_) => PaymentPopup(
        amount: _totalPrice,
        metadata: {
          'routeId':
              widget.routeDetails['routeId'] ?? widget.routeDetails['_id'],
          'seatCount': _seatCount.toString(),
          'busType': _selectedBusType ?? 'normal',
          'start': widget.routeDetails['start'] ?? '',
          'destination': widget.routeDetails['destination'] ?? '',
          'date': DateFormat(
            'yyyy-MM-dd',
          ).format(widget.selectedDate ?? DateTime.now()),
        },
      ),
    );

    // Handle payment result
    if (result == null || result['success'] != true) {
      if (mounted && result != null && result['success'] == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment cancelled'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    // Payment successful, proceed with reservation
    setState(() => _isProcessing = true);

    try {
      final routeId =
          widget.routeDetails['routeId'] ?? widget.routeDetails['_id'];
      if (routeId == null) {
        throw Exception('Route not available');
      }

      final date = widget.selectedDate ?? DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(date);

      final bookedSeats = await _reservationService.getBookedSeats(
        routeId.toString(),
        dateStr,
      );

      final seatsToBook = _autoAssignSeats(
        _seatCount,
        bookedSeats,
        _totalSeats,
      );
      if (seatsToBook.length < _seatCount) {
        throw Exception('Not enough seats available');
      }

      final reservationResult = await _reservationService.createReservation(
        routeId: routeId.toString(),
        seats: seatsToBook,
        date: dateStr,
      );

      final reservationId =
          reservationResult['reservation']?['_id'] ?? reservationResult['_id'];

      await _reservationService.confirmReservation(
        reservationId: reservationId,
        paymentMethod: result['paymentMethod'] ?? 'stripe',
        amount: _totalPrice,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment successful! Seats ${seatsToBook.join(', ')} reserved.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                Etickets(reservationId: reservationId, autoDownload: true),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildPriceCard({
    required String title,
    required String description,
    required Color color,
    required IconData icon,
    required String type,
    required double? price,
    required bool isSelected,
  }) {
    final isAvailable = price != null && price > 0;

    return GestureDetector(
      onTap: isAvailable ? () => _selectBusType(type, price!) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isAvailable ? Colors.white : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? color
                : (isAvailable ? Colors.grey.shade300 : Colors.grey.shade400),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isAvailable
                          ? color.withOpacity(0.15)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: isAvailable ? color : Colors.grey.shade600,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.heading.copyWith(
                            fontSize: 18,
                            color: isAvailable
                                ? AppColors.textDark
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 12,
                            color: isAvailable
                                ? AppColors.textSecondary
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Price per seat',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    isAvailable
                        ? 'LKR ${price.toStringAsFixed(0)}'
                        : 'Not Available',
                    style: AppTextStyles.heading.copyWith(
                      fontSize: 20,
                      color: isAvailable ? color : Colors.grey.shade500,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.waygoDarkBlue,
              AppColors.waygoDarkBlue.withOpacity(0.9),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Bus Type',
                            style: AppTextStyles.heading.copyWith(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _routeName,
                            style: AppTextStyles.body.copyWith(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Route summary card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
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
                              '${widget.routeDetails['departure'] ?? ''} → ${widget.routeDetails['arrival'] ?? ''}',
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 16,
                                color: AppColors.waygoDarkBlue,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.routeDetails['duration'] ?? '',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            if (widget.routeDetails['distance'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                '${widget.routeDetails['distance']} km',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (widget.selectedDate != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.waygoDarkBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            DateFormat('dd MMM').format(widget.selectedDate!),
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.waygoDarkBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Price selection cards
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Your Preferred Bus Type',
                          style: AppTextStyles.heading.copyWith(
                            fontSize: 18,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select a bus type to see available seats and book',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                // Normal/Standard
                                _buildPriceCard(
                                  title: 'Normal',
                                  description:
                                      'Standard seating with basic amenities',
                                  color: AppColors.waygoDarkBlue,
                                  icon: Icons.directions_bus,
                                  type: 'normal',
                                  price: _normalPrice,
                                  isSelected: _selectedBusType == 'normal',
                                ),
                                // Semi-Luxury
                                _buildPriceCard(
                                  title: 'Semi-Luxury',
                                  description:
                                      'More comfortable seats with AC and extra legroom',
                                  color: Colors.orange.shade700,
                                  icon: Icons.airline_seat_flat,
                                  type: 'semiLuxury',
                                  price: _semiLuxuryPrice,
                                  isSelected: _selectedBusType == 'semiLuxury',
                                ),
                                // Luxury
                                _buildPriceCard(
                                  title: 'Luxury',
                                  description:
                                      'Premium comfort with reclining seats and entertainment',
                                  color: Colors.purple.shade700,
                                  icon: Icons.airline_seat_recline_extra,
                                  type: 'luxury',
                                  price: _luxuryPrice,
                                  isSelected: _selectedBusType == 'luxury',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Seat count and total summary
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.waygoPaleBackground.withOpacity(
                              0.4,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Number of seats',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.textDark,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed:
                                            _seatCount > 1 && !_isProcessing
                                            ? () => setState(() => _seatCount--)
                                            : null,
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                      ),
                                      Text(
                                        _seatCount.toString(),
                                        style: AppTextStyles.heading.copyWith(
                                          fontSize: 18,
                                          color: AppColors.waygoDarkBlue,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed:
                                            !_isProcessing &&
                                                _seatCount < _totalSeats
                                            ? () => setState(() => _seatCount++)
                                            : null,
                                        icon: const Icon(
                                          Icons.add_circle_outline,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _selectedPrice != null
                                    ? 'Rs ${_selectedPrice!.toStringAsFixed(0)} per seat'
                                    : 'Select a bus type to see price',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _selectedPrice != null
                                    ? 'Total: LKR ${_totalPrice.toStringAsFixed(0)}'
                                    : 'Total: --',
                                style: AppTextStyles.heading.copyWith(
                                  color: AppColors.waygoDarkBlue,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Confirm & Pay
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed:
                                _selectedBusType != null && !_isProcessing
                                ? _confirmAndPay
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.waygoLightBlue,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isProcessing
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.waygoDarkBlue,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Confirm & Pay',
                                        style: AppTextStyles.button.copyWith(
                                          color: Colors.white,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.lock_open,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
