import 'package:flutter/material.dart';

class OverviewWidget extends StatelessWidget {
  const OverviewWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Overview & Analytics',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),

          // ✅ Responsive Stat Cards Section
          LayoutBuilder(
            builder: (context, constraints) {
              double cardWidth =
                  (constraints.maxWidth - 16) / 2; // Two cards per row
              if (constraints.maxWidth < 700) {
                // One card per row for smaller screens
                cardWidth = constraints.maxWidth;
              }

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _buildMetricCard(
                    'Daily Revenue',
                    '\$2,450',
                    Icons.attach_money,
                    Colors.green,
                    '+15%',
                    cardWidth,
                  ),
                  _buildMetricCard(
                    'Response Time',
                    '1.2s',
                    Icons.speed,
                    Colors.blue,
                    '-8%',
                    cardWidth,
                  ),
                  _buildMetricCard(
                    'Growth Rate',
                    '23%',
                    Icons.trending_up,
                    Colors.purple,
                    '+5%',
                    cardWidth,
                  ),
                  _buildMetricCard(
                    'Active Routes',
                    '18',
                    Icons.route,
                    Colors.orange,
                    '+2',
                    cardWidth,
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 24),

          // ✅ Responsive Bus Fleet Status + Recent Activities
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 900) {
                // Side by side for large screens
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildFleetStatusCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildRecentActivitiesCard()),
                  ],
                );
              } else {
                // Stack vertically for smaller screens
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFleetStatusCard(),
                    const SizedBox(height: 16),
                    _buildRecentActivitiesCard(),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 24),
          _buildSystemAlertsCard(),
        ],
      ),
    );
  }

  // ✅ Metric Card (Responsive)
  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String change,
    double width,
  ) {
    return Container(
      width: width,
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
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFleetStatusCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          const Text(
            'Bus Fleet Status',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildFleetItem('On Route', 28, Colors.green, 0.67),
          const SizedBox(height: 12),
          _buildFleetItem('Delayed', 8, Colors.orange, 0.19),
          const SizedBox(height: 12),
          _buildFleetItem('Maintenance', 6, Colors.red, 0.14),
        ],
      ),
    );
  }

  Widget _buildFleetItem(
    String status,
    int count,
    Color color,
    double percentage,
  ) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            status,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade200,
            color: color,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivitiesCard() {
    final activities = [
      {
        'icon': Icons.person_add,
        'text': 'New user registered',
        'time': '2 min ago',
        'color': Colors.green,
      },
      {
        'icon': Icons.directions_bus,
        'text': 'Bus #205 went offline',
        'time': '15 min ago',
        'color': Colors.red,
      },
      {
        'icon': Icons.confirmation_number,
        'text': '45 tickets sold',
        'time': '1 hour ago',
        'color': Colors.blue,
      },
      {
        'icon': Icons.warning,
        'text': 'Route 8 delayed',
        'time': '2 hours ago',
        'color': Colors.orange,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
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
          const Text(
            'Recent Activities',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...activities.map(
            (activity) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (activity['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      activity['icon'] as IconData,
                      size: 20,
                      color: activity['color'] as Color,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity['text'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          activity['time'] as String,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemAlertsCard() {
    final alerts = [
      {
        'title': 'Database backup pending',
        'severity': 'Warning',
        'time': '30 min ago',
        'color': Colors.orange,
      },
      {
        'title': 'Payment gateway connection restored',
        'severity': 'Info',
        'time': '1 hour ago',
        'color': Colors.blue,
      },
      {
        'title': 'High server load detected',
        'severity': 'Critical',
        'time': '2 hours ago',
        'color': Colors.red,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(24),
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
          const Text(
            'System Alerts',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...alerts.map(
            (alert) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (alert['color'] as Color).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (alert['color'] as Color).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: alert['color'] as Color,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          alert['title'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alert['time'] as String,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (alert['color'] as Color).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      alert['severity'] as String,
                      style: TextStyle(
                        color: alert['color'] as Color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
