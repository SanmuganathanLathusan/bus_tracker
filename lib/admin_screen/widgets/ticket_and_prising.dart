import 'package:flutter/material.dart';
import 'package:waygo/services/admin_service.dart';

class TicketPricingWidget extends StatefulWidget {
  const TicketPricingWidget({Key? key}) : super(key: key);

  @override
  State<TicketPricingWidget> createState() => _TicketPricingWidgetState();
}

class _TicketPricingWidgetState extends State<TicketPricingWidget> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _routes = [];
  Map<String, dynamic> _stats = {
    'totalIncome': 0.0,
    'totalSold': 0,
    'averagePrice': 0.0,
    'activeRoutes': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadPricingData();
  }

  Future<void> _loadPricingData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _adminService.getPricingStats();
      final routes = List<Map<String, dynamic>>.from(data['routes'] ?? []);
      final stats = Map<String, dynamic>.from(data['stats'] ?? {});

      setState(() {
        _routes = routes;
        _stats = {
          'totalIncome': (stats['totalIncome'] ?? 0).toDouble(),
          'totalSold': stats['totalSold'] ?? 0,
          'averagePrice': (stats['averagePrice'] ?? 0).toDouble(),
          'activeRoutes': stats['activeRoutes'] ?? 0,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load pricing data: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error', style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPricingData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final totalIncome = _stats['totalIncome'] as double;
    final totalSold = _stats['totalSold'] as int;
    final avgPrice = _stats['averagePrice'] as double;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Ticket & Pricing Management',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _loadPricingData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Summary Cards in Grid
          LayoutBuilder(
            builder: (context, constraints) {
              int crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 3,
                children: [
                  _buildSummaryCard(
                    'Total Income',
                    'Rs ${totalIncome.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                  _buildSummaryCard(
                    'Tickets Sold',
                    '$totalSold',
                    Icons.confirmation_number,
                    Colors.blue,
                  ),
                  _buildSummaryCard(
                    'Average Price',
                    'Rs ${avgPrice.toStringAsFixed(2)}',
                    Icons.price_change,
                    Colors.purple,
                  ),
                  _buildSummaryCard(
                    'Active Routes',
                    '${_stats['activeRoutes']}',
                    Icons.route,
                    Colors.orange,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Route Cards
          _routes.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Text('No routes found'),
                  ),
                )
              : Column(
                  children: _routes.map((route) => _buildRouteCard(route)).toList(),
                ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(Map<String, dynamic> route) {
    bool reservationEnabled = route['reservation'] == 'Enabled';
    final routeName = route['route'] ?? '${route['start']} - ${route['destination']}';
    final price = route['price']?.toString() ?? '0.0';
    final capacity = route['capacity']?.toString() ?? '0';
    final sold = route['sold']?.toString() ?? '0';
    final income = route['income']?.toStringAsFixed(2) ?? '0.00';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scrollable Row for wide content
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Text(
                  routeName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Rs $price',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Income',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        'Rs $income',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Capacity, Sold, Reservation Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Icon(Icons.people, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  'Capacity: $capacity',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(width: 20),
                Icon(
                  Icons.confirmation_number,
                  size: 16,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Sold: $sold',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(width: 20),
                Icon(
                  reservationEnabled ? Icons.check_circle : Icons.cancel,
                  size: 16,
                  color: reservationEnabled ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 4),
                Text(
                  'Reservation ${route['reservation'] ?? 'Enabled'}',
                  style: TextStyle(
                    color: reservationEnabled ? Colors.green : Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action buttons using Wrap for responsiveness
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit Price', style: TextStyle(fontSize: 12)),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: Icon(
                  reservationEnabled ? Icons.toggle_on : Icons.toggle_off,
                  size: 20,
                ),
                label: const Text(
                  'Toggle Reservation',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text(
                  'View Details',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
