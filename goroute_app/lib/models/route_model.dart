import 'package:cloud_firestore/cloud_firestore.dart';

class RouteModel {
  final String id;
  final String driverId;
  final String driverName;
  final String from;
  final String to;
  final String estimatedTime;
  final bool isActive;

  /// Explicit status string: 'active' | 'inactive' | 'completed' | 'cancelled'
  /// Falls back to isActive if not set (backwards compatible).
  final String routeStatus;

  final DateTime? createdAt;

  const RouteModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.from,
    required this.to,
    required this.estimatedTime,
    required this.isActive,
    required this.routeStatus,
    this.createdAt,
  });

  /// A route is visible to passengers only when it is explicitly active.
  bool get isLive => routeStatus == 'active' && isActive;

  factory RouteModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final active = (data['isActive'] as bool?) ?? false;
    return RouteModel(
      id: doc.id,
      driverId: (data['driverId'] as String?) ?? '',
      driverName: (data['driverName'] as String?) ?? 'Unknown Driver',
      from: (data['from'] as String?) ?? '',
      to: (data['to'] as String?) ?? '',
      estimatedTime:
          (data['estimatedTime'] as String?) ?? (data['time'] as String?) ?? '',
      isActive: active,
      // Backwards compatible: if routeStatus not set, derive from isActive
      routeStatus:
          (data['routeStatus'] as String?) ?? (active ? 'active' : 'inactive'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'driverId': driverId,
    'driverName': driverName,
    'from': from,
    'to': to,
    'estimatedTime': estimatedTime,
    'isActive': isActive,
    'routeStatus': routeStatus,
    'createdAt': FieldValue.serverTimestamp(),
  };
}
