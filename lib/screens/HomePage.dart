import 'package:flutter/material.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  final List<_DashboardItem> items = const [
    _DashboardItem(
      "assest/main_news.jpg",
      Icons.article,
      "Main News Feed",
      '/news',
    ),
    _DashboardItem(
      "assest/live_location.jpg",
      Icons.location_city_outlined,
      "Live Location",
      '/live_location',
    ),
    _DashboardItem(
      "assest/schedule.jpg",
      Icons.schedule,
      "Bus Schedule",
      '/schedule',
    ),
    _DashboardItem(
      "assest/seat_reserve.jpg",
      Icons.bus_alert_sharp,
      "Seat Reservation",
      '/seats',
    ),
    _DashboardItem(
      "assest/ticket_price.jpg",
      Icons.price_change_rounded,
      "Ticket Prices",
      '/prices',
    ),
    _DashboardItem(
      "assest/eticket.jpg",
      Icons.e_mobiledata,
      "Purchase E-Tickets",
      '/eticket',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C2442),
      appBar: AppBar(
        backgroundColor: AppColors.waygoDarkBlue,
        title: const Text("WayGo"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () {
              // Navigate back to login page
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Top banner with background image and overlay text
          Stack(
            children: [
              Image.asset(
                "assest/banner.jpg",
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
              Container(
                width: double.infinity,
                height: 200,
                color: AppColors.waygoDarkBlue.withOpacity(0.5),
              ),
              Positioned(
                left: 20,
                bottom: 30,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "WayGo",
                      style: AppTextStyles.heading.copyWith(
                        color: AppColors.textLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Smarter travel, simpler journeys",
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: GridView.builder(
                itemCount: items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _DashboardCard(item: item);
                },
              ),
            ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}

class _DashboardItem {
  final String imagePath;
  final IconData icon;
  final String label;
  final String route;

  const _DashboardItem(this.imagePath, this.icon, this.label, this.route);
}

class _DashboardCard extends StatelessWidget {
  final _DashboardItem item;

  const _DashboardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, item.route);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.waygoDarkBlue.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(item.imagePath, fit: BoxFit.cover),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.waygoDarkBlue.withOpacity(0.5),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(item.icon, size: 36, color: AppColors.accentPrimary),
                  const SizedBox(height: 8),
                  Text(
                    item.label,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.subHeading.copyWith(
                      color: AppColors.textLight,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
