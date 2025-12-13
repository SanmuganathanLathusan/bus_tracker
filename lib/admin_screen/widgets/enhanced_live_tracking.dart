import 'dart:async';
import 'dart:convert';
import 'dart:math' show min, max;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';

class EnhancedLiveTrackingWidget extends StatefulWidget {
  const EnhancedLiveTrackingWidget({Key? key}) : super(key: key);

  @override
  State<EnhancedLiveTrackingWidget> createState() =>
      _EnhancedLiveTrackingWidgetState();
}

class _EnhancedLiveTrackingWidgetState
    extends State<EnhancedLiveTrackingWidget> {
  bool _isFullScreen = false;
  final String serverUrl = "http://10.0.2.2:5000"; // Update to match backend
  Timer? _locationTimer;
  Map<String, LatLng> busLocations = {}; // Store all bus locations
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final Completer<GoogleMapController> _controller = Completer();
  LatLng initialPosition = const LatLng(6.7071, 80.3565); // Default: Ratnapura
  List<Map<String, dynamic>> buses = []; // Store bus data
  List<Map<String, dynamic>> routes = []; // Store route data
  String? _selectedBusId;
  bool _showRoutes = false;

  @override
  void initState() {
    super.initState();
    _startFetchingLocations();
    _fetchAllBuses();
    _fetchAllRoutes();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  // Fetch all buses from server
  Future<void> _fetchAllBuses() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    final url = Uri.parse("$serverUrl/api/bus/admin/all");
    try {
      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        List<Map<String, dynamic>> busList = [];

        for (var bus in data) {
          if (bus is Map<String, dynamic>) {
            busList.add({
              'id': bus['_id'] ?? '',
              'busNumber': bus['busNumber'] ?? 'Unknown',
              'busName': bus['busName'] ?? 'Unknown Bus',
              'driver': bus['driverId'] is Map
                  ? bus['driverId']['userName']
                  : 'Unassigned',
              'status': _getStatusFromCondition(bus['conditionStatus']),
              'color': _getColorFromStatus(
                _getStatusFromCondition(bus['conditionStatus']),
              ),
              'isLocationSharing': bus['isLocationSharing'] ?? false,
              'routeId': bus['currentAssignmentId'],
            });
          }
        }

        setState(() {
          buses = busList;
        });
      }
    } catch (e) {
      debugPrint("Error fetching buses: $e");
    }
  }

  // Fetch all routes from server
  Future<void> _fetchAllRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    final url = Uri.parse("$serverUrl/api/routes");
    try {
      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        List<Map<String, dynamic>> routeList = [];

        for (var route in data) {
          if (route is Map<String, dynamic>) {
            routeList.add({
              'id': route['_id'] ?? '',
              'start': route['start'] ?? '',
              'destination': route['destination'] ?? '',
              'routeNumber': route['routeNumber'] ?? '',
            });
          }
        }

        setState(() {
          routes = routeList;
        });
      }
    } catch (e) {
      debugPrint("Error fetching routes: $e");
    }
  }

  String _getStatusFromCondition(String? condition) {
    switch (condition) {
      case 'workable':
        return 'On Route';
      case 'maintenance':
        return 'Maintenance';
      case 'non_workable':
        return 'Out of Service';
      default:
        return 'Unknown';
    }
  }

  Color _getColorFromStatus(String status) {
    switch (status) {
      case 'On Route':
        return Colors.green;
      case 'Delayed':
        return Colors.orange;
      case 'Maintenance':
      case 'Out of Service':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Fetch all bus locations from server
  void _startFetchingLocations() {
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _fetchBusLocations();
    });
  }

  Future<void> _fetchBusLocations() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    final url = Uri.parse("$serverUrl/api/bus/admin/locations");
    try {
      final res = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        Map<String, LatLng> newLocations = {};
        Set<Marker> newMarkers = {};

        for (var bus in data) {
          String busId = bus['bus_id'];
          String busNumber = bus['busNumber'];
          double lat = bus['latitude'];
          double lng = bus['longitude'];
          LatLng position = LatLng(lat, lng);

          newLocations[busNumber] = position;
          newMarkers.add(
            Marker(
              markerId: MarkerId(busId),
              position: position,
              infoWindow: InfoWindow(
                title: "Bus $busNumber",
                snippet: _getBusStatusSnippet(busId),
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
            ),
          );
        }

        setState(() {
          busLocations = newLocations;
          _markers = newMarkers;
        });
      }
    } catch (e) {
      debugPrint("Error fetching locations: $e");
    }
  }

  String _getBusStatusSnippet(String busId) {
    final bus = buses.firstWhere((b) => b['id'] == busId, orElse: () => {});

    if (bus.isEmpty) return 'Unknown status';

    return '${bus['status']} - ${bus['driver']}';
  }

  // Select a specific bus to highlight
  void _selectBus(String busId) {
    setState(() {
      _selectedBusId = _selectedBusId == busId ? null : busId;
    });

    // Move camera to selected bus
    _moveCameraToSelectedBus(busId);
  }

  void _moveCameraToSelectedBus(String busId) {
    final bus = buses.firstWhere((b) => b['id'] == busId, orElse: () => {});

    if (bus.isEmpty) return;

    final busNumber = bus['busNumber'] as String;
    if (busLocations.containsKey(busNumber)) {
      final position = busLocations[busNumber]!;
      _controller.future.then((controller) {
        controller.animateCamera(CameraUpdate.newLatLngZoom(position, 15.0));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isFullScreen ? _buildFullScreenMap() : _buildSplitView(context),
    );
  }

  Widget _buildFullScreenMap() {
    return Stack(
      children: [
        _buildMapSection(context),
        Positioned(
          top: 40,
          left: 20,
          child: IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => setState(() => _isFullScreen = false),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              shape: const CircleBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSplitView(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 900) {
          // Wide screen - side by side
          return Row(
            children: [
              Expanded(flex: 2, child: _buildMapSection(context)),
              Expanded(
                flex: 1,
                child: BusTrackingSidebar(
                  busLocations: busLocations,
                  buses: buses,
                  onBusSelected: _selectBus,
                  selectedBusId: _selectedBusId,
                ),
              ),
            ],
          );
        } else {
          // Narrow screen - column
          return SingleChildScrollView(
            child: Column(
              children: [
                _buildMapSection(context),
                const SizedBox(height: 16),
                BusTrackingSidebar(
                  busLocations: busLocations,
                  buses: buses,
                  onBusSelected: _selectBus,
                  selectedBusId: _selectedBusId,
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildMapSection(BuildContext context) {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: GoogleMap(
              onMapCreated: (controller) => _controller.complete(controller),
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 12.0,
              ),
              markers: _markers,
              polylines: _polylines,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: IconButton(
              icon: const Icon(Icons.fullscreen, color: Colors.blueAccent),
              tooltip: "Expand map",
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: const CircleBorder(),
              ),
              onPressed: () => setState(() => _isFullScreen = true),
            ),
          ),
        ],
      ),
    );
  }
}

class BusTrackingSidebar extends StatelessWidget {
  final Map<String, LatLng> busLocations;
  final List<Map<String, dynamic>> buses;
  final Function(String) onBusSelected;
  final String? selectedBusId;

  const BusTrackingSidebar({
    Key? key,
    required this.busLocations,
    required this.buses,
    required this.onBusSelected,
    required this.selectedBusId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusCount = {
      'On Route': buses.where((b) => b['status'] == 'On Route').length,
      'Delayed': buses.where((b) => b['status'] == 'Delayed').length,
      'Maintenance': buses.where((b) => b['status'] == 'Maintenance').length,
      'Out of Service': buses
          .where((b) => b['status'] == 'Out of Service')
          .length,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search bus...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
          ),
          const SizedBox(height: 20),

          // Status summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                const Text(
                  'Fleet Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatusChip(
                      'On Route',
                      statusCount['On Route'] ?? 0,
                      Colors.green,
                    ),
                    _buildStatusChip(
                      'Delayed',
                      statusCount['Delayed'] ?? 0,
                      Colors.orange,
                    ),
                    _buildStatusChip(
                      'Maintenance',
                      statusCount['Maintenance'] ?? 0,
                      Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              const Text(
                'All Buses',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Text(
                '${buses.length}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bus list
          Expanded(
            child: ListView(
              shrinkWrap: true,
              children: buses.map((bus) {
                // Check if this bus has live location
                String busNumber = bus['busNumber'].toString();
                bool hasLocation = busLocations.containsKey(busNumber);

                return _buildBusItem(
                  bus,
                  hasLocation,
                  bus['id'] == selectedBusId,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _buildBusItem(
    Map<String, dynamic> bus,
    bool hasLocation,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => onBusSelected(bus['id']),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: hasLocation ? Colors.green : Colors.grey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${bus['busNumber']} - ${bus['busName']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bus['driver'],
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: bus['color'],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      bus['status'],
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            if (hasLocation) const Icon(Icons.location_on, color: Colors.green),
          ],
        ),
      ),
    );
  }
}
