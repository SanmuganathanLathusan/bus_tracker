import 'package:flutter/material.dart';

class FeedbackWidget extends StatelessWidget {
  const FeedbackWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final reports = [
      {
        'type': 'Complaint',
        'user': 'Alice Johnson',
        'subject': 'Bus delayed by 30 minutes on Route 5',
        'date': '2025-10-30',
        'status': 'Pending',
        'rating': 2,
      },
      {
        'type': 'Feedback',
        'user': 'Bob Smith',
        'subject': 'Great service on Route 5, very punctual',
        'date': '2025-10-29',
        'status': 'Resolved',
        'rating': 5,
      },
      {
        'type': 'Issue',
        'user': 'Carol White',
        'subject': 'AC not working on Bus #205',
        'date': '2025-10-28',
        'status': 'In Progress',
        'rating': 3,
      },
      {
        'type': 'Complaint',
        'user': 'David Brown',
        'subject': 'Driver was rude and unprofessional',
        'date': '2025-10-27',
        'status': 'Escalated',
        'rating': 1,
      },
      {
        'type': 'Delay',
        'user': 'Emma Wilson',
        'subject': 'Route 12 delayed due to traffic',
        'date': '2025-10-26',
        'status': 'Resolved',
        'rating': 3,
      },
    ];

    int totalReports = reports.length;
    int pending = reports.where((r) => r['status'] == 'Pending').length;
    int inProgress = reports.where((r) => r['status'] == 'In Progress').length;
    int resolved = reports.where((r) => r['status'] == 'Resolved').length;
    double avgRating =
        reports.fold(0, (sum, r) => sum + (r['rating'] as int)) /
        reports.length;

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
            inProgress,
            resolved,
            avgRating,
          ),
          const SizedBox(height: 32),
          _buildReportsSection(reports),
        ],
      ),
    );
  }

  // Header Section
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Reports, Feedback & Issues',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
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
                value: 'All Types',
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, size: 24),
                items: ['All Types', 'Complaint', 'Feedback', 'Issue', 'Delay']
                    .map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    })
                    .toList(),
                onChanged: (value) {},
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
    int inProgress,
    int resolved,
    double avgRating,
  ) {
    return Column(
      children: [
        // First Row - 3 cards
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
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'In Progress',
                '$inProgress',
                Icons.refresh,
                Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Second Row - 2 cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Resolved',
                '$resolved',
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Avg Rating',
                avgRating.toStringAsFixed(1),
                Icons.star,
                Colors.amber,
              ),
            ),
          ],
        ),
      ],
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
  Widget _buildReportsSection(List<Map<String, dynamic>> reports) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Reports',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.filter_list, size: 18),
              label: const Text('Filter'),
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

  Widget _buildCardHeader(Map<String, dynamic> report) {
    Color typeColor = _getTypeColor(report['type'] as String);
    Color statusColor = _getStatusColor(report['status'] as String);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row with badges and rating
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
                report['type'],
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
                report['status'],
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Rating Stars
            Expanded(
              child: Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < (report['rating'] as int)
                        ? Icons.star
                        : Icons.star_border,
                    size: 18,
                    color: Colors.amber,
                  );
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Action buttons on separate row
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.visibility_outlined, size: 20),
            color: Colors.blue,
            onPressed: () {},
            tooltip: 'View Details',
          ),
          Container(width: 1, height: 20, color: Colors.grey.shade300),
          IconButton(
            icon: const Icon(Icons.reply_outlined, size: 20),
            color: Colors.green,
            onPressed: () {},
            tooltip: 'Reply',
          ),
          Container(width: 1, height: 20, color: Colors.grey.shade300),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, size: 20),
            color: Colors.orange,
            onPressed: () {},
            tooltip: 'Mark as Resolved',
          ),
        ],
      ),
    );
  }

  Widget _buildCardBody(Map<String, dynamic> report) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          report['subject'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildCardFooter(Map<String, dynamic> report) {
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
            report['user'],
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
            report['date'],
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
  Color _getTypeColor(String type) {
    switch (type) {
      case 'Complaint':
        return Colors.red;
      case 'Feedback':
        return Colors.blue;
      case 'Delay':
        return Colors.orange;
      case 'Issue':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Resolved':
        return Colors.green;
      case 'In Progress':
        return Colors.blue;
      case 'Escalated':
        return Colors.purple;
      case 'Pending':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
