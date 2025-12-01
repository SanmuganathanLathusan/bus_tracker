import 'dart:async'; 
// Importing async support (Timer etc.)

import 'package:flutter/material.dart';
// Basic UI components package.

import 'package:geolocator/geolocator.dart';
// For getting device location.

import 'package:socket_io_client/socket_io_client.dart' as IO;
// Socket.IO client package (communication with backend).


class DriverLivePage extends StatefulWidget {
  const DriverLivePage({super.key}); 
  // Widget constructor

  @override
  State<DriverLivePage> createState() => _DriverLivePageState();
  // Create the state class
}


class _DriverLivePageState extends State<DriverLivePage> {
  IO.Socket? socket; 
  // Socket object (nullable because not connected immediately)

  Position? _position; 
  // Holds current GPS location values

  String busId = "bus_101"; 
  // Hardcoded Bus ID - can be dynamic later if needed

  Timer? timer; 
  // Timer to update location every few seconds
  @override
  void initState() {
    super.initState();

    _initSocket(); 
    // Initialize socket connection

    _startLocationUpdates(); 
    // Start sending live location
  }


  void _initSocket() {
    socket = IO.io(
      'http://10.0.2.2:5000', 
      // Localhost for Android Emulator (10.0.2.2 means PC localhost)

      IO.OptionBuilder()
          .setTransports(['websocket']) 
          // Use WebSocket transport for real-time data

          .disableAutoConnect() 
          // Prevents auto connection, so we manually connect

          .build(),
    );

    socket!.connect(); 
    // Connect socket manually

    socket!.onConnect((_) => print('Connected to server')); 
    // On successful connection

    socket!.onDisconnect((_) => print('Disconnected')); 
    // On disconnection
  }


  void _startLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    // Check if location is enabled in device

    if (!serviceEnabled) return; 
    // If location is OFF → exit

    await Geolocator.requestPermission(); 
    // Request location permission (runtime)

    timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      // Every 3 seconds execute following block

      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        // High accuracy for better precision
      );

      _position = pos; 
      // Save latest location

      socket?.emit("updateLocation", {
        // Send location data to backend via socket

        "busId": busId, 
        // Bus ID used to identify which bus

        "lat": pos.latitude, 
        // Current latitude

        "lng": pos.longitude, 
        // Current longitude
      });
    });
  }


  @override
  void dispose() {
    timer?.cancel(); 
    // Stop timer when widget closes

    socket?.dispose(); 
    // Dispose socket properly

    super.dispose(); 
    // Always call super
  }


  @override
  Widget build(BuildContext context) {
    // UI code

    return Scaffold(
      appBar: AppBar(title: const Text("Driver Live Tracker")),
      // Top app bar title

