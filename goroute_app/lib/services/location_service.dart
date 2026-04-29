import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

/// Handles GPS permission, continuous location streaming,
/// and writing driver location to Firestore.
/// Uses geolocator — works on Android, iOS, and Flutter Web.
class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  StreamSubscription<Position>? _positionSubscription;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Permission ────────────────────────────────────────────────────────

  Future<bool> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return false;
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // ── One-shot current position ─────────────────────────────────────────

  Future<Position?> getCurrentPosition() async {
    final granted = await requestPermission();
    if (!granted) return null;
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  // ── Start continuous tracking (driver) ───────────────────────────────

  void startTracking({
    required String driverId,
    required String driverName,
    required String routeId,
    required String routeLabel,
  }) {
    _positionSubscription?.cancel();

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10, // update every 10 metres
    );

    // Mark driver as online
    _db.collection('users').doc(driverId).update({
      'isOnline': true,
      'lastActive': FieldValue.serverTimestamp(),
    });

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((Position pos) {
      _db.collection('live_locations').doc(driverId).set({
        'driverName': driverName,
        'routeId': routeId,
        'routeLabel': routeLabel,
        'lat': pos.latitude,
        'lng': pos.longitude,
        'speed': (pos.speed * 3.6).clamp(0.0, 200.0), // m/s → km/h
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ── Stop tracking ─────────────────────────────────────────────────────

  Future<void> stopTracking(String driverId) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    await _db.collection('live_locations').doc(driverId).delete();
    await _db.collection('users').doc(driverId).update({
      'isOnline': false,
      'lastActive': FieldValue.serverTimestamp(),
    });
  }

  // ── Passenger: stream of all live driver locations ────────────────────

  Stream<QuerySnapshot> liveLocationsStream() {
    return _db.collection('live_locations').snapshots();
  }

  // ── Passenger: stream for a single driver ────────────────────────────

  Stream<DocumentSnapshot> driverLocationStream(String driverId) {
    return _db.collection('live_locations').doc(driverId).snapshots();
  }
}
