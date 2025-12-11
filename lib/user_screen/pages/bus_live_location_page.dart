import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';

class BusLiveLocationPage extends StatefulWidget {
  final String busId;
  final String? busNumber;
  final String? busName;
  final String? routeName;
  final Map<String, dynamic>? initialLocation;

  const BusLiveLocationPage({
    Key? key,
    required this.busId,
    this.busNumber,
    this.busName,
    this.routeName,
    this.initialLocation,
  }) : super(key: key);

  @override
  State<BusLiveLocationPage> createState() => _BusLiveLocationPageState();
}

class _BusLiveLocationPageState extends State<BusLiveLocationPage> {
  final Completer<GoogleMapController> _mapController = Completer();

  static const String baseUrl = "http://10.0.2.2:5000/api";
  static const LatLng sriLankaCenter = LatLng(6.9271, 79.8612);

  LatLng? _busLocation;
  List<LatLng> _routeHistory = [];
  Marker? _busMarker;

  bool _loading = true;
  bool _sharing = false;
  String? _error;
  DateTime? _lastUpdate;

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadInitialLocation();
    _startAutoFetch();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // -------------------------------
  // Validation Helper
  // -------------------------------
  bool _isValidSL(double lat, double lng) {
    return lat >= 5.9 && lat <= 10.0 && lng >= 79.6 && lng <= 82.0;
  }

  // -------------------------------
  // Initial Location
  // -------------------------------
  void _loadInitialLocation() {
    final loc = widget.initialLocation;
    if (loc == null) return;

    final lat = double.tryParse(loc['lat'].toString());
    final lng = double.tryParse(loc['lng'].toString());

    if (lat != null && lng != null && _isValidSL(lat, lng)) {
      _busLocation = LatLng(lat, lng);
      _routeHistory.add(_busLocation!);
      _sharing = true;
      _lastUpdate =
          DateTime.tryParse(loc['updatedAt']?.toString() ?? '') ?? DateTime.now();
    }
  }

  // -------------------------------
  // Auto Fetch Timer
  // -------------------------------
  void _startAutoFetch() {
    _fetchLocation();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchLocation());
  }

  // -------------------------------
  // Fetch Location API
  // -------------------------------
  Future<void> _fetchLocation() async {
    try {
      final url = Uri.parse("$baseUrl/bus/${widget.busId}");
      final res = await http.get(url).timeout(const Duration(seconds: 5));

      if (res.statusCode != 200) {
        setState(() {
          _loading = false;
          _sharing = false;
          _error = "Server error: ${res.statusCode}";
        });
        return;
      }

      final data = jsonDecode(res.body);
      final loc = data['location'];

      if (loc == null) {
        setState(() {
          _loading = false;
          _sharing = false;
          _error = "Bus location sharing disabled";
        });
        return;
      }

      final lat = double.tryParse(loc['lat'].toString());
      final lng = double.tryParse(loc['lng'].toString());

      if (lat == null || lng == null || !_isValidSL(lat, lng)) {
        setState(() {
          _loading = false;
          _sharing = false;
          _error = "Waiting for a valid GPS signal...";
        });
        return;
      }

      _updateMap(LatLng(lat, lng), loc['updatedAt']);

    } catch (e) {
      setState(() {
        _loading = false;
        _sharing = false;
        _error = "Connection error";
      });
    }
  }

  // -------------------------------
  // Update Map UI
  // -------------------------------
  Future<void> _updateMap(LatLng newPos, dynamic updatedAt) async {
    final changed = _busLocation == null ||
        _busLocation!.latitude != newPos.latitude ||
        _busLocation!.longitude != newPos.longitude;

    if (!changed) return;

    _busLocation = newPos;
    _sharing = true;
    _loading = false;
    _lastUpdate =
        DateTime.tryParse(updatedAt?.toString() ?? '') ?? DateTime.now();

    _routeHistory.add(newPos);
    if (_routeHistory.length > 50) _routeHistory.removeAt(0);

    _busMarker = Marker(
      markerId: const MarkerId('bus'),
      position: newPos,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      infoWindow: InfoWindow(
        title: widget.busName ?? "Bus ${widget.busNumber}",
        snippet: widget.routeName ?? "Live Location",
      ),
    );

    if (_mapController.isCompleted) {
      final c = await _mapController.future;
      c.animateCamera(CameraUpdate.newLatLngZoom(newPos, 15));
    }

    setState(() {});
  }

  // -------------------------------
  // UI
  // -------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.busNumber ?? "Live Bus",
          style: AppTextStyles.heading.copyWith(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.waygoDarkBlue,
      ),

      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (c) => _mapController.complete(c),
            initialCameraPosition: CameraPosition(
              target: _busLocation ?? sriLankaCenter,
              zoom: _busLocation != null ? 15 : 8,
            ),
            markers: _busMarker != null ? {_busMarker!} : {},
            polylines: {
              if (_routeHistory.length > 1)
                Polyline(
                  polylineId: const PolylineId("route"),
                  points: _routeHistory,
                  width: 5,
                  color: Colors.blue,
                ),
            },
            myLocationEnabled: true,
          ),

          if (_loading)
            const Center(child: CircularProgressIndicator()),

          _buildInfoCard(),
        ],
      ),
    );
  }

  // -------------------------------
  // Info Bottom Card
  // -------------------------------
  Widget _buildInfoCard() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              blurRadius: 8,
              color: Colors.black.withOpacity(0.1),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _sharing ? Icons.circle : Icons.circle_outlined,
                  color: _sharing ? Colors.green : Colors.grey,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _sharing ? "Live Location Active" : "No Location",
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _sharing ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),

            if (_busLocation != null) ...[
              const SizedBox(height: 8),
              Text(
                "Lat: ${_busLocation!.latitude.toStringAsFixed(5)}",
                style: AppTextStyles.bodySmall,
              ),
              Text(
                "Lng: ${_busLocation!.longitude.toStringAsFixed(5)}",
                style: AppTextStyles.bodySmall,
              ),
            ],

            if (_lastUpdate != null) ...[
              const SizedBox(height: 8),
              Text(
                "Updated: ${DateFormat("HH:mm:ss").format(_lastUpdate!)}",
                style: AppTextStyles.bodySmall,
              ),
            ],

            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.orange.shade700,
                ),
              )
            ]
          ],
        ),
      ),
    );
  }
}
