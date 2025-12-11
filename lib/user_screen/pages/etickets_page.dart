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
  bool _isDownloading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.reservationId != null ? _loadReservation() : _loadUserReservations();
  }

  // -------------------------------------------------------
  // Load a single reservation
  // -------------------------------------------------------
  Future<void> _loadReservation() async {
    _setLoading();
    try {
      final res = await _reservationService.getReservationById(widget.reservationId!);
      _setSuccess(res);
    } catch (e) {
      _setError(e);
    }
  }

  // -------------------------------------------------------
  // Load user's reservations and filter paid ones
  // -------------------------------------------------------
  Future<void> _loadUserReservations() async {
    _setLoading();
    try {
      final res = await _reservationService.getUserReservations();
      final paid = res.where((r) => r['status'] == 'paid').toList();

      paid.isEmpty ? _setError("No tickets found") : _setSuccess(paid.first);
    } catch (e) {
      _setError(e);
    }
  }

  // -------------------------------------------------------
  // Download Ticket PDF
  // -------------------------------------------------------
  Future<void> _downloadTicket() async {
    final id = _reservation?['_id'] ?? widget.reservationId;
    if (id == null) {
      _showSnack("No reservation selected.", isError: true);
      return;
    }

    try {
      setState(() => _isDownloading = true);

      final token = await _authService.getToken();
      if (token == null) throw "Login expired. Please sign in again.";

      final url = "${ReservationService.baseUrl}/reservations/$id/download";
      final dir = await getApplicationDocumentsDirectory();
      final file = "${dir.path}/WayGoTicket_${DateTime.now().millisecondsSinceEpoch}.pdf";

      await Dio().download(
        url,
        file,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      if (!mounted) return;
      _showSnack("Ticket saved to $file");
      await OpenFilex.open(file);
    } catch (e) {
      _showSnack("Download failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  // -------------------------------------------------------
  // UI Helpers
  // -------------------------------------------------------
  void _setLoading() {
    setState(() {
      _isLoading = true;
      _error = null;
    });
  }

  void _setSuccess(dynamic data) {
    setState(() {
      _reservation = data;
      _isLoading = false;
    });
  }

  void _setError(dynamic e) {
    setState(() {
      _error = e.toString();
      _isLoading = false;
    });
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  // -------------------------------------------------------
  // BUILD
  // -------------------------------------------------------
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
              ? _buildError()
              : _reservation == null
                  ? const Center(child: Text("No ticket found"))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: _buildTicketCard(),
                    ),
    );
  }

  // -------------------------------------------------------
  // Error Widget
  // -------------------------------------------------------
  Widget _buildError() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Error: $_error"),
            ElevatedButton(
              onPressed:
                  widget.reservationId != null ? _loadReservation : _loadUserReservations,
              child: const Text("Retry"),
            ),
          ],
        ),
      );

  // -------------------------------------------------------
  // Ticket Card
  // -------------------------------------------------------
  Widget _buildTicketCard() {
    final route = _reservation?['routeId'] ?? {};
    final bus = _reservation?['busId'] ?? {};
    final user = _reservation?['userId'] ?? {};

    final ticketId = _reservation?['ticketId'] ?? 'N/A';
    final qrData = _reservation?['qrCode'] ?? ticketId;

    final travelDate = _parseDate(_reservation?['date']);

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text("WayGo",
                    style: AppTextStyles.heading.copyWith(
                      color: AppColors.waygoDarkBlue,
                      fontSize: 24,
                    )),
                Text("E-Ticket",
                    style: AppTextStyles.body.copyWith(color: Colors.grey)),
              ]),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: Colors.green, borderRadius: BorderRadius.circular(8)),
                child: const Text("CONFIRMED",
                    style: TextStyle(color: Colors.white, fontSize: 12)),
              )
            ],
          ),

          const Divider(height: 32),

          // Route Info
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _buildRouteSide(route['start'], route['departure'], false),
            const Icon(Icons.arrow_forward, size: 32, color: AppColors.waygoLightBlue),
            _buildRouteSide(route['destination'], route['arrival'], true),
          ]),

          const SizedBox(height: 24),

          // Ticket Details
          _buildDetailRow("Ticket ID", ticketId),
          _buildDetailRow("Date", DateFormat("dd MMM yyyy").format(travelDate)),
          _buildDetailRow("Seats", (_reservation?['seats'] as List?)?.join(", ") ?? "N/A"),
          _buildDetailRow("Bus", bus['busName'] ?? route['busName'] ?? 'N/A'),
          _buildDetailRow("Passenger", user['userName'] ?? 'N/A'),
          _buildDetailRow("Amount", "Rs. ${_reservation?['totalAmount'] ?? 0}"),

          const Divider(height: 28),

          // QR Code
          Center(
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300)),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
              const SizedBox(height: 10),
              Text("Scan QR Code for Boarding",
                  style: AppTextStyles.body.copyWith(fontSize: 12, color: Colors.grey)),
            ]),
          ),

          const SizedBox(height: 24),

          // Download Button
          ElevatedButton.icon(
            onPressed: _isDownloading ? null : _downloadTicket,
            icon: _isDownloading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.download),
            label: Text(_isDownloading ? "Downloading..." : "Download Ticket"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.waygoLightBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ]),
      ),
    );
  }

  // -------------------------------------------------------
  // Helpers
  // -------------------------------------------------------
  DateTime _parseDate(dynamic input) {
    if (input is String) return DateTime.tryParse(input) ?? DateTime.now();
    if (input is Map && input['\$date'] != null) {
      return DateTime.fromMillisecondsSinceEpoch(input['\$date']);
    }
    return DateTime.now();
  }

  Widget _buildRouteSide(String? title, String? time, bool right) {
    return Expanded(
      child: Column(
        crossAxisAlignment: right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(title ?? 'N/A', style: AppTextStyles.heading.copyWith(fontSize: 20)),
          Text(time ?? '', style: AppTextStyles.body.copyWith(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: AppTextStyles.body
                .copyWith(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
        Text(value, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.bold)),
      ]),
    );
  }
}
