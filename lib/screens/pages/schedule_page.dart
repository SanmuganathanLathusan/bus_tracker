import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'schedule_results.dart'; // import results page

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

  final List<String> _locations = ['Colombo', 'Kandy', 'Galle'];
  final List<String> _times = ['06:00 AM', '12:00 PM', '06:00 PM'];
  final List<String> _busTypes = ['Any', 'A/C', 'Non-A/C', 'Luxury'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus Time Table'),
        backgroundColor: const Color(0xFF0C3866),
      ),
      body: Stack(
        children: [
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
                    color: Colors.blue.shade900.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Search Bus Time Table',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Divider(color: Colors.white54, height: 25),
                      _buildDropdownField(
                          label: 'From *',
                          items: _locations,
                          value: _from,
                          onChanged: (v) => setState(() => _from = v)),
                      _buildDropdownField(
                          label: 'To *',
                          items: _locations,
                          value: _to,
                          onChanged: (v) => setState(() => _to = v)),
                      _buildDropdownField(
                          label: 'Start Time',
                          items: _times,
                          value: _startTime,
                          onChanged: (v) => setState(() => _startTime = v)),
                      _buildDropdownField(
                          label: 'End Time',
                          items: _times,
                          value: _endTime,
                          onChanged: (v) => setState(() => _endTime = v)),
                      _buildDropdownField(
                          label: 'Bus Type',
                          items: _busTypes,
                          value: _busType ?? 'Any',
                          onChanged: (v) => setState(() => _busType = v)),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: () async {
                          if (_from == null || _to == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Select From & To")),
                            );
                            return;
                          }

                          final response = await http.post(
                            Uri.parse("http://localhost:5000/api/schedule/search"),
                            headers: {"Content-Type": "application/json"},
                            body: jsonEncode({
                              "from": _from,
                              "to": _to,
                              "startTime": _startTime ?? "",
                              "endTime": _endTime ?? "",
                              "busType": _busType ?? "Any",
                            }),
                          );

                          final List results = jsonDecode(response.body);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ScheduleResultsPage(results: results),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text(
                          'Search',
                          style: TextStyle(fontSize: 18),
                        ),
                      )
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

  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: value,
                hint: const Text('Select'),
                icon: const Icon(Icons.arrow_drop_down),
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
