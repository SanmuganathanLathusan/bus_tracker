import 'package:flutter/material.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';
import 'package:waygo/services/reservation_service.dart';
import 'package:waygo/services/driver_service.dart';
import '../widgets/passenger_tile.dart';
import '../widgets/qr_scanner_page.dart';
import '../widgets/passenger_model.dart';
import '../widgets/route_assignment.dart';

class PassengerListPage extends StatefulWidget {
  final RouteAssignment? activeAssignment;

  const PassengerListPage({Key? key, this.activeAssignment}) : super(key: key);

  @override
  State<PassengerListPage> createState() => _PassengerListPageState();
}

class _PassengerListPageState extends State<PassengerListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ReservationService _reservationService = ReservationService();
  final DriverService _driverService = DriverService();

  List<Passenger> passengers = [];
  List<Passenger> filteredPassengers = [];
  bool _isLoading = true;
  String? _error;
  RouteAssignment? _assignment;

  @override
  void initState() {
    super.initState();
    _assignment = widget.activeAssignment;
    _loadPassengers();
  }

  @override
  void didUpdateWidget(covariant PassengerListPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeAssignment?.id != oldWidget.activeAssignment?.id) {
      _assignment = widget.activeAssignment;
      _loadPassengers();
    }
  }

  Future<void> _loadPassengers() async {
    if (_assignment == null) {
      setState(() {
        passengers = [];
        filteredPassengers = [];
        _isLoading = false;
        _error = "Accept a schedule to view passengers.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data =
          await _driverService.getAssignmentPassengers(_assignment!.id);
      final reservations = (data['passengers'] as List?) ?? [];

      final passengerList = reservations.map((res) {
        final reservation = res as Map<String, dynamic>;
        final user = reservation['userId'] is Map
            ? reservation['userId'] as Map<String, dynamic>
            : <String, dynamic>{};
        final seats = (reservation['seats'] as List?) ?? [];

        return Passenger(
          ticketId: reservation['ticketId']?.toString() ?? 'N/A',
          name: user['userName']?.toString() ?? 'Unknown',
          seat: seats.isNotEmpty ? seats.first.toString() : 'N/A',
          status: reservation['boardingStatus'] == 'boarded'
              ? PassengerStatus.boarded
              : PassengerStatus.notBoarded,
          bookingType: reservation['status'] == 'paid'
              ? BookingType.paid
              : BookingType.reserved,
          reservationId: reservation['_id']?.toString(),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        passengers = passengerList;
        filteredPassengers = List.from(passengerList);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _searchPassenger(String query) {
    setState(() {
      filteredPassengers = passengers
          .where(
            (p) =>
                p.name.toLowerCase().contains(query.toLowerCase()) ||
                p.ticketId.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();
    });
  }

  Future<void> _updatePassengerStatus(
      String reservationId, PassengerStatus newStatus) async {
    try {
      await _reservationService.markPassengerStatus(
        reservationId: reservationId,
        status: newStatus == PassengerStatus.boarded ? 'boarded' : 'absent',
      );

      if (!mounted) return;
      setState(() {
        passengers = passengers.map((p) {
          if (p.reservationId == reservationId) {
            return p.copyWith(status: newStatus);
          }
          return p;
        }).toList();
        filteredPassengers = passengers;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passenger status updated to ${newStatus.name}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleScanResult(String scannedId) async {
    if (_assignment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Accept a schedule before scanning tickets."),
        ),
      );
      return;
    }

    try {
      final validationResult =
          await _reservationService.validateTicket(scannedId);

      if (validationResult['valid'] == true) {
        final reservation = validationResult['reservation'];
        final route = reservation['routeId'] is Map ? reservation['routeId'] : {};
        final user = reservation['userId'] is Map ? reservation['userId'] : {};
        final seats = reservation['seats'] as List? ?? [];

        final passenger = Passenger(
          ticketId: reservation['ticketId'] ?? scannedId,
          name: user['userName'] ?? 'Unknown',
          seat: seats.isNotEmpty ? seats.first.toString() : 'N/A',
          status: reservation['boardingStatus'] == 'boarded'
              ? PassengerStatus.boarded
              : PassengerStatus.notBoarded,
          bookingType: reservation['status'] == 'paid'
              ? BookingType.paid
              : BookingType.reserved,
          reservationId: reservation['_id'],
        );

        final existingIndex =
            passengers.indexWhere((p) => p.ticketId == passenger.ticketId);
        if (existingIndex == -1) {
          setState(() {
            passengers.add(passenger);
            filteredPassengers = List.from(passengers);
          });
        }

        if (!mounted) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text(
              "✅ Ticket Verified",
              style: TextStyle(color: Colors.green),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Passenger: ${passenger.name}"),
                Text("Seat: ${passenger.seat}"),
                Text("Ticket ID: ${passenger.ticketId}"),
                Text("Route: ${route['start']} → ${route['destination']}"),
                Text("Booking: ${passenger.bookingLabel}"),
                Text("Status: ${passenger.status.name}"),
              ],
            ),
            actions: [
              if (passenger.status != PassengerStatus.boarded)
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _updatePassengerStatus(
                        passenger.reservationId ?? '', PassengerStatus.boarded);
                  },
                  child: const Text("Mark Boarded"),
                ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text(
            "❌ Invalid Ticket",
            style: TextStyle(color: Colors.red),
          ),
          content: Text("This ticket is invalid or not found: ${e.toString()}"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        ),
      );
    }
  }

  void _openScanner() async {
    if (_assignment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No active schedule available for scanning."),
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerPage()),
    );

    if (result != null && result is String) {
      _handleScanResult(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 150, 208, 245),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Passenger Management", style: AppTextStyles.heading),
                const SizedBox(height: 4),
                Text(
                  _assignment == null
                      ? "No active schedule"
                      : "${_assignment!.fromLocation} → ${_assignment!.toLocation} on ${_assignment!.formattedDate}",
                  style: AppTextStyles.body.copyWith(
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _searchController,
                  onChanged: _searchPassenger,
                  decoration: InputDecoration(
                    hintText: "Search by ticket ID or name",
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSecondary,
                    ),
                    filled: true,
                    fillColor: AppColors.backgroundSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openScanner,
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text("Scan QR"),
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
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => filteredPassengers = passengers);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text("Clear"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.backgroundSecondary,
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Colors.black54),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadPassengers,
                        child: filteredPassengers.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 80),
                                  Center(
                                    child: Text(
                                      "No passengers found for this schedule.",
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: filteredPassengers.length,
                                itemBuilder: (context, index) {
                                  final passenger = filteredPassengers[index];
                                  return PassengerTile(
                                    passenger: passenger,
                                    onStatusChanged: (newStatus) =>
                                        _updatePassengerStatus(
                                      passenger.reservationId ?? '',
                                      newStatus,
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}
