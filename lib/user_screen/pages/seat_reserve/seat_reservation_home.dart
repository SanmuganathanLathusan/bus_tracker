// lib/user_screen/pages/seat_reserve/seat_reservation_home.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Needed for date formatting
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';
import 'package:waygo/services/reservation_service.dart';
import 'route_details.dart';
import 'widgets/route_card.dart';

class SeatReservationHome extends StatefulWidget {
  const SeatReservationHome({super.key});

  @override
  State<SeatReservationHome> createState() => _SeatReservationHomeState();
}

class _SeatReservationHomeState extends State<SeatReservationHome> {
  String start = 'Colombo';
  String destination = 'Kandy';
  DateTime selectedDate = DateTime.now();
  bool isSearching = false;
  bool _isLoading = false;
  String? _error;

  final ReservationService _reservationService = ReservationService();
  List<Map<String, dynamic>> searchedRoutes = [];

  // Helper to format date for display
  String get formattedDate => DateFormat('dd/MM/yyyy').format(selectedDate);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        // Apply dark theme aesthetics to the Date Picker itself
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.waygoLightBlue, // Use app primary color
              onPrimary: Colors.white,
              surface: AppColors.waygoDarkBlue, // Use app dark background
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: AppColors.waygoDarkBlue,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _performSearch() async {
    FocusScope.of(context).unfocus(); // Close keyboard
    setState(() {
      isSearching = true;
      _isLoading = true;
      _error = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(selectedDate);
      final routes = await _reservationService.searchRoutes(
        start: start,
        destination: destination,
        date: dateStr,
      );

      setState(() {
        searchedRoutes = routes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error searching routes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      // Extend body to cover area behind AppBar/StatusBar
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white), // Ensures visibility
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🔹 1. Branded Background Image (Darkened)
          // Ensure 'assest/images4.jpg' is a suitable dark, high-quality image.
          Image.asset(
            'assest/images4.jpg',
            fit: BoxFit.cover,
            // Apply a strong black overlay to make content readable
            color: Colors.black.withOpacity(0.65),
            colorBlendMode: BlendMode.darken,
          ),

          // 🔹 2. Gradient Overlay for enhanced contrast and depth
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  // Pure black/dark blue at the top for title
                  AppColors.waygoDarkBlue.withOpacity(1.0),
                  AppColors.waygoDarkBlue.withOpacity(0.7),
                  Colors.transparent, // Fades out towards the bottom
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 0.9],
              ),
            ),
          ),

          // 🔹 3. Main UI Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Text(
                      'Seat Reservation',
                      style: AppTextStyles.heading.copyWith(
                        color: Colors.white,
                        fontSize: 26,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Text(
                    'Find your preferred route and reserve seats',
                    style: AppTextStyles.body.copyWith(color: Colors.white70),
                  ),

                  const SizedBox(height: 25),

                  // Search Card (Glassmorphism effect)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Start
                            Expanded(
                              child: _buildDropdownField(
                                label: "From",
                                value: start,
                                onChanged: (v) => setState(() => start = v!),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.swap_horiz_rounded,
                                size: 30,
                              ),
                              // Use primary blue accent color for the swap button
                              color: AppColors.waygoLightBlue,
                              onPressed: () {
                                setState(() {
                                  final temp = start;
                                  start = destination;
                                  destination = temp;
                                });
                              },
                            ),
                            // Destination
                            Expanded(
                              child: _buildDropdownField(
                                label: "To",
                                value: destination,
                                onChanged: (v) =>
                                    setState(() => destination = v!),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Date + Search Button
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _pickDate,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_rounded,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    // Use formattedDate getter
                                    formattedDate,
                                    style: AppTextStyles.body.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              onPressed: _performSearch,
                              icon: const Icon(Icons.search, size: 20),
                              label: const Text("Search"),
                              style: ElevatedButton.styleFrom(
                                // Use a strong, consistent background color
                                backgroundColor: AppColors.waygoLightBlue,
                                foregroundColor: AppColors.textLight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 22,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                                elevation: 3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Section Title
                  Text(
                    isSearching ? "Available Buses" : "Search for Routes",
                    style: AppTextStyles.subHeading.copyWith(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Bus List
                  Expanded(
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(color: Colors.white),
                          )
                        : _error != null
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Error: $_error",
                                      style: const TextStyle(color: Colors.red),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 10),
                                    ElevatedButton(
                                      onPressed: _performSearch,
                                      child: const Text("Retry"),
                                    ),
                                  ],
                                ),
                              )
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 400),
                                child: searchedRoutes.isEmpty
                                    ? Center(
                                        key: ValueKey(isSearching),
                                        child: Text(
                                          isSearching
                                              ? "No buses found for this route"
                                              : "Search for routes to see available buses",
                                          style: AppTextStyles.body.copyWith(
                                            color: Colors.white70,
                                            fontSize: 14,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        key: ValueKey(searchedRoutes.length),
                                        padding: EdgeInsets.zero,
                                        itemCount: searchedRoutes.length,
                                        itemBuilder: (context, index) {
                                          final route = searchedRoutes[index];
                                          final routeData = route['routeId'] is Map
                                              ? route['routeId']
                                              : route;
                                          final busData = route['busId'] is Map
                                              ? route['busId']
                                              : {};
                                          
                                          return RouteCard(
                                            start: routeData['start'] ?? route['start'] ?? '',
                                            destination: routeData['destination'] ?? route['destination'] ?? '',
                                            departure: routeData['departure'] ?? route['departure'] ?? '',
                                            arrival: routeData['arrival'] ?? route['arrival'] ?? '',
                                            duration: routeData['duration'] ?? route['duration'] ?? '',
                                            bus: busData['busName'] ?? routeData['busName'] ?? route['busName'] ?? 'Bus',
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => RouteDetailsScreen(
                                                    routeDetails: {
                                                      ...route,
                                                      '_id': route['_id'],
                                                      'routeId': route['routeId'] is Map 
                                                          ? route['routeId']['_id'] 
                                                          : route['routeId'],
                                                      'totalSeats': busData['totalSeats'] ?? routeData['totalSeats'] ?? 40,
                                                      'price': routeData['price'] ?? route['price'] ?? 0,
                                                      'bookedSeats': route['bookedSeats'] ?? [],
                                                    },
                                                    selectedDate: selectedDate,
                                                  ),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for the custom dropdown field
  Widget _buildDropdownField({
    required String label,
    required String value,
    required Function(String?) onChanged,
  }) {
    const cities = ['Colombo', 'Kandy', 'Galle', 'Matara', 'Jaffna'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.body.copyWith(
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 48, // Set a consistent height
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.25)),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: AppColors.waygoDarkBlue.withOpacity(0.95),
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
            style: AppTextStyles.body.copyWith(color: Colors.white),
            items: cities
                .map(
                  (e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e,
                      style: AppTextStyles.body.copyWith(color: Colors.white),
                    ),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
