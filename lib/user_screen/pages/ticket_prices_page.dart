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

