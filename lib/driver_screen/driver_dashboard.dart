import 'package:flutter/material.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';
import 'package:waygo/driver_screen/widgets/route_assignment.dart';
import 'package:waygo/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Import all driver pages
import 'pages/trip_overview_page.dart';
import 'pages/live_map_page.dart';
import 'pages/passenger_list_page.dart';
import 'pages/schedule_page.dart';
import 'pages/performance_page.dart';
import 'pages/maintenance_page.dart';
import 'pages/notifications_page.dart';
import 'pages/profile_page.dart';
import 'pages/tickets_reservations_page.dart';
import 'widgets/stat_card.dart';

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({Key? key}) : super(key: key);

  @override
  _DriverDashboardState createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _currentIndex = 0;
  final ProfileService _profileService = ProfileService();

  String _driverName = "Loading...";
  String _busNumber = "Loading...";
  String _currentRoute = "No route assigned";
  String? _profileImageUrl;
  RouteAssignment? _assignedRoute;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadDriverProfile();
  }

  Future<void> _loadDriverProfile() async {
    try {
      // Load from SharedPreferences first for instant display
      final prefs = await SharedPreferences.getInstance();
      final cachedName = prefs.getString('driverName');
      final cachedBus = prefs.getString('busNumber');
      final cachedImage = prefs.getString('profileImage');

      if (cachedName != null) {
        setState(() {
          _driverName = cachedName;
          _busNumber = cachedBus ?? 'Not Assigned';
          _profileImageUrl = cachedImage;
        });
      }

      // Then fetch latest from API
      final response = await _profileService.getProfile();
      final user = response['user'] as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        _driverName = user['userName'] ?? 'Driver';
        _busNumber = user['busNumber'] ?? 'Not Assigned';
        _profileImageUrl = user['profileImage'];
        _isLoadingProfile = false;
      });

      // Cache the values
      await prefs.setString('driverName', _driverName);
      if (_busNumber != 'Not Assigned') {
        await prefs.setString('busNumber', _busNumber);
      }
      if (_profileImageUrl != null) {
        await prefs.setString('profileImage', _profileImageUrl!);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingProfile = false);
      debugPrint('Error loading profile: $e');
    }
  }

  void _handleProfileUpdate({
    String? name,
    String? busNumber,
    String? busName,
    String? profileImage,
  }) async {
    setState(() {
      if (name != null) _driverName = name;
      if (busNumber != null) {
        _busNumber = busName != null ? '$busNumber' : busNumber;
      }
      if (profileImage != null) _profileImageUrl = profileImage;
    });

    // Update cache
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString('driverName', name);
    if (busNumber != null) await prefs.setString('busNumber', busNumber);
    if (profileImage != null)
      await prefs.setString('profileImage', profileImage);
  }

  void _handleRouteUpdate(RouteAssignment updatedRoute) async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _assignedRoute = updatedRoute;
      if (updatedRoute.isAccepted) {
        _currentRoute =
            "${updatedRoute.fromLocation} → ${updatedRoute.toLocation}";
        if ((updatedRoute.busNumber ?? updatedRoute.busName)?.isNotEmpty ??
            false) {
          _busNumber =
              updatedRoute.busNumber ?? updatedRoute.busName ?? _busNumber;
        }
      } else if (updatedRoute.isRejected) {
        _currentRoute = "Route rejected";
      } else if (updatedRoute.isPending) {
        _currentRoute = "Awaiting confirmation";
      } else {
        _currentRoute = "No route assigned";
      }
    });

    // Cache the bus number if assigned
    if (updatedRoute.isAccepted &&
        (updatedRoute.busNumber ?? updatedRoute.busName)?.isNotEmpty == true) {
      await prefs.setString('busNumber', _busNumber);
    }
  }

  // void _updateRoute(String from, String to) {
  //   setState(() {
  //     _currentRoute = "$from → $to";
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final pages = [
      TripOverviewPage(
        key: ValueKey("trip-${_assignedRoute?.id ?? 'none'}"),
        activeAssignment: _assignedRoute,
        onTripCompleted: (nextAssignment) {
          setState(() {
            if (nextAssignment == null) {
              _assignedRoute = null;
              _currentRoute = "No route assigned";
            } else {
              _assignedRoute = nextAssignment;
              _currentRoute =
                  "${nextAssignment.fromLocation} → ${nextAssignment.toLocation}";
            }
          });
        },
      ),
      LiveMapPage(busId: _busNumber), // Keep as is for manual activation
      PassengerListPage(
        key: ValueKey(_assignedRoute?.id ?? 'no-assignment'),
        activeAssignment: _assignedRoute,
      ),
      const TicketsReservationsPage(),
      SchedulePage(
        key: ValueKey("schedule-${_assignedRoute?.id ?? 'none'}"),
        assignedRoute: _assignedRoute,
        onRouteUpdate: _handleRouteUpdate,
      ),
      PerformancePage(),
      MaintenancePage(activeAssignment: _assignedRoute),
      NotificationsPage(),
      ProfilePage(onProfileUpdated: _handleProfileUpdate),
    ];

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 113, 171, 209),
      body: Column(
        children: [
          _buildTopBanner(),
          _buildFloatingStatCards(),
          Expanded(child: pages[_currentIndex]),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
    );
  }

  Widget _buildTopBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0B1E36), Color(0xFF102C54), Color(0xFF1E4777)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Driver Dashboard",
                  style: AppTextStyles.heading.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _currentIndex = 7),
                      icon: const Icon(
                        Icons.notifications,
                        color: Colors.white,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _currentIndex = 8),
                      icon: const Icon(Icons.person, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "Driver: $_driverName",
              style: AppTextStyles.body.copyWith(
                color: Colors.white.withOpacity(0.95),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Bus: $_busNumber  |  Route: $_currentRoute",
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingStatCards() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 90,
                  child: StatCard(
                    title: "Total Trips Today",
                    value: "3",
                    icon: Icons.directions_bus,
                    color: const Color(0xFF42A5F5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 90,
                  child: StatCard(
                    title: "Passengers Onboard",
                    value: "24",
                    icon: Icons.people,
                    color: const Color(0xFF66BB6A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 90,
                  child: StatCard(
                    title: "Time Remaining",
                    value: "45 min",
                    icon: Icons.access_time,
                    color: const Color(0xFFFFA726),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 90,
                  child: StatCard(
                    title: "Average Rating",
                    value: "4.7⭐",
                    icon: Icons.star,
                    color: const Color(0xFFAB47BC),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return BottomNavigationBar(
      backgroundColor: Colors.white,
      currentIndex: _currentIndex,
      onTap: (index) => setState(() => _currentIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.waygoDarkBlue,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      selectedLabelStyle: AppTextStyles.bodySmall.copyWith(
        fontWeight: FontWeight.w600,
      ),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Overview'),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Passengers'),
        BottomNavigationBarItem(
          icon: Icon(Icons.confirmation_number),
          label: 'Bookings',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.schedule), label: 'Schedule'),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'Performance',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Maintenance'),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Alerts',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
