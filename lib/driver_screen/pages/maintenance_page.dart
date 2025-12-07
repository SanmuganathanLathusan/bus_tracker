import 'package:flutter/material.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Main page with tabs (My Reports / New Report)
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 150, 208, 245),

        body: Column(
          children: [

            // Header + TabBar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Maintenance & Reports", style: AppTextStyles.heading),

                  const SizedBox(height: 16),

                  const TabBar(
                    labelColor: Color.fromARGB(255, 6, 6, 173),
                    unselectedLabelColor: Color.fromARGB(255, 15, 11, 11),
                    indicatorColor: Color.fromARGB(255, 89, 147, 240),
                    tabs: [
                      Tab(text: "My Reports"),
                      Tab(text: "New Report"),
                    ],
                  ),
                ],
              ),
            ),

            // Page switching
            const Expanded(
              child: TabBarView(
                children: [
                  MaintenanceReportsList(),
                  NewMaintenanceReportForm(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// LIST OF USER'S PREVIOUS REPORTS

class MaintenanceReportsList extends StatelessWidget {
  const MaintenanceReportsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Static list of sample reports (dummy data)
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        _buildReportCard(
          date: "Oct 31, 2025",
          issue: "AC not working",
          status: "Pending",
          statusColor: Colors.orange,
        ),

        _buildReportCard(
          date: "Oct 29, 2025",
          issue: "Tire replaced",
          status: "Resolved",
          statusColor: Colors.green,
        ),

        _buildReportCard(
          date: "Oct 25, 2025",
          issue: "Engine noise",
          status: "Resolved",
          statusColor: Colors.green,
        ),
      ],
    );
  }

  // Card for each maintenance report
  Widget _buildReportCard({
    required String date,
    required String issue,
    required String status,
    required Color statusColor,
  }) {
    return Card(
      elevation: 3,
      shadowColor: AppColors.shadowLight,
      color: AppColors.backgroundSecondary,
      margin: const EdgeInsets.only(bottom: 16),

      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // Date + Status Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
                ),

                // Status label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Issue name
            Text(
              issue,
              style: AppTextStyles.subHeading.copyWith(
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 15),

            // Action buttons (View Details / Follow Up)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.accentPrimary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text("View Details"),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentPrimary,
                      foregroundColor: AppColors.textLight,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Follow Up"),
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


