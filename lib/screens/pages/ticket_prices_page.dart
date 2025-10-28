import 'package:flutter/material.dart';

// --- DATA MODELS (No change) ---
class BusInfo {
  final String busName;
  final String departureTime;
  final String arrivalTime;
  final String duration;
  final double price;

  BusInfo({
    required this.busName,
    required this.departureTime,
    required this.arrivalTime,
    required this.duration,
    required this.price,
  });
}

// --- MAIN SCREEN WIDGET (Changed) ---
class TicketPrices extends StatefulWidget {
  const TicketPrices({super.key});

  @override
  State<TicketPrices> createState() => _TicketPricesState();
}

class _TicketPricesState extends State<TicketPrices> {
  // --- STATE AND LOGIC (No change) ---
  String? _selectedOrigin;
  String? _selectedDestination;
  List<BusInfo> _searchResults = [];
  bool _isLoading = false;

  final List<String> _cities = ['Colombo', 'Kandy', 'Galle', 'Jaffna', 'Matara'];
  
  final List<BusInfo> _allBuses = [
    BusInfo(busName: 'Luxury Express', departureTime: '07:00 AM', arrivalTime: '10:00 AM', duration: '3h', price: 1500.00),
    BusInfo(busName: 'Super Line', departureTime: '08:30 AM', arrivalTime: '11:45 AM', duration: '3h 15m', price: 1450.00),
    BusInfo(busName: 'Highway Star', departureTime: '09:00 AM', arrivalTime: '11:30 AM', duration: '2h 30m', price: 2000.00),
  ];

  void _searchBuses() {
    if (_selectedOrigin == null || _selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both origin and destination.')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _searchResults = []; 
    });

    Future.delayed(const Duration(seconds: 2), () {
      setState(() {
        if (_selectedOrigin == 'Colombo' && _selectedDestination == 'Kandy') {
            _searchResults = _allBuses;
        } else {
            _searchResults = [];
        }
        _isLoading = false;
      });
    });
  }

  // --- BUILD METHOD (Completely New Design) ---
  @override
  Widget build(BuildContext context) {
    // Define our new Sri Lankan color palette
    final Color primaryColor = Colors.red[900]!; // Deep Maroon
    final Color accentColor = Colors.amber[700]!; // Bright Amber/Yellow
    final Color lightBgColor = Colors.grey[100]!;
    
    return Scaffold(
      backgroundColor: lightBgColor, // Soft grey background
      appBar: AppBar(
        title: const Text('Ticket Prices'),
        backgroundColor: primaryColor, // Maroon App Bar
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- HEADER IMAGE ---
            _buildHeaderImage(),
            
            // --- SEARCH CARD ---
            _buildSearchCard(context, accentColor),
            
            // --- RESULTS SECTION ---
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'Available Buses',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            
            _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  // --- NEW WIDGETS FOR THE DESIGN ---

  Widget _buildHeaderImage() {
    return Stack(
      children: [
        // Your banner image
        Container(
          height: 180,
          width: double.infinity,
          child: Image.asset(
            'assest/banner.jpg', // Using your asset
            fit: BoxFit.cover,
            // Add error handling in case the image fails to load
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
              );
            },
          ),
        ),
        // Dark overlay for text readability
        Container(
          height: 180,
          width: double.infinity,
          color: Colors.black.withOpacity(0.4),
        ),
        // Title text on top of the image
        Positioned(
          bottom: 20,
          left: 16,
          child: Text(
            'Find Your Ride',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                const Shadow(blurRadius: 10.0, color: Colors.black, offset: Offset(2.0, 2.0)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchCard(BuildContext context, Color accentColor) {
    return Card(
      // This makes the card "float" over the image
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildDropdown(
              hint: 'Select Origin',
              icon: Icons.my_location,
              value: _selectedOrigin,
              items: _cities,
              onChanged: (value) => setState(() => _selectedOrigin = value),
            ),
            const SizedBox(height: 12),
            _buildDropdown(
              hint: 'Select Destination',
              icon: Icons.location_on,
              value: _selectedDestination,
              items: _cities,
              onChanged: (value) => setState(() => _selectedDestination = value),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _searchBuses,
              icon: const Icon(Icons.search, color: Colors.black87),
              label: const Text(
                'Search Buses',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor, // Amber button
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildResultsSection() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'No buses found for this route.\nTry searching Colombo to Kandy!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
          ),
        ),
      );
    }
    
    // Use ListView.separated for nice dividers
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(), // Disables scrolling inside the SingleChildScrollView
      shrinkWrap: true,
      itemCount: _searchResults.length,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final bus = _searchResults[index];
        return _buildBusResultCard(bus);
      },
    );
  }

  // --- HELPER WIDGETS (Updated Design) ---

  Widget _buildDropdown({
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: hint,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      value: value,
      items: items.map((city) {
        return DropdownMenuItem(value: city, child: Text(city));
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildBusResultCard(BusInfo bus) {
    return Card(
      elevation: 3,
      shadowColor: Colors.grey.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_bus_filled, color: Colors.red[900]),
                const SizedBox(width: 8),
                Text(
                  bus.busName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeInfo('Departure', bus.departureTime),
                Icon(Icons.arrow_forward, color: Colors.grey[400]),
                _buildTimeInfo('Arrival', bus.arrivalTime, crossAxisAlignment: CrossAxisAlignment.end),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Duration
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 4),
                    Text(
                      bus.duration,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ],
                ),
                // Price
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[700], // Green for price
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'LKR ${bus.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeInfo(String label, String time, {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 2),
        Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
