// schedule.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'schedule_results.dart'; // import results page

// Since we updated the API service to use Environment Variables, 
// we assume the base URL is available from your service file.
// Replace 'YOUR_PACKAGE_NAME' with your actual package name (e.g., bus_tracker)
// If you cannot import the service, you must ensure you define the base URL locally 
// or import the correct service file here.
// For now, we use a placeholder that you must replace with the correct dynamic URL:
// final String BASE_URL = ApiService.baseUrl; 

// --- TEMPORARY FIX: Assume a mechanism to get the base URL ---
// You MUST replace this with a call to your actual API service.
const String API_BASE_URL = "http://localhost:5000/api";
// -----------------------------------------------------------


class Schedule extends StatefulWidget {
  const Schedule({super.key});

  @override
  State<Schedule> createState() => _ScheduleState();
}

class _ScheduleState extends State<Schedule> {
  String? _from;
  String? _to;
  String? _startTime;
  String? _endTime;
  String? _busType;
  bool _isSearching = false; // Add state for loading indicator

  // Improved Locations (Sri Lankan major cities)
  final List<String> _locations = [
    'Colombo', 'Kandy', 'Jaffna', 'Galle', 'Anuradhapura', 
    'Trincomalee', 'Matara', 'Kurunegala', 'Batticaloa', 'Polonnaruwa'
  ];
  
  // Improved Time Slots
  final List<String> _times = [
    'Any', '05:00 AM', '07:00 AM', '10:00 AM', '12:00 PM', 
    '03:00 PM', '06:00 PM', '09:00 PM'
  ];
  
  // Bus Types (Unchanged, looks good)
  final List<String> _busTypes = ['Any', 'A/C', 'Non-A/C', 'Luxury'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Time Table'),
        backgroundColor: const Color(0xFF0C3866),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Background Image (You use 'assets/images/city_night.jpg', ensure this path is correct)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/city_night.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade900.withOpacity(0.95), // Slightly less transparent
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Search Bus Time Table',
                        style: TextStyle(
                          fontSize: 22, // Increased font size
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Divider(color: Colors.white54, height: 25),
                      // Dropdown for 'From' Location
                      _buildDropdownField(
                          label: 'From *',
                          items: _locations,
                          value: _from,
                          onChanged: (v) => setState(() => _from = v)),
                      // Dropdown for 'To' Location
                      _buildDropdownField(
                          label: 'To *',
                          items: _locations,
                          value: _to,
                          onChanged: (v) => setState(() => _to = v)),
                      // Dropdown for 'Start Time'
                      _buildDropdownField(
                          label: 'Start Time',
                          items: _times,
                          value: _startTime,
                          onChanged: (v) => setState(() => _startTime = v)),
                      // Dropdown for 'End Time'
                      _buildDropdownField(
                          label: 'End Time',
                          items: _times,
                          value: _endTime,
                          onChanged: (v) => setState(() => _endTime = v)),
                      // Dropdown for 'Bus Type'
                      _buildDropdownField(
                          label: 'Bus Type',
                          items: _busTypes,
                          value: _busType ?? 'Any',
                          onChanged: (v) => setState(() => _busType = v)),
                      const SizedBox(height: 30),
                      
                      // Search Button (Now includes loading state)
                      _isSearching
                          ? const Center(
                              child: CircularProgressIndicator(color: Colors.deepOrange),
                            )
                          : ElevatedButton(
                              onPressed: () => _searchSchedule(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.deepOrange,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Text(
                                'Search',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // --- Method to handle the API call ---
  void _searchSchedule(BuildContext context) async {
    if (_from == null || _to == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both From and To locations.")),
      );
      return;
    }

    setState(() {
      _isSearching = true; // Show loading indicator
    });

    try {
      final url = Uri.parse("$API_BASE_URL/schedule/search"); // Refactored URL
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "from": _from,
          "to": _to,
          "startTime": _startTime ?? "Any",
          "endTime": _endTime ?? "Any",
          "busType": _busType ?? "Any",
        }),
      );

      setState(() {
        _isSearching = false; // Hide loading indicator
      });

      if (response.statusCode == 200) {
        final List results = jsonDecode(response.body);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ScheduleResultsPage(results: results),
          ),
        );
      } else {
        // Handle server errors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error ${response.statusCode}: Could not fetch schedule. Try again.")),
        );
      }
    } catch (e) {
      setState(() {
        _isSearching = false; // Hide loading indicator on error
      });
      // Handle network or parsing errors
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Network error: Could not connect to the server.")),
      );
      print("Error fetching schedule: $e");
    }
  }

  // --- Helper Widget for Dropdowns ---
  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    // Determine the effective value for the DropdownButton
    String? effectiveValue = (value == 'Any' || value == null && label == 'Bus Type') 
        ? (label == 'Bus Type' ? 'Any' : null) 
        : value;

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.white)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8), // More rounded corners
              border: Border.all(color: Colors.black12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: effectiveValue,
                hint: Text('Select $label', style: const TextStyle(color: Colors.grey)),
                icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF0C3866)),
                onChanged: onChanged,
                items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}