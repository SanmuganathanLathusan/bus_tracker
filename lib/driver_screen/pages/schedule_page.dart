import 'package:flutter/material.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';
import 'package:waygo/driver_screen/widgets/route_assignment.dart';
import 'package:waygo/services/driver_service.dart';

class SchedulePage extends StatefulWidget {
  final RouteAssignment? assignedRoute;
  final Function(RouteAssignment)? onRouteUpdate;

  const SchedulePage({
    Key? key,
    this.assignedRoute,
    this.onRouteUpdate,
  }) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  final DriverService _driverService = DriverService();
  final TextEditingController _rejectReasonController = TextEditingController();

  bool _isLoading = true;
  String? _errorMessage;
  List<RouteAssignment> _assignments = [];
  RouteAssignment? _activeAssignment;

  @override
  void initState() {
    super.initState();
    _activeAssignment = widget.assignedRoute;
    _loadAssignments();
  }

  Future<void> _loadAssignments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final assignments = await _driverService.getAssignments();
      
      // Filter out completed assignments from the list
      final activeAssignments = assignments.where((a) => !a.isCompleted).toList();
      
      // Find accepted assignment first
      RouteAssignment? accepted = widget.assignedRoute;
      for (final assignment in activeAssignments) {
        if (assignment.isAccepted) {
          accepted = assignment;
          break;
        }
      }
      
      // If no accepted assignment, get the next pending one
      if (accepted == null) {
        final pendingAssignments = activeAssignments.where((a) => a.isPending).toList();
        if (pendingAssignments.isNotEmpty) {
          // Sort by date and time, get the earliest one
          pendingAssignments.sort((a, b) {
            final dateCompare = a.scheduledDate.compareTo(b.scheduledDate);
            if (dateCompare != 0) return dateCompare;
            return a.scheduledTime.compareTo(b.scheduledTime);
          });
          accepted = pendingAssignments.first;
        }
      }

      if (!mounted) return;
      setState(() {
        _assignments = activeAssignments;
        _activeAssignment = accepted;
        _isLoading = false;
      });

      if (accepted != null && accepted.id != widget.assignedRoute?.id) {
        widget.onRouteUpdate?.call(accepted);
      } else if (accepted == null && widget.assignedRoute != null) {
        // Assignment was completed, clear it
        // Don't call onRouteUpdate with null, let the parent handle it
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _handleRespond(
    RouteAssignment assignment,
    RouteStatus status,
  ) async {
    String? reason;
    if (status == RouteStatus.rejected) {
      reason = await _promptRejectReason();
      if (reason == null) return;
    }

    try {
      final updated = await _driverService.respondToAssignment(
        assignmentId: assignment.id,
        status: status,
        responseNote: reason,
      );

      if (!mounted) return;
      setState(() {
        _assignments = _assignments
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
        if (updated.isAccepted) {
          _activeAssignment = updated;
          widget.onRouteUpdate?.call(updated);
        } else if (_activeAssignment?.id == updated.id) {
          _activeAssignment = null;
          widget.onRouteUpdate?.call(updated);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == RouteStatus.accepted
                ? "Assignment accepted"
                : "Assignment rejected",
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update assignment: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<String?> _promptRejectReason() async {
    _rejectReasonController.clear();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reject assignment"),
        content: TextField(
          controller: _rejectReasonController,
          decoration: const InputDecoration(
            hintText: "Enter reason...",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context, _rejectReasonController.text.trim());
            },
            child: const Text("Reject"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 150, 208, 245),
      appBar: AppBar(
        title: const Text("Driver Schedule"),
        backgroundColor: AppColors.accentPrimary,
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadAssignments,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    if (_assignments.isEmpty) {
      return const Center(
        child: Text(
          "No schedules assigned yet.",
          style: TextStyle(fontSize: 18, color: Colors.black54),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAssignments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _assignments.length,
        itemBuilder: (context, index) {
          final assignment = _assignments[index];
          final isActive = _activeAssignment?.id == assignment.id;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildAssignmentCard(assignment, isActive),
          );
        },
      ),
    );
  }

  Widget _buildAssignmentCard(RouteAssignment assignment, bool isActive) {
    final Color statusColor = Color(
      int.parse(assignment.status.hexColor.replaceAll("#", "0xFF")),
    );

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
        border: isActive
            ? Border.all(color: AppColors.accentPrimary, width: 2)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.route, color: AppColors.accentPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${assignment.fromLocation} → ${assignment.toLocation}",
                    style: AppTextStyles.heading.copyWith(fontSize: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _infoTile("Date", assignment.formattedDate),
            _infoTile("Start Time", assignment.formattedStartTime),
            _infoTile(
              "Bus",
              assignment.busNumber ??
                  assignment.busName ??
                  assignment.busId ??
                  "Not assigned",
            ),
            if (assignment.depotLabel != null)
              _infoTile("Depot", assignment.depotLabel!),
            _infoTile("Assigned By", assignment.assignedBy),
            if (assignment.notes != null && assignment.notes!.isNotEmpty)
              _infoTile("Notes", assignment.notes!),
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.circle, color: statusColor, size: 14),
                const SizedBox(width: 8),
                Text(
                  assignment.status.displayName,
                  style: AppTextStyles.body.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isActive)
                  Container(
                    margin: const EdgeInsets.only(left: 12),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Active",
                      style: TextStyle(
                        color: AppColors.accentPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            if (assignment.isPending) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleRespond(
                        assignment,
                        RouteStatus.accepted,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text("Accept"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleRespond(
                        assignment,
                        RouteStatus.rejected,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text("Reject"),
                    ),
                  ),
                ],
              ),
            ] else if (assignment.driverResponse != null &&
                assignment.driverResponse!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                "Response: ${assignment.driverResponse}",
                style: const TextStyle(color: Colors.black87),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.waygoDarkBlue,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.body.copyWith(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _rejectReasonController.dispose();
    super.dispose();
  }
}

