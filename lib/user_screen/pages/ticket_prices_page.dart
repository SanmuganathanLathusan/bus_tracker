import 'package:flutter/material.dart';
import 'package:waygo/services/reservation_service.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';

/// file: lib/user_screen/pages/ticket_prices_page.dart
/// Display route number, route, and prices by type (normal, semi-luxurious, luxury)

/// -----------------------------
/// MODELS
/// -----------------------------
class RoutePrice {
  final String routeNumber;
  final String route;
  final double? distance;
  final double normalPrice;
  final double? semiLuxuriousPrice;
  final double? luxuryPrice;

  RoutePrice({
    required this.routeNumber,
    required this.route,
    this.distance,
    required this.normalPrice,
    this.semiLuxuriousPrice,
    this.luxuryPrice,
  });

  factory RoutePrice.fromJson(Map<String, dynamic> json) {
    final prices = json['prices'] as Map<String, dynamic>? ?? {};
    return RoutePrice(
      routeNumber: json['routeNumber']?.toString() ?? 'N/A',
      route: json['route']?.toString() ?? '',
      distance: json['distance'] != null
          ? (json['distance'] as num).toDouble()
          : null,
      normalPrice: prices['normal'] != null
          ? (prices['normal'] as num).toDouble()
          : 0.0,
      semiLuxuriousPrice: prices['semiLuxurious'] != null
          ? (prices['semiLuxurious'] as num).toDouble()
          : null,
      luxuryPrice: prices['luxury'] != null
          ? (prices['luxury'] as num).toDouble()
          : null,
    );
  }
}

/// -----------------------------
/// PAGE — TICKET PRICES
/// -----------------------------
class TicketPricesPage extends StatefulWidget {
  const TicketPricesPage({super.key});

  @override
  State<TicketPricesPage> createState() => _TicketPricesPageState();
}

class _TicketPricesPageState extends State<TicketPricesPage> {
  final ReservationService _reservationService = ReservationService();
  List<RoutePrice> _routes = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _sortBy = 'route'; // 'route', 'normal', 'semi', 'luxury'
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _loadRoutePrices();
  }

  Future<void> _loadRoutePrices() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _reservationService.getRoutePricesByType();
      setState(() {
        _routes = data.map((json) => RoutePrice.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading prices: ${e.toString()}')),
        );
      }
    }
  }

  List<RoutePrice> get _filteredRoutes {
    var filtered = List<RoutePrice>.from(_routes);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((route) {
        return route.route.toLowerCase().contains(query) ||
            route.routeNumber.toLowerCase().contains(query);
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'route':
          comparison = a.route.compareTo(b.route);
          break;
        case 'normal':
          comparison = a.normalPrice.compareTo(b.normalPrice);
          break;
        case 'semi':
          comparison = (a.semiLuxuriousPrice ?? 0.0).compareTo(
            b.semiLuxuriousPrice ?? 0.0,
          );
          break;
        case 'luxury':
          comparison = (a.luxuryPrice ?? 0.0).compareTo(b.luxuryPrice ?? 0.0);
          break;
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
  }

  void _sort(String column) {
    setState(() {
      if (_sortBy == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortBy = column;
        _sortAscending = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1544620347-c4fd4a3d5957?w=1200&q=80',
            ),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.3),
              BlendMode.darken,
            ),
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.maybePop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.waygoDarkBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 20,
                          color: AppColors.waygoDarkBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ticket Prices',
                            style: AppTextStyles.heading.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.waygoDarkBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'View prices by route and bus type',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _loadRoutePrices,
                      icon: const Icon(
                        Icons.refresh,
                        color: AppColors.waygoDarkBlue,
                      ),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search routes...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.95),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Table
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_error'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadRoutePrices,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _filteredRoutes.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty
                              ? 'No routes found'
                              : 'No routes match your search',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columnSpacing: 16,
                              horizontalMargin: 12,
                              headingRowColor: MaterialStateProperty.all(
                                AppColors.waygoDarkBlue.withOpacity(0.1),
                              ),
                              columns: [
                                _buildSortableColumn('Route #', 'routeNumber'),
                                _buildSortableColumn('Route', 'route'),
                                _buildSortableColumn('Normal', 'normal'),
                                _buildSortableColumn('Semi-Lux', 'semi'),
                                _buildSortableColumn('Luxury', 'luxury'),
                              ],
                              rows: _filteredRoutes.map((route) {
                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Text(
                                        route.routeNumber,
                                        style: AppTextStyles.body.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 120,
                                        child: Text(
                                          route.route,
                                          style: AppTextStyles.body.copyWith(
                                            fontSize: 13,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        'Rs ${route.normalPrice.toStringAsFixed(0)}',
                                        style: AppTextStyles.body.copyWith(
                                          color: AppColors.waygoDarkBlue,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        route.semiLuxuriousPrice != null
                                            ? 'Rs ${route.semiLuxuriousPrice!.toStringAsFixed(0)}'
                                            : 'N/A',
                                        style: AppTextStyles.body.copyWith(
                                          color:
                                              route.semiLuxuriousPrice != null
                                              ? Colors.orange.shade700
                                              : Colors.grey,
                                          fontWeight:
                                              route.semiLuxuriousPrice != null
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      Text(
                                        route.luxuryPrice != null
                                            ? 'Rs ${route.luxuryPrice!.toStringAsFixed(0)}'
                                            : 'N/A',
                                        style: AppTextStyles.body.copyWith(
                                          color: route.luxuryPrice != null
                                              ? Colors.purple.shade700
                                              : Colors.grey,
                                          fontWeight: route.luxuryPrice != null
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
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

  DataColumn _buildSortableColumn(String label, String sortKey) {
    final isSorted = _sortBy == sortKey;
    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.waygoDarkBlue,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (isSorted)
            Icon(
              _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: AppColors.waygoDarkBlue,
            ),
        ],
      ),
      onSort: (columnIndex, ascending) => _sort(sortKey),
    );
  }
}
