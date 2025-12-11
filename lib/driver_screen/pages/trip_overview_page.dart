import 'package:flutter/material.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';
import 'package:waygo/driver_screen/widgets/route_assignment.dart';
import 'package:waygo/services/driver_service.dart';
import '../widgets/alert_banner.dart';
import './live_map_page.dart';

class TripOverviewPage extends StatefulWidget {
  final RouteAssignment? activeAssignment;
  final Function(RouteAssignment?)? onTripCompleted;

  const TripOverviewPage({
    Key? key,
    this.activeAssignment,
    this.onTripCompleted,
  }) : super(key: key);

  @override
  State<TripOverviewPage> createState() => _TripOverviewPageState();
}

class _TripOverviewPageState extends State<TripOverviewPage> {
  final DriverService _driverService = DriverService();
  bool _isLoading = false;
  String? _tripId;
  String? _tripStatus;

  @override
  void initState() {
    super.initState();
    _loadCurrentTrip();
  }

  @override
  void didUpdateWidget(covariant TripOverviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeAssignment?.id != oldWidget.activeAssignment?.id) {
      _loadCurrentTrip();
    }
  }

  Future<void> _loadCurrentTrip() async {
    if (widget.activeAssignment == null ||
        !widget.activeAssignment!.isAccepted) {
      setState(() {
        _tripId = null;
        _tripStatus = null;
      });
      return;
    }

    try {
      final trips = await _driverService.getTrips();
      final activeTrip = trips.firstWhere(
        (trip) =>
            trip['assignmentId']?.toString() == widget.activeAssignment!.id &&
            (trip['status'] == 'started' || trip['status'] == 'paused'),
        orElse: () => <String, dynamic>{},
      );

      if (mounted) {
        setState(() {
          _tripId = activeTrip.isEmpty ? null : activeTrip['_id']?.toString();
          _tripStatus = activeTrip.isEmpty
              ? null
              : activeTrip['status']?.toString();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tripId = null;
          _tripStatus = null;
        });
      }
    }
  }

  Future<void> _startTrip() async {
    if (widget.activeAssignment == null) {
      _showError("No active assignment");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _driverService.startTrip(
        widget.activeAssignment!.id,
      );
      if (mounted) {
        setState(() {
          _tripId = result['trip']?['_id']?.toString();
          _tripStatus = 'started';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Trip started successfully"),
            backgroundColor: Colors.green,
          ),
        );
        await _loadCurrentTrip();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError("Failed to start trip: $e");
      }
    }
  }

  Future<void> _endTrip() async {
    if (_tripId == null) {
      _showError("No active trip to end");
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Complete Trip"),
        content: const Text(
          "Are you sure you want to mark this trip as completed?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Complete"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await _driverService.endTrip(_tripId!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Trip completed successfully"),
            backgroundColor: Colors.green,
          ),
        );

        // Get next pending assignment
        final nextAssignment = await _driverService.getNextPendingAssignment();

        // Clear current assignment
        widget.onTripCompleted?.call(null);

        if (nextAssignment != null) {
          // Show notification about next assignment
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Next assignment available: ${nextAssignment.fromLocation} → ${nextAssignment.toLocation}",
                ),
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: "View",
                  onPressed: () {
                    // Navigate to schedule page or update assignment
                    widget.onTripCompleted?.call(nextAssignment);
                  },
                ),
              ),
            );
          }
        }

        setState(() {
          _tripId = null;
          _tripStatus = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showError("Failed to end trip: $e");
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignment = widget.activeAssignment;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 150, 208, 245),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Trip Overview", style: AppTextStyles.heading),
            const SizedBox(height: 16),

            if (assignment == null)
              Card(
                elevation: 3,
                color: AppColors.backgroundSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "No Active Assignment",
                        style: AppTextStyles.subHeading,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Accept a schedule assignment to start a trip.",
                        style: AppTextStyles.body.copyWith(
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              // Trip Details Card
              Card(
                elevation: 3,
                shadowColor: AppColors.shadowLight,
                color: AppColors.backgroundSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Route & Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "${assignment.fromLocation} → ${assignment.toLocation}",
                              style: AppTextStyles.subHeading.copyWith(
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _tripStatus == 'started'
                                  ? AppColors.accentSuccess
                                  : _tripStatus == 'paused'
                                  ? Colors.orange
                                  : assignment.isAccepted
                                  ? Colors.blue
                                  : Colors.grey,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _tripStatus == 'started'
                                  ? "Active"
                                  : _tripStatus == 'paused'
                                  ? "Paused"
                                  : assignment.isAccepted
                                  ? "Accepted"
                                  : "Pending",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 10),

                      _buildTripDetailRow("Date", assignment.formattedDate),
                      _buildTripDetailRow(
                        "Start Time",
                        assignment.formattedStartTime,
                      ),
                      if (assignment.arrivalTime != null)
                        _buildTripDetailRow(
                          "Estimated Arrival",
                          assignment.arrivalTime!,
                        ),
                      _buildTripDetailRow(
                        "Bus",
                        assignment.busNumber ??
                            assignment.busName ??
                            "Not assigned",
                      ),

                      const SizedBox(height: 20),

                      // Action Buttons
                      if (!assignment.isAccepted)
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            "Please accept this assignment first",
                            style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else if (_tripStatus == null || _tripStatus == 'pending')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _startTrip,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.play_arrow),
                            label: const Text("Start Trip"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentSuccess,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        )
                      else if (_tripStatus == 'started' ||
                          _tripStatus == 'paused')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _endTrip,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.check_circle),
                            label: const Text("Complete Trip"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accentError,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Live Location Sharing Button
              if (_tripStatus == 'started' && assignment.busId != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LiveMapPage(
                            busId: assignment.busId!,
                            autoStart: true,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.location_on),
                    label: const Text("Share Live Location"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // Alert Banner
              if (_tripStatus == 'started')
                AlertBanner(
                  message:
                      "Trip is in progress. Complete the trip when finished.",
                  type: AlertType.info,
                )
              else if (assignment.isAccepted && _tripStatus == null)
                AlertBanner(
                  message: "Assignment accepted. Start the trip when ready.",
                  type: AlertType.success,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTripDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodySmall),
          Text(
            value,
            style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
