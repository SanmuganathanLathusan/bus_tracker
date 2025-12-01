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
