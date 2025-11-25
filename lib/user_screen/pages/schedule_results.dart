import 'package:flutter/material.dart';

// This page shows a list of available bus schedules
class ScheduleResultsPage extends StatelessWidget {
  // The list of bus results passed from previous page
  final List results;

  // Constructor with required results parameter
  const ScheduleResultsPage({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // App bar at the top of the page
      appBar: AppBar(
        title: const Text("Bus Schedules"), // Title of the page
        backgroundColor: Colors.indigo.shade900, // AppBar color
      ),

      // Body of the page
      body: results.isEmpty
          // If there are no buses, show a message in the center
          ? const Center(
              child: Text(
                "Sorry, no buses available.",
                style: TextStyle(
                  fontSize: 18, // Text size
                  fontWeight: FontWeight.w500, // Medium font weight
                ),
              ),
            )
          // If buses exist, show them in a scrollable list
          : ListView.separated(
              padding: const EdgeInsets.all(10), // Padding around list
              itemCount: results.length, // Number of buses
              separatorBuilder: (context, index) => const SizedBox(height: 10), // Space between list items
              
              // Build each bus item
              itemBuilder: (context, index) {
                final bus = results[index]; // Get bus details
                
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white, // Card background color
                    borderRadius: BorderRadius.circular(8), // Rounded corners
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12, // Shadow color
                        blurRadius: 4, // Shadow blur
                        offset: Offset(0, 2), // Shadow position
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 15, vertical: 10), // Padding inside the tile
                    
                    // Bus name and type
                    title: Text(
                      "${bus["busName"]} (${bus["busType"]})",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    
                    // Route and timing information
                    subtitle: Text(
                      "${bus["from"]} ➝ ${bus["to"]}\nTime: ${bus["startTime"]} - ${bus["endTime"]}",
                    ),
                    
                    // Price of the bus ticket
                    trailing: Text(
                      "Rs ${bus["price"]}",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
                
