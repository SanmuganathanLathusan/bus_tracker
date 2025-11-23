// lib/screens/pages/ticket_prices_page.dart

import 'package:flutter/material.dart';

// --- Bus Model (Data Structure) ---
class Bus {
  final String busId;
  final String route;
  final String departureCity;
  final String arrivalCity;
  final String departureTime;
  final String arrivalTime;
  final int seatsAvailable;
  final double price;

  Bus({
    required this.busId,
    required this.route,
    required this.departureCity,
    required this.arrivalCity,
    required this.departureTime,
    required this.arrivalTime,
    required this.seatsAvailable,
    required this.price,
  });
}

// --- Extended Mock Data (Simulates real bus routes in Sri Lanka) ---
List<Bus> mockBuses = [
  Bus(
    busId: 'BUS-001-SLTB',
    route: 'Colombo (Pettah) - Jaffna',
    departureCity: 'Colombo',
    arrivalCity: 'Jaffna',
    departureTime: '06:00 AM',
    arrivalTime: '02:30 PM',
    seatsAvailable: 15,
    price: 1850.00,
  ),
  Bus(
    busId: 'EXPRESS-005',
    route: 'Kottawa - Kandy',
    departureCity: 'Colombo',
    arrivalCity: 'Kandy',
    departureTime: '07:30 AM',
    arrivalTime: '10:30 AM',
    seatsAvailable: 8,
    price: 680.00,
  ),
  Bus(
    busId: 'PUN-210-LUX',
    route: 'Galle - Anuradhapura',
    departureCity: 'Galle',
    arrivalCity: 'Anuradhapura',
    departureTime: '11:00 AM',
    arrivalTime: '07:00 PM',
    seatsAvailable: 22,
    price: 1550.00,
  ),
  Bus(
    busId: 'GLL-333-Semi',
    route: 'Matara - Colombo',
    departureCity: 'Matara',
    arrivalCity: 'Colombo',
    departureTime: '04:00 PM',
    arrivalTime: '07:00 PM',
    seatsAvailable: 3,
    price: 750.00,
  ),
  Bus(
    busId: 'BATT-888-NV',
    route: 'Batticaloa - Colombo',
    departureCity: 'Batticaloa',
    arrivalCity: 'Colombo',
    departureTime: '09:00 PM',
    arrivalTime: '05:00 AM',
    seatsAvailable: 28,
    price: 2100.00,
  ),
];

// --- Main Widget with State Management (handles loading data) ---
class TicketPrices extends StatefulWidget {
  const TicketPrices({super.key});

  @override
  State<TicketPrices> createState() => _TicketPricesState();
}

class _TicketPricesState extends State<TicketPrices> {
  List<Bus> _availableBuses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBusData();
  }
  // Function to simulate API data fetching
  Future<void> _fetchBusData() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate network delay for a realistic user experience
    await Future.delayed(const Duration(seconds: 1)); 

    setState(() {
      _availableBuses = mockBuses; 
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF0C3866); // Dark Blue
    const accentColor = Color(0xFFFFA000); // Orange

    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Buses & Prices'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      // Display a loading indicator while data is being fetched
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _availableBuses.length,
              itemBuilder: (context, index) {
                final bus = _availableBuses[index];
                return _buildBusCard(bus, primaryColor, accentColor, context);
              },
            ),
    );
  }

  // Helper method to build the aesthetically improved Bus Card
  Widget _buildBusCard(Bus bus, Color primaryColor, Color accentColor, BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Route Title & Price Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    bus.route,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: primaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  'Rs. ${bus.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            // Departure/Arrival Times
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTimeInfo(
                  icon: Icons.access_time,
                  label: 'Departure',
                  time: bus.departureTime,
                ),
                const Icon(Icons.arrow_right_alt, color: Colors.grey),
                _buildTimeInfo(
                  icon: Icons.timer_off,
                  label: 'Arrival',
                  time: bus.arrivalTime,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Bus ID and Seats Available
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ID: ${bus.busId}', style: TextStyle(color: Colors.grey.shade600)),
                Row(
                  children: [
                    Icon(Icons.event_seat, size: 16, color: bus.seatsAvailable > 5 ? Colors.green : accentColor),
                    const SizedBox(width: 4),
                    Text(
                      '${bus.seatsAvailable} Seats Left',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: bus.seatsAvailable > 5 ? Colors.green.shade700 : accentColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Buy Ticket Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to Ticket Purchase Page
                  Navigator.pushNamed(
                    context, 
                    '/eticket',
                    arguments: {'busId': bus.busId},
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Buy Ticket',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Small helper widget for displaying time information
  Widget _buildTimeInfo({required IconData icon, required String label, required String time}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const SizedBox(height: 4),
        Text(time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }

