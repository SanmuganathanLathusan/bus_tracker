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
  bool _isDisposed = false;
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
  static const Duration uiBatchDuration = Duration(seconds: 3);
  static const Duration userUpdateMinInterval = Duration(seconds: 3);
  static const Duration cameraMinInterval = Duration(seconds: 10);
  static const int locationDistanceFilterMeters = 30;
  static const String userMarkerId = 'user_location';
  static const String busMarkerId = 'selected_bus_location';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Delay initialization slightly to ensure widget is fully mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed && mounted) {
        _startBatchTimer();
        _initSocket();
        _determinePositionAndStream();
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
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
    if (_isDisposed) return;

    if (state == AppLifecycleState.paused) {
      _positionStream?.pause();
      try {
        _socket?.disconnect();
      } catch (e) {
        debugPrint('Error disconnecting socket: $e');
      }
    } else if (state == AppLifecycleState.resumed) {
      _positionStream?.resume();
      if (_socket != null && _socket!.disconnected) {
        try {
          _socket!.connect();
        } catch (e) {
          debugPrint('Error reconnecting socket: $e');
        }
      }
    }
  }

  // ---------------- SOCKET ----------------
  void _initSocket() {
    if (_isDisposed) return;

    try {
      _socket = IO.io(
        'http://10.0.2.2:5000',
        IO.OptionBuilder()
            .setTransports(['websocket', 'polling']) // Add polling as fallback
            .disableAutoConnect() // Disable auto-connect to handle manually
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .setTimeout(10000)
            .build(),
      );

      _socket!.onConnect((_) {
        debugPrint('✅ Socket connected');
        // Request initial bus locations
        _socket?.emit('requestBusLocations');
      });

      _socket!.onDisconnect((_) => debugPrint('❌ Socket disconnected'));

      _socket!.onConnectError((data) {
        debugPrint('⚠️ Socket connect error: $data');
        // Don't show error to user, socket is optional feature
      });

      _socket!.onError((data) {
        debugPrint('⚠️ Socket error: $data');
      });

      // Collect but do not setState here
      _socket!.on('busLocations', (data) {
        if (_isDisposed) return;

        debugPrint('📍 Received bus locations: $data');

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
            } catch (e) {
              debugPrint('Error processing bus location: $e');
            }
          });
        }
      });

      _socket!.on('busLocationUpdate', (data) {
        if (_isDisposed) return;

        debugPrint('📍 Bus location update: $data');

        try {
          if (data is Map && data['busId'] != null) {
            final busId = data['busId'].toString();
            if (data['location'] is Map &&
                data['location']['lat'] != null &&
                data['location']['lng'] != null) {
              final lat = (data['location']['lat'] as num).toDouble();
              final lng = (data['location']['lng'] as num).toDouble();
              _pendingBusUpdates[busId] = LatLng(lat, lng);
            }
          }
        } catch (e) {
          debugPrint('Error processing bus update: $e');
        }
      });

      // Connect manually with error handling
      try {
        _socket!.connect();
      } catch (e) {
        debugPrint('⚠️ Failed to connect socket: $e');
      }
    } catch (e) {
      debugPrint('⚠️ Socket init failed: $e');
      // Socket is optional, app continues without it
    }
  }

  void _disconnectSocket() {
    try {
      _socket?.off('busLocations');
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
    } catch (e) {
      debugPrint('Error disposing socket: $e');
    }
  }

  // ---------------- BATCH FLUSH ----------------
  void _startBatchTimer() {
    if (_isDisposed) return;

    _batchTimer = Timer.periodic(uiBatchDuration, (_) {
      if (!_isDisposed && mounted) {
        _flushPendingMarkers();
      }
    });
  }

  Future<void> _flushPendingMarkers() async {
    if (_isDisposed || !mounted || _pendingBusUpdates.isEmpty) return;

    const double degreesThreshold = 0.001;

    final Map<String, Marker> updates = {};
    final List<Future<void>> expensiveCheckFutures = [];

    _pendingBusUpdates.forEach((id, newLatLng) {
      if (_isDisposed) return;

      final existing = _markerMap[id];
      if (existing == null) {
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

        if (latDiff > degreesThreshold || lngDiff > degreesThreshold) {
          updates[id] = Marker(
            markerId: MarkerId(id),
            position: newLatLng,
            infoWindow: InfoWindow(title: 'Bus $id'),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueAzure,
            ),
          );
        } else {
          final fut = _computeDistanceKm(existing.position, newLatLng)
              .then((km) {
                if (_isDisposed) return;
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
              })
              .catchError((e) {
                debugPrint('Error computing distance: $e');
              });
          expensiveCheckFutures.add(fut);
        }
      }
    });

    if (expensiveCheckFutures.isNotEmpty) {
      await Future.wait(expensiveCheckFutures);
    }

    if (_isDisposed || !mounted) return;

    if (updates.isEmpty) {
      _pendingBusUpdates.clear();
      return;
    }

    _markerMap.addAll(updates);
    _pendingBusUpdates.clear();

    if (mounted) {
      setState(() {});
    }
  }

  // ---------------- LOCATION (USER) ----------------
  Future<void> _determinePositionAndStream() async {
    if (_isDisposed) return;

    try {
      // Check location services
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services')),
          );
          setState(() => _loading = false);
        }
        return;
      }

      final status = await Permission.location.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          setState(() => _loading = false);
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );

      if (_isDisposed || !mounted) return;

      _updateUserPosition(LatLng(pos.latitude, pos.longitude), immediate: true);

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.best,
              distanceFilter: locationDistanceFilterMeters,
            ),
          ).listen(
            (position) {
              if (_isDisposed || !mounted) return;

              final now = DateTime.now();
              if (now.difference(_lastUserUpdate) < userUpdateMinInterval)
                return;
              _lastUserUpdate = now;
              _updateUserPosition(
                LatLng(position.latitude, position.longitude),
              );
            },
            onError: (error) {
              debugPrint('Position stream error: $error');
            },
          );
    } catch (e) {
      debugPrint('Location error: $e');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Location error: $e')));
      }
    }
  }

  static const double _cheapUserThresholdDeg = 0.00045; // ~50m

  void _updateUserPosition(LatLng newPos, {bool immediate = false}) {
    if (_isDisposed || !mounted) return;

    _currentPosition = newPos;

    final existing = _markerMap[userMarkerId];
    final movedCheap =
        existing == null ||
        (existing.position.latitude - newPos.latitude).abs() >
            _cheapUserThresholdDeg ||
        (existing.position.longitude - newPos.longitude).abs() >
            _cheapUserThresholdDeg;

    if (movedCheap) {
      _markerMap[userMarkerId] = Marker(
        markerId: const MarkerId(userMarkerId),
        position: newPos,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        infoWindow: const InfoWindow(title: 'You are here'),
      );

      if (immediate) {
        _moveCameraThrottled(newPos, force: true);
      } else {
        _moveCameraThrottled(newPos);
      }

      if (mounted) {
        setState(() => _loading = false);
      }
    } else {
      if (_loading && mounted) {
        setState(() => _loading = false);
      }
    }
  }

  // ---------------- CAMERA THROTTLE ----------------
  void _moveCameraThrottled(LatLng target, {bool force = false}) {
    if (_isDisposed || _mapController == null) return;

    final now = DateTime.now();
    if (!force && now.difference(_lastCameraMove) < cameraMinInterval) {
      _cameraTimer?.cancel();
      final delay = cameraMinInterval - now.difference(_lastCameraMove);
      _cameraTimer = Timer(delay, () {
        if (_isDisposed || _mapController == null) return;
        _lastCameraMove = DateTime.now();
        try {
          _mapController?.animateCamera(CameraUpdate.newLatLng(target));
        } catch (e) {
          debugPrint('Camera animation error: $e');
        }
      });
      return;
    }

    _cameraTimer?.cancel();
    _lastCameraMove = now;
    try {
      _mapController?.animateCamera(CameraUpdate.newLatLng(target));
    } catch (e) {
      debugPrint('Camera animation error: $e');
    }
  }

  // ---------------- HELPERS ----------------
  double _calculateDistanceKm(LatLng a, LatLng b) {
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
    return R * c;
  }

  double _deg2rad(double deg) => deg * (pi / 180);

  String _estimateTravelTime(LatLng from, LatLng to) {
    final distance = _calculateDistanceKm(from, to);
    final hours = distance / estimatedSpeedKmH;
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return "${h}h ${m}m";
  }

  List<LatLng> _generateRoutePath(LatLng origin, LatLng destination) {
    final points = <LatLng>[origin];

    const numIntermediatePoints = 10;
    for (int i = 1; i < numIntermediatePoints; i++) {
      final ratio = i / numIntermediatePoints;
      final lat =
          origin.latitude + (destination.latitude - origin.latitude) * ratio;
      final lng =
          origin.longitude + (destination.longitude - origin.longitude) * ratio;
      points.add(LatLng(lat, lng));
    }

    points.add(destination);
    return points;
  }

  // ---------------- ROUTE SEARCH ----------------
  Future<void> _showRouteSearchDialog() async {
    if (_isDisposed || !mounted) return;

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

    if (result != null && mounted) {
      setState(() {
        _selectedFrom = result['from'];
        _selectedTo = result['to'];
        _selectedDate = result['date'];
      });
      await _searchAndSelectRoute();
    }
  }

  Future<void> _searchAndSelectRoute() async {
    if (_isDisposed || !mounted || _selectedFrom == null || _selectedTo == null)
      return;

    try {
      final dateForApi = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('Searching routes...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final routes = await _reservationService.searchRoutes(
        start: _selectedFrom!,
        destination: _selectedTo!,
        date: dateForApi,
      );

      if (!mounted) return;

      if (routes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No routes found for selected date')),
        );
        return;
      }

      final routesWithLiveLocation = routes
          .where(
            (r) =>
                (r['hasLiveLocation'] == true ||
                    r['isLocationSharing'] == true) &&
                r['busId'] != null,
          )
          .toList();

      if (routesWithLiveLocation.isEmpty) {
        // If no routes with live location, show all routes anyway
        debugPrint('⚠️ No routes with live location, showing all routes');

        final selectedRoute = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (context) =>
              _RouteSelectionDialog(routes: routes, hasLiveLocation: false),
        );

        if (selectedRoute != null && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('This route does not have live location tracking'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final selectedRoute = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => _RouteSelectionDialog(
          routes: routesWithLiveLocation,
          hasLiveLocation: true,
        ),
      );

      if (selectedRoute != null && mounted) {
        setState(() {
          _selectedRoute = selectedRoute;
          _busId = selectedRoute['busId']?.toString();
          _routeOrigin = _cityCoordinates[_selectedFrom];
          _routeDestination = _cityCoordinates[_selectedTo];
        });

        if (_routeOrigin != null && _routeDestination != null) {
          _routePolyline = _generateRoutePath(
            _routeOrigin!,
            _routeDestination!,
          );
        }

        _startFetchingBusLocation();
        _fitMapToRoute();
      }
    } on Exception catch (e) {
      debugPrint('❌ Error searching routes: $e');
      if (mounted) {
        String errorMessage = 'Error searching routes';
        if (e.toString().contains('Authentication')) {
          errorMessage = 'Please login to view routes';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Unexpected error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startFetchingBusLocation() {
    if (_isDisposed) return;

    _busLocationTimer?.cancel();
    _fetchBusLocation();
    _busLocationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!_isDisposed && mounted) {
        _fetchBusLocation();
      }
    });
  }

  Future<void> _fetchBusLocation() async {
    if (_isDisposed || !mounted || _busId == null) return;

    try {
      final uri = Uri.parse("$baseUrl/bus/$_busId");
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (!mounted || _isDisposed) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['location'] == null) {
          debugPrint('Bus location sharing is disabled');
          return;
        }

        if (data['location'] is Map &&
            data['location']['lat'] != null &&
            data['location']['lng'] != null) {
          final lat = (data['location']['lat'] as num).toDouble();
          final lng = (data['location']['lng'] as num).toDouble();

          if (lat >= 5.9 && lat <= 10.0 && lng >= 79.6 && lng <= 82.0) {
            if (!mounted || _isDisposed) return;

            setState(() {
              _busLocation = LatLng(lat, lng);
            });

            _markerMap[busMarkerId] = Marker(
              markerId: const MarkerId(busMarkerId),
              position: _busLocation!,
              infoWindow: InfoWindow(
                title:
                    _selectedRoute?['busName'] ??
                    'Bus ${_selectedRoute?['busNumber'] ?? _busId}',
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
    if (_isDisposed || _mapController == null) return;

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

    try {
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 100));
    } catch (e) {
      debugPrint('Error fitting map bounds: $e');
    }
  }

  // ---------------- MAP ----------------
  void _onMapCreated(GoogleMapController controller) {
    if (_isDisposed) {
      controller.dispose();
      return;
    }

    _mapController = controller;

    try {
      _mapController?.setMapStyle('''
        [
          {"featureType":"poi","elementType":"labels","stylers":[{"visibility":"off"}]},
          {"featureType":"transit","elementType":"labels","stylers":[{"visibility":"off"}]}
        ]
      ''');

      if (_currentPosition != null) {
        _moveCameraThrottled(_currentPosition!, force: true);
      }
    } catch (e) {
      debugPrint('Error setting map style: $e');
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
          Positioned(bottom: 20, left: 20, right: 20, child: _buildInfoCard()),
        ],
      ),
    );
  }

  Set<Marker> _createMarkerSet() {
    final markers = Set<Marker>.of(_markerMap.values);

    if (_routeOrigin != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('route_origin'),
          position: _routeOrigin!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: 'Origin: $_selectedFrom'),
        ),
      );
    }

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
                  const Icon(
                    Icons.directions_bus,
                    color: Colors.blue,
                    size: 25,
                  ),
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
  State<_RouteSearchBottomSheet> createState() =>
      _RouteSearchBottomSheetState();
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
    if (picked != null && mounted) {
      setState(() => _selectedDate = picked);
    }
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
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null && mounted) {
                          setState(() => _from = v);
                        }
                      },
                      decoration: InputDecoration(
                        isDense: true, // optional, makes it a bit more compact
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 👇 Constrained swap button so it doesn't eat space
              SizedBox(
                width: 35,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: const Icon(Icons.swap_horiz),
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        final temp = _from;
                        _from = _to;
                        _to = temp;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('To'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _to,
                      items: widget.cities
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null && mounted) {
                          setState(() => _to = v);
                        }
                      },
                      decoration: InputDecoration(
                        isDense: true, // optional
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
                foregroundColor: Colors.white,
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
  final bool hasLiveLocation;

  const _RouteSelectionDialog({
    required this.routes,
    this.hasLiveLocation = true,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: routes.length,
                itemBuilder: (context, index) {
                  final route = routes[index];
                  final isLive =
                      hasLiveLocation &&
                      (route['hasLiveLocation'] == true ||
                          route['isLocationSharing'] == true);

                  return ListTile(
                    leading: const Icon(
                      Icons.directions_bus,
                      color: Colors.blue,
                    ),
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
                        if (isLive)
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Live Location Available',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        else
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'No Live Location',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
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
