import 'package:cloud_firestore/cloud_firestore.dart';

class RouteModel {
  final String id;
  final String driverId;
  final String driverName;
  final String from;
  final String to;
  final String estimatedTime;
  final bool isActive;
  final DateTime? createdAt;

  const RouteModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.from,
    required this.to,
    required this.estimatedTime,
    required this.isActive,
    this.createdAt,
  });

  factory RouteModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RouteModel(
      id: doc.id,
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'] ?? 'Unknown Driver',
      from: data['from'] ?? '',
      to: data['to'] ?? '',
      estimatedTime: data['estimatedTime'] ?? data['time'] ?? '',
      isActive: data['isActive'] ?? false,
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
    'createdAt': FieldValue.serverTimestamp(),
  };
}
