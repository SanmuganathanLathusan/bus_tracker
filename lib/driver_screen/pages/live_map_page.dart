import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LiveMapPage extends StatefulWidget {
  final String busId; /// Unique ID used to identify each bus

  const LiveMapPage({Key? key, required this.busId}) : super(key: key);

  @override
  State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage> {
  // Completer is used to store the Google Map controller asynchronously
  final Completer<GoogleMapController> _controller = Completer();

  // Backend API URL (10.0.2.2 is Android Emulator's localhost)
  final String serverUrl = "http://10.0.2.2:5000";

  // Stores the current GPS position of the bus
  LatLng? currentPos;

  // Shows if currently sharing location or not
  bool isSharing = false;

  // Timer to send location every 5 seconds
  Timer? locationTimer;

  @override
  void initState() {
    super.initState();
    _checkPermissions();  /// On startup, check GPS permission and get initial location
  }

  @override
  void dispose() {
    locationTimer?.cancel(); /// Stop periodic timer when page is closed
    super.dispose();
  }
