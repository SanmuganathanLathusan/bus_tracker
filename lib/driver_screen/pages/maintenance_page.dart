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

