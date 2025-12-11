import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waygo/services/driver_service.dart';
import 'package:waygo/services/reservation_service.dart';
import 'package:waygo/driver_screen/widgets/qr_scanner_page.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';

class TicketsReservationsPage extends StatefulWidget {
  const TicketsReservationsPage({Key? key}) : super(key: key);

  @override
  State<TicketsReservationsPage> createState() =>
      _TicketsReservationsPageState();
}

class _TicketsReservationsPageState extends State<TicketsReservationsPage>
    with SingleTickerProviderStateMixin {
  final DriverService _driverService = DriverService();
  final ReservationService _reservationService = ReservationService();

  late TabController _tabController;
  bool _isLoading = true;
  String? _error;

  List<Map<String, dynamic>> _reservations = [];
  List<Map<String, dynamic>> _tickets = [];
  Map<String, dynamic> _summary = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _driverService.getTicketsAndReservations();

      if (!mounted) return;
      setState(() {
        _reservations = List<Map<String, dynamic>>.from(
          data['reservations'] ?? [],
        );
        _tickets = List<Map<String, dynamic>>.from(data['tickets'] ?? []);
        _summary = Map<String, dynamic>.from(data['summary'] ?? {});
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _scanQRCode() async {
    try {
      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const QRScannerPage()),
      );

      if (result == null || !mounted) return;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Validate ticket
      final validationResult = await _reservationService.validateTicket(result);

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (validationResult['valid'] == true) {
        final reservation = validationResult['reservation'];
        _showTicketDetailsDialog(reservation);
      } else {
        _showErrorDialog(
          'Invalid Ticket',
          'This ticket could not be verified.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog if still open
      _showErrorDialog('Validation Error', e.toString());
    }
  }

  void _showTicketDetailsDialog(Map<String, dynamic> reservation) {
    final route = reservation['routeId'] as Map<String, dynamic>? ?? {};
    final user = reservation['userId'] as Map<String, dynamic>? ?? {};
    final seats = reservation['seats'] as List? ?? [];
    final status = reservation['status'] as String? ?? '';
    final boardingStatus =
        reservation['boardingStatus'] as String? ?? 'pending';
    final ticketId = reservation['ticketId'] ?? 'N/A';

    final isPaid = status == 'paid';
    final isBoarded = boardingStatus == 'boarded';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isPaid ? Icons.check_circle : Icons.info,
              color: isPaid ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Text('Ticket Verified'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Ticket ID', ticketId),
              const Divider(),
              _buildDetailRow('Passenger', user['userName'] ?? 'Unknown'),
              if (user['phone'] != null)
                _buildDetailRow('Phone', user['phone']),
              const Divider(),
              _buildDetailRow(
                'Route',
                '${route['start'] ?? 'N/A'} → ${route['destination'] ?? 'N/A'}',
              ),
              _buildDetailRow('Seats', seats.join(', ')),
              const Divider(),
              _buildDetailRow(
                'Status',
                isPaid ? 'PAID ✓' : 'RESERVED',
                valueColor: isPaid ? Colors.green : Colors.orange,
              ),
              _buildDetailRow(
                'Boarding',
                boardingStatus.toUpperCase(),
                valueColor: isBoarded ? Colors.blue : Colors.grey,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!isBoarded)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Mark as boarded
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mark as boarded feature coming soon'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Mark as Boarded'),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black87,
                fontWeight: valueColor != null
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 150, 208, 245),
      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Bookings & Reservations", style: AppTextStyles.heading),
                const SizedBox(height: 8),
                Text(
                  "View all passenger bookings for your routes",
                  style: AppTextStyles.body.copyWith(color: Colors.black87),
                ),
              ],
            ),
          ),

          // Summary Cards
          if (!_isLoading && _error == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      "Reserved",
                      _summary['totalReservations']?.toString() ?? '0',
                      Icons.bookmark_outline,
                      Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      "Paid",
                      _summary['totalTickets']?.toString() ?? '0',
                      Icons.confirmation_number,
                      Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      "Seats",
                      _summary['totalSeatsBooked']?.toString() ?? '0',
                      Icons.event_seat,
                      AppColors.accentPrimary,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Tabs
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.accentPrimary,
              unselectedLabelColor: Colors.grey,
              indicatorColor: AppColors.accentPrimary,
              tabs: const [
                Tab(text: "All"),
                Tab(text: "Reserved"),
                Tab(text: "Paid Tickets"),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "Error loading data",
                          style: AppTextStyles.heading.copyWith(
                            color: Colors.red,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: AppTextStyles.body,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadData,
                          icon: const Icon(Icons.refresh),
                          label: const Text("Retry"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentPrimary,
                          ),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // All bookings
                      _buildBookingsList([..._reservations, ..._tickets]),
                      // Reserved only
                      _buildBookingsList(_reservations),
                      // Paid tickets only
                      _buildBookingsList(_tickets),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scanQRCode,
        backgroundColor: AppColors.accentPrimary,
        icon: const Icon(Icons.qr_code_scanner),
        label: const Text('Scan QR'),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<Map<String, dynamic>> bookings) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "No bookings found",
              style: AppTextStyles.heading.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              "Passenger bookings will appear here",
              style: AppTextStyles.body.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking);
        },
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final passenger = booking['passenger'] as Map<String, dynamic>? ?? {};
    final route = booking['route'] as Map<String, dynamic>? ?? {};
    final seats = booking['seats'] as List? ?? [];
    final status = booking['status'] as String? ?? '';
    final boardingStatus = booking['boardingStatus'] as String? ?? 'pending';
    final amount = booking['amount'] ?? 0;
    final ticketId = booking['ticketId'] ?? 'N/A';

    final isPaid = status == 'paid';
    final isBoarded = boardingStatus == 'boarded';

    Color statusColor = isPaid ? Colors.green : Colors.orange;
    Color boardingColor = isBoarded ? Colors.blue : Colors.grey;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status badges
            Row(
              children: [
                Expanded(
                  child: Text(
                    passenger['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPaid ? 'PAID' : 'RESERVED',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: boardingColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    boardingStatus.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: boardingColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Ticket ID
            Row(
              children: [
                const Icon(
                  Icons.confirmation_number,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ticket: $ticketId',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Route information
            Row(
              children: [
                const Icon(Icons.route, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${route['start'] ?? 'N/A'} → ${route['destination'] ?? 'N/A'}',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Seats
            Row(
              children: [
                const Icon(Icons.event_seat, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Seats: ${seats.join(', ')}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Amount
            if (isPaid)
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Rs. ${amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),

            // Contact info
            if (passenger['phone'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.phone, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      passenger['phone'] ?? '',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),

            // Booking date
            if (booking['createdAt'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Booked: ${_formatDate(booking['createdAt'])}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is Map && date['\$date'] != null) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(date['\$date'] as int);
      } else {
        return 'N/A';
      }
      return DateFormat('dd MMM yyyy, HH:mm').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }
}
