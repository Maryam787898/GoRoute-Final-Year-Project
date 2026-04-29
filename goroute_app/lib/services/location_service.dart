import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:goroute_app/services/route_service.dart';

/// Handles GPS permission, continuous location streaming,
/// and writing driver location to Firestore.
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
  // Writes to live_locations IMMEDIATELY (before first GPS fix) so the
  // passenger Routes screen shows this driver the instant they go active.

  void startTracking({
    required String driverId,
    required String driverName,
    required String routeId,
    required String routeLabel,
  }) {
    _positionSubscription?.cancel();

    // Mark driver online
    _db.collection('users').doc(driverId).update({
      'isOnline': true,
      'lastActive': FieldValue.serverTimestamp(),
    });

    // Write placeholder immediately — passengers see the route right away
    _db.collection('live_locations').doc(driverId).set({
      'driverName': driverName,
      'routeId': routeId,
      'routeLabel': routeLabel,
      'routeStatus': 'active',
      'lat': 0.0,
      'lng': 0.0,
      'speed': 0.0,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Stream real GPS updates every 10 m
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen((Position pos) {
      _db.collection('live_locations').doc(driverId).set({
        'driverName': driverName,
        'routeId': routeId,
        'routeLabel': routeLabel,
        'routeStatus': 'active',
        'lat': pos.latitude,
        'lng': pos.longitude,
        'speed': (pos.speed * 3.6).clamp(0.0, 200.0),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ── Stop tracking ─────────────────────────────────────────────────────

  Future<void> stopTracking(String driverId) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    // Delete live location — passengers no longer see this driver
    await _db.collection('live_locations').doc(driverId).delete();

    // Mark driver offline
    await _db.collection('users').doc(driverId).update({
      'isOnline': false,
      'lastActive': FieldValue.serverTimestamp(),
    });

    // Deactivate all active routes for this driver
    await RouteService().deactivateAllRoutesForDriver(driverId);
  }

  // ── Passenger: stream of ACTIVE live driver locations only ────────────
  // Filters by routeStatus == 'active' so stale/placeholder docs are excluded.

  Stream<QuerySnapshot> liveLocationsStream() {
    return _db
        .collection('live_locations')
        .where('routeStatus', isEqualTo: 'active')
        .snapshots();
  }

  // ── Passenger: stream for a single driver ────────────────────────────

  Stream<DocumentSnapshot> driverLocationStream(String driverId) {
    return _db.collection('live_locations').doc(driverId).snapshots();
  }
}
