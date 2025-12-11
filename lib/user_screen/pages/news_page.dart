import 'package:flutter/material.dart';
import 'package:waygo/services/news_service.dart';
import 'package:intl/intl.dart';

class MainNews extends StatefulWidget {
  const MainNews({super.key});

  @override
  State<MainNews> createState() => _PassengerNewsFeedState();
}

class _PassengerNewsFeedState extends State<MainNews> {
  final NewsService _newsService = NewsService();
  List<Map<String, dynamic>> _newsList = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final news = await _newsService.getNews();
      setState(() {
        _newsList = news;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  // ----------------------------
  // REUSABLE NEWS CARD WIDGET
  // ----------------------------
  Widget _buildNewsCard(Map<String, dynamic> news) {
    DateTime? newsDate;

    if (news["date"] is String) {
      newsDate = DateTime.tryParse(news["date"]);
    } else if (news["date"] is Map && news["date"]["\$date"] != null) {
      newsDate =
          DateTime.fromMillisecondsSinceEpoch(news["date"]["\$date"] as int);
    }

    newsDate ??= DateTime.now();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // IMAGE
          if (news["imageUrl"] != null && news["imageUrl"].toString().isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                news["imageUrl"],
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: Colors.grey.shade900,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),

          // TEXT CONTENT
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news['title'] ?? 'Untitled News',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  news['description'] ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.bottomRight,
                  child: Text(
                    DateFormat("dd/MM/yyyy").format(newsDate),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  // ----------------------------
  // MAIN UI
  // ----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assest/images4.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Dark overlay
          Container(color: Colors.black.withOpacity(0.6)),

          SafeArea(
            child: Column(
              children: [
                // BACK BUTTON
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.5),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                      )
                    ],
                  ),
                ),

                // TITLE
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "LATEST NEWS",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // CONTENT
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
                                  const Text("Error loading news",
                                      style: TextStyle(color: Colors.red)),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: _loadNews,
                                    child: const Text("Retry"),
                                  )
                                ],
                              ),
                            )
                          : _newsList.isEmpty
                              ? const Center(
                                  child: Text(
                                    "No news available",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                )
                              : RefreshIndicator(
                                  onRefresh: _loadNews,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    itemCount: _newsList.length,
                                    itemBuilder: (_, i) =>
                                        _buildNewsCard(_newsList[i]),
                                  ),
                                ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
