import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';

import 'package:waygo/services/reservation_service.dart';
import 'package:waygo/services/api_service.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';

class Etickets extends StatefulWidget {
  final String? reservationId;
  const Etickets({super.key, this.reservationId});

  @override
  State<Etickets> createState() => _EticketsState();
}

class _EticketsState extends State<Etickets> {
  final ReservationService _reservationService = ReservationService();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _reservation;
  bool _isLoading = true;
  String? _error;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    if (widget.reservationId != null) {
      _loadReservation();
    } else {
      _loadUserReservations();
    }
  }

  Future<void> _loadReservation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reservation = await _reservationService.getReservationById(widget.reservationId!);
      setState(() {
        _reservation = reservation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUserReservations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final reservations = await _reservationService.getUserReservations();
      // Show only paid reservations
      final paidReservations = reservations.where((r) => r['status'] == 'paid').toList();
      if (paidReservations.isNotEmpty) {
        setState(() {
          _reservation = paidReservations.first;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'No tickets found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadTicket() async {
    final reservationId = _reservation?['_id'] ?? widget.reservationId;
    if (reservationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No reservation selected to download.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      setState(() => _isDownloading = true);
      final token = await _authService.getToken();
      if (token == null) throw Exception('Login expired. Please sign in again.');

      final downloadUrl =
          "${ReservationService.baseUrl}/reservations/$reservationId/download";
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = "${directory.path}/WayGoTicket_$timestamp.pdf";

      final dio = Dio();
      await dio.download(
        downloadUrl,
        filePath,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          responseType: ResponseType.bytes,
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket saved to $filePath')),
      );
      await OpenFilex.open(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("E-Ticket"),
        backgroundColor: AppColors.waygoDarkBlue,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      ElevatedButton(
                        onPressed: widget.reservationId != null ? _loadReservation : _loadUserReservations,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _reservation == null
                  ? const Center(child: Text('No ticket found'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildTicketCard(),
                    ),
    );
  }

  Widget _buildTicketCard() {
    final route = _reservation!['routeId'] is Map ? _reservation!['routeId'] : {};
    final bus = _reservation!['busId'] is Map ? _reservation!['busId'] : {};
    final user = _reservation!['userId'] is Map ? _reservation!['userId'] : {};
    
    DateTime? travelDate;
    if (_reservation!['date'] != null) {
      if (_reservation!['date'] is String) {
        travelDate = DateTime.tryParse(_reservation!['date']);
      } else if (_reservation!['date'] is Map) {
        final dateMap = _reservation!['date'] as Map;
        if (dateMap['\$date'] != null) {
          travelDate = DateTime.fromMillisecondsSinceEpoch(dateMap['\$date'] as int);
        }
      }
    }
    travelDate ??= DateTime.now();

    final ticketId = _reservation!['ticketId'] ?? 'N/A';
    final qrCodeData = _reservation!['qrCode'] ?? ticketId;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WayGo',
                      style: AppTextStyles.heading.copyWith(
                        color: AppColors.waygoDarkBlue,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      'E-Ticket',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'CONFIRMED',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 32),

            // Route Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route['start'] ?? 'N/A',
                        style: AppTextStyles.heading.copyWith(fontSize: 20),
                      ),
                      Text(
                        route['departure'] ?? '',
                        style: AppTextStyles.body.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward, size: 32, color: AppColors.waygoLightBlue),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        route['destination'] ?? 'N/A',
                        style: AppTextStyles.heading.copyWith(fontSize: 20),
                        textAlign: TextAlign.right,
                      ),
                      Text(
                        route['arrival'] ?? '',
                        style: AppTextStyles.body.copyWith(color: Colors.grey),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Ticket Details
            _buildDetailRow('Ticket ID', ticketId),
            _buildDetailRow('Date', DateFormat('dd MMM yyyy').format(travelDate)),
            _buildDetailRow('Seats', (_reservation!['seats'] as List?)?.join(', ') ?? 'N/A'),
            _buildDetailRow('Bus', bus['busName'] ?? route['busName'] ?? 'N/A'),
            _buildDetailRow('Passenger', user['userName'] ?? 'N/A'),
            _buildDetailRow('Amount', 'Rs. ${_reservation!['totalAmount'] ?? 0}'),
            const Divider(height: 32),

            // QR Code
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: QrImageView(
                      data: qrCodeData,
                      version: QrVersions.auto,
                      size: 200,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Scan QR Code for Boarding',
                    style: AppTextStyles.body.copyWith(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Download button
            ElevatedButton.icon(
              onPressed: _isDownloading ? null : _downloadTicket,
              icon: _isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.download),
              label: Text(_isDownloading ? 'Downloading...' : 'Download Ticket'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.waygoLightBlue,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

