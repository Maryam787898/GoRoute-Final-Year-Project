import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goroute_app/models/route_model.dart';

/// All Firestore operations for routes.
class RouteService {
  static final RouteService _instance = RouteService._internal();
  factory RouteService() => _instance;
  RouteService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── Driver: add a new route (inactive by default) ─────────────────────

  Future<String> addRoute(RouteModel route) async {
    final ref = await _db.collection('routes').add(route.toMap());
    return ref.id;
  }

  // ── Driver: toggle active/inactive ───────────────────────────────────

  Future<void> setRouteActive(String routeId, bool isActive) async {
    await _db.collection('routes').doc(routeId).update({'isActive': isActive});
  }

  // ── Driver: stream of their own routes ───────────────────────────────
  // No compound index needed — single-field where + client-side sort.

  Stream<QuerySnapshot> driverRoutesStream(String driverId) {
    return _db
        .collection('routes')
        .where('driverId', isEqualTo: driverId)
        .snapshots();
  }

  // ── Passenger: stream of ONLY active routes ───────────────────────────
  // Single-field filter only — no composite index required.

  Stream<QuerySnapshot> activeRoutesStream() {
    return _db
        .collection('routes')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  // ── Delete a route ────────────────────────────────────────────────────

  Future<void> deleteRoute(String routeId) async {
    await _db.collection('routes').doc(routeId).delete();
  }
}
