import 'dart:async';
import 'dart:convert';
import 'dart:math' show pi, sin, min, max;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:waygo/services/location_service.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';

class RouteBusTrackingPage extends StatefulWidget {
  final Map<String, dynamic> routeDetails;
  final String? busId;
  final String? busNumber;
  final String? busName;

  const RouteBusTrackingPage({
    Key? key,
    required this.routeDetails,
    this.busId,
    this.busNumber,
    this.busName,
  }) : super(key: key);

  @override
  State<RouteBusTrackingPage> createState() => _RouteBusTrackingPageState();
}

class _RouteBusTrackingPageState extends State<RouteBusTrackingPage> {
  final Completer<GoogleMapController> _controller = Completer();
  final LocationService _locationService = LocationService();

  // Sri Lanka center coordinates
  static const LatLng sriLankaCenter = LatLng(6.9271, 79.8612);

  LatLng? _busLocation;
  bool _isLoading = true;
  bool _isLocationSharing = false;
  Timer? _locationTimer;
  String? _error;
  DateTime? _lastUpdateTime;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final String busMarkerId = 'bus_marker';

  // Route coordinates
  LatLng? _routeOrigin;
  LatLng? _routeDestination;

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

  @override
  void initState() {
    super.initState();
    _initializeRouteData();
    _startFetchingLocation();
  }

  void _initializeRouteData() {
    final startCity = widget.routeDetails['start'];
    final destinationCity = widget.routeDetails['destination'];

    _routeOrigin = _cityCoordinates[startCity];
    _routeDestination = _cityCoordinates[destinationCity];

    // Draw route polyline
    if (_routeOrigin != null && _routeDestination != null) {
      _drawRoutePath(_routeOrigin!, _routeDestination!);
    }
  }

  void _drawRoutePath(LatLng origin, LatLng destination) {
    // Generate a simple curved path between origin and destination
    final List<LatLng> points = _generateCurvedRoute(origin, destination);

    setState(() {
      _polylines = {
        Polyline(
          polylineId: const PolylineId('route_path'),
          points: points,
          color: AppColors.waygoLightBlue,
          width: 5,
          geodesic: true,
        ),
      };
    });
  }

  List<LatLng> _generateCurvedRoute(LatLng origin, LatLng destination) {
    // Simple curved route generation
    final List<LatLng> points = [];

    // Add start point
    points.add(origin);

    // Add intermediate points to create a curve
    const int segments = 20;
    for (int i = 1; i < segments; i++) {
      final double fraction = i / segments;
      // Simple interpolation with slight curvature
      final double lat =
          origin.latitude + (destination.latitude - origin.latitude) * fraction;
      final double lng =
          origin.longitude +
          (destination.longitude - origin.longitude) * fraction;

      // Add slight curvature
      final double curveOffset = 0.05 * sin(fraction * pi);
      points.add(LatLng(lat + curveOffset, lng));
    }

    // Add end point
    points.add(destination);

    return points;
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startFetchingLocation() {
    // Fetch location immediately
    _fetchBusLocation();

    // Then periodically
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _fetchBusLocation();
    });
  }

  Future<void> _fetchBusLocation() async {
    if (widget.busId == null) return;

    try {
      final data = await _locationService.getBusLocation(widget.busId!);

      if (data['location'] == null) {
        setState(() {
          _isLocationSharing = false;
          _isLoading = false;
          _error = 'Bus location sharing is disabled';
        });
        return;
      }

      if (data['location'] is Map &&
          data['location']['lat'] != null &&
          data['location']['lng'] != null) {
        final lat = (data['location']['lat'] as num).toDouble();
        final lng = (data['location']['lng'] as num).toDouble();

        // Validate coordinates are within Sri Lanka
        if (lat >= 5.9 && lat <= 10.0 && lng >= 79.6 && lng <= 82.0) {
          setState(() {
            _busLocation = LatLng(lat, lng);
            _isLocationSharing = true;
            _isLoading = false;
            _error = null;
            _lastUpdateTime = DateTime.now();
          });

          // Update marker
          _updateBusMarker(LatLng(lat, lng));

          // Move camera to show bus location
          _moveCameraToBus(LatLng(lat, lng));
        } else {
          setState(() {
            _error = 'Invalid bus location';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _error = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  void _updateBusMarker(LatLng position) {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('bus_marker'),
          position: position,
          infoWindow: InfoWindow(
            title: widget.busName ?? widget.busNumber ?? 'Bus',
            snippet: 'Live Location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        ),
        // Add origin marker
        if (_routeOrigin != null)
          Marker(
            markerId: const MarkerId('origin_marker'),
            position: _routeOrigin!,
            infoWindow: InfoWindow(
              title: widget.routeDetails['start'],
              snippet: 'Route Start',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueGreen,
            ),
          ),
        // Add destination marker
        if (_routeDestination != null)
          Marker(
            markerId: const MarkerId('destination_marker'),
            position: _routeDestination!,
            infoWindow: InfoWindow(
              title: widget.routeDetails['destination'],
              snippet: 'Route End',
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueRed,
            ),
          ),
      };
    });
  }

  void _moveCameraToBus(LatLng position) {
    _controller.future.then((controller) {
      controller.animateCamera(CameraUpdate.newLatLngZoom(position, 14.0));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Live Tracking - ${widget.busNumber ?? widget.busName ?? "Bus"}',
          style: AppTextStyles.heading.copyWith(
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.waygoDarkBlue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Map view
          GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);

              // Center map on route
              if (_routeOrigin != null && _routeDestination != null) {
                final bounds = LatLngBounds(
                  southwest: LatLng(
                    min(_routeOrigin!.latitude, _routeDestination!.latitude),
                    min(_routeOrigin!.longitude, _routeDestination!.longitude),
                  ),
                  northeast: LatLng(
                    max(_routeOrigin!.latitude, _routeDestination!.latitude),
                    max(_routeOrigin!.longitude, _routeDestination!.longitude),
                  ),
                );

                controller.animateCamera(
                  CameraUpdate.newLatLngBounds(bounds, 80.0),
                );
              } else {
                controller.animateCamera(
                  CameraUpdate.newLatLngZoom(sriLankaCenter, 8.0),
                );
              }
            },
            initialCameraPosition: CameraPosition(
              target: sriLankaCenter,
              zoom: 8.0,
            ),
            markers: _markers,
            polylines: _polylines,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: true,
          ),

          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.waygoLightBlue,
                ),
              ),
            ),

          // Error message
          if (_error != null)
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),

          // Bus info panel
          if (!_isLoading)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            widget.busName ?? widget.busNumber ?? 'Bus',
                            style: AppTextStyles.heading.copyWith(
                              fontSize: 18,
                              color: AppColors.waygoDarkBlue,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _isLocationSharing
                                ? AppColors.accentSuccess
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _isLocationSharing ? 'Live' : 'Offline',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.routeDetails['start']} → ${widget.routeDetails['destination']}',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (_lastUpdateTime != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Last updated: ${_formatTimeDifference(_lastUpdateTime!)} ago',
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatTimeDifference(DateTime time) {
    final difference = DateTime.now().difference(time);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} seconds';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes';
    } else {
      return '${difference.inHours} hours';
    }
  }
}
