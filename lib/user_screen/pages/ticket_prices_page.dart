import 'package:flutter/material.dart';

// Mock Bus Model
class Bus {
  final String busId;
  final String route;
  final String departureTime;
  final String arrivalTime;
  final int seatsAvailable;
  final double price;

  Bus({
    required this.busId,
    required this.route,
    required this.departureTime,
    required this.arrivalTime,
    required this.seatsAvailable,
    required this.price,
  });
}

// Mock Data
List<Bus> mockBuses = [
  Bus(
    busId: 'KCB7-2000-C/2',
    route: 'Colombo - Jaffna',
    departureTime: '06:00 AM',
    arrivalTime: '06:00 PM',
    seatsAvailable: 10,
    price: 1385.50,
  ),
  Bus(
    busId: 'BSC5-1100-A/1',
    route: 'Colombo - Kandy',
    departureTime: '07:30 AM',
    arrivalTime: '11:30 AM',
    seatsAvailable: 5,
    price: 650.00,
  ),
  Bus(
    busId: 'LNK8-300-C/4',
    route: 'Kandy - Jaffna',
    departureTime: '08:00 AM',
    arrivalTime: '08:00 PM',
    seatsAvailable: 8,
    price: 1500.00,
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
                  Text(
                    'Departure: ${bus.departureTime} - Arrival: ${bus.arrivalTime}',
                  ),
                  const SizedBox(height: 5),
                  Text('Seats Available: ${bus.seatsAvailable}'),
                  const SizedBox(height: 5),
                  Text(
                    'Price: Rs. ${bus.price.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
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
