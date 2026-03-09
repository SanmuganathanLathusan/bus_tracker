import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waygo/services/reservation_service.dart';
import 'package:waygo/utils/app_colors.dart';
import 'package:waygo/utils/app_text_styles.dart';
import 'eticket_price_selection_page.dart';

class EticketBookingPage extends StatefulWidget {
  const EticketBookingPage({super.key});

  @override
  State<EticketBookingPage> createState() => _EticketBookingPageState();
}

class _EticketBookingPageState extends State<EticketBookingPage> {
  final List<String> _cities = [
    'Colombo',
    'Kandy',
    'Galle',
    'Matara',
    'Jaffna',
    'Negombo',
    'Anuradhapura',
    'Trincomalee',
  ];

  String _from = 'Colombo';
  String _to = 'Kandy';
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _routes = [];

  final ReservationService _reservationService = ReservationService();

  String get _formattedDate => DateFormat('dd MMM yyyy').format(_selectedDate);
  String get _dateForApi => DateFormat('yyyy-MM-dd').format(_selectedDate);

  void _swapLocations() {
    setState(() => (_from, _to) = (_to, _from));
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _searchRoutes() async {
    FocusScope.of(context).unfocus();

    if (_from == _to) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Origin and destination must be different'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _routes = [];
    });

    try {
      final results = await _reservationService.searchRoutes(
        start: _from,
        destination: _to,
        date: _dateForApi,
      );

      final normalized = (results ?? []).map<Map<String, dynamic>>((item) {
        final map = Map<String, dynamic>.from(item as Map);

        if (map['route'] is Map) {
          return Map<String, dynamic>.from(map['route']);
        }

        return map;
      }).toList();

      setState(() {
        _routes = normalized;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Widget _backgroundWrapper(Widget child) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const NetworkImage(
            'https://images.unsplash.com/photo-1570125909232-eb263c188f7e?w=1200&q=80',
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.white.withOpacity(0.70),
            BlendMode.lighten,
          ),
        ),
      ),
      child: child,
    );
  }

  Widget _header() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.maybePop(context),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.waygoDarkBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.arrow_back,
              color: AppColors.waygoLightBlue,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Book E-Ticket',
                style: AppTextStyles.heading.copyWith(
                  color: AppColors.textDark,
                  fontSize: 24,
                ),
              ),
              Text(
                'Search and book your journey',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _modernDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButton<String>(
      value: value,
      isExpanded: true,
      underline: const SizedBox(),
      items: _cities
          .map(
            (c) => DropdownMenuItem(
              value: c,
              child: Text(c),
            ),
          )
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _searchCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.waygoDarkBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _modernDropdown(
                  label: 'From',
                  value: _from,
                  onChanged: (v) => setState(() => _from = v!),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                color: Colors.white,
                onPressed: _swapLocations,
              ),
              Expanded(
                child: _modernDropdown(
                  label: 'To',
                  value: _to,
                  onChanged: (v) => setState(() => _to = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.white24,
                    child: Text(
                      _formattedDate,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _isLoading ? null : _searchRoutes,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text("Search"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scheduleCard(Map<String, dynamic> r) {
    final start = r['start'] ?? '';
    final destination = r['destination'] ?? '';
    final departure = r['departure'] ?? '';
    final arrival = r['arrival'] ?? '';
    final routeId = r['_id'] ?? '';

    return Card(
      child: ListTile(
        title: Text('$start → $destination'),
        subtitle: Text('$departure  -  $arrival'),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EticketPriceSelectionPage(
                routeDetails: r,
                selectedDate: _selectedDate,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _resultsSection() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_routes.isEmpty) {
      return const Center(child: Text("Search routes to book tickets"));
    }

    _routes.sort((a, b) {
      final ta = (a['departure'] ?? '').toString();
      final tb = (b['departure'] ?? '').toString();
      return ta.compareTo(tb);
    });

    return ListView.builder(
      itemCount: _routes.length,
      itemBuilder: (context, i) => _scheduleCard(_routes[i]),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _backgroundWrapper(
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _header(),
                const SizedBox(height: 16),
                _searchCard(),
                const SizedBox(height: 16),
                Expanded(child: _resultsSection()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}