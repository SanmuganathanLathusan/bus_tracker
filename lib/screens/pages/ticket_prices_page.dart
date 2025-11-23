import 'package:flutter/material.dart';
// lib/constants/bus_data.dart

// Bus Model for structured data
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

// Mock Data covering major routes in Sri Lanka
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
    route: 'Colombo (Kottawa) - Kandy',
    departureCity: 'Colombo',
    arrivalCity: 'Kandy',
    departureTime: '07:30 AM',
    arrivalTime: '10:30 AM',
    seatsAvailable: 8,
    price: 680.00,
  ),
  Bus(
    busId: 'PUN-210-LUX',
    route: 'Kandy - Anuradhapura',
    departureCity: 'Kandy',
    arrivalCity: 'Anuradhapura',
    departureTime: '11:00 AM',
    arrivalTime: '03:00 PM',
    seatsAvailable: 22,
    price: 750.00,
  ),
  Bus(
    busId: 'GLL-333-Semi',
    route: 'Galle - Matara',
    departureCity: 'Galle',
    arrivalCity: 'Matara',
    departureTime: '04:00 PM',
    arrivalTime: '05:30 PM',
    seatsAvailable: 3,
    price: 250.00,
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

class TicketPrices extends StatelessWidget {
  const TicketPrices({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Buses & Prices'),
        backgroundColor: const Color(0xFF0C3866), // Primary color
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: mockBuses.length,
        itemBuilder: (context, index) {
          final bus = mockBuses[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bus.route,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text('Bus ID: ${bus.busId}'),
                  const SizedBox(height: 5),
                  Text('Departure: ${bus.departureTime} - Arrival: ${bus.arrivalTime}'),
                  const SizedBox(height: 5),
                  Text('Seats Available: ${bus.seatsAvailable}'),
                  const SizedBox(height: 5),
                  Text('Price: Rs. ${bus.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
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
                        backgroundColor: const Color(0xFFFFA000),
                        foregroundColor: const Color(0xFF0C3866),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Buy Ticket',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
