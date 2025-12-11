import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';
import 'package:waygo/services/maintenance_service.dart';
import 'package:waygo/driver_screen/widgets/route_assignment.dart';
import 'package:intl/intl.dart';

class MaintenancePage extends StatefulWidget {
  final RouteAssignment? activeAssignment;
  
  const MaintenancePage({Key? key, this.activeAssignment}) : super(key: key);

  @override
  State<MaintenancePage> createState() => _MaintenancePageState();
}

class _MaintenancePageState extends State<MaintenancePage> {
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
                  NewMaintenanceReportForm(activeAssignment: widget.activeAssignment),
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
  State<MaintenanceReportsList> createState() => _MaintenanceReportsListState();
}

class _MaintenanceReportsListState extends State<MaintenanceReportsList> {
  final MaintenanceService _maintenanceService = MaintenanceService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _reports = [];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reports = await _maintenanceService.getDriverReports();
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

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
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReports,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: _reports.map((report) => _buildReportCard(report)).toList(),
      ),
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
                    statusLabel,
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
                Icon(Icons.directions_bus, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Bus: $busInfo',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.grey.shade600,
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // --- Issue Description ---
            Text(
              description,
              style: AppTextStyles.subHeading.copyWith(
                color: AppColors.textPrimary,
              ),
            ),

            // --- Image if available ---
            if (imageUrl != null && imageUrl.toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  'http://10.0.2.2:5000/$imageUrl',
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 150,
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'received':
        return 'Received';
      case 'not_received':
        return 'Not Received';
      case 'resolved':
        return 'Resolved';
      case 'unsent':
        return 'Draft';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'received':
        return Colors.blue;
      case 'not_received':
        return Colors.red;
      case 'resolved':
        return Colors.green;
      case 'unsent':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}

class NewMaintenanceReportForm extends StatefulWidget {
  final RouteAssignment? activeAssignment;
  
  const NewMaintenanceReportForm({Key? key, this.activeAssignment}) : super(key: key);

  @override
  State<NewMaintenanceReportForm> createState() => _NewMaintenanceReportFormState();
}


// NEW MAINTENANCE REPORT FORM

class NewMaintenanceReportForm extends StatelessWidget {
  const NewMaintenanceReportForm({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Scrollable form for submitting new issues
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text("Submit New Report", style: AppTextStyles.subHeading),
          const SizedBox(height: 16),

          // Issue type section
          Text(
            "Issue Type",
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          DropdownButtonFormField<String>(
            items: const [
              DropdownMenuItem(value: "engine", child: Text("Engine")),
              DropdownMenuItem(value: "brakes", child: Text("Brakes")),
              DropdownMenuItem(value: "tires", child: Text("Tires")),
              DropdownMenuItem(value: "ac", child: Text("AC / Cooling")),
              DropdownMenuItem(value: "electrical", child: Text("Electrical")),
              DropdownMenuItem(value: "other", child: Text("Other")),
            ],
            onChanged: (value) {},

            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.backgroundSecondary,

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.accentPrimary,
                  width: 1.5,
                ),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),

              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Description box
          Text(
            "Description",
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          TextFormField(
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Describe the issue in detail...",
              filled: true,
              fillColor: AppColors.backgroundSecondary,

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.accentPrimary,
                  width: 1.5,
                ),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Image upload area
          Text(
            "Upload Photo (Optional)",
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 8),

          Card(
            elevation: 2,
            color: AppColors.backgroundSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),

            child: InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(12),

              child: const SizedBox(
                height: 150,

                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text("Tap to add photo", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
          ),

          const SizedBox(height: 24),

          // Submit button
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentPrimary,
                foregroundColor: AppColors.textLight,
                padding: const EdgeInsets.symmetric(vertical: 16),

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              child: const Text(
                "Submit Report",
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete_forever),
                title: const Text('Remove photo'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedImage = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}


