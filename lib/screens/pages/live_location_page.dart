import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

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

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    // Request location permission
    var status = await Permission.location.request();
    if (!status.isGranted) {
      openAppSettings();
      return;
    }

    // Get current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentPosition = LatLng(position.latitude, position.longitude);
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: _currentPosition!,
          infoWindow: const InfoWindow(title: 'You are here'),
        ),
      );
      _loading = false;
    });

    // Listen to location updates
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((pos) {
      LatLng newPos = LatLng(pos.latitude, pos.longitude);
      _updateMarker(newPos);
      _moveCamera(newPos);
    });
  }

  void _updateMarker(LatLng newPosition) {
    setState(() {
      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: newPosition,
          infoWindow: const InfoWindow(title: 'You are here'),
        ),
      );
    });
  }

  void _moveCamera(LatLng newPosition) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(newPosition),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;

    // Optional: Custom map style for better clarity
    _mapController?.setMapStyle('''
    [
      {
        "featureType": "poi",
        "elementType": "labels",
        "stylers": [{"visibility": "off"}]
      },
      {
        "featureType": "transit",
        "elementType": "labels",
        "stylers": [{"visibility": "off"}]
      }
    ]
    ''');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Location"),
        backgroundColor: const Color(0xFF0C2442),
      ),
      body: _loading
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
    );
  }
}
