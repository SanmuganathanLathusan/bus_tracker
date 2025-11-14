import 'package:flutter/material.dart';

class SeatReservation extends StatefulWidget {
  const SeatReservation({super.key});

  @override
  State<SeatReservation> createState() => _SeatReservationState();
}

class _SeatReservationState extends State<SeatReservation> {
  String? _fromLocation;
  String? _toLocation;
  final List<String> _locations = ['Colombo', 'Kandy', 'Galle', 'Jaffna', 'Kilinochchi'];

  @override
  Widget build(BuildContext context) {
    // Mimics the background image seen in the design
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('WayGo Tickets', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background image or gradient placeholder
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bus_background.jpg'), // Replace with your asset
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
              ),
            ),
          ),
          // Main content container
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Online Seat Reservation',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0C3866), // Dark Blue header
                      ),
                    ),
                    const SizedBox(height: 20),

                    // FROM Dropdown
                    _buildLocationDropdown(
                      label: 'FROM',
                      value: _fromLocation,
                      onChanged: (newValue) {
                        setState(() {
                          _fromLocation = newValue;
                        });
                      },
                      icon: Icons.location_on,
                    ),
                    const SizedBox(height: 20),

                    // TO Dropdown
                    _buildLocationDropdown(
                      label: 'TO',
                      value: _toLocation,
                      onChanged: (newValue) {
                        setState(() {
                          _toLocation = newValue;
                        });
                      },
                      icon: Icons.location_city,
                    ),
                    const SizedBox(height: 30),

                    // SEARCH BUSES Button
                    ElevatedButton(
                      onPressed: () {
                        // Implement bus search logic here
                        if (_fromLocation != null && _toLocation != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Searching buses from $_fromLocation to $_toLocation...')),
                          );
                          // Navigate to the schedule or ticket prices page
                          // Navigator.pushNamed(context, '/schedule');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange, // Prominent orange color
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'SEARCH BUSES',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDropdown({
    required String label,
    required String? value,
    required ValueChanged<String?> onChanged,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red, width: 2.0), // Red border like the image
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
            ],
          ),
          value: value,
          items: _locations.map((String location) {
            return DropdownMenuItem<String>(
              value: location,
              child: Text(location),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}