import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class DriverLivePage extends StatefulWidget {
  const DriverLivePage({super.key});

  @override
  State<DriverLivePage> createState() => _DriverLivePageState();
}

class _DriverLivePageState extends State<DriverLivePage> {
  IO.Socket? socket;
  Position? _position;
  String busId = "bus_101"; // Example bus ID
  Timer? timer;

  @override
  void initState() {
    super.initState();
    _initSocket();
    _startLocationUpdates();
  }

  void _initSocket() {
    socket = IO.io(
      'http://10.0.2.2:5000', // localhost for emulator
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );
    socket!.connect();

    socket!.onConnect((_) => print('Connected to server'));
    socket!.onDisconnect((_) => print('Disconnected'));
  }

  void _startLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    await Geolocator.requestPermission();

    timer = Timer.periodic(const Duration(seconds: 3), (_) async {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _position = pos;
      socket?.emit("updateLocation", {
        "busId": busId,
        "lat": pos.latitude,
        "lng": pos.longitude,
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    socket?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Driver Live Tracker")),
      body: Center(
        child: _position == null
            ? const CircularProgressIndicator()
            : Text(
                "Live: ${_position!.latitude}, ${_position!.longitude}",
                style: const TextStyle(fontSize: 18),
              ),
      ),
    );
  }
}
