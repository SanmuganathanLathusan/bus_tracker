import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapWidget extends StatelessWidget {
  const MapWidget({Key? key}) : super(key: key);

  final LatLng _center = const LatLng(7.2906, 80.6337); // Kandy, Sri Lanka

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: ClipRRect(
        // ✅ Added ClipRRect
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(target: _center, zoom: 12.0),
          markers: {
            Marker(
              markerId: const MarkerId('bus'),
              position: _center,
              infoWindow: const InfoWindow(title: 'Your Bus'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueBlue,
              ),
            ),
            Marker(
              markerId: const MarkerId('stop1'), // ✅ Added const
              position: const LatLng(7.2856, 80.6287), // ✅ Added const
              infoWindow: const InfoWindow(title: 'Stop 1: Kandy City Center'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
            Marker(
              markerId: const MarkerId('stop2'), // ✅ Added const
              position: const LatLng(7.2956, 80.6437), // ✅ Added const
              infoWindow: const InfoWindow(title: 'Stop 2: Peradeniya'),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                BitmapDescriptor.hueGreen,
              ),
            ),
          },
          polylines: {
            const Polyline(
              polylineId: PolylineId('route'),
              color: Colors.blue,
              width: 5,
              points: [
                LatLng(7.2856, 80.6287),
                LatLng(7.2906, 80.6337),
                LatLng(7.2956, 80.6437),
              ],
            ),
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
        ),
      ),
    );
  }
}
