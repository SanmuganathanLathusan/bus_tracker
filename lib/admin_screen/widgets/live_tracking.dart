import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LiveTrackingWidget extends StatefulWidget {
  const LiveTrackingWidget({Key? key}) : super(key: key);

  @override
  State<LiveTrackingWidget> createState() => _LiveTrackingWidgetState();
}

class _LiveTrackingWidgetState extends State<LiveTrackingWidget> {
  bool _isFullScreen = false;
  final String serverUrl = "http://10.0.2.2:5000"; // Update to match backend
  Timer? _locationTimer;
  Map<String, LatLng> busLocations = {}; // Store all bus locations
  Set<Marker> markers = {};
  final Completer<GoogleMapController> _controller = Completer();
  LatLng initialPosition = const LatLng(6.7071, 80.3565); // Default: Ratnapura

  @override
  void initState() {
    super.initState();
    _startFetchingLocations();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  // Fetch all bus locations from server
  void _startFetchingLocations() {
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      await _fetchBusLocations();
    });
  }

  Future<void> _fetchBusLocations() async {
    final url = Uri.parse("$serverUrl/api/location/all");
    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        Map<String, LatLng> newLocations = {};
        Set<Marker> newMarkers = {};

        for (var bus in data) {
          String busId = bus['bus_id'];
          double lat = bus['latitude'];
          double lng = bus['longitude'];
          LatLng position = LatLng(lat, lng);

          newLocations[busId] = position;
          newMarkers.add(
            Marker(
              markerId: MarkerId(busId),
              position: position,
              infoWindow: InfoWindow(title: "Bus $busId"),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueAzure,
              ),
            ),
          );
        }

        setState(() {
          busLocations = newLocations;
          markers = newMarkers;
        });
      }
    } catch (e) {
      debugPrint("Error fetching locations: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: _isFullScreen
              ? SizedBox(
                  height: MediaQuery.of(context).size.height - 48,
                  child: _buildFullScreenMap(context),
                )
              : isWide
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildMapSection(context)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: BusTrackingSidebar(busLocations: busLocations),
                      ),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildMapSection(context),
                    const SizedBox(height: 16),
                    BusTrackingSidebar(busLocations: busLocations),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMapSection(BuildContext context) {
    return Container(
      height: 400,
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
              markers: markers,
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
                elevation: 2,
              ),
              onPressed: () {
                setState(() => _isFullScreen = true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullScreenMap(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          onMapCreated: (controller) => _controller.complete(controller),
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 12.0,
          ),
          markers: markers,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: true,
        ),
        Positioned(
          top: 24,
          right: 24,
          child: IconButton(
            icon: const Icon(
              Icons.close_fullscreen,
              color: Colors.white,
              size: 28,
            ),
            tooltip: "Exit full screen",
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              elevation: 4,
            ),
            onPressed: () {
              setState(() => _isFullScreen = false);
            },
          ),
        ),
      ],
    );
  }
}

class BusTrackingSidebar extends StatelessWidget {
  final Map<String, LatLng> busLocations;

  const BusTrackingSidebar({Key? key, required this.busLocations})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buses = [
      {
        'id': 'Bus #101',
        'route': 'Route 5',
        'status': 'On Route',
        'color': Colors.green,
        'driver': 'John Doe',
        'updated': '1 min ago',
      },
      {
        'id': 'Bus #205',
        'route': 'Route 12',
        'status': 'Delayed',
        'color': Colors.orange,
        'driver': 'Jane Smith',
        'updated': '3 min ago',
      },
      {
        'id': 'Bus #309',
        'route': 'Route 8',
        'status': 'On Route',
        'color': Colors.green,
        'driver': 'Mike Johnson',
        'updated': '2 min ago',
      },
      {
        'id': 'Bus #412',
        'route': 'Route 3',
        'status': 'Maintenance',
        'color': Colors.red,
        'driver': 'Sarah Williams',
        'updated': '25 min ago',
      },
    ];

    final statusCount = {
      'On Route': buses.where((b) => b['status'] == 'On Route').length,
      'Delayed': buses.where((b) => b['status'] == 'Delayed').length,
      'Maintenance': buses.where((b) => b['status'] == 'Maintenance').length,
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
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const SizedBox(height: 20),

          // Status cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: _buildStatusCard(
                  'On Route',
                  statusCount['On Route']!,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusCard(
                  'Delayed',
                  statusCount['Delayed']!,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusCard(
                  'Maintenance',
                  statusCount['Maintenance']!,
                  Colors.red,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              const Text(
                'Recent Activities',
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
          ...buses.map((bus) {
            // Check if this bus has live location
            String busNumber = bus['id'].toString().replaceAll('Bus #', '');
            bool hasLocation = busLocations.containsKey(busNumber);

            return _buildBusItem(bus, hasLocation);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBusItem(Map<String, dynamic> bus, bool hasLocation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: bus['color'],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bus['id'],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasLocation)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.wifi, size: 12, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.phone, size: 18, color: Colors.blue),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            bus['route'],
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            'Driver: ${bus['driver']}',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                bus['status'],
                style: TextStyle(
                  color: bus['color'],
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                bus['updated'],
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
