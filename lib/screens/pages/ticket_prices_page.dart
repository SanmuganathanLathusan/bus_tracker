import 'package:flutter/material.dart';

// ------------------ DATA MODEL ------------------
class BusTicket {
  final String busName;
  final String routeNumber;
  final String departure;
  final String arrival;
  final String duration;
  final double price;

  BusTicket({
    required this.busName,
    required this.routeNumber,
    required this.departure,
    required this.arrival,
    required this.duration,
    required this.price,
  });
}

// ------------------ MAIN PAGE ------------------
class TicketPrices extends StatefulWidget {
  const TicketPrices({super.key});

  @override
  State<TicketPrices> createState() => _TicketPricesState();
}

class _TicketPricesState extends State<TicketPrices> {
  String? _selectedOrigin;
  String? _selectedDestination;
  bool _isLoading = false;
  List<BusTicket> _results = [];

  final List<String> _cities = [
    'Colombo',
    'Kandy',
    'Galle',
    'Jaffna',
    'Matara',
  ];

  final List<BusTicket> _allTickets = [
    BusTicket(
      busName: "Super Line Express",
      routeNumber: "EX001",
      departure: "06:00 AM",
      arrival: "09:00 AM",
      duration: "3h",
      price: 1500.00,
    ),
    BusTicket(
      busName: "Luxury Highway Star",
      routeNumber: "EX002",
      departure: "08:00 AM",
      arrival: "11:00 AM",
      duration: "3h",
      price: 2000.00,
    ),
    BusTicket(
      busName: "Comfort Travels",
      routeNumber: "EX003",
      departure: "10:00 AM",
      arrival: "01:30 PM",
      duration: "3h 30m",
      price: 1300.00,
    ),
  ];

  void _searchTickets() {
    if (_selectedOrigin == null || _selectedDestination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both origin and destination'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _results = [];
    });

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        if (_selectedOrigin == 'Colombo' && _selectedDestination == 'Kandy') {
          _results = _allTickets;
        } else {
          _results = [];
        }
        _isLoading = false;
      });
    });
  }

  // ------------------ UI ------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('E-Ticket Prices'),
        backgroundColor: Colors.red[900],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeaderBanner(),
            _buildSearchCard(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Available Buses',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            _buildResults(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner() {
    return Stack(
      children: [
        Container(
          height: 180,
          width: double.infinity,
          child: Image.asset(
            'assets/bus_banner.jpg', // Make sure this exists
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              color: Colors.grey[300],
              child: const Center(
                child: Icon(Icons.directions_bus_filled,
                    size: 80, color: Colors.grey),
              ),
            ),
          ),
        ),
        Container(
          height: 180,
          color: Colors.black.withOpacity(0.4),
        ),
        const Positioned(
          bottom: 20,
          left: 20,
          child: Text(
            "Find Your E-Ticket",
            style: TextStyle(
              fontSize: 26,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 6, color: Colors.black45, offset: Offset(2, 2))],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _searchTickets,
                icon: const Icon(Icons.search, color: Colors.black87),
                label: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        "Search Buses",
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      value: value,
      items: items.map((city) {
        return DropdownMenuItem(
          value: city,
          child: Text(city),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Text(
          'No buses found for this route.\nTry searching Colombo → Kandy!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey[700]),
        ),
      );
    }

    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _results.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildBusCard(_results[index]),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    );
  }

  Widget _buildBusCard(BusTicket bus) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_bus, color: Colors.red[900]),
                const SizedBox(width: 8),
                Text(
                  bus.busName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  bus.routeNumber,
                  style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeColumn('Departure', bus.departure),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                _buildTimeColumn('Arrival', bus.arrival),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 5),
                    Text(bus.duration,
                        style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "LKR ${bus.price.toStringAsFixed(2)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTimeColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
