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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color.fromARGB(255, 150, 208, 245),
        body: Column(
          children: [
            // --- Header ---
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

            Expanded(
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

class MaintenanceReportsList extends StatefulWidget {
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
              onPressed: _loadReports,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No reports yet',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
            ),
          ],
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

  Widget _buildReportCard(dynamic report) {
    final date = report['createdAt'] != null
        ? DateFormat('MMM dd, yyyy').format(DateTime.parse(report['createdAt']))
        : 'Unknown date';
    final issueType = report['issueType'] ?? 'other';
    final issueTypeLabel = issueType.substring(0, 1).toUpperCase() + issueType.substring(1);
    final description = report['description'] ?? 'No description';
    final status = report['status'] ?? 'unsent';
    final statusLabel = _getStatusLabel(status);
    final statusColor = _getStatusColor(status);
    final imageUrl = report['imageUrl'];
    final busInfo = report['busId'] is Map
        ? (report['busId']['busNumber'] ?? report['busId']['busName'] ?? 'Unknown Bus')
        : 'Unknown Bus';

    return Card(
      elevation: 3,
      shadowColor: AppColors.shadowLight,
      color: AppColors.backgroundSecondary,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Date & Status ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  date,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
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

            // --- Bus Info ---
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
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    issueTypeLabel,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
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

class _NewMaintenanceReportFormState extends State<NewMaintenanceReportForm> {
  final MaintenanceService _maintenanceService = MaintenanceService();
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  
  String? _selectedIssueType;
  File? _selectedImage;
  String? _busId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Get busId from active assignment
    _busId = widget.activeAssignment?.busId;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
        maxWidth: 1500,
        maxHeight: 1500,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1500,
        maxHeight: 1500,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo: $e')),
        );
      }
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIssueType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an issue type')),
      );
      return;
    }
    if (_busId == null || _busId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bus ID is required. Please ensure you have an active assignment.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _maintenanceService.createReport(
        busId: _busId!,
        issueType: _selectedIssueType!,
        description: _descriptionController.text.trim(),
        imageFile: _selectedImage,
      );

      // Submit the report to admin
      if (result['report'] != null && result['report']['_id'] != null) {
        await _maintenanceService.submitReport(result['report']['_id'].toString());
      }

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset form
      _formKey.currentState!.reset();
      _descriptionController.clear();
      setState(() {
        _selectedIssueType = null;
        _selectedImage = null;
      });

      // Refresh reports list (parent widget should handle this)
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: ${e.toString().replaceAll('Exception: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Submit New Report", style: AppTextStyles.subHeading),
            if (_busId == null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'No active bus assignment. Please wait for an assignment to submit a report.',
                        style: TextStyle(color: Colors.orange.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // --- Issue Type Dropdown ---
            Text(
              "Issue Type",
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedIssueType,
              items: const [
                DropdownMenuItem(value: "engine", child: Text("Engine")),
                DropdownMenuItem(value: "brakes", child: Text("Brakes")),
                DropdownMenuItem(value: "tires", child: Text("Tires")),
                DropdownMenuItem(value: "ac", child: Text("AC / Cooling")),
                DropdownMenuItem(value: "electrical", child: Text("Electrical")),
                DropdownMenuItem(value: "other", child: Text("Other")),
              ],
              onChanged: (value) => setState(() => _selectedIssueType = value),
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
              validator: (value) => value == null ? 'Please select an issue type' : null,
            ),

            const SizedBox(height: 16),

            // --- Description ---
            Text(
              "Description",
              style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
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
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // --- Image Upload ---
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
                onTap: () => _showImageOptions(),
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 150,
                  child: _selectedImage != null
                      ? Stack(
                          children: [
                            Image.file(
                              _selectedImage!,
                              width: double.infinity,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () => setState(() => _selectedImage = null),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 40,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Tap to add photo",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- Submit Button ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busId == null || _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentPrimary,
                  foregroundColor: AppColors.textLight,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        "Submit Report",
                        style: TextStyle(fontSize: 16),
                      ),
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
