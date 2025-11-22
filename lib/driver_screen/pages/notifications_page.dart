import 'package:flutter/material.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 150, 208, 245),
      body: Column(
        children: [
          // --- Header + Tabs ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Notifications & Alerts", style: AppTextStyles.heading),
                const SizedBox(height: 16),

                DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      const TabBar(
                        labelColor: Color.fromARGB(255, 6, 6, 173),
                        unselectedLabelColor: Color.fromARGB(255, 15, 11, 11),
                        indicatorColor: Color.fromARGB(255, 89, 147, 240),
                        tabs: [
                          Tab(text: "All"),
                          Tab(text: "Alerts"),
                          Tab(text: "Updates"),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // --- Quick Action Buttons ---
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.mark_email_read),
                              label: const Text("Mark All Read"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.backgroundSecondary,
                                foregroundColor: AppColors.textPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.filter_list),
                              label: const Text("Filter"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.backgroundSecondary,
                                foregroundColor: AppColors.textPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFE0E0E0)),

          // --- Notifications List ---
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildNotificationCard(
                  type: "Alert",
                  message: "Traffic ahead on Route 5",
                  time: "10:45 AM",
                  isRead: false,
                  icon: Icons.warning,
                  iconColor: Colors.orange,
                ),
                _buildNotificationCard(
                  type: "Update",
                  message: "Trip delayed by 15 mins",
                  time: "11:00 AM",
                  isRead: true,
                  icon: Icons.info,
                  iconColor: AppColors.accentPrimary,
                ),
                _buildNotificationCard(
                  type: "Alert",
                  message: "Severe weather warning for afternoon trips",
                  time: "Yesterday",
                  isRead: true,
                  icon: Icons.cloud,
                  iconColor: Colors.purple,
                ),
                _buildNotificationCard(
                  type: "Update",
                  message: "New schedule published for next week",
                  time: "Oct 30",
                  isRead: true,
                  icon: Icons.calendar_today,
                  iconColor: Colors.green,
                ),
                _buildNotificationCard(
                  type: "Alert",
                  message: "Maintenance required for bus SP-1234",
                  time: "Oct 29",
                  isRead: true,
                  icon: Icons.build,
                  iconColor: Colors.red,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard({
    required String type,
    required String message,
    required String time,
    required bool isRead,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isRead
          ? AppColors.backgroundSecondary
          : AppColors.accentPrimary.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Notification Header ---
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type + Time
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            type,
                            style: AppTextStyles.subHeading.copyWith(
                              color: iconColor,
                            ),
                          ),
                          Text(
                            time,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Message
                      Text(
                        message,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // --- Action Buttons ---
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isRead)
                  TextButton(
                    onPressed: () {},
                    child: const Text("Mark as Read"),
                  ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentPrimary,
                    foregroundColor: AppColors.textLight,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("View Details"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
