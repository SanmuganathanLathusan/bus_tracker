import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';

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
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _mapController?.dispose();
    super.dispose();
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

    // Add your own location marker
    _markers.add(
      Marker(
        markerId: const MarkerId('currentLocation'),
        position: _currentPosition!,
        infoWindow: const InfoWindow(title: 'You are here'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      ),
    );

    _addNearbyBusMarkers(); // Add some nearby buses

    setState(() => _loading = false);

    // Listen to location updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      final now = DateTime.now();
      if (now.difference(_lastUpdate) > const Duration(seconds: 1)) {
        _lastUpdate = now;
        LatLng newPos = LatLng(pos.latitude, pos.longitude);
        _updateMarker(newPos);
        _moveCamera(newPos);
        _addNearbyBusMarkers(); // Update buses periodically
      }
    });
  }

  // Simulate nearby buses around user
  void _addNearbyBusMarkers() {
    if (_currentPosition == null) return;

    // Remove old bus markers
    _markers.removeWhere((m) => m.markerId.value.startsWith('bus_'));

    for (int i = 0; i < 5; i++) {
      double offsetLat = (_random.nextDouble() - 0.5) / 500;
      double offsetLng = (_random.nextDouble() - 0.5) / 500;
      LatLng busPos = LatLng(
        _currentPosition!.latitude + offsetLat,
        _currentPosition!.longitude + offsetLng,
      );

      _markers.add(
        Marker(
          markerId: MarkerId('bus_$i'),
          position: busPos,
          infoWindow: InfoWindow(title: 'Bus #$i'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    setState(() {}); // Update map markers
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

  void _moveCamera(LatLng newPosition) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(newPosition),
    );
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Bus Tracker"),
        backgroundColor: const Color(0xFF0C2442),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 17,
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
                borderRadius: BorderRadius.circular(12),
              ),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.directions_bus, color: Colors.blue, size: 30),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Current Location',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          _currentPosition != null
                              ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(5)}'
                              : '',
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_currentPosition != null) _moveCamera(_currentPosition!);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orangeAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Center"),
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
