import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    String currentTime = DateFormat('hh:mm a').format(DateTime.now());
    String currentDate = DateFormat('EEEE, yyyy.MM.dd').format(DateTime.now());

    final List<Map<String, dynamic>> gridItems = [
      {
        "title": "Main News Feed",
        "icon": Icons.feed,
        "color": Colors.cyan,
        "route": "/news",
      },
      {
        "title": "Live Train Alerts",
        "icon": Icons.warning,
        "color": Colors.cyan,
        "route": "/alerts",
      },
      {
        "title": "RDMNS Live Train Radar",
        "icon": Icons.public,
        "color": Colors.cyan,
        "badge": "LIVE",
        "route": "/radar",
      },
      {
        "title": "Live Train Schedule",
        "icon": Icons.train,
        "color": Colors.cyan,
        "badge": "LIVE",
        "route": "/schedule",
      },
      {
        "title": "Seat Reservation Details",
        "icon": Icons.confirmation_num,
        "color": Colors.cyan,
        "badge": "NEW",
        "route": "/reservation",
      },
      {
        "title": "Ticket Prices",
        "icon": Icons.confirmation_num_outlined,
        "color": Colors.cyan,
        "route": "/ticket",
      },
      {
        "title": "Purchase E-Tickets",
        "icon": Icons.qr_code,
        "color": Colors.cyan,
        "route": "/eticket",
      },
      {
        "title": "Reserve Train Seats",
        "icon": Icons.event_seat,
        "color": Colors.cyan,
        "route": "/reserve",
      },
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          SizedBox.expand(
            child: Image.asset("assest/images1.jpg", fit: BoxFit.cover),
          ),

          // Overlay
          Container(color: Colors.black.withOpacity(0.4)),

          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // App name and subtitle
                  const Text(
                    "RDMNS.LK",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Official Network of Railway Passengers",
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 8),

                  // Date & Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currentTime,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            currentDate,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // My Route card
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, "/route");
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.yellow[700],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text(
                            "My Route\nSelect Line",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(Icons.more_horiz, color: Colors.black),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Grid of buttons
                  Expanded(
                    child: GridView.builder(
                      itemCount: gridItems.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.2,
                          ),
                      itemBuilder: (context, index) {
                        final item = gridItems[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, item['route']);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      if (item.containsKey('badge'))
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: item['badge'] == "LIVE"
                                                ? Colors.red
                                                : Colors.blue,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            item['badge'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      const Spacer(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item['title'],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            item['icon'],
                                            color: item['color'],
                                            size: 28,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
}
