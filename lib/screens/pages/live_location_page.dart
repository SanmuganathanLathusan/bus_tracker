import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:google_fonts/google_fonts.dart';

class LiveLocationPage extends StatefulWidget {
  const LiveLocationPage({super.key});

  @override
  State<LiveLocationPage> createState() => _LiveLocationPageState();
}

class _LiveLocationPageState extends State<LiveLocationPage> {
  GoogleMapController? _mapController;
  LatLng? _currentPosition;
  bool _loading = true;
  final Set<Marker> _markers = {};
  StreamSubscription<Position>? _positionStream;
  DateTime _lastUpdate = DateTime.now();
  IO.Socket? socket;

  // Route info
  final LatLng origin = LatLng(6.9271, 79.8612); // Colombo
  final LatLng destination = LatLng(8.5550, 80.9980); // Mannar
  final double estimatedSpeedKmH = 50; // average bus speed

  @override
  void initState() {
    super.initState();
    _initSocket();
    _determinePosition();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    socket?.disconnect();
    socket?.dispose();
    super.dispose();
  }

  void _initSocket() {
    socket = IO.io(
      'http://10.0.2.2:5000',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket!.connect();

    socket!.onConnect((_) => print('✅ Connected to server'));

    socket!.on('busLocations', (data) {
      _updateBusMarkers(Map<String, dynamic>.from(data));
    });

    socket!.onDisconnect((_) => print('❌ Disconnected from server'));
  }

  Future<void> _determinePosition() async {
    var status = await Permission.location.request();
    if (!status.isGranted) {
      openAppSettings();
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _currentPosition = LatLng(position.latitude, position.longitude);

    _markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: _currentPosition!,
        infoWindow: const InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    );

    setState(() => _loading = false);

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 50, // reduce frequent updates
      ),
    ).listen((pos) {
      final now = DateTime.now();
      if (now.difference(_lastUpdate) > const Duration(seconds: 5)) {
        _lastUpdate = now;
        LatLng newPos = LatLng(pos.latitude, pos.longitude);
        _updateMarker(newPos);
        _moveCamera(newPos);
      }
    });
  }

  void _updateMarker(LatLng newPosition) {
    _markers.removeWhere((m) => m.markerId.value == 'currentLocation');
    _markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: newPosition,
        infoWindow: const InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    );
    setState(() {});
  }

  void _updateBusMarkers(Map<String, dynamic> busData) {
    _markers.removeWhere((m) => m.markerId.value.startsWith('bus_'));
    busData.forEach((id, loc) {
      _markers.add(Marker(
        markerId: MarkerId(id),
        position: LatLng(loc['lat'], loc['lng']),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(title: 'Bus $id'),
      ));
    });
    setState(() {});
  }

  void _moveCamera(LatLng newPosition) {
    _mapController?.animateCamera(CameraUpdate.newLatLng(newPosition));
  }

  double _calculateDistanceKm(LatLng from, LatLng to) {
    const double R = 6371; // km
    double dLat = _deg2rad(to.latitude - from.latitude);
    double dLon = _deg2rad(to.longitude - from.longitude);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(from.latitude)) *
            cos(_deg2rad(to.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  String _estimateTravelTime(LatLng from, LatLng to) {
    double distance = _calculateDistanceKm(from, to);
    double hours = distance / estimatedSpeedKmH;
    int h = hours.floor();
    int m = ((hours - h) * 60).round();
    return "${h}h ${m}m";
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController?.setMapStyle('''
      [
        {"featureType": "poi", "elementType": "labels", "stylers": [{"visibility": "off"}]},
        {"featureType": "transit", "elementType": "labels", "stylers": [{"visibility": "off"}]}
      ]
    ''');
  }

  @override
  Widget build(BuildContext context) {
    String travelTime = _estimateTravelTime(origin, destination);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "🚌 Live Real-Time Bus Tracker",
          style: GoogleFonts.roboto(
              fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0C2442),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ?? origin,
                    zoom: 6,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: _onMapCreated,
                ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              color: Colors.white,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.place, color: Colors.red, size: 30),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Route: Colombo → Mannar",
                            style: GoogleFonts.roboto(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                        Text(
                          travelTime,
                          style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w500, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.my_location,
                            color: Colors.orange, size: 25),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _currentPosition != null
                                ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}, '
                                    'Lng: ${_currentPosition!.longitude.toStringAsFixed(5)}'
                                : 'Fetching location...',
                            style: GoogleFonts.roboto(fontSize: 14),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (_currentPosition != null) {
                              _moveCamera(_currentPosition!);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orangeAccent,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8))),
                          child: const Text("Center"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
