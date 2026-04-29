import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goroute_app/models/route_model.dart';

/// All Firestore operations for routes.
class RouteService {
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Driver: add a new route ───────────────────────────────────────────

  Future<String> addRoute(RouteModel route) async {
    final ref = await _db.collection('routes').add(route.toMap());
    return ref.id;
  }

  // ── Driver: activate a route ──────────────────────────────────────────
  // Writes both isActive and routeStatus atomically.

  Future<void> setRouteActive(String routeId, bool isActive) async {
    await _db.collection('routes').doc(routeId).update({
      'isActive': isActive,
      'routeStatus': isActive ? 'active' : 'inactive',
    });
  }

  // ── Driver: stream of their own routes ────────────────────────────────

  Stream<QuerySnapshot> driverRoutesStream(String driverId) {
    return _db
        .collection('routes')
        .where('driverId', isEqualTo: driverId)
        .snapshots();
  }

  // ── Passenger: stream of ONLY active routes ───────────────────────────
  // Queries directly on routeStatus == 'active' — the single source of truth.
  // isActive is kept in sync but routeStatus is the authoritative field.

  Stream<QuerySnapshot> activeRoutesStream() {
    return _db
        .collection('routes')
        .where('routeStatus', isEqualTo: 'active')
        .snapshots();
  }

  // ── Driver: deactivate all routes for a driver ────────────────────────
  // Called on stopTracking and on app startup to clean stale state.

  Future<void> deactivateAllRoutesForDriver(String driverId) async {
    try {
      final snap =
          await _db
              .collection('routes')
              .where('driverId', isEqualTo: driverId)
              .where('routeStatus', isEqualTo: 'active')
              .get();

      if (snap.docs.isEmpty) return;

      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {
          'isActive': false,
          'routeStatus': 'inactive',
        });
      }
      await batch.commit();
    } catch (_) {}
  }

  // ── Delete a route ────────────────────────────────────────────────────

  Future<void> deleteRoute(String routeId) async {
    await _db.collection('routes').doc(routeId).delete();
  }
}
