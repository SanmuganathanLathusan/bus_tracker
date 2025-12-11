import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:waygo/services/admin_service.dart';

class BusDriverWidget extends StatefulWidget {
  const BusDriverWidget({Key? key}) : super(key: key);

  @override
  State<BusDriverWidget> createState() => _BusDriverWidgetState();
}

class _BusDriverWidgetState extends State<BusDriverWidget> {
  final AdminService _adminService = AdminService();
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = true;
  bool _isAssigning = false;
  String? _resettingDriverId;
  String? _resettingBusId;
  String? _error;

  Map<String, dynamic> _stats = {
    "totalBuses": 0,
    "workableBuses": 0,
    "assignedBuses": 0,
    "totalDrivers": 0,
    "availableDrivers": 0,
    "assignedDrivers": 0,
  };
  Map<String, List<dynamic>> _busesByStatus = {
    "workable": [],
    "non_workable": [],
    "maintenance": [],
    "assigned": [],
  };
  Map<String, List<dynamic>> _driversByStatus = {
    "available": [],
    "assigned": [],
    "off_duty": [],
    "on_leave": [],
  };
  List<dynamic> _routes = [];
  List<dynamic> _depots = [];

  String? _selectedDriverId;
  String? _selectedRouteId;
  String? _selectedBusId;
  String? _assignmentDepotId;
  String _busStatusFilter = "workable";
  String _driverStatusFilter = "available";
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  List<dynamic> get _availableDriversForAssignment {
    final available = List<dynamic>.from(_driversByStatus["available"] ?? []);
    return _filterByDepot(available, depotKey: "homeDepotId");
  }

  List<dynamic> get _availableBusesForAssignment {
    // Get all workable buses (backend now returns all non-assigned buses in workable)
    // The backend already filters out assigned buses, so we just need to get workable buses
    final workable = List<dynamic>.from(_busesByStatus["workable"] ?? []);
    
    // Double-check: exclude any buses that might still be assigned
    // (this is a safety check, backend should already handle this)
    final assigned = List<dynamic>.from(_busesByStatus["assigned"] ?? []);
    final assignedBusIds = assigned
        .map((bus) => bus["_id"]?.toString())
        .where((id) => id != null)
        .toSet();
    
    // Filter out any assigned buses (safety check)
    final unassigned = workable.where((bus) {
      final busId = bus["_id"]?.toString();
      final assignmentStatus = bus["assignmentStatus"] ?? "available";
      final currentAssignmentId = bus["currentAssignmentId"];
      final isMaintenance = bus["conditionStatus"] == "maintenance";
      
      // Exclude if assigned or in maintenance
      return !assignedBusIds.contains(busId) &&
          assignmentStatus != "assigned" &&
          currentAssignmentId == null &&
          !isMaintenance;
    }).toList();
    
    return _filterByDepot(unassigned, depotKey: "depotId");
  }

  List<dynamic> _filterByDepot(List<dynamic> items, {required String depotKey}) {
    if (_assignmentDepotId == null || _assignmentDepotId!.isEmpty) {
      return items;
    }
    return items.where((item) {
      final depot = item[depotKey];
      if (depot == null) return false;
      if (depot is Map) {
        final id = (depot["_id"] ?? depot["id"])?.toString();
        return id == _assignmentDepotId;
      }
      return depot.toString() == _assignmentDepotId;
    }).toList();
  }

  String? _resolveSelection(String? currentId, List<dynamic> items) {
    if (currentId != null &&
        items.any((item) => item["_id"]?.toString() == currentId)) {
      return currentId;
    }
    if (items.isNotEmpty) {
      final firstId = items.first["_id"];
      return firstId?.toString();
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final statsResponse = await _adminService.getBusDriverStats();
      final routesResponse = await _adminService.getRoutes();

      final stats = Map<String, dynamic>.from(statsResponse["stats"] ?? {});
      final busGroups = Map<String, dynamic>.from(statsResponse["buses"] ?? {});
      final driverGroups =
          Map<String, dynamic>.from(statsResponse["drivers"] ?? {});
      final depots = List<dynamic>.from(statsResponse["depots"] ?? []);

      setState(() {
        _stats = {
          "totalBuses": stats["totalBuses"] ?? 0,
          "workableBuses": stats["workableBuses"] ?? stats["activeBuses"] ?? 0,
          "assignedBuses": stats["assignedBuses"] ?? 0,
          "totalDrivers": stats["totalDrivers"] ?? 0,
          "availableDrivers":
              stats["availableDrivers"] ?? stats["activeDrivers"] ?? 0,
          "assignedDrivers": stats["assignedDrivers"] ?? 0,
        };
        _busesByStatus = {
          for (final entry in _busesByStatus.entries)
            entry.key: List<dynamic>.from(busGroups[entry.key] ?? entry.value),
        };
        _driversByStatus = {
          for (final entry in _driversByStatus.entries)
            entry.key:
                List<dynamic>.from(driverGroups[entry.key] ?? entry.value),
        };
        _depots = depots;
        _routes = List<dynamic>.from(routesResponse);
        _selectedRouteId ??= _routes.isNotEmpty ? _routes.first["_id"] : null;
        _selectedDriverId =
            _resolveSelection(_selectedDriverId, _availableDriversForAssignment);
        _selectedBusId =
            _resolveSelection(_selectedBusId, _availableBusesForAssignment);
        _selectedDate ??= DateTime.now();
        _selectedTime ??= const TimeOfDay(hour: 8, minute: 0);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final result = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
    );
    if (result != null) {
      setState(() => _selectedDate = result);
    }
  }

  Future<void> _pickTime() async {
    final result = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (result != null) {
      setState(() => _selectedTime = result);
    }
  }

  Future<void> _assignSchedule() async {
    if (_selectedDriverId == null ||
        _selectedRouteId == null ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all required fields."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    final timeStr =
        "${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}";

    setState(() => _isAssigning = true);
    try {
      await _adminService.createAssignment(
        driverId: _selectedDriverId!,
        routeId: _selectedRouteId!,
        scheduledDate: dateStr,
        scheduledTime: timeStr,
        busId: _selectedBusId,
        depotId: _assignmentDepotId,
        notes: _notesController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Schedule assigned successfully."),
          backgroundColor: Colors.green,
        ),
      );
      _notesController.clear();
      // Clear bus selection after assignment (bus will be marked as assigned)
      setState(() => _selectedBusId = null);
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to assign schedule: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isAssigning = false);
      }
    }
  }

  Future<void> _handleBusStatusUpdate(
    String busId,
    String conditionStatus,
  ) async {
    try {
      await _adminService.updateBusCondition(
        busId: busId,
        conditionStatus: conditionStatus,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Bus marked as ${conditionStatus.replaceAll('_', ' ')}"),
        ),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update bus: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _handleDriverDutyStatusUpdate(
    String driverId,
    String dutyStatus,
  ) async {
    try {
      await _adminService.updateDriverDutyStatus(
        driverId: driverId,
        dutyStatus: dutyStatus,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Driver marked as ${dutyStatus.replaceAll('_', ' ')}"),
        ),
      );
      await _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update driver: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _resetDriverAssignment(String driverId) async {
    setState(() {
      _resettingDriverId = driverId;
    });
    try {
      await _adminService.resetDriverAssignment(driverId);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Driver reset to available."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _resettingDriverId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to reset driver: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _resettingDriverId = null);
      }
    }
  }

  Future<void> _resetBusAssignment(String busId, String? assignmentId) async {
    if (assignmentId == null || assignmentId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No assignment found for this bus."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _resettingBusId = busId;
    });
    try {
      await _adminService.deleteAssignment(assignmentId);
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Bus reset to available."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _resettingBusId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to reset bus: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _resettingBusId = null);
      }
    }
  }

  Future<void> _showAddBusDialog() async {
    final numberController = TextEditingController();
    final nameController = TextEditingController();
    final seatsController = TextEditingController(text: "40");
    String busType = "standard";
    String conditionStatus = "workable";
    String? depotId = _assignmentDepotId;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              if (!formKey.currentState!.validate()) return;
              setDialogState(() => isSaving = true);
              try {
                await _adminService.createBus(
                  busNumber: numberController.text.trim(),
                  busName: nameController.text.trim(),
                  totalSeats: int.tryParse(seatsController.text.trim()),
                  busType: busType,
                  depotId: depotId,
                  conditionStatus: conditionStatus,
                );
                if (!mounted) return;
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Bus added successfully"),
                  ),
                );
                await _loadData();
              } catch (e) {
                if (!mounted) return;
                setDialogState(() => isSaving = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Failed to add bus: $e"),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Text("Add New Bus"),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: numberController,
                        decoration: const InputDecoration(
                          labelText: "Bus Number",
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? "Bus number is required"
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: "Bus Name",
                        ),
                        validator: (value) => (value == null || value.isEmpty)
                            ? "Bus name is required"
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: seatsController,
                        decoration: const InputDecoration(
                          labelText: "Total Seats",
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: busType,
                        decoration: const InputDecoration(
                          labelText: "Bus Type",
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "standard",
                            child: Text("Standard"),
                          ),
                          DropdownMenuItem(
                            value: "deluxe",
                            child: Text("Deluxe"),
                          ),
                          DropdownMenuItem(
                            value: "luxury",
                            child: Text("Luxury"),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => busType = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: conditionStatus,
                        decoration: const InputDecoration(
                          labelText: "Condition",
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: "workable",
                            child: Text("Workable"),
                          ),
                          DropdownMenuItem(
                            value: "non_workable",
                            child: Text("Non-workable"),
                          ),
                          DropdownMenuItem(
                            value: "maintenance",
                            child: Text("Maintenance"),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => conditionStatus = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        value: depotId,
                        decoration: const InputDecoration(
                          labelText: "Depot",
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text("Unassigned"),
                          ),
                          ..._depots.map(
                            (depot) => DropdownMenuItem<String?>(
                              value: depot["_id"].toString(),
                              child: Text(
                                depot["name"] ?? depot["code"] ?? "Depot",
                              ),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setDialogState(() => depotId = value),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.of(context).pop(),
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: isSaving ? null : submit,
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              onPressed: _loadData,
              child: const Text("Retry"),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFF5F7FA),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Buses',
                    _stats["totalBuses"].toString(),
                    Icons.directions_bus,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Workable Buses',
                    _stats["workableBuses"].toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Total Drivers',
                    _stats["totalDrivers"].toString(),
                    Icons.person,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Available Drivers',
                    _stats["availableDrivers"].toString(),
                    Icons.how_to_reg,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildAssignmentCard(),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: BusManagementCard(
                          busesByStatus: _busesByStatus,
                          selectedFilter: _busStatusFilter,
                          onFilterChanged: (value) =>
                              setState(() => _busStatusFilter = value),
                          onStatusChange: _handleBusStatusUpdate,
                          onAddBus: _showAddBusDialog,
                          onResetAssignment: _resetBusAssignment,
                          resettingBusId: _resettingBusId,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: DriverManagementCard(
                          driversByStatus: _driversByStatus,
                          selectedFilter: _driverStatusFilter,
                          onFilterChanged: (value) =>
                              setState(() => _driverStatusFilter = value),
                          onDutyStatusChange: _handleDriverDutyStatusUpdate,
                          onResetAssignment: _resetDriverAssignment,
                          resettingDriverId: _resettingDriverId,
                        ),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      BusManagementCard(
                        busesByStatus: _busesByStatus,
                        selectedFilter: _busStatusFilter,
                        onFilterChanged: (value) =>
                            setState(() => _busStatusFilter = value),
                        onStatusChange: _handleBusStatusUpdate,
                        onAddBus: _showAddBusDialog,
                        onResetAssignment: _resetBusAssignment,
                        resettingBusId: _resettingBusId,
                      ),
                      const SizedBox(height: 24),
                      DriverManagementCard(
                        driversByStatus: _driversByStatus,
                        selectedFilter: _driverStatusFilter,
                        onFilterChanged: (value) =>
                            setState(() => _driverStatusFilter = value),
                        onDutyStatusChange: _handleDriverDutyStatusUpdate,
                        onResetAssignment: _resetDriverAssignment,
                        resettingDriverId: _resettingDriverId,
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignmentCard() {
    // keep card height bounded so keyboard or small viewports don't overflow
    final maxCardHeight = MediaQuery.of(context).size.height * 0.75;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: AnimatedPadding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxCardHeight),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(Icons.schedule, color: Colors.teal.shade600),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Assign Driver Schedule",
                        style: TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                        onPressed: _loadData,
                        icon: const Icon(Icons.refresh)),
                  ],
                ),
                const SizedBox(height: 12),

                // Responsive controls
                LayoutBuilder(builder: (context, constraints) {
                  final maxW = constraints.maxWidth;
                  final bool wide = maxW > 900;
                  final double target = wide ? 280.0 : (maxW / 2) - 24.0;
                  final double controlWidth = target.clamp(150.0, maxW);

                  Widget control(Widget child) =>
                      SizedBox(width: controlWidth, child: child);

                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Depot
                      control(
                        DropdownButtonFormField<String?>(
                          value: _assignmentDepotId,
                          decoration: const InputDecoration(
                            labelText: "Depot",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String?>(
                                value: null, child: Text("All depots")),
                            ..._depots.map((depot) =>
                                DropdownMenuItem<String?>(
                                  value: depot["_id"].toString(),
                                  child: Text(
                                    "${depot["code"] ?? ""} - ${depot["name"] ?? "Depot"}",
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _assignmentDepotId = value;
                              _selectedDriverId = _resolveSelection(
                                  _selectedDriverId,
                                  _availableDriversForAssignment);
                              _selectedBusId = _resolveSelection(
                                  _selectedBusId,
                                  _availableBusesForAssignment);
                            });
                          },
                        ),
                      ),

                      // Driver
                      control(
                        DropdownButtonFormField<String>(
                          value: _selectedDriverId,
                          decoration: const InputDecoration(
                            labelText: "Driver",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: _availableDriversForAssignment.map((driver) {
                            final depotLabel = (() {
                              final d = driver["homeDepotId"];
                              if (d == null) return "No depot";
                              if (d is Map) {
                                final code = d["code"] ?? "";
                                final name = d["name"] ?? "";
                                return (code.toString().isNotEmpty)
                                    ? "$code • $name"
                                    : name.toString();
                              }
                              return d.toString();
                            })();
                            return DropdownMenuItem<String>(
                              value: driver["_id"].toString(),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      driver["userName"] ??
                                          "Unnamed Driver",
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    fit: FlexFit.loose,
                                    child: Text(
                                      depotLabel,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.black54),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged:
                              _availableDriversForAssignment.isEmpty
                                  ? null
                                  : (value) =>
                                      setState(() => _selectedDriverId = value),
                        ),
                      ),

                      // Route
                      control(
                        DropdownButtonFormField<String>(
                          value: _selectedRouteId,
                          decoration: const InputDecoration(
                            labelText: "Route",
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          isExpanded: true,
                          items: _routes.map((route) {
                            return DropdownMenuItem<String>(
                              value: route["_id"].toString(),
                              child: Text(
                                "${route["start"] ?? "N/A"} → ${route["destination"] ?? "N/A"}",
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) =>
                              setState(() => _selectedRouteId = value),
                        ),
                      ),

                      // Bus optional - Available buses only (excludes assigned buses)
                      control(
                        DropdownButtonFormField<String?>(
                          value: _selectedBusId,
                          menuMaxHeight: 400,
                          decoration: InputDecoration(
                            labelText:
                                "Available Bus ${_availableBusesForAssignment.isEmpty ? '(none)' : '(${_availableBusesForAssignment.length} available)'}",
                            hintText: _availableBusesForAssignment.isEmpty
                                ? "No available buses"
                                : "Select a bus (optional)",
                            border: const OutlineInputBorder(),
                            isDense: true,
                            helperText: _availableBusesForAssignment.isEmpty
                                ? "No workable buses available for assignment"
                                : "Optional: Assign a specific bus to this schedule",
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Row(
                                children: [
                                  Icon(Icons.directions_bus_outlined,
                                      size: 18, color: Colors.grey),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "No bus assigned (auto-assign)",
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ..._availableBusesForAssignment.map((bus) {
                              final depotData = bus["depotId"];
                              String depotLabel = "";
                              if (depotData != null) {
                                depotLabel = depotData is Map
                                    ? (depotData["code"] ??
                                            depotData["name"] ??
                                            "")
                                        .toString()
                                    : depotData.toString();
                              }
                              final busNumber = bus["busNumber"] ??
                                  bus["busName"] ??
                                  "Unnamed bus";
                              final busType =
                                  (bus["busType"] ?? "").toString();
                              final seats =
                                  bus["totalSeats"]?.toString() ?? "";

                              // Build a single line with all info
                              final details = [
                                if (depotLabel.isNotEmpty) depotLabel,
                                if (busType.isNotEmpty) busType,
                                if (seats.isNotEmpty) "$seats seats",
                              ].join(" • ");

                              return DropdownMenuItem<String?>(
                                value: bus["_id"].toString(),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                                  child: Row(
                                    children: [
                                      Icon(Icons.directions_bus,
                                          size: 18,
                                          color: Colors.blue.shade700),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          details.isNotEmpty
                                              ? "$busNumber ($details)"
                                              : busNumber.toString(),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                          onChanged:
                              _availableBusesForAssignment.isEmpty
                                  ? null
                                  : (value) =>
                                      setState(() => _selectedBusId = value),
                        ),
                      ),

                      // Date picker
                      control(
                        OutlinedButton.icon(
                          onPressed: _pickDate,
                          icon:
                              const Icon(Icons.calendar_today_outlined),
                          label: Text(
                            _selectedDate == null
                                ? "Pick Date"
                                : DateFormat('dd MMM yyyy')
                                    .format(_selectedDate!),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 10),
                          ),
                        ),
                      ),

                      // Time picker
                      control(
                        OutlinedButton.icon(
                          onPressed: _pickTime,
                          icon: const Icon(Icons.access_time),
                          label: Text(
                            _selectedTime == null
                                ? "Pick Time"
                                : _selectedTime!.format(context),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 10),
                          ),
                        ),
                      ),
                    ],
                  );
                }),

                const SizedBox(height: 12),

                // Notes
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Notes (optional)",
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),

                // Assign button
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _isAssigning ? null : _assignSchedule,
                    icon: _isAssigning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: Text(
                        _isAssigning ? "Assigning..." : "Assign Schedule"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class BusManagementCard extends StatelessWidget {
  final Map<String, List<dynamic>> busesByStatus;
  final String selectedFilter;
  final void Function(String status) onFilterChanged;
  final Future<void> Function(String busId, String status) onStatusChange;
  final VoidCallback onAddBus;
  final Future<void> Function(String busId, String? assignmentId) onResetAssignment;
  final String? resettingBusId;

  static const Map<String, String> _statusLabels = {
    "workable": "Workable",
    "non_workable": "Non-workable",
    "maintenance": "Maintenance",
    "assigned": "Assigned",
  };

  const BusManagementCard({
    Key? key,
    required this.busesByStatus,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onStatusChange,
    required this.onAddBus,
    required this.onResetAssignment,
    this.resettingBusId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentBuses =
        List<dynamic>.from(busesByStatus[selectedFilter] ?? []);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: Colors.blue.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Bus Fleet',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton.icon(
                onPressed: onAddBus,
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Bus'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statusLabels.entries.map((entry) {
              final count = busesByStatus[entry.key]?.length ?? 0;
              return ChoiceChip(
                label: Text("${entry.value} ($count)"),
                selected: selectedFilter == entry.key,
                onSelected: (_) => onFilterChanged(entry.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (currentBuses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  "No ${_statusLabels[selectedFilter]?.toLowerCase()} buses.",
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            ...currentBuses
                .map((bus) => _buildBusCard(context, bus))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildBusCard(BuildContext context, dynamic bus) {
    final driver = bus["driverId"];
    final depot = bus["depotId"];
    final conditionStatus = (bus["conditionStatus"] ?? "workable").toString();
    final assignmentStatus = (bus["assignmentStatus"] ?? "available").toString();
    final assignment = bus["currentAssignment"];
    final route = assignment is Map ? assignment["route"] : null;
    final routeLabel = route != null
        ? "${route["start"] ?? "N/A"} → ${route["destination"] ?? "N/A"}"
        : null;
    final scheduleLabel =
        assignment != null ? _formatScheduleLabel(assignment) : null;
    final assignmentDriver = assignment is Map && assignment["driver"] is Map
        ? assignment["driver"] as Map<String, dynamic>
        : null;
    final assignedDriverName = assignmentDriver?["userName"]?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.directions_bus,
                  color: Colors.blue.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (bus['busNumber'] ?? bus['busName'] ?? 'Unnamed Bus')
                          .toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    if (depot != null)
                      Text(
                        "${depot["code"] ?? depot["name"] ?? "Depot"}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: "Update condition",
                onSelected: (value) =>
                    onStatusChange(bus["_id"].toString(), value),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: "workable",
                    child: Text("Mark as workable"),
                  ),
                  PopupMenuItem(
                    value: "non_workable",
                    child: Text("Mark as non-workable"),
                  ),
                  PopupMenuItem(
                    value: "maintenance",
                    child: Text("Mark as maintenance"),
                  ),
                ],
                child: Chip(
                  avatar: const Icon(Icons.tune, size: 16),
                  label: const Text("Update status"),
                  backgroundColor: Colors.blueGrey.shade50,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusBadge(
                label: conditionStatus.replaceAll('_', ' ').toUpperCase(),
                color: _statusColor(conditionStatus),
              ),
              _statusBadge(
                label: assignmentStatus.toUpperCase(),
                color: assignmentStatus == "assigned"
                    ? Colors.deepOrange
                    : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoChip(
                  Icons.store,
                  'Depot',
                  depot == null
                      ? "Not set"
                      : (depot is Map
                          ? depot['name'] ?? depot['code'] ?? 'Depot'
                          : depot.toString()),
                  Colors.blueGrey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoChip(
                  Icons.person,
                  'Driver',
                  driver == null
                      ? "Unassigned"
                      : (driver is Map
                          ? driver['userName'] ?? 'Unknown'
                          : driver.toString()),
                  Colors.purple,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildInfoChip(
                  Icons.event_seat,
                  'Seats',
                  (bus['totalSeats'] ?? 'N/A').toString(),
                  Colors.orange,
                ),
              ),
            ],
          ),
          if (bus["notes"] != null && bus["notes"].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                "Notes: ${bus["notes"]}",
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          if (assignment != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              "Current Assignment",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoChip(
              Icons.route,
              "Route",
              routeLabel ?? "Route pending",
              Colors.teal,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildInfoChip(
                    Icons.schedule,
                    "Schedule",
                    scheduleLabel ?? (assignment["status"] ?? "").toString(),
                    Colors.indigo,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildInfoChip(
                    Icons.person,
                    "Driver",
                    assignedDriverName ?? "TBD",
                    Colors.deepPurple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final assignmentId = assignment is Map 
                    ? (assignment["_id"]?.toString() ?? bus["currentAssignmentId"]?.toString())
                    : bus["currentAssignmentId"]?.toString();
                final isResetting = resettingBusId == bus["_id"].toString();
                return Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: isResetting
                        ? null
                        : () => onResetAssignment(bus["_id"].toString(), assignmentId),
                    icon: isResetting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.restart_alt),
                    label: Text(isResetting ? "Resetting..." : "Reset to available"),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: color.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case "non_workable":
        return Colors.redAccent;
      case "maintenance":
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  String _formatScheduleLabel(Map<String, dynamic> assignment) {
    final dateRaw = assignment["scheduledDate"];
    final time = assignment["scheduledTime"]?.toString() ?? "";
    if (dateRaw == null) return time;
    final date = DateTime.tryParse(dateRaw.toString());
    if (date == null) return time;
    final dateLabel = DateFormat("dd MMM").format(date.toLocal());
    return [dateLabel, time].where((value) => value.isNotEmpty).join(" • ");
  }
}

class DriverManagementCard extends StatelessWidget {
  final Map<String, List<dynamic>> driversByStatus;
  final String selectedFilter;
  final void Function(String status) onFilterChanged;
  final Future<void> Function(String driverId, String dutyStatus)
      onDutyStatusChange;
  final Future<void> Function(String driverId) onResetAssignment;
  final String? resettingDriverId;

  static const Map<String, String> _driverStatusLabels = {
    "available": "Available",
    "assigned": "Assigned",
    "off_duty": "Off duty",
    "on_leave": "On leave",
  };

  const DriverManagementCard({
    Key? key,
    required this.driversByStatus,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onDutyStatusChange,
    required this.onResetAssignment,
    this.resettingDriverId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final drivers = List<dynamic>.from(driversByStatus[selectedFilter] ?? []);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.people,
                  color: Colors.purple.shade600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Driver Team',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              const Tooltip(
                message: "Drivers are managed centrally. Update duty status instead.",
                child: Icon(Icons.info_outline, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _driverStatusLabels.entries.map((entry) {
              final count = driversByStatus[entry.key]?.length ?? 0;
              return ChoiceChip(
                label: Text("${entry.value} ($count)"),
                selected: selectedFilter == entry.key,
                onSelected: (_) => onFilterChanged(entry.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          if (drivers.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  "No ${_driverStatusLabels[selectedFilter]?.toLowerCase()} drivers.",
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
            )
          else
            ...drivers.map((driver) => _buildDriverCard(context, driver)),
        ],
      ),
    );
  }

  Widget _buildDriverCard(BuildContext context, dynamic driver) {
    final bus = driver['busId'];
    final depot = driver['homeDepotId'];
    final dutyStatus = (driver['dutyStatus'] ?? 'available').toString();
    final dutyColor = _driverStatusColor(dutyStatus);
    final canUpdateStatus = dutyStatus != "assigned";
    final assignment = driver["currentAssignment"];
    final route = assignment is Map ? assignment["route"] : null;
    final routeLabel = route != null
        ? "${route["start"] ?? "N/A"} → ${route["destination"] ?? "N/A"}"
        : null;
    final assignmentBus = assignment is Map && assignment["bus"] is Map
        ? assignment["bus"] as Map<String, dynamic>
        : null;
    final assignedBus = assignmentBus?["busNumber"] ?? assignmentBus?["busName"];
    final scheduleLabel =
        assignment != null ? _formatScheduleLabel(assignment) : null;
    final isResetting = resettingDriverId == driver["_id"].toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.purple.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      driver['userName'] ?? 'Unnamed Driver',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      driver['licenseNumber'] ?? 'No license',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                enabled: canUpdateStatus,
                tooltip: canUpdateStatus
                    ? "Update duty status"
                    : "Status controlled by assignment",
                onSelected: (value) =>
                    onDutyStatusChange(driver["_id"].toString(), value),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: "available",
                    child: Text("Mark available"),
                  ),
                  PopupMenuItem(
                    value: "off_duty",
                    child: Text("Mark off duty"),
                  ),
                  PopupMenuItem(
                    value: "on_leave",
                    child: Text("Mark on leave"),
                  ),
                ],
                child: Chip(
                  avatar: Icon(
                    Icons.circle,
                    size: 10,
                    color: dutyColor,
                  ),
                  label: Text(
                    dutyStatus.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(color: dutyColor, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: dutyColor.withOpacity(0.1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _driverInfoTile(
                  icon: Icons.store,
                  title: "Depot",
                  value: depot == null
                      ? "Not set"
                      : (depot is Map
                          ? depot['name'] ?? depot['code'] ?? 'Depot'
                          : depot.toString()),
                  color: Colors.blueGrey,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _driverInfoTile(
                  icon: Icons.phone,
                  title: "Contact",
                  value: driver['phone'] ?? 'N/A',
                  color: Colors.green.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _driverInfoTile(
            icon: Icons.directions_bus,
            title: "Assigned Bus",
            value: bus == null
                ? 'No bus assigned'
                : (bus is Map
                    ? (bus['busNumber'] ?? bus['busName'] ?? 'Bus').toString()
                    : bus.toString()),
            color: Colors.blue.shade700,
          ),
          if (assignment != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              "Active Route",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            _driverInfoTile(
              icon: Icons.route,
              title: "Route",
              value: routeLabel ?? "Pending",
              color: Colors.teal,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _driverInfoTile(
                    icon: Icons.schedule,
                    title: "Schedule",
                    value: scheduleLabel ?? assignment["status"] ?? "Pending",
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _driverInfoTile(
                    icon: Icons.directions_bus_filled,
                    title: "Bus",
                    value: assignedBus ??
                        (assignment["bus"]?["busName"] ?? "TBD"),
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: isResetting
                    ? null
                    : () => onResetAssignment(driver["_id"].toString()),
                icon: isResetting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restart_alt),
                label: Text(isResetting ? "Resetting..." : "Reset to available"),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _driverInfoTile({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _driverStatusColor(String status) {
    switch (status) {
      case "assigned":
        return Colors.deepOrange;
      case "off_duty":
        return Colors.blueGrey;
      case "on_leave":
        return Colors.indigo;
      default:
        return Colors.green;
    }
  }

  String _formatScheduleLabel(Map<String, dynamic> assignment) {
    final dateRaw = assignment["scheduledDate"];
    final time = assignment["scheduledTime"]?.toString() ?? "";
    if (dateRaw == null) return time;
    final date = DateTime.tryParse(dateRaw.toString());
    if (date == null) return time;
    final dateLabel = DateFormat("dd MMM").format(date.toLocal());
    return [dateLabel, time].where((value) => value.isNotEmpty).join(" • ");
  }
}
