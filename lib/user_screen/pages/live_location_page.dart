import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:waygo/services/reservation_service.dart';
import 'package:http/http.dart' as http;

/// Top-level isolate worker for accurate distance (km) using Haversine.
/// compute() requires a top-level or static function and only serializable args.
double _haversineWorker(Map<String, double> args) {
  const R = 6371.0; // km
  final lat1 = args['lat1']!;
  final lon1 = args['lon1']!;
  final lat2 = args['lat2']!;
  final lon2 = args['lon2']!;
  final dLat = (lat2 - lat1) * (pi / 180);
  final dLon = (lon2 - lon1) * (pi / 180);
  final a =
      sin(dLat / 2) * sin(dLat / 2) +
      cos(lat1 * (pi / 180)) *
          cos(lat2 * (pi / 180)) *
          sin(dLon / 2) *
          sin(dLon / 2);
  final c = 2 * atan2(sqrt(a), sqrt(1 - a));
  return R * c; // km
}

/// Helper that runs the compute worker and returns km (async)
Future<double> _computeDistanceKm(LatLng a, LatLng b) async {
  return compute(_haversineWorker, {
    'lat1': a.latitude,
    'lon1': a.longitude,
    'lat2': b.latitude,
    'lon2': b.longitude,
  });
}

class LiveLocationPage extends StatefulWidget {
  const LiveLocationPage({super.key});

  @override
  State<LiveLocationPage> createState() => _LiveLocationPageState();
}

class _LiveLocationPageState extends State<LiveLocationPage>
    with WidgetsBindingObserver {
  GoogleMapController? _mapController;

  // Efficient marker storage
  LatLng? _currentPosition;
  final Map<String, Marker> _markerMap = {}; // includes user and bus markers
  final Map<String, LatLng> _pendingBusUpdates = {};

  // Streams / sockets / timers
  StreamSubscription<Position>? _positionStream;
  IO.Socket? _socket;
  Timer? _batchTimer; // flush pending updates
  Timer? _cameraTimer; // throttle camera moves

  // Flags & timestamps
  bool _loading = true;
  DateTime _lastUserUpdate = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastCameraMove = DateTime.fromMillisecondsSinceEpoch(0);

  // Route search state
  String? _selectedFrom;
  String? _selectedTo;
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _selectedRoute;
  LatLng? _busLocation;
  String? _busId;
  Timer? _busLocationTimer;
  final ReservationService _reservationService = ReservationService();
  static const String baseUrl = "http://10.0.2.2:5000/api";

  // City coordinates mapping for Sri Lanka
  static const Map<String, LatLng> _cityCoordinates = {
    'Colombo': LatLng(6.9271, 79.8612),
    'Kandy': LatLng(7.2906, 80.6337),
    'Galle': LatLng(6.0329, 80.2170),
    'Matara': LatLng(5.9549, 80.5550),
    'Jaffna': LatLng(9.6615, 80.0255),
    'Negombo': LatLng(7.2083, 79.8358),
    'Anuradhapura': LatLng(8.3114, 80.4037),
    'Trincomalee': LatLng(8.5874, 81.2152),
  };

  final List<String> _cities = [
    'Colombo',
    'Kandy',
    'Galle',
    'Matara',
    'Jaffna',
    'Negombo',
    'Anuradhapura',
    'Trincomalee',
  ];

  // Route info
  LatLng? _routeOrigin;
  LatLng? _routeDestination;
  List<LatLng> _routePolyline = [];
  final double estimatedSpeedKmH = 50; // average bus speed

  // Tunables (safe defaults)
  static const Duration uiBatchDuration = Duration(
    seconds: 3,
  ); // reduced GPU churn
  static const Duration userUpdateMinInterval = Duration(seconds: 3);
  static const Duration cameraMinInterval = Duration(seconds: 10);
  static const int locationDistanceFilterMeters = 30;
  static const String userMarkerId = 'user_location';
  static const String busMarkerId = 'selected_bus_location';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _startBatchTimer();
    _initSocket();
    _determinePositionAndStream();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _batchTimer?.cancel();
    _cameraTimer?.cancel();
    _positionStream?.cancel();
    _busLocationTimer?.cancel();
    _mapController?.dispose();
    _disconnectSocket();
    super.dispose();
  }

  // Lifecycle: pause/resume to save CPU & battery
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _positionStream?.pause();
      try {
        _socket?.disconnect();
      } catch (_) {}
    } else if (state == AppLifecycleState.resumed) {
      _positionStream?.resume();
      if (_socket != null && _socket!.disconnected) _socket!.connect();
    }
  }

  // ---------------- SOCKET ----------------
  void _initSocket() {
    try {
      _socket = IO.io(
        'http://10.0.2.2:5000',
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .build(),
      );

      _socket!.onConnect((_) => debugPrint('✅ Socket connected'));
      _socket!.onDisconnect((_) => debugPrint('❌ Socket disconnected'));
      _socket!.onConnectError(
        (data) => debugPrint('Socket connect error: $data'),
      );
      _socket!.onError((data) => debugPrint('Socket error: $data'));

      // Collect but do not setState here
      _socket!.on('busLocations', (data) {
        if (data is Map) {
          data.forEach((key, value) {
            try {
              final id = key.toString();
              if (value is Map &&
                  value['lat'] != null &&
                  value['lng'] != null) {
                final lat = (value['lat'] as num).toDouble();
                final lng = (value['lng'] as num).toDouble();
                _pendingBusUpdates[id] = LatLng(lat, lng);
              }
            } catch (_) {}
          });
        }
      });
    } catch (e) {
      debugPrint('Socket init failed: $e');
    }
  }

  void _disconnectSocket() {
    try {
      _socket?.disconnect();
      _socket?.destroy();
      _socket = null;
    } catch (_) {}
  }

  // ---------------- BATCH FLUSH ----------------
  void _startBatchTimer() {
    // Flush less often to relieve GPU / ImageReader
    _batchTimer = Timer.periodic(
      uiBatchDuration,
      (_) => _flushPendingMarkers(),
    );
  }

  Future<void> _flushPendingMarkers() async {
    if (_pendingBusUpdates.isEmpty) return;

    // Quick cheap degree-based pre-check threshold to avoid trig math often.
    // degreesThreshold approx -> 0.001 deg ≈ 111m (latitude). This is cheap.
    const double degreesThreshold = 0.001; // around 100m

    final Map<String, Marker> updates = {};
    final List<Future<void>> expensiveCheckFutures = [];

    _pendingBusUpdates.forEach((id, newLatLng) {
      final existing = _markerMap[id];
      if (existing == null) {
        // new bus -> create marker immediately
        updates[id] = Marker(
          markerId: MarkerId(id),
          position: newLatLng,
          infoWindow: InfoWindow(title: 'Bus $id'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        );
      } else {
        final latDiff = (existing.position.latitude - newLatLng.latitude).abs();
        final lngDiff = (existing.position.longitude - newLatLng.longitude)
            .abs();

        // If difference > degreesThreshold in either axis we update quickly
        if (latDiff > degreesThreshold || lngDiff > degreesThreshold) {
          // For larger moves we can update without exact haversine
          updates[id] = Marker(
            markerId: MarkerId(id),
            position: newLatLng,
            infoWindow: InfoWindow(title: 'Bus $id'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          );
        } else {
          // small difference — run accurate distance in isolate and update only if > ~60m
          final fut = _computeDistanceKm(existing.position, newLatLng).then((
            km,
          ) {
            if (km > 0.06) {
              updates[id] = Marker(
                markerId: MarkerId(id),
                position: newLatLng,
                infoWindow: InfoWindow(title: 'Bus $id'),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueAzure,
                ),
              );
            }
          });
          expensiveCheckFutures.add(fut);
        }
      }
    });

    // Wait for expensive checks to finish (but they run in isolates)
    if (expensiveCheckFutures.isNotEmpty) {
      await Future.wait(expensiveCheckFutures);
    }

    // If there are no actual updates, just clear pending and return
    if (updates.isEmpty) {
      _pendingBusUpdates.clear();
      return;
    }

    // Apply updates to marker map, clear pending, and update UI once via post frame callback
    _markerMap.addAll(updates);
    _pendingBusUpdates.clear();

    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {}); // single, safe UI refresh
    });
  }

  // ---------------- LOCATION (USER) ----------------
  Future<void> _determinePositionAndStream() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      await openAppSettings();
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      _updateUserPosition(LatLng(pos.latitude, pos.longitude), immediate: true);

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: locationDistanceFilterMeters,
            ),
          ).listen((position) {
            final now = DateTime.now();
            if (now.difference(_lastUserUpdate) < userUpdateMinInterval) return;
            _lastUserUpdate = now;
            _updateUserPosition(LatLng(position.latitude, position.longitude));
          });
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  static const double _cheapUserThresholdDeg = 0.00045; // ~50m
  // ~111m

  void _updateUserPosition(LatLng newPos, {bool immediate = false}) async {
    _currentPosition = newPos;

    final existing = _markerMap[userMarkerId];
    final movedCheap =
        existing == null ||
        (existing.position.latitude - newPos.latitude).abs() >
            _cheapUserThresholdDeg ||
        (existing.position.longitude - newPos.longitude).abs() >
            _cheapUserThresholdDeg;

    if (movedCheap) {
      // For user, we accept the cheap threshold—avoid isolate for user to keep snappy UI
      _markerMap[userMarkerId] = Marker(
        markerId: const MarkerId(userMarkerId),
        position: newPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'You are here'),
      );

      // center camera on first fix or when forced
      if (immediate) {
        _moveCameraThrottled(newPos, force: true);
      } else {
        _moveCameraThrottled(newPos);
      }

      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _loading = false);
        });
      }
    } else {
      if (_loading && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _loading = false);
        });
      }
    }
  }

  // ---------------- CAMERA THROTTLE ----------------
  void _moveCameraThrottled(LatLng target, {bool force = false}) {
    final now = DateTime.now();
    if (!force && now.difference(_lastCameraMove) < cameraMinInterval) {
      _cameraTimer?.cancel();
      final delay = cameraMinInterval - now.difference(_lastCameraMove);
      _cameraTimer = Timer(delay, () {
        _lastCameraMove = DateTime.now();
        try {
          _mapController?.animateCamera(CameraUpdate.newLatLng(target));
        } catch (_) {}
      });
      return;
    }

    _cameraTimer?.cancel();
    _lastCameraMove = DateTime.now();
    try {
      _mapController?.animateCamera(CameraUpdate.newLatLng(target));
    } catch (_) {}
  }

  // ---------------- HELPERS ----------------
  double _calculateDistanceKm(LatLng a, LatLng b) {
    // Keep this lightweight; use compute only when you need accurate result elsewhere.
    // For UI thresholds we rely on degree approximations and isolate elsewhere.
    const R = 6371.0;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final aa =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(a.latitude)) *
            cos(_deg2rad(b.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(aa), sqrt(1 - aa));
    return R * c; // km
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  String _estimateTravelTime(LatLng from, LatLng to) {
    final distance = _calculateDistanceKm(from, to);
    final hours = distance / estimatedSpeedKmH;
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return "${h}h ${m}m";
  }

  // Generate route path with intermediate points for smoother visualization
  List<LatLng> _generateRoutePath(LatLng origin, LatLng destination) {
    final points = <LatLng>[origin];
    
    // Add intermediate points for smoother curve (simple interpolation)
    const numIntermediatePoints = 10;
    for (int i = 1; i < numIntermediatePoints; i++) {
      final ratio = i / numIntermediatePoints;
      final lat = origin.latitude + (destination.latitude - origin.latitude) * ratio;
      final lng = origin.longitude + (destination.longitude - origin.longitude) * ratio;
      points.add(LatLng(lat, lng));
    }
    
    points.add(destination);
    return points;
  }

  // ---------------- ROUTE SEARCH ----------------
  Future<void> _showRouteSearchDialog() async {
    String? from = _selectedFrom;
    String? to = _selectedTo;
    DateTime selectedDate = _selectedDate;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RouteSearchBottomSheet(
        initialFrom: from,
        initialTo: to,
        initialDate: selectedDate,
        cities: _cities,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedFrom = result['from'];
        _selectedTo = result['to'];
        _selectedDate = result['date'];
      });
      await _searchAndSelectRoute();
    }
  }

  Future<void> _searchAndSelectRoute() async {
    if (_selectedFrom == null || _selectedTo == null) return;

    try {
      final dateForApi = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final routes = await _reservationService.searchRoutes(
        start: _selectedFrom!,
        destination: _selectedTo!,
        date: dateForApi,
      );

      if (routes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No routes found for selected date')),
          );
        }
        return;
      }

      // Filter routes with live location (check both hasLiveLocation and isLocationSharing)
      final routesWithLiveLocation = routes.where((r) => 
        (r['hasLiveLocation'] == true || r['isLocationSharing'] == true) && 
        r['busId'] != null
      ).toList();

      if (routesWithLiveLocation.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No buses with live location available')),
          );
        }
        return;
      }

      // Show route selection dialog
      final selectedRoute = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _RouteSelectionDialog(
          routes: routesWithLiveLocation,
        ),
      );

      if (selectedRoute != null) {
        setState(() {
          _selectedRoute = selectedRoute;
          _busId = selectedRoute['busId']?.toString();
          _routeOrigin = _cityCoordinates[_selectedFrom];
          _routeDestination = _cityCoordinates[_selectedTo];
        });

        // Draw route polyline with intermediate points for smoother curve
        if (_routeOrigin != null && _routeDestination != null) {
          _routePolyline = _generateRoutePath(_routeOrigin!, _routeDestination!);
        }

        // Start fetching bus location
        _startFetchingBusLocation();

        // Fit bounds to show both origin, destination, and current positions
        _fitMapToRoute();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error searching routes: $e')),
        );
      }
    }
  }

  void _startFetchingBusLocation() {
    _busLocationTimer?.cancel();
    _fetchBusLocation();
    _busLocationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchBusLocation();
    });
  }

  Future<void> _fetchBusLocation() async {
    if (_busId == null) return;

    try {
      final uri = Uri.parse("$baseUrl/bus/$_busId");
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Handle case where location sharing is disabled
        if (data['location'] == null) {
          debugPrint('Bus location sharing is disabled');
          return;
        }
        
        if (data['location'] is Map && 
            data['location']['lat'] != null && 
            data['location']['lng'] != null) {
          final lat = (data['location']['lat'] as num).toDouble();
          final lng = (data['location']['lng'] as num).toDouble();
          
          // Validate coordinates are in Sri Lanka
          if (lat >= 5.9 && lat <= 10.0 && lng >= 79.6 && lng <= 82.0) {
            setState(() {
              _busLocation = LatLng(lat, lng);
            });

            // Update bus marker
            _markerMap[busMarkerId] = Marker(
              markerId: const MarkerId(busMarkerId),
              position: _busLocation!,
              infoWindow: InfoWindow(
                title: _selectedRoute?['busName'] ?? 'Bus ${_selectedRoute?['busNumber'] ?? _busId}',
                snippet: '${_selectedFrom} → ${_selectedTo}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
            );

            if (mounted) {
              setState(() {});
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching bus location: $e');
    }
  }

  void _fitMapToRoute() {
    if (_mapController == null) return;

    final positions = <LatLng>[];
    if (_currentPosition != null) positions.add(_currentPosition!);
    if (_routeOrigin != null) positions.add(_routeOrigin!);
    if (_routeDestination != null) positions.add(_routeDestination!);
    if (_busLocation != null) positions.add(_busLocation!);

    if (positions.isEmpty) return;

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final pos in positions) {
      minLat = min(minLat, pos.latitude);
      maxLat = max(maxLat, pos.latitude);
      minLng = min(minLng, pos.longitude);
      maxLng = max(maxLng, pos.longitude);
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat - 0.1, minLng - 0.1),
      northeast: LatLng(maxLat + 0.1, maxLng + 0.1),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  // ---------------- MAP ----------------
  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    // Lighter style: hide POIs & transit labels
    _mapController?.setMapStyle('''
      [
        {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},
        {"featureType":"transit","elementType":"labels","stylers":[{"visibility":"off"}]}
      ]
    ''');

    if (_currentPosition != null) {
      _moveCameraThrottled(_currentPosition!, force: true);
    }
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "🚌 Live Real-Time Bus Tracker",
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0C2442),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showRouteSearchDialog,
            tooltip: 'Search Route',
          ),
        ],
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ?? const LatLng(6.9271, 79.8612),
                    zoom: 6,
                  ),
                  markers: _createMarkerSet(),
                  polylines: _createPolylines(),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: _onMapCreated,
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: true,
                  trafficEnabled: false,
                  buildingsEnabled: false,
                  indoorViewEnabled: false,
                ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildInfoCard(),
          ),
        ],
      ),
    );
  }

  Set<Marker> _createMarkerSet() {
    final markers = Set<Marker>.of(_markerMap.values);
    
    // Add origin marker if route is selected
    if (_routeOrigin != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('route_origin'),
          position: _routeOrigin!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(title: 'Origin: $_selectedFrom'),
        ),
      );
    }
    
    // Add destination marker if route is selected
    if (_routeDestination != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('route_destination'),
          position: _routeDestination!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'Destination: $_selectedTo'),
        ),
      );
    }
    
    return markers;
  }

  Set<Polyline> _createPolylines() {
    final polylines = <Polyline>{};
    
    // Route polyline (origin to destination)
    if (_routePolyline.length >= 2) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route_path'),
          points: _routePolyline,
          color: Colors.blue,
          width: 5,
          patterns: [],
        ),
      );
    }
    
    return polylines;
  }

  Widget _buildInfoCard() {
    final travelTime = _routeOrigin != null && _routeDestination != null
        ? _estimateTravelTime(_routeOrigin!, _routeDestination!)
        : '';

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_selectedRoute != null) ...[
              Row(
                children: [
                  const Icon(Icons.route, color: Colors.blue, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "$_selectedFrom → $_selectedTo",
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (travelTime.isNotEmpty)
                    Text(
                      travelTime,
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              if (_selectedRoute?['busName'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Bus: ${_selectedRoute!['busName']} ${_selectedRoute?['busNumber'] ?? ''}',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Divider(color: Colors.grey[300]),
            ],
            Row(
              children: [
                const Icon(Icons.my_location, color: Colors.orange, size: 25),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentPosition != null
                        ? 'You: ${_currentPosition!.latitude.toStringAsFixed(5)}, ${_currentPosition!.longitude.toStringAsFixed(5)}'
                        : 'Fetching your location...',
                    style: GoogleFonts.roboto(fontSize: 14),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPosition != null) {
                      _moveCameraThrottled(_currentPosition!, force: true);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orangeAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Center"),
                ),
              ],
            ),
            if (_busLocation != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.directions_bus, color: Colors.blue, size: 25),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bus: ${_busLocation!.latitude.toStringAsFixed(5)}, ${_busLocation!.longitude.toStringAsFixed(5)}',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Live',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Route Search Bottom Sheet
class _RouteSearchBottomSheet extends StatefulWidget {
  final String? initialFrom;
  final String? initialTo;
  final DateTime initialDate;
  final List<String> cities;

  const _RouteSearchBottomSheet({
    this.initialFrom,
    this.initialTo,
    required this.initialDate,
    required this.cities,
  });

  @override
  State<_RouteSearchBottomSheet> createState() => _RouteSearchBottomSheetState();
}

class _RouteSearchBottomSheetState extends State<_RouteSearchBottomSheet> {
  late String _from;
  late String _to;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _from = widget.initialFrom ?? widget.cities.first;
    _to = widget.initialTo ?? widget.cities[1];
    _selectedDate = widget.initialDate;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 20,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Search Route',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('From'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _from,
                      items: widget.cities
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _from = v!),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                onPressed: () {
                  setState(() {
                    final temp = _from;
                    _from = _to;
                    _to = temp;
                  });
                },
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('To'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _to,
                      items: widget.cities
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) => setState(() => _to = v!),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today),
                  const SizedBox(width: 12),
                  Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context, {
                  'from': _from,
                  'to': _to,
                  'date': _selectedDate,
                });
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: const Color(0xFF0C2442),
              ),
              child: const Text('Search Routes'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

// Route Selection Dialog
class _RouteSelectionDialog extends StatelessWidget {
  final List<Map<String, dynamic>> routes;

  const _RouteSelectionDialog({required this.routes});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Select Route',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: routes.length,
                itemBuilder: (context, index) {
                  final route = routes[index];
                  return ListTile(
                    leading: const Icon(Icons.directions_bus, color: Colors.blue),
                    title: Text(
                      '${route['start']} → ${route['destination']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (route['busName'] != null)
                          Text('Bus: ${route['busName']}'),
                        if (route['scheduledTime'] != null)
                          Text('Time: ${route['scheduledTime']}'),
                        if (route['driverName'] != null)
                          Text('Driver: ${route['driverName']}'),
                      ],
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.pop(context, route),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
