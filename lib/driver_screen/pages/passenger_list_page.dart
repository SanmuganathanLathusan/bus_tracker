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

  // ---------------------------------------------------------------------------
  // LOAD PASSENGERS
  // ---------------------------------------------------------------------------

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
      final data = await _driverService.getAssignmentPassengers(_assignment!.id);

      final list = (data['passengers'] as List? ?? []).map((raw) {
        final r = raw as Map<String, dynamic>;
        final user = (r['userId'] as Map?) ?? {};
        final seats = (r['seats'] as List?) ?? [];

        return Passenger(
          ticketId: r['ticketId']?.toString() ?? 'N/A',
          name: user['userName']?.toString() ?? 'Unknown',
          seat: seats.isNotEmpty ? seats.first.toString() : 'N/A',
          status: r['boardingStatus'] == 'boarded'
              ? PassengerStatus.boarded
              : PassengerStatus.notBoarded,
          bookingType:
              r['status'] == 'paid' ? BookingType.paid : BookingType.reserved,
          reservationId: r['_id']?.toString(),
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        passengers = list;
        filteredPassengers = List.from(list);
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

  // ---------------------------------------------------------------------------
  // SEARCH PASSENGERS
  // ---------------------------------------------------------------------------
  void _searchPassenger(String query) {
    setState(() {
      filteredPassengers = passengers.where((p) {
        final q = query.toLowerCase();
        return p.name.toLowerCase().contains(q) ||
            p.ticketId.toLowerCase().contains(q);
      }).toList();
    });
  }

  // ---------------------------------------------------------------------------
  // UPDATE STATUS
  // ---------------------------------------------------------------------------

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
          return p.reservationId == reservationId
              ? p.copyWith(status: newStatus)
              : p;
        }).toList();

        filteredPassengers = passengers;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Passenger status updated to ${newStatus.name}"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error updating status: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // SCAN QR → PROCESS TICKET
  // ---------------------------------------------------------------------------

  Future<void> _handleScanResult(String scannedId) async {
    if (_assignment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Accept a schedule before scanning.")),
      );
      return;
    }

    try {
      final r = await _reservationService.validateTicket(scannedId);

      if (r['valid'] != true) return;

      final data = r['reservation'];
      final user = (data['userId'] as Map?) ?? {};
      final route = (data['routeId'] as Map?) ?? {};
      final seats = (data['seats'] as List?) ?? [];

      final passenger = Passenger(
        ticketId: data['ticketId'] ?? scannedId,
        name: user['userName'] ?? "Unknown",
        seat: seats.isNotEmpty ? seats.first.toString() : 'N/A',
        status: data['boardingStatus'] == 'boarded'
            ? PassengerStatus.boarded
            : PassengerStatus.notBoarded,
        bookingType:
            data['status'] == 'paid' ? BookingType.paid : BookingType.reserved,
        reservationId: data['_id'],
      );

      // Add if not inside existing list
      if (!passengers.any((p) => p.ticketId == passenger.ticketId)) {
        setState(() {
          passengers.add(passenger);
          filteredPassengers = List.from(passengers);
        });
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Ticket Verified", style: TextStyle(color: Colors.green)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Passenger: ${passenger.name}"),
              Text("Seat: ${passenger.seat}"),
              Text("Ticket: ${passenger.ticketId}"),
              Text("Route: ${route['start']} → ${route['destination']}"),
              Text("Booking: ${passenger.bookingLabel}"),
              Text("Status: ${passenger.status.name}"),
            ],
          ),
          actions: [
            if (passenger.status != PassengerStatus.boarded)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _updatePassengerStatus(
                      passenger.reservationId ?? "", PassengerStatus.boarded);
                },
                child: const Text("Mark Boarded"),
              ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            )
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Invalid Ticket", style: TextStyle(color: Colors.red)),
          content: Text("This ticket is invalid: $e"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            )
          ],
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // OPEN SCANNER
  // ---------------------------------------------------------------------------

  void _openScanner() async {
    if (_assignment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No active schedule to scan.")),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerPage()),
    );

    if (result is String) _handleScanResult(result);
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF96D0F5),
      body: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // -----------------------------------
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Passenger Management", style: AppTextStyles.heading),
          const SizedBox(height: 4),
          Text(
            _assignment == null
                ? "No active schedule"
                : "${_assignment!.fromLocation} → ${_assignment!.toLocation} on ${_assignment!.formattedDate}",
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 16),

          // Search
          TextField(
            controller: _searchController,
            onChanged: _searchPassenger,
            decoration: InputDecoration(
              hintText: "Search by ticket ID or name",
              prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.backgroundSecondary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Buttons
          Row(
            children: [
              Expanded(child: _scanButton()),
              const SizedBox(width: 10),
              Expanded(child: _clearButton()),
            ],
          )
        ],
      ),
    );
  }

  Widget _scanButton() {
    return ElevatedButton.icon(
      onPressed: _openScanner,
      icon: const Icon(Icons.qr_code_scanner),
      label: const Text("Scan QR"),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accentPrimary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _clearButton() {
    return ElevatedButton.icon(
      onPressed: () {
        _searchController.clear();
        setState(() => filteredPassengers = passengers);
      },
      icon: const Icon(Icons.refresh),
      label: const Text("Clear"),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.backgroundSecondary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  // -----------------------------------
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.black54)),
      );
    }

    if (filteredPassengers.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadPassengers,
        child: ListView(
          children: const [
            SizedBox(height: 80),
            Center(
              child: Text(
                "No passengers found.",
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPassengers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredPassengers.length,
        itemBuilder: (_, i) {
          final p = filteredPassengers[i];
          return PassengerTile(
            passenger: p,
            onStatusChanged: (status) =>
                _updatePassengerStatus(p.reservationId ?? "", status),
          );
        },
      ),
    );
  }
}
