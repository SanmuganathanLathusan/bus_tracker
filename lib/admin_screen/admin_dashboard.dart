import 'package:flutter/material.dart';
import 'package:waygo/admin_screen/widgets/bus_and_drivers.dart';
import 'package:waygo/admin_screen/widgets/dashboard_banner.dart';
import 'package:waygo/admin_screen/widgets/feedback.dart';
import 'package:waygo/admin_screen/widgets/horizontal_menu_bar.dart';
import 'package:waygo/admin_screen/widgets/live_tracking.dart';
import 'package:waygo/admin_screen/widgets/news_feed.dart';
import 'package:waygo/admin_screen/widgets/overview.dart';
import 'package:waygo/admin_screen/widgets/setting.dart';
import 'package:waygo/admin_screen/widgets/ticket_and_prising.dart';
import 'package:waygo/admin_screen/widgets/users.dart';
import 'package:waygo/admin_screen/widgets/profile.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color.fromARGB(255, 187, 224, 255),
      ),
      home: const DashboardHome(),
    );
  }
}

class DashboardHome extends StatefulWidget {
  const DashboardHome({Key? key}) : super(key: key);

  @override
  State<DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<DashboardHome> {
  int _selectedSection = 0;

  final List<Map<String, dynamic>> _sections = [
    {'icon': Icons.analytics, 'label': 'Overview'},
    {'icon': Icons.article, 'label': 'News Feed'},
    {'icon': Icons.map, 'label': 'Live Tracking'},
    {'icon': Icons.directions_bus, 'label': 'Buses & Drivers'},
    {'icon': Icons.confirmation_number, 'label': 'Ticket & Pricing'},
    {'icon': Icons.people, 'label': 'Users'},
    {'icon': Icons.feedback, 'label': 'Report and Issue'},
    {'icon': Icons.settings, 'label': 'Settings'},
  ];

  void _navigateToProfile() {
    setState(() {
      _selectedSection = 8; // Profile section index
    });
  }

  Widget _getSelectedContent() {
    switch (_selectedSection) {
      case 0:
        return const OverviewWidget();
      case 1:
        return const NewsFeedWidget();
      case 2:
        return const LiveTrackingWidget();
      case 3:
        return const BusDriverWidget();
      case 4:
        return const TicketPricingWidget();
      case 5:
        return const UsersWidget();
      case 6:
        return const FeedbackWidget();
      case 7:
        return const SettingsWidget();
      case 8:
        return const AdminProfileWidget();
      default:
        return const OverviewWidget();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          DashboardBanner(onProfileTap: _navigateToProfile),
          HorizontalMenuBar(
            sections: _sections,
            selectedIndex: _selectedSection,
            onSectionTapped: (index) {
              setState(() {
                _selectedSection = index;
              });
            },
          ),
          Expanded(child: _getSelectedContent()),
        ],
      ),
    );
  }
}
