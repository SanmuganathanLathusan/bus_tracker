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
  final String busId; /// Unique ID used to identify each bus

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
  // ============================================================
  //    LOCATION PERMISSION CHECK + INITIAL GPS POSITION
  // ============================================================
  Future<void> _checkPermissions() async {
    /// Check if GPS hardware is turned ON
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enable location services")),
      );
      return;
    }

    /// Check if app has permission to access GPS
    LocationPermission permission = await Geolocator.checkPermission();

    /// Asking permission if denied
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied")),
        );
        return;
      }
    }

    /// Permission denied forever (User must change from phone settings)
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Location permissions permanently denied. Enable them from settings.",
          ),
        ),
      );
      return;
    }

    /// If permission granted → get initial GPS location
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    setState(() => currentPos = LatLng(pos.latitude, pos.longitude));
  }
  // ============================================================
  //    START / STOP SHARING BUTTON
  // ============================================================
  void _toggleSharing() {
    /// If already sharing → stop timer
    if (isSharing) {
      // Stop sharing
      locationTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Stopped sharing location")),
      );
    } else {
      /// If not sharing → start sending location
      _startSendingLocation();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Started sharing location")),
      );
    }

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

  // ============================================================
  //    SEND LOCATION EVERY 5 SECONDS TO BACKEND
  // ============================================================
  void _startSendingLocation() {
    /// Timer triggers every 5 seconds
    locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      try {
        /// Get new GPS coordinates
        Position pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best,
        );

        currentPos = LatLng(pos.latitude, pos.longitude);
        setState(() {});

        /// Move Google Map camera to bus's new location
        _moveCamera(currentPos!);

        /// Send coordinates to server
        await _sendLocationToServer(currentPos!);
      } catch (e) {
        debugPrint("Error updating location: $e");
      }
    });
  }
  // ============================================================
  //    API CALL (POST REQUEST) → UPDATE BUS LOCATION
  // ============================================================
  Future<void> _sendLocationToServer(LatLng location) async {
    final url = Uri.parse("$serverUrl/api/location/update");

    try {
      /// POST request with JSON body
      final res = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "bus_id": widget.busId,     /// Unique bus ID
          "latitude": location.latitude,
          "longitude": location.longitude,
        }),
      );

      /// 200 = success, otherwise log error
      if (res.statusCode != 200) {
        debugPrint("Server error: ${res.body}");
      }
    } catch (e) {
      debugPrint("Error sending location: $e");
    }
  }

  // ============================================================
  //    CAMERA FOLLOW THE BUS
  // ============================================================
  Future<void> _moveCamera(LatLng target) async {
    /// Wait for Google Map to be created
    final GoogleMapController mapController = await _controller.future;

    /// Smooth camera animation to updated position
    mapController.animateCamera(CameraUpdate.newLatLng(target));
  }

  // ============================================================
  //    UI SECTION – MAP + BUTTON
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Live Map - ${widget.busId}"),
        backgroundColor: const Color.fromARGB(255, 150, 208, 245),
      ),

      /// Show loading spinner until GPS position is ready
      body: currentPos == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                /// MAIN GOOGLE MAP
                GoogleMap(
                  onMapCreated: (controller) =>
                      _controller.complete(controller),

                  initialCameraPosition: CameraPosition(
                    target: currentPos!,
                    zoom: 15.0,
                  ),
                  /// Allow phone to show blue dot location
                  myLocationEnabled: true,

                  /// Show bus marker on the map
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

                /// START / STOP SHARING BUTTON
                Positioned(
                  bottom: 25,
                  left: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: _toggleSharing,

                    /// Button theme changes depending on state
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isSharing ? Colors.redAccent : Colors.green,
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


