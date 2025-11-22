import 'package:flutter/material.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';
import 'package:waygo/services/api_service.dart';
import 'cusmot_widget/live_time.dart';

class PassengerDashboard extends StatefulWidget {
  const PassengerDashboard({super.key});

  @override
  State<PassengerDashboard> createState() => _PassengerDashboardState();
}

class _PassengerDashboardState extends State<PassengerDashboard> {
  bool _isNewUser = false;

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
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      final isNew = await AuthService().isFirstLogin();
      if (mounted) setState(() => _isNewUser = isNew);
    } catch (_) {
      setState(() => _isNewUser = false);
    }
  }

  void _handleBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      if (_isNewUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Welcome to WayGo! You’re already on the dashboard."),
          ),
        );
      } else {
        Navigator.maybePop(context);
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.waygoPaleBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Logout",
          style: AppTextStyles.heading.copyWith(color: AppColors.waygoDarkBlue),
        ),
        content: Text(
          "Are you sure you want to log out?",
          style: AppTextStyles.body.copyWith(color: AppColors.waygoDarkBlue),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              "Cancel",
              style: TextStyle(
                color: AppColors.waygoDarkBlue.withValues(alpha: 0.8),
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.waygoDarkBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await AuthService().logout();
      } catch (_) {}

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/welcome',
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 1, 9, 19),
      body: SafeArea(
        child: Stack(
          children: [
            /// 🔹 Scrollable content
            Column(
              children: [
                Stack(
                  children: [
                    /// Banner image (non-interactive)
                    IgnorePointer(
                      child: Image.asset(
                        "assest/banner.jpg",
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    ),

                    /// 🔙 Back button
                    Positioned(
                      top: 12,
                      left: 12,
                      child: GestureDetector(
                        onTap: () => _handleBack(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),

                    /// 🚪 Logout button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _handleLogout(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),

                    /// Banner texts
                    Positioned(
                      left: 20,
                      bottom: 30,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "WayGo",
                            style: AppTextStyles.heading.copyWith(
                              color: const Color.fromARGB(255, 6, 36, 76),
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Smarter travel, simpler journeys",
                            style: AppTextStyles.body.copyWith(
                              color: const Color.fromARGB(255, 14, 33, 40),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Positioned(
                      right: 20,
                      bottom: 30,
                      child: LiveDateTime(),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                /// Dashboard grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: GridView.builder(
                      itemCount: items.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
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
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Dashboard Item
class _DashboardItem {
  final String imagePath;
  final IconData icon;
  final String label;
  final String route;

  const _DashboardItem(this.imagePath, this.icon, this.label, this.route);
}

/// Dashboard Card
class _DashboardCard extends StatelessWidget {
  final _DashboardItem item;

  const _DashboardCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, item.route),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.waygoDarkBlue.withValues(alpha: 0.15),
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
                color: AppColors.waygoDarkBlue.withValues(alpha: 0.5),
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
