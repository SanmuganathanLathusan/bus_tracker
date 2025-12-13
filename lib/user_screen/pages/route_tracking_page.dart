import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:waygo/services/location_service.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';

class RouteTrackingPage extends StatefulWidget {
  final String routeId;
  final String routeName;
  final String date;

  const RouteTrackingPage({
    Key? key,
    required this.routeId,
    required this.routeName,
    required this.date,
  }) : super(key: key);

  @override
  State<RouteTrackingPage> createState() => _RouteTrackingPageState();
}

class _RouteTrackingPageState extends State<RouteTrackingPage> {
  final LocationService _locationService = LocationService();
  final Completer<GoogleMapController> _controller = Completer();

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _buses = [];
  Set<Marker> _markers = {};
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadBuses();
    // Refresh bus locations every 10 seconds
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _loadBuses(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBuses() async {
    try {
      final buses = await _locationService.getBusesForRoute(
        widget.routeId,
        widget.date,
      );

      if (!mounted) return;

      setState(() {
        _buses = buses;
        _isLoading = false;
        _error = null;
        _updateMarkers();
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _updateMarkers() {
    Set<Marker> newMarkers = {};

    for (var bus in _buses) {
      final location = bus['location'] as Map<String, dynamic>?;

      if (location != null &&
          location['lat'] != null &&
          location['lng'] != null &&
          bus['isLocationSharing'] == true) {
        final lat = location['lat'] is num
            ? location['lat'].toDouble()
            : double.tryParse(location['lat'].toString());
        final lng = location['lng'] is num
            ? location['lng'].toDouble()
            : double.tryParse(location['lng'].toString());

        if (lat != null && lng != null) {
          newMarkers.add(
            Marker(
              markerId: MarkerId(bus['busId'].toString()),
              position: LatLng(lat, lng),
              infoWindow: InfoWindow(
                title: '${bus['busNumber']} - ${bus['driverName']}',
                snippet: 'Scheduled: ${bus['scheduledTime'] ?? 'N/A'}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
            ),
          );
        }
      }
    }

    setState(() {
      _markers = newMarkers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Tracking - ${widget.routeName}',
          style: AppTextStyles.heading.copyWith(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.waygoDarkBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading bus locations',
                    style: AppTextStyles.heading,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: AppTextStyles.body,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadBuses,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    onMapCreated: (GoogleMapController controller) {
                      _controller.complete(controller);
                    },
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(6.9271, 79.8612), // Center of Sri Lanka
                      zoom: 10,
                    ),
                    markers: _markers,
                    myLocationButtonEnabled: true,
                    zoomControlsEnabled: true,
                  ),
                ),
                // Bus list at the bottom
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Available Buses (${_buses.length})',
                        style: AppTextStyles.subHeading,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _buses.isEmpty
                            ? const Center(
                                child: Text(
                                  'No buses available for this route',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _buses.length,
                                itemBuilder: (context, index) {
                                  final bus = _buses[index];
                                  final isLive =
                                      bus['isLocationSharing'] == true;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: isLive
                                              ? Colors.green
                                              : Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      title: Text(
                                        '${bus['busNumber']} - ${bus['driverName']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Scheduled: ${bus['scheduledTime'] ?? 'N/A'}\nStatus: ${bus['status']}',
                                      ),
                                      trailing: isLive
                                          ? const Icon(
                                              Icons.wifi,
                                              color: Colors.green,
                                            )
                                          : const Icon(
                                              Icons.wifi_off,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
