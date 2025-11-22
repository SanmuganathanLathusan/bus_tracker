import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

class LiveMapPage extends StatefulWidget {
  final String busId; // Unique bus ID

  const LiveMapPage({Key? key, required this.busId}) : super(key: key);

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
    _checkPermissions();
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
  void _toggleSharing() {
    if (isSharing) {
      locationTimer?.cancel();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Stopped sharing location")));
    } else {
      _startSendingLocation();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Started sharing location")));
    }
    setState(() => isSharing = !isSharing);
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
    final url = Uri.parse("$serverUrl/api/location/update");
    try {
      final res = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "bus_id": widget.busId,
          "latitude": location.latitude,
          "longitude": location.longitude,
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
