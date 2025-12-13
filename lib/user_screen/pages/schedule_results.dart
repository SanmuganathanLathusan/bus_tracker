import 'package:flutter/material.dart';

class ScheduleResultsPage extends StatelessWidget {
  final List results;
  const ScheduleResultsPage({super.key, required this.results});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Buses"),
        backgroundColor: const Color(0xFF0C3866),
      ),
      body: results.isEmpty
          ? const Center(child: Text("No buses found."))
          : ListView.builder(
              itemCount: results.length,
              itemBuilder: (context, index) {
                final bus = results[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text("${bus["busName"]} (${bus["busType"]})"),
                    subtitle: Text(
                      "${bus["from"]} ➝ ${bus["to"]}\nTime: ${bus["startTime"]} - ${bus["endTime"]}",
                    ),
                    trailing: Text("LKR ${bus["price"]}"),
                  ),
                );
              },
            ),
    );
  }
}
