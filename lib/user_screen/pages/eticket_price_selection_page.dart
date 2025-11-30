import 'package:flutter/material.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';
import 'seat_reserve/route_details.dart';
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
  State<EticketPriceSelectionPage> createState() => _EticketPriceSelectionPageState();
}

class _EticketPriceSelectionPageState extends State<EticketPriceSelectionPage> {
  String? _selectedBusType;
  double? _selectedPrice;

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

  String get _routeName => '${widget.routeDetails['start'] ?? ''} - ${widget.routeDetails['destination'] ?? ''}';

  void _selectBusType(String type, double price) {
    setState(() {
      _selectedBusType = type;
      _selectedPrice = price;
    });
  }

  void _proceedToSeatSelection() {
    if (_selectedBusType == null || _selectedPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a bus type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Update route details with selected price
    final updatedRouteDetails = {
      ...widget.routeDetails,
      'price': _selectedPrice,
      'selectedBusType': _selectedBusType,
    };

    // Navigate to seat selection (route_details.dart)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouteDetailsScreen(
          routeDetails: updatedRouteDetails,
          selectedDate: widget.selectedDate,
        ),
      ),
    );
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
                            onTap: isAvailable
          ? () => _selectBusType(type, price)
          : null,
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
                        ? 'Rs ${price.toStringAsFixed(0)}'
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
                                  description: 'Standard seating with basic amenities',
                                  color: AppColors.waygoDarkBlue,
                                  icon: Icons.directions_bus,
                                  type: 'normal',
                                  price: _normalPrice,
                                  isSelected: _selectedBusType == 'normal',
                                ),
                                // Semi-Luxury
                                _buildPriceCard(
                                  title: 'Semi-Luxury',
                                  description: 'More comfortable seats with AC and extra legroom',
                                  color: Colors.orange.shade700,
                                  icon: Icons.airline_seat_flat,
                                  type: 'semiLuxury',
                                  price: _semiLuxuryPrice,
                                  isSelected: _selectedBusType == 'semiLuxury',
                                ),
                                // Luxury
                                _buildPriceCard(
                                  title: 'Luxury',
                                  description: 'Premium comfort with reclining seats and entertainment',
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
                        const SizedBox(height: 16),
                        // Continue button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _proceedToSeatSelection,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _selectedBusType != null
                                  ? AppColors.waygoLightBlue
                                  : Colors.grey,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Continue to Seat Selection',
                                  style: AppTextStyles.button.copyWith(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward,
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

