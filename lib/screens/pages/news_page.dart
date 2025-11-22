import 'package:flutter/material.dart';

class MainNews extends StatelessWidget {
  const MainNews({super.key});

  final List<Map<String, String>> mockNews = const [
    {
      "title": "Colombo Fort Bus Stand Renovation Completed",
      "subtitle":
          "The central bus stand now features new waiting areas and improved ticket counters.",
      "time": "3 hours ago",
      "image": "https://images.pexels.com/photos/139406/pexels-photo-139406.jpeg"
    },
    {
      "title": "Kandy–Colombo Bus Delays Reported",
      "subtitle":
          "Heavy rain and road repairs near Kadugannawa caused significant traffic delays.",
      "time": "1 hour ago",
      "image": "https://images.pexels.com/photos/256210/pexels-photo-256210.jpeg"
    },
    {
      "title": "New AC Luxury Bus Service Launched",
      "subtitle":
          "SLTB introduces new luxury express buses for long-distance routes.",
      "time": "6 hours ago",
      "image": "https://images.pexels.com/photos/238133/pexels-photo-238133.jpeg"
    },
    {
      "title": "Minor Bus Accident Reported",
      "subtitle":
          "A private bus skidded on a wet road. No major injuries were reported.",
      "time": "2 hours ago",
      "image": "https://images.pexels.com/photos/65219/pexels-photo-65219.jpeg"
    },
    {
      "title": "Ticket Price Revision Expected",
      "subtitle":
          "Fuel price drop may reduce long-distance bus fares, says SLTB.",
      "time": "4 hours ago",
      "image": "https://images.pexels.com/photos/161931/bus-travel-tour-161931.jpeg"
    },
    {
      "title": "Crowd Rush at Pettah Bus Stand",
      "subtitle":
          "Heavy rush seen at Pettah due to the weekend intercity travel peak.",
      "time": "30 minutes ago",
      "image": "https://images.pexels.com/photos/125072/pexels-photo-125072.jpeg"
    },
    {
      "title": "Badulla Route Bus Breakdown",
      "subtitle":
          "A Badulla–Colombo express bus broke down near Bandarawela. Long delays reported.",
      "time": "2 hours ago",
      "image": "https://images.pexels.com/photos/236557/pexels-photo-236557.jpeg"
    },
    {
      "title": "Heavy Rain Warning Issued",
      "subtitle":
          "Drivers are urged to maintain safe speeds due to low visibility.",
      "time": "5 hours ago",
      "image": "https://images.pexels.com/photos/39811/pexels-photo-39811.jpeg"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Transport News",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: mockNews.length,
        itemBuilder: (context, index) {
          final news = mockNews[index];

          return Card(
            elevation: 4,
            shadowColor: Colors.black12,
            margin: const EdgeInsets.only(bottom: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Image Section
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    news["image"]!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                /// Text Section
                Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        news["title"]!,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        news["subtitle"]!,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey.shade700,
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Icon(Icons.access_time,
                              size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 6),

                          /// Fixes RenderFlex Overflow
                          Expanded(
                            child: Text(
                              news["time"]!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
