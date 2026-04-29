import 'package:cloud_firestore/cloud_firestore.dart';

class DriverLocationModel {
  final String driverId;
  final String driverName;
  final String routeId;
  final String routeLabel; // "From → To"
  final double lat;
  final double lng;
  final double speed; // km/h
  final DateTime? updatedAt;

  const DriverLocationModel({
    required this.driverId,
    required this.driverName,
    required this.routeId,
    required this.routeLabel,
    required this.lat,
    required this.lng,
    required this.speed,
    this.updatedAt,
  });

  factory DriverLocationModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DriverLocationModel(
      driverId: doc.id,
      driverName: data['driverName'] ?? 'Driver',
      routeId: data['routeId'] ?? '',
      routeLabel: data['routeLabel'] ?? '',
      lat: (data['lat'] as num?)?.toDouble() ?? 0.0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0.0,
      speed: (data['speed'] as num?)?.toDouble() ?? 0.0,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'driverName': driverName,
    'routeId': routeId,
    'routeLabel': routeLabel,
    'lat': lat,
    'lng': lng,
    'speed': speed,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
