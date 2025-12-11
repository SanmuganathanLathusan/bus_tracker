import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waygo/services/notification_service.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  final NotificationService _notificationService = NotificationService();

  final List<String?> _tabTypes = [null, "Alert", "Update"];

  bool _isLoading = true;
  bool _showUnreadOnly = false;
  String? _error;
  int _unreadCount = 0;
  List<dynamic> _notifications = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabTypes.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _loadNotifications();
    });
    _loadNotifications();
  }

  Future<void> _loadNotifications({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final type = _tabTypes[_tabController.index];
      final data = await _notificationService.fetchNotifications(
        type: type,
        unreadOnly: _showUnreadOnly,
      );
      setState(() {
        _notifications = List<dynamic>.from(data["notifications"] ?? []);
        _unreadCount = data["unreadCount"] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      await _loadNotifications(silent: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("All notifications marked as read")),
        );
      }
    } catch (e) {
      _showErrorSnack(e.toString());
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _notificationService.markAsRead(id);
      await _loadNotifications(silent: true);
    } catch (e) {
      _showErrorSnack(e.toString());
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await _notificationService.deleteNotification(id);
      await _loadNotifications(silent: true);
    } catch (e) {
      _showErrorSnack(e.toString());
    }
  }

  void _showErrorSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatTimestamp(String? raw) {
    if (raw == null) return "";
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return DateFormat("dd MMM, hh:mm a").format(date.toLocal());
  }

  IconData _iconForNotification(Map<String, dynamic> notification) {
    final iconName = notification["icon"]?.toString() ?? "";
    final type = notification["type"]?.toString() ?? "";
    switch (iconName) {
      case "assignment":
        return Icons.assignment;
      case "person_add":
        return Icons.person_add_alt;
      case "person_remove":
        return Icons.person_remove;
      case "check_circle":
        return Icons.check_circle;
      case "warning":
        return Icons.warning;
      case "build":
        return Icons.build;
    }
    switch (type) {
      case "Alert":
        return Icons.warning_amber;
      case "Update":
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) {
      return AppColors.accentPrimary;
    }
    final buffer = StringBuffer();
    if (!hex.startsWith('#')) buffer.write('#');
    buffer.write(hex.replaceAll('#', ''));
    final value = int.tryParse(buffer.toString().substring(1), radix: 16);
    if (value == null) return AppColors.accentPrimary;
    return Color(0xFF000000 | value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 150, 208, 245),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Notifications & Alerts",
                      style: AppTextStyles.heading,
                    ),
                    if (_unreadCount > 0)
                      Chip(
                        backgroundColor: Colors.red.shade100,
                        label: Text(
                          "$_unreadCount unread",
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                DefaultTabController(
                  length: _tabTypes.length,
                  child: Column(
                    children: [
                      TabBar(
                        controller: _tabController,
                        labelColor: const Color.fromARGB(255, 6, 6, 173),
                        unselectedLabelColor: const Color.fromARGB(
                          255,
                          15,
                          11,
                          11,
                        ),
                        indicatorColor: const Color.fromARGB(255, 89, 147, 240),
                        tabs: const [
                          Tab(text: "All"),
                          Tab(text: "Alerts"),
                          Tab(text: "Updates"),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _unreadCount == 0
                                  ? null
                                  : _markAllAsRead,
                              icon: const Icon(Icons.mark_email_read),
                              label: const Text("Mark All Read"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.backgroundSecondary,
                                foregroundColor: AppColors.textPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showUnreadOnly = !_showUnreadOnly;
                                });
                                _loadNotifications();
                              },
                              icon: Icon(
                                _showUnreadOnly
                                    ? Icons.filter_alt_off
                                    : Icons.filter_list,
                              ),
                              label: Text(
                                _showUnreadOnly ? "Show All" : "Unread Only",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.backgroundSecondary,
                                foregroundColor: AppColors.textPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE0E0E0)),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadNotifications,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }
    if (_notifications.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadNotifications,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: const [
            Icon(Icons.notifications_off, size: 48, color: Colors.black54),
            SizedBox(height: 12),
            Text(
              "No notifications yet",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index] as Map<String, dynamic>;
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification["isRead"] == true;
    final type = notification["type"]?.toString() ?? "Info";
    final message = notification["message"]?.toString() ?? "";
    final title = notification["title"]?.toString() ?? type;
    final createdAt = _formatTimestamp(notification["createdAt"]?.toString());
    final icon = _iconForNotification(notification);
    final cardColor = isRead
        ? AppColors.backgroundSecondary
        : AppColors.accentPrimary.withOpacity(0.08);
    final iconColor = _colorFromHex(notification["iconColor"]?.toString());
    final metadata = notification["metadata"];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: AppTextStyles.subHeading.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            createdAt,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: iconColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.body.copyWith(color: AppColors.textPrimary),
            ),
            if (metadata is Map && metadata.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: metadata.entries
                    .map<Widget>(
                      (entry) => Chip(
                        label: Text("${entry.key}: ${entry.value}"),
                        backgroundColor: AppColors.backgroundSecondary
                            .withOpacity(0.6),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (!isRead)
                  TextButton(
                    onPressed: () =>
                        _markAsRead(notification["_id"].toString()),
                    child: const Text("Mark as read"),
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () =>
                      _deleteNotification(notification["_id"].toString()),
                  child: const Text("Delete"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
