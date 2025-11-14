import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:google_fonts/google_fonts.dart';

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
  final a = sin(dLat / 2) * sin(dLat / 2) +
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

  // Route info
  final LatLng origin = const LatLng(6.9271, 79.8612); // Colombo
  final LatLng destination = const LatLng(8.5550, 80.9980); // Mannar
  final double estimatedSpeedKmH = 50; // average bus speed

  // Tunables (safe defaults)
  static const Duration uiBatchDuration = Duration(seconds: 3); // reduced GPU churn
  static const Duration userUpdateMinInterval = Duration(seconds: 3);
  static const Duration cameraMinInterval = Duration(seconds: 10);
  static const int locationDistanceFilterMeters = 30;
  static const String userMarkerId = 'user_location';

  // Precomputed travel time (route distances don't change)
  late final String travelTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    travelTime = _estimateTravelTime(origin, destination);

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
      _socket!.onConnectError((data) => debugPrint('Socket connect error: $data'));
      _socket!.onError((data) => debugPrint('Socket error: $data'));

      // Collect but do not setState here
      _socket!.on('busLocations', (data) {
        if (data is Map) {
          (data as Map).forEach((key, value) {
            try {
              final id = key.toString();
              if (value is Map && value['lat'] != null && value['lng'] != null) {
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
    _batchTimer = Timer.periodic(uiBatchDuration, (_) => _flushPendingMarkers());
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        );
      } else {
        final latDiff = (existing.position.latitude - newLatLng.latitude).abs();
        final lngDiff = (existing.position.longitude - newLatLng.longitude).abs();

        // If difference > degreesThreshold in either axis we update quickly
        if (latDiff > degreesThreshold || lngDiff > degreesThreshold) {
          // For larger moves we can update without exact haversine
          updates[id] = Marker(
            markerId: MarkerId(id),
            position: newLatLng,
            infoWindow: InfoWindow(title: 'Bus $id'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          );
        } else {
          // small difference — run accurate distance in isolate and update only if > ~60m
          final fut = _computeDistanceKm(existing.position, newLatLng).then((km) {
            if (km > 0.06) {
              updates[id] = Marker(
                markerId: MarkerId(id),
                position: newLatLng,
                infoWindow: InfoWindow(title: 'Bus $id'),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
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

      _positionStream = Geolocator.getPositionStream(
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
  static const double _cheapBusThresholdDeg = 0.001; // ~111m

  void _updateUserPosition(LatLng newPos, {bool immediate = false}) async {
    _currentPosition = newPos;

    final existing = _markerMap[userMarkerId];
    final movedCheap = existing == null ||
        (existing.position.latitude - newPos.latitude).abs() > _cheapUserThresholdDeg ||
        (existing.position.longitude - newPos.longitude).abs() > _cheapUserThresholdDeg;

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
    final aa = sin(dLat / 2) * sin(dLat / 2) +
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
              fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0C2442),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator())
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition ?? origin,
                    zoom: 6,
                  ),
                  markers: _createMarkerSet(),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: _onMapCreated,
                  mapToolbarEnabled: false,
                  zoomControlsEnabled: false,
                  trafficEnabled: false,
                  buildingsEnabled: false,
                  indoorViewEnabled: false,
                ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: _buildInfoCard(travelTime),
          ),
        ],
      ),
    );
  }

  Set<Marker> _createMarkerSet() => Set<Marker>.of(_markerMap.values);

  Widget _buildInfoCard(String travelTime) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.place, color: Colors.red, size: 30),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Route: Colombo → Mannar",
                    style: GoogleFonts.roboto(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                Text(
                  travelTime,
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.my_location, color: Colors.orange, size: 25),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _currentPosition != null
                        ? 'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}, '
                            'Lng: ${_currentPosition!.longitude.toStringAsFixed(5)}'
                        : 'Fetching location...',
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
                          borderRadius: BorderRadius.circular(8))),
                  child: const Text("Center"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
