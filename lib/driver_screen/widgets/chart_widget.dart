import 'package:flutter/material.dart';

class ChartWidget extends StatelessWidget {
  const ChartWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This is a simple bar chart implementation
    // In a real app, you would use a charting library like fl_chart or charts_flutter
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar("Mon", 80, Colors.blue),
              _buildBar("Tue", 90, Colors.blue),
              _buildBar("Wed", 70, Colors.blue),
              _buildBar("Thu", 95, Colors.blue),
              _buildBar("Fri", 85, Colors.blue),
              _buildBar("Sat", 75, Colors.blue),
              _buildBar("Sun", 65, Colors.blue),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          "Punctuality Rate (%)",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBar(String day, double height, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Container(
              height: height * 1.5, // Scale for better visibility
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              day,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}