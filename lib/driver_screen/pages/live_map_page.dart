import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Add callback function type
typedef LocationSharingCallback = void Function(bool isSharing);

class LiveMapPage extends StatefulWidget {
  final String busId; // Unique bus ID
  final bool autoStart; // Auto-start location sharing
  final LocationSharingCallback?
  onLocationSharingUpdate; // Add callback parameter

  const LiveMapPage({
    Key? key,
    required this.busId,
    this.autoStart = false,
    this.onLocationSharingUpdate, // Add callback parameter
  }) : super(key: key);

  @override
  State<LiveMapPage> createState() => _LiveMapPageState();
}

class _LiveMapPageState extends State<LiveMapPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final String serverUrl = "http://10.0.2.2:5000"; // ✅ Update to match backend
  LatLng? currentPos;
  bool isSharing = false;
  Timer? locationTimer;

  @override
  void initState() {
    super.initState();
    _checkPermissions().then((_) {
      if (widget.autoStart && currentPos != null && !isSharing) {
        // Auto-start sharing if requested and not already sharing
        _toggleSharing();
      }
    });
  }

  @override
  void dispose() {
    locationTimer?.cancel();
    super.dispose();
  }

  // -------------------- LOCATION PERMISSION --------------------
  Future<void> _checkPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable location services")),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Location permissions are permanently denied. Enable them in settings.",
          ),
        ),
      );
      return;
    }

    // Get initial position
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );
    setState(() => currentPos = LatLng(pos.latitude, pos.longitude));
  }

  // -------------------- START / STOP SHARING --------------------
  void _toggleSharing() async {
    if (isSharing) {
      // Stop sharing
      locationTimer?.cancel();

      // Notify server that location sharing has stopped
      await _toggleLocationSharing(false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Stopped sharing location")));
    } else {
      // Start sharing
      _startSendingLocation();

      // Notify server that location sharing has started
      await _toggleLocationSharing(true);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Started sharing location")));
    }

    // Update UI immediately
    setState(() => isSharing = !isSharing);

    // Notify parent widget if callback is provided
    widget.onLocationSharingUpdate?.call(isSharing);
  }

  Future<void> _toggleLocationSharing(bool isSharing) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    final url = Uri.parse("$serverUrl/api/bus/toggle-sharing");
    try {
      await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"busId": widget.busId, "isSharing": isSharing}),
      );
    } catch (e) {
      debugPrint("Error toggling location sharing: $e");
    }
  }

  // -------------------- SEND LOCATION TO SERVER --------------------
  void _startSendingLocation() {
    locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );
        currentPos = LatLng(pos.latitude, pos.longitude);
        setState(() {});
        _moveCamera(currentPos!);

        await _sendLocationToServer(currentPos!);
      } catch (e) {
        debugPrint("Error updating location: $e");
      }
    });
  }

  Future<void> _sendLocationToServer(LatLng location) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    final url = Uri.parse("$serverUrl/api/bus/update-location");
    try {
      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "busId": widget.busId,
          "lat": location.latitude,
          "lng": location.longitude,
        }),
      );
      if (res.statusCode != 200) {
        debugPrint("Server error: ${res.body}");
      }
    } catch (e) {
      debugPrint("Error sending location: $e");
    }
  }

  // -------------------- CAMERA FOLLOWING --------------------
  Future<void> _moveCamera(LatLng target) async {
    final GoogleMapController mapController = await _controller.future;
    mapController.animateCamera(CameraUpdate.newLatLng(target));
  }

  // -------------------- UI --------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Live Map - ${widget.busId}"),
        backgroundColor: const Color.fromARGB(255, 150, 208, 245),
      ),
      body: currentPos == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: (controller) =>
                      _controller.complete(controller),
                  initialCameraPosition: CameraPosition(
                    target: currentPos!,
                    zoom: 15.0,
                  ),
                  myLocationEnabled: true,
                  markers: {
                    Marker(
                      markerId: MarkerId(widget.busId),
                      position: currentPos!,
                      infoWindow: InfoWindow(title: "Bus ${widget.busId}"),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueAzure,
                      ),
                    ),
                  },
                ),
                Positioned(
                  bottom: 25,
                  left: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: _toggleSharing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSharing
                          ? Colors.redAccent
                          : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 6,
                    ),
                    child: Text(
                      isSharing ? "Stop Sharing" : "Start Sharing",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
