import 'package:flutter/material.dart';

class TicketPricingWidget extends StatelessWidget {
  const TicketPricingWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final routes = [
      {
        'route': 'Route 5: Downtown - Airport',
        'price': '8.50',
        'capacity': '45',
        'sold': '234',
        'income': '1989',
        'reservation': 'Enabled',
      },
      {
        'route': 'Route 12: City Center - Beach',
        'price': '6.00',
        'capacity': '40',
        'sold': '189',
        'income': '1134',
        'reservation': 'Enabled',
      },
      {
        'route': 'Route 8: Mall - University',
        'price': '5.50',
        'capacity': '50',
        'sold': '312',
        'income': '1716',
        'reservation': 'Disabled',
      },
      {
        'route': 'Route 3: Station - Hospital',
        'price': '4.00',
        'capacity': '38',
        'sold': '156',
        'income': '624',
        'reservation': 'Enabled',
      },
    ];

    double totalIncome = routes.fold(
      0,
      (sum, route) => sum + double.parse(route['income']!),
    );
    int totalSold = routes.fold(
      0,
      (sum, route) => sum + int.parse(route['sold']!),
    );
    double avgPrice =
        routes.fold(0.0, (sum, route) => sum + double.parse(route['price']!)) /
        routes.length;

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
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add Route'),
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
                    '\$${totalIncome.toStringAsFixed(2)}',
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
                    '\$${avgPrice.toStringAsFixed(2)}',
                    Icons.price_change,
                    Colors.purple,
                  ),
                  _buildSummaryCard(
                    'Active Routes',
                    '${routes.length}',
                    Icons.route,
                    Colors.orange,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // Route Cards
          Column(
            children: routes.map((route) => _buildRouteCard(route)).toList(),
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

  Widget _buildRouteCard(Map<String, String> route) {
    bool reservationEnabled = route['reservation'] == 'Enabled';

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
                  route['route']!,
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
                    '\$${route['price']}',
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
                        '${route['income']}',
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
                  'Capacity: ${route['capacity']}',
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
                  'Sold: ${route['sold']}',
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
                  'Reservation ${route['reservation']}',
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
