import 'package:flutter/material.dart';
import 'package:waygo/services/maintenance_service.dart';
import 'package:intl/intl.dart';

class FeedbackWidget extends StatefulWidget {
  const FeedbackWidget({Key? key}) : super(key: key);

  @override
  State<FeedbackWidget> createState() => _FeedbackWidgetState();
}

class _FeedbackWidgetState extends State<FeedbackWidget> {
  final MaintenanceService _maintenanceService = MaintenanceService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _reports = [];
  String _selectedStatusFilter = 'All Types';

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
      final reports = await _maintenanceService.getAllReports();
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

  List<dynamic> get _filteredReports {
    if (_selectedStatusFilter == 'All Types') {
      return _reports;
    }
    return _reports.where((r) {
      final status = r['status'] ?? 'unsent';
      return _getStatusDisplayName(status) == _selectedStatusFilter;
    }).toList();
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

    int totalReports = _reports.length;
    int pending = _reports.where((r) => (r['status'] ?? '') == 'pending').length;
    int received = _reports.where((r) => (r['status'] ?? '') == 'received').length;
    int notReceived = _reports.where((r) => (r['status'] ?? '') == 'not_received').length;
    int resolved = _reports.where((r) => (r['status'] ?? '') == 'resolved').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildStatsSection(
            totalReports,
            pending,
            received,
            notReceived,
            resolved,
          ),
          const SizedBox(height: 32),
          _buildReportsSection(_filteredReports),
        ],
      ),
    );
  }

  // Header Section
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Reports and Issues',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadReports,
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButton<String>(
                value: _selectedStatusFilter,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, size: 24),
                items: ['All Types', 'Pending', 'Received', 'Not Received', 'Resolved']
                    .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    })
                    .toList(),
                onChanged: (value) {
                  setState(() => _selectedStatusFilter = value ?? 'All Types');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Stats Section
  Widget _buildStatsSection(
    int total,
    int pending,
    int received,
    int notReceived,
    int resolved,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return Column(
          children: [
            // First Row
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Reports',
                    '$total',
                    Icons.report,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Pending',
                    '$pending',
                    Icons.pending,
                    Colors.red,
                  ),
                ),
                if (isWide) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      'Received',
                      '$received',
                      Icons.inbox,
                      Colors.blue,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            // Second Row
            Row(
              children: [
                if (!isWide) ...[
                  Expanded(
                    child: _buildStatCard(
                      'Received',
                      '$received',
                      Icons.inbox,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(
                  child: _buildStatCard(
                    'Not Received',
                    '$notReceived',
                    Icons.cancel,
                    Colors.red.shade700,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Resolved',
                    '$resolved',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Reports Section
  Widget _buildReportsSection(List<dynamic> reports) {
    if (reports.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Icon(Icons.description_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No reports found',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Maintenance Reports (${reports.length})',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: _loadReports,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...reports.map((report) => _buildFeedbackCard(report)),
      ],
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(report),
          const SizedBox(height: 16),
          _buildCardBody(report),
          const SizedBox(height: 16),
          _buildCardFooter(report),
        ],
      ),
    );
  }

  Widget _buildCardHeader(dynamic report) {
    final issueType = report['issueType'] ?? 'other';
    final typeColor = _getTypeColor(issueType);
    final status = report['status'] ?? 'unsent';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusDisplayName(status);
    final bus = report['busId'] is Map
        ? (report['busId']['busNumber'] ?? report['busId']['busName'] ?? 'Unknown Bus')
        : 'Unknown Bus';
    final reportId = report['_id']?.toString() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row with badges and bus info
        Row(
          children: [
            // Type Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                issueType.substring(0, 1).toUpperCase() + issueType.substring(1),
                style: TextStyle(
                  color: typeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const Spacer(),
            // Bus Info
            Row(
              children: [
                Icon(Icons.directions_bus, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  bus,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Action buttons on separate row
        _buildActionButtons(reportId, status),
      ],
    );
  }

  Widget _buildActionButtons(String reportId, String currentStatus) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20, color: Colors.blue),
            tooltip: 'Update Status',
            onSelected: (status) => _updateReportStatus(reportId, status),
            itemBuilder: (context) => [
              if (currentStatus != 'pending')
                const PopupMenuItem(
                  value: 'pending',
                  child: Row(
                    children: [
                      Icon(Icons.pending, size: 18, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Mark as Pending'),
                    ],
                  ),
                ),
              if (currentStatus != 'received')
                const PopupMenuItem(
                  value: 'received',
                  child: Row(
                    children: [
                      Icon(Icons.inbox, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Mark as Received'),
                    ],
                  ),
                ),
              if (currentStatus != 'not_received')
                const PopupMenuItem(
                  value: 'not_received',
                  child: Row(
                    children: [
                      Icon(Icons.cancel, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Mark as Not Received'),
                    ],
                  ),
                ),
              if (currentStatus != 'resolved')
                const PopupMenuItem(
                  value: 'resolved',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Mark as Resolved'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _updateReportStatus(String reportId, String status) async {
    try {
      await _maintenanceService.updateReportStatus(
        reportId: reportId,
        status: status,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report status updated to ${_getStatusDisplayName(status)}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadReports();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCardBody(dynamic report) {
    final description = report['description'] ?? 'No description';
    final imageUrl = report['imageUrl'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
        if (imageUrl != null && imageUrl.toString().isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              'http://10.0.2.2:5000/$imageUrl',
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
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
    );
  }

  Widget _buildCardFooter(dynamic report) {
    final driver = report['driverId'] is Map
        ? (report['driverId']['userName'] ?? 'Unknown Driver')
        : 'Unknown Driver';
    final date = report['createdAt'] != null
        ? DateFormat('yyyy-MM-dd').format(DateTime.parse(report['createdAt']))
        : 'Unknown date';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 6),
          Text(
            driver,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 20),
          Icon(
            Icons.calendar_today_outlined,
            size: 16,
            color: Colors.grey.shade600,
          ),
          const SizedBox(width: 6),
          Text(
            date,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Color _getTypeColor(String issueType) {
    switch (issueType) {
      case 'engine':
        return Colors.red;
      case 'brakes':
        return Colors.orange;
      case 'tires':
        return Colors.blue;
      case 'ac':
        return Colors.cyan;
      case 'electrical':
        return Colors.purple;
      case 'other':
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'received':
        return Colors.blue;
      case 'not_received':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'unsent':
      default:
        return Colors.grey;
    }
  }

  String _getStatusDisplayName(String status) {
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
}
