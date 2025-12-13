import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';

class BusLiveLocationPage extends StatefulWidget {
  final String busId;
  final String? busNumber;
  final String? busName;
  final String? routeName;
  final Map<String, dynamic>? initialLocation;

  const BusLiveLocationPage({
    Key? key,
    required this.busId,
    this.busNumber,
    this.busName,
    this.routeName,
    this.initialLocation,
  }) : super(key: key);

  @override
  State<BusLiveLocationPage> createState() => _BusLiveLocationPageState();
}

class _BusLiveLocationPageState extends State<BusLiveLocationPage> {
  final Completer<GoogleMapController> _controller = Completer();
  static const String baseUrl = "http://10.0.2.2:5000/api";
  
  // Sri Lanka center coordinates (Colombo)
  static const LatLng sriLankaCenter = LatLng(6.9271, 79.8612);
  
  LatLng? _busLocation;
  bool _isLoading = true;
  bool _isLocationSharing = false;
  Timer? _locationTimer;
  String? _error;
  DateTime? _lastUpdateTime;
  List<LatLng> _locationHistory = []; // Track movement path
  Marker? _busMarker;

  // Validate if coordinates are valid (not 0,0 and within Sri Lanka bounds)
  bool _isValidLocation(double lat, double lng) {
    // Sri Lanka bounds approximately: 5.9°N to 10.0°N, 79.6°E to 82.0°E
    return lat != 0.0 && 
           lng != 0.0 && 
           lat >= 5.9 && 
           lat <= 10.0 && 
           lng >= 79.6 && 
           lng <= 82.0;
  }

  @override
  void initState() {
    super.initState();
    // Use initial location if provided and valid
    if (widget.initialLocation != null) {
      final lat = widget.initialLocation!['lat'];
      final lng = widget.initialLocation!['lng'];
      if (lat != null && lng != null) {
        final latValue = lat is num ? lat.toDouble() : double.tryParse(lat.toString());
        final lngValue = lng is num ? lng.toDouble() : double.tryParse(lng.toString());
        if (latValue != null && lngValue != null && _isValidLocation(latValue, lngValue)) {
          _busLocation = LatLng(latValue, lngValue);
          _isLocationSharing = true;
          _lastUpdateTime = widget.initialLocation!['updatedAt'] != null
              ? DateTime.tryParse(widget.initialLocation!['updatedAt'].toString())
              : DateTime.now();
          _locationHistory.add(_busLocation!);
        }
      }
    }
    _startFetchingLocation();
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  void _startFetchingLocation() {
    // Fetch immediately
    _fetchBusLocation();
    
    // Then fetch every 3 seconds for real-time updates
    _locationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _fetchBusLocation();
    });
  }

  Future<void> _fetchBusLocation() async {
    try {
      final uri = Uri.parse("$baseUrl/bus/${widget.busId}");
      final response = await http.get(uri).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Check if location sharing is enabled
        if (data['location'] != null) {
          final locationData = data['location'];
          
          if (locationData['lat'] != null && locationData['lng'] != null) {
            final lat = locationData['lat'] is num 
                ? locationData['lat'].toDouble() 
                : double.tryParse(locationData['lat'].toString());
            final lng = locationData['lng'] is num 
                ? locationData['lng'].toDouble() 
                : double.tryParse(locationData['lng'].toString());
            
            if (lat != null && lng != null && _isValidLocation(lat, lng)) {
              final newLocation = LatLng(lat, lng);
              
              // Check if location actually changed (avoid unnecessary updates)
              final hasChanged = _busLocation == null ||
                  (_busLocation!.latitude != lat || _busLocation!.longitude != lng);
              
              if (hasChanged) {
                setState(() {
                  _busLocation = newLocation;
                  _isLocationSharing = true;
                  _isLoading = false;
                  _error = null;
                  _lastUpdateTime = locationData['updatedAt'] != null
                      ? DateTime.tryParse(locationData['updatedAt'].toString())
                      : DateTime.now();
                  
                  // Add to history (keep last 50 points for path)
                  _locationHistory.add(newLocation);
                  if (_locationHistory.length > 50) {
                    _locationHistory.removeAt(0);
                  }
                  
                  // Update marker
                  _busMarker = Marker(
                    markerId: const MarkerId('bus_location'),
                    position: newLocation,
                    infoWindow: InfoWindow(
                      title: widget.busName ?? 'Bus ${widget.busNumber ?? widget.busId}',
                      snippet: widget.routeName ?? 'Live Location',
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueBlue,
                    ),
                  );
                });

                // Smoothly animate camera to new location
                if (_controller.isCompleted && _busLocation != null) {
                  final mapController = await _controller.future;
                  mapController.animateCamera(
                    CameraUpdate.newLatLngZoom(_busLocation!, 15.0),
                  );
                }
              }
            } else {
              // Invalid coordinates
              setState(() {
                _isLocationSharing = false;
                _isLoading = false;
                _error = 'Waiting for valid location data...';
              });
            }
          } else {
            setState(() {
              _isLocationSharing = false;
              _isLoading = false;
              _error = 'Location coordinates not available';
            });
          }
        } else {
          setState(() {
            _isLocationSharing = false;
            _isLoading = false;
            _error = 'Location sharing is disabled';
          });
        }
      } else {
        setState(() {
          _isLocationSharing = false;
          _isLoading = false;
          _error = 'Failed to fetch location (${response.statusCode})';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLocationSharing = false;
          _isLoading = false;
          _error = 'Connection error: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.busNumber != null 
              ? 'Live: ${widget.busNumber}' 
              : 'Live Bus Location',
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
                    // Always show the map - center on Sri Lanka or bus location
                    GoogleMap(
                      onMapCreated: (GoogleMapController controller) {
                        _controller.complete(controller);
                        // Center on bus location or Sri Lanka if no location yet
                        if (_busLocation != null) {
                          controller.animateCamera(
                            CameraUpdate.newLatLngZoom(_busLocation!, 15.0),
                          );
                        } else {
                          controller.animateCamera(
                            CameraUpdate.newLatLngZoom(sriLankaCenter, 8.0),
                          );
                        }
                      },
                      initialCameraPosition: CameraPosition(
                        target: _busLocation ?? sriLankaCenter,
                        zoom: _busLocation != null ? 15.0 : 8.0,
                      ),
                      markers: _busMarker != null ? {_busMarker!} : {},
                      polylines: _locationHistory.length > 1
                          ? {
                              Polyline(
                                polylineId: const PolylineId('bus_path'),
                                points: _locationHistory,
                                color: Colors.blue,
                                width: 4,
                                patterns: [],
                              ),
                            }
                          : {},
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      mapType: MapType.normal,
                      zoomControlsEnabled: true,
                      compassEnabled: true,
                    ),
                    // Loading overlay
                    if (_isLoading)
                      Container(
                        color: Colors.white.withOpacity(0.8),
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    // Info card at bottom
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
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: _isLocationSharing ? Colors.green : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isLocationSharing
                                        ? 'Live Location Active'
                                        : 'Location Not Available',
                                    style: AppTextStyles.body.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: _isLocationSharing ? Colors.green : Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (widget.busName != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                widget.busName!,
                                style: AppTextStyles.body.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                            if (widget.busNumber != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Bus: ${widget.busNumber}',
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                            if (_busLocation != null) ...[
                              const SizedBox(height: 8),
                              Divider(color: Colors.grey.shade300),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      '${_busLocation!.latitude.toStringAsFixed(6)}, ${_busLocation!.longitude.toStringAsFixed(6)}',
                                      style: AppTextStyles.body.copyWith(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (_lastUpdateTime != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Updated: ${DateFormat('HH:mm:ss').format(_lastUpdateTime!)}',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (_error != null && !_isLocationSharing) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      size: 16,
                                      color: Colors.orange.shade700,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: AppTextStyles.body.copyWith(
                                          color: Colors.orange.shade700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
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
}

