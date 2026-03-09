import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waygo/services/reservation_service.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';
import 'eticket_price_selection_page.dart';

/// E-Ticket Booking Page
/// Similar to schedule_page.dart - allows searching routes and booking tickets
class EticketBookingPage extends StatefulWidget {
  const EticketBookingPage({super.key});

  @override
  State<EticketBookingPage> createState() => _EticketBookingPageState();
}

class _EticketBookingPageState extends State<EticketBookingPage> {
  final List<String> _cities = [
    'Colombo',
    'Kandy',
    'Galle',
    'Matara',
    'Jaffna',
    'Negombo',
    'Anuradhapura',
    'Trincomalee',
  ];

  String _from = 'Colombo';
  String _to = 'Kandy';
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _routes = [];

  final ReservationService _reservationService = ReservationService();

  String get _formattedDate => DateFormat('dd MMM yyyy').format(_selectedDate);
  String get _dateForApi => DateFormat('yyyy-MM-dd').format(_selectedDate);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.waygoDarkBlue,
              onPrimary: Colors.white,
              surface: AppColors.backgroundSecondary,
              onSurface: AppColors.textDark,
            ),
            dialogBackgroundColor: AppColors.backgroundSecondary,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _searchRoutes() async {
    FocusScope.of(context).unfocus();
    if (_from.isEmpty || _to.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select origin and destination')),
      );
      return;
    }

    if (_from == _to) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Origin and destination must be different'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _routes = [];
    });

    try {
      final results = await _reservationService.searchRoutes(
        start: _from,
        destination: _to,
        date: _dateForApi,
      );
      final List<Map<String, dynamic>> normalized = (results ?? [])
          .map<Map<String, dynamic>>((r) {
            final routeData = Map<String, dynamic>.from(r as Map);
            // If the data has a nested 'route' object, extract it
            if (routeData.containsKey('route') && routeData['route'] is Map) {
              return Map<String, dynamic>.from(routeData['route'] as Map);
            }
            return routeData;
          })
          .toList();

      setState(() {
        _routes = normalized;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error: ${e.toString()}')),
        );
      }
    }
  }

  void _swapLocations() {
    setState(() {
      final t = _from;
      _from = _to;
      _to = t;
    });
  }

  Widget _searchCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.waygoDarkBlue,
            AppColors.waygoDarkBlue.withOpacity(0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.waygoDarkBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Location selectors
          Row(
            children: [
              Expanded(
                child: _modernDropdown(
                  label: 'From',
                  icon: Icons.trip_origin,
                  value: _from,
                  onChanged: (v) => setState(() => _from = v!),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: IconButton(
                  onPressed: _swapLocations,
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.waygoLightBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.swap_horiz_rounded,
                      color: AppColors.waygoLightBlue,
                      size: 24,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _modernDropdown(
                  label: 'To',
                  icon: Icons.location_on,
                  value: _to,
                  onChanged: (v) => setState(() => _to = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Date picker and search button
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.waygoLightBlue.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.waygoLightBlue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_today_outlined,
                            color: AppColors.waygoLightBlue,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Travel Date',
                              style: AppTextStyles.body.copyWith(
                                fontSize: 11,
                                color: AppColors.waygoLightBlue.withOpacity(
                                  0.8,
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formattedDate,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.waygoWhite,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _searchRoutes,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.waygoLightBlue,
                  foregroundColor: AppColors.waygoDarkBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.search, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Search',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modernDropdown({
    required String label,
    required IconData icon,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: AppColors.waygoLightBlue.withOpacity(0.8),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.waygoLightBlue.withOpacity(0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.waygoLightBlue.withOpacity(0.3),
            ),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: AppColors.waygoLightBlue),
            style: AppTextStyles.body.copyWith(
              color: AppColors.waygoWhite,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
            dropdownColor: AppColors.waygoDarkBlue,
            items: _cities
                .map(
                  (c) => DropdownMenuItem(
                    value: c,
                    child: Text(
                      c,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.waygoWhite,
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> r, int index) {
    // Route data is already extracted at top level from searchRoutes
    // No need to check for nested routeId since we extracted it earlier

    // Route ID
    final routeId = r['_id']?.toString() ?? 'N/A';

    // Route information - use direct access since data is already extracted
    final start = r['start'] ?? '';
    final destination = r['destination'] ?? '';
    final routeName = '$start - $destination';

    // Times
    final departure = r['departure'] ?? '';
    final arrival = r['arrival'] ?? '';
    final duration = r['duration'] ?? '';

    // Distance/Kilometers
    final distance = r['distance'];
    final distanceStr = distance != null ? '${distance.toString()} km' : '';

    final routeNumber = r['routeNumber']?.toString() ?? '';
    final busName = r['busName'] ?? 'Standard Service';
    final busType = r['busType'] ?? 'Standard';
    final totalSeats = r['totalSeats'] ?? 40;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to price selection page
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EticketPriceSelectionPage(
                  routeDetails: {
                    '_id': routeId,
                    'routeId': routeId,
                    'start': start,
                    'destination': destination,
                    'departure': departure,
                    'arrival': arrival,
                    'duration': duration,
                    'distance': distance,
                    'routeNumber': routeNumber,
                    'busName': busName,
                    'busType': busType,
                    'totalSeats': totalSeats,
                    // Prices from database - ensure they're passed as numbers
                    'price': r['price'] ?? 0,
                    'priceDeluxe': r['priceDeluxe'],
                    'priceLuxury': r['priceLuxury'],
                  },
                  selectedDate: _selectedDate,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Route ID and Route Name
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.route,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Route ID: ${routeId.substring(0, 8)}...',
                                style: AppTextStyles.body.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            routeName,
                            style: AppTextStyles.heading.copyWith(
                              fontSize: 16,
                              color: AppColors.waygoDarkBlue,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    if (routeNumber.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.waygoDarkBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '#$routeNumber',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 11,
                            color: AppColors.waygoDarkBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Time and duration row
                Row(
                  children: [
                    // Departure
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Dispatch',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            departure.toString(),
                            style: AppTextStyles.heading.copyWith(
                              fontSize: 20,
                              color: AppColors.waygoDarkBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Duration indicator
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.waygoLightBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: AppColors.waygoLightBlue.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: AppColors.waygoLightBlue,
                              ),
                              Expanded(
                                child: Container(
                                  height: 2,
                                  color: AppColors.waygoLightBlue.withOpacity(
                                    0.3,
                                  ),
                                ),
                              ),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppColors.waygoLightBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ),
                          if (duration.toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              duration.toString(),
                              style: AppTextStyles.body.copyWith(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Arrival
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Arrival',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            arrival.toString(),
                            style: AppTextStyles.heading.copyWith(
                              fontSize: 20,
                              color: AppColors.waygoDarkBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Kilometers and Total Time info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.waygoPaleBackground.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      // Kilometers
                      if (distanceStr.isNotEmpty) ...[
                        Icon(
                          Icons.straighten,
                          size: 16,
                          color: AppColors.waygoDarkBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          distanceStr,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 12,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      // Total Time
                      if (duration.toString().isNotEmpty) ...[
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: AppColors.waygoDarkBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Total: $duration',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 12,
                            color: AppColors.textDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _resultsSection() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.waygoDarkBlue,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Searching schedules...',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: AppTextStyles.heading.copyWith(color: AppColors.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _searchRoutes,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.waygoDarkBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_routes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.waygoPaleBackground.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search,
                size: 64,
                color: AppColors.textSecondary.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Book Your E-Ticket',
              style: AppTextStyles.heading.copyWith(
                color: AppColors.textDark,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select your route and date to view\navailable schedules and book tickets',
              style: AppTextStyles.body.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Sort by departure time
    _routes.sort((a, b) {
      final ta =
          (a['routeId'] is Map ? a['routeId']['departure'] : a['departure']) ??
          '';
      final tb =
          (b['routeId'] is Map ? b['routeId']['departure'] : b['departure']) ??
          '';
      return ta.toString().compareTo(tb.toString());
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_routes.length} schedules found',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _searchRoutes,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.waygoDarkBlue,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: _routes.length,
            itemBuilder: (context, i) => _buildScheduleCard(_routes[i], i),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=1200&q=80',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.white.withOpacity(0.70),
              BlendMode.lighten,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.waygoDarkBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: AppColors.waygoLightBlue,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Book E-Ticket',
                            style: AppTextStyles.heading.copyWith(
                              color: AppColors.textDark,
                              fontSize: 24,
                            ),
                          ),
                          Text(
                            'Search and book your journey',
                            style: AppTextStyles.body.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _searchCard(),
                const SizedBox(height: 16),
                Expanded(child: _resultsSection()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
