// lib/models/route_assignment.dart

import 'package:intl/intl.dart';

/// Represents a driver schedule/assignment created by admin.
class RouteAssignment {
  final String id;
  final String driverId;
  final String? busId;
  final String statusRaw;
  final RouteStatus status;
  final DateTime scheduledDate;
  final String scheduledTime;
  final DateTime? startTime;
  final DateTime? endTime;
  final String routeId;
  final String fromLocation;
  final String toLocation;
  final String? departureTime;
  final String? arrivalTime;
  final String? busNumber;
  final String? busName;
  final String assignedBy;
  final String? notes;
  final String? driverResponse;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? depotId;
  final String? depotName;
  final String? depotCode;

  RouteAssignment({
    required this.id,
    required this.driverId,
    required this.statusRaw,
    required this.status,
    required this.scheduledDate,
    required this.scheduledTime,
    required this.routeId,
    required this.fromLocation,
    required this.toLocation,
    required this.assignedBy,
    required this.createdAt,
    required this.updatedAt,
    this.busId,
    this.startTime,
    this.endTime,
    this.departureTime,
    this.arrivalTime,
    this.busNumber,
    this.busName,
    this.notes,
    this.driverResponse,
    this.depotId,
    this.depotName,
    this.depotCode,
  });

  factory RouteAssignment.fromJson(Map<String, dynamic> json) {
    final route = json['routeId'] ?? {};
    final bus = json['busId'] ?? {};
    final assignedBy = json['assignedBy'] ?? {};
    final depot = json['depotId'];
    return RouteAssignment(
      id: (json['_id'] ?? json['id']).toString(),
      driverId: (json['driverId'] ?? '').toString(),
      busId: bus is Map
          ? (bus['_id'] ?? bus['id'])?.toString()
          : bus?.toString(),
      statusRaw: (json['status'] ?? 'pending').toString(),
      status: RouteStatusExtension.fromString(json['status']),
      scheduledDate: DateTime.tryParse(json['scheduledDate'] ?? '') ??
          DateTime.now(),
      scheduledTime: json['scheduledTime'] ?? '00:00',
      startTime: json['startTime'] != null
          ? DateTime.tryParse(json['startTime'])
          : null,
      endTime:
          json['endTime'] != null ? DateTime.tryParse(json['endTime']) : null,
      routeId: route is Map
          ? (route['_id'] ?? route['id'] ?? '').toString()
          : route?.toString() ?? '',
      fromLocation: route is Map ? (route['start'] ?? 'Unknown') : 'Unknown',
      toLocation:
          route is Map ? (route['destination'] ?? 'Unknown') : 'Unknown',
      departureTime: route is Map ? route['departure']?.toString() : null,
      arrivalTime: route is Map ? route['arrival']?.toString() : null,
      busNumber: bus is Map ? bus['busNumber']?.toString() : null,
      busName: bus is Map ? bus['busName']?.toString() : null,
      assignedBy: assignedBy is Map
          ? (assignedBy['userName'] ?? 'Admin')
          : assignedBy?.toString() ?? 'Admin',
      notes: json['notes']?.toString(),
      driverResponse: json['driverResponse']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      depotId: depot is Map
          ? (depot['_id'] ?? depot['id'] ?? '').toString()
          : depot?.toString(),
      depotName: depot is Map ? depot['name']?.toString() : null,
      depotCode: depot is Map ? depot['code']?.toString() : null,
    );
  }

  RouteAssignment copyWith({
    RouteStatus? status,
    String? statusRaw,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    String? driverResponse,
    String? depotId,
    String? depotName,
    String? depotCode,
  }) {
    return RouteAssignment(
      id: id,
      driverId: driverId,
      busId: busId,
      statusRaw: statusRaw ?? this.statusRaw,
      status: status ?? this.status,
      scheduledDate: scheduledDate,
      scheduledTime: scheduledTime,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      routeId: routeId,
      fromLocation: fromLocation,
      toLocation: toLocation,
      departureTime: departureTime,
      arrivalTime: arrivalTime,
      busNumber: busNumber,
      busName: busName,
      assignedBy: assignedBy,
      notes: notes ?? this.notes,
      driverResponse: driverResponse ?? this.driverResponse,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      depotId: depotId ?? this.depotId,
      depotName: depotName ?? this.depotName,
      depotCode: depotCode ?? this.depotCode,
    );
  }

  bool get isPending => status == RouteStatus.pending;
  bool get isAccepted => status == RouteStatus.accepted;
  bool get isRejected => status == RouteStatus.rejected;
  bool get isCompleted => status == RouteStatus.completed;

  String get formattedDate =>
      DateFormat('dd MMM yyyy').format(scheduledDate.toLocal());

  String get formattedStartTime {
    if (startTime != null) {
      return DateFormat('hh:mm a').format(startTime!.toLocal());
    }
    return scheduledTime;
  }

  String? get depotLabel {
    final hasName = (depotName ?? '').isNotEmpty;
    final hasCode = (depotCode ?? '').isNotEmpty;

    if (!hasName && !hasCode) return null;
    if (!hasCode) return depotName;
    if (!hasName) return depotCode;
    return "$depotCode • $depotName";
  }
}

enum RouteStatus { pending, accepted, rejected, completed }

extension RouteStatusExtension on RouteStatus {
  static RouteStatus fromString(String? value) {
    switch ((value ?? '').toLowerCase()) {
      case 'accepted':
        return RouteStatus.accepted;
      case 'rejected':
        return RouteStatus.rejected;
      case 'completed':
        return RouteStatus.completed;
      default:
        return RouteStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case RouteStatus.pending:
        return 'Pending';
      case RouteStatus.accepted:
        return 'Accepted';
      case RouteStatus.rejected:
        return 'Rejected';
      case RouteStatus.completed:
        return 'Completed';
    }
  }

  String get hexColor {
    switch (this) {
      case RouteStatus.pending:
        return '#FFA726';
      case RouteStatus.accepted:
        return '#2E7D32';
      case RouteStatus.rejected:
        return '#D32F2F';
      case RouteStatus.completed:
        return '#1976D2';
    }
  }
}
