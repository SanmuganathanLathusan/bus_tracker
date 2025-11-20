import 'package:flutter/material.dart';
import 'package:waygo/services/news_service.dart';
import 'package:intl/intl.dart';
import 'create_edit_news_screen.dart';

class NewsFeedWidget extends StatefulWidget {
  const NewsFeedWidget({Key? key}) : super(key: key);

  @override
  State<NewsFeedWidget> createState() => _NewsFeedWidgetState();
}

class _NewsFeedWidgetState extends State<NewsFeedWidget> {
  final NewsService _newsService = NewsService();
  List<Map<String, dynamic>> _news = [];
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
      final news = await _newsService.getAllNews();
      setState(() {
        _news = news;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteNews(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete News'),
        content: const Text('Are you sure you want to delete this news?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _newsService.deleteNews(id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('News deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadNews();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _editNews(Map<String, dynamic> news) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateEditNewsScreen(news: news),
      ),
    );

    if (result == true) {
      _loadNews();
    }
  }

  Future<void> _createNews() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateEditNewsScreen(),
      ),
    );

    if (result == true) {
      _loadNews();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 500;
              return isSmall
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'News Feed & Announcements',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _createNews,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Post'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'News Feed & Announcements',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _createNews,
                          icon: const Icon(Icons.add),
                          label: const Text('Create Post'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    );
            },
          ),
          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        children: [
                          Text('Error: $_error'),
                          ElevatedButton(
                            onPressed: _loadNews,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _news.isEmpty
                      ? const Center(child: Text('No news found'))
                      : Column(
                          children: _news.map((item) => _buildNewsCard(item)).toList(),
                        ),
        ],
      ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news) {
    DateTime? newsDate;
    if (news['createdAt'] != null) {
      if (news['createdAt'] is String) {
        newsDate = DateTime.tryParse(news['createdAt']);
      } else if (news['createdAt'] is Map) {
        final dateMap = news['createdAt'] as Map;
        if (dateMap['\$date'] != null) {
          newsDate = DateTime.fromMillisecondsSinceEpoch(dateMap['\$date'] as int);
        }
      }
    }
    newsDate ??= DateTime.now();

    DateTime? publishDate;
    if (news['publishDate'] != null) {
      if (news['publishDate'] is String) {
        publishDate = DateTime.tryParse(news['publishDate']);
      }
    }

    DateTime? expiryDate;
    if (news['expiryDate'] != null) {
      if (news['expiryDate'] is String) {
        expiryDate = DateTime.tryParse(news['expiryDate']);
      }
    }

    final postedBy = news['postedBy'] is Map 
        ? (news['postedBy']['userName'] ?? 'Admin')
        : (news['postedBy'] ?? 'Admin');
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildTypeBadge(news['type']!),
              const SizedBox(width: 12),
              _buildStatusBadge(news['status']!),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                onPressed: () => _editNews(news),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _deleteNews(news['_id']),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            news['title']?.toString() ?? 'No title',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 20,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    postedBy,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Posted: ${DateFormat('dd/MM/yyyy').format(newsDate)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 20,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.publish, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    publishDate != null 
                        ? 'Publish: ${DateFormat('dd/MM/yyyy').format(publishDate)}'
                        : 'Publish: Not set',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    expiryDate != null 
                        ? 'Expiry: ${DateFormat('dd/MM/yyyy').format(expiryDate)}'
                        : 'Expiry: Not set',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypeBadge(dynamic type) {
    final typeStr = type?.toString() ?? 'Info';
    Color color = typeStr == 'Info'
        ? Colors.blue
        : typeStr == 'Warning'
        ? Colors.orange
        : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        typeStr,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(dynamic status) {
    final statusStr = status?.toString() ?? 'Draft';
    Color color = statusStr == 'Published'
        ? Colors.green
        : statusStr == 'Active'
        ? Colors.blue
        : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusStr,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
