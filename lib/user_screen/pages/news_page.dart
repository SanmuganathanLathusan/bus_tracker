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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 🔹 Background Image
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assest/images4.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // 🔹 Dark Overlay for readability
          Container(
            color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.6),
          ),

          // 🔹 Main Content (Back icon + News list)
          SafeArea(
            child: Column(
              children: [
                // Back icon
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 24),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Title
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
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

                // News List
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
                                    "Error loading news",
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: _loadNews,
                                    child: const Text("Retry"),
                                  ),
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
                                  color: Colors.white,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    itemCount: _newsList.length,
                                    itemBuilder: (context, index) {
                                      final news = _newsList[index];
                                      DateTime? newsDate;
                                      if (news['date'] != null) {
                                        if (news['date'] is String) {
                                          newsDate = DateTime.tryParse(news['date']);
                                        } else if (news['date'] is Map) {
                                          // Handle MongoDB date format
                                          final dateMap = news['date'] as Map;
                                          if (dateMap['\$date'] != null) {
                                            newsDate = DateTime.fromMillisecondsSinceEpoch(
                                                dateMap['\$date'] as int);
                                          }
                                        }
                                      }
                                      newsDate ??= DateTime.now();

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 14),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(255, 0, 0, 0)
                                              .withOpacity(0.45),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(0.08),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // News Image
                                            if (news['imageUrl'] != null &&
                                                news['imageUrl'] != '' &&
                                                news['imageUrl'].toString().isNotEmpty)
                                              ClipRRect(
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(16),
                                                  topRight: Radius.circular(16),
                                                ),
                                                child: Image.network(
                                                  news['imageUrl'],
                                                  height: 180,
                                                  width: double.infinity,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Container(
                                                      height: 180,
                                                      color: Colors.grey.shade800,
                                                      child: const Icon(
                                                        Icons.image_not_supported,
                                                        color: Colors.grey,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),

                                            // Text Section
                                            Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    news['title'] ?? 'No title',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 17,
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
                                                      DateFormat('dd/MM/yyyy')
                                                          .format(newsDate),
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
