import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EtaAlertService  —  exactly 3 alert types, no spam
//
// Alert 1: Driver started trip       (type: 'driver_start')
// Alert 2: Bus is within 1 km        (type: 'driver_approaching')
// Alert 3: Bus has arrived           (type: 'driver_arrived')
//
// All stored in: passengers/{uid}/notifications/{autoId}
// Each fires ONCE per tracking session — enforced by the caller.
// ─────────────────────────────────────────────────────────────────────────────

class EtaAlertService {
  static final _db = FirebaseFirestore.instance;

  // ── Type constants ────────────────────────────────────────────────────────
  static const String typeStarted = 'driver_start';
  static const String typeApproaching = 'driver_approaching';
  static const String typeArrived = 'driver_arrived';

  // ── Core write ────────────────────────────────────────────────────────────

  static Future<void> fire({
    required String title,
    required String message,
    required String type,
    String? driverName,
    String? routeLabel,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      await _db
          .collection('passengers')
          .doc(uid)
          .collection('notifications')
          .add({
            'title': title,
            'message': message,
            'type': type,
            if (driverName != null) 'driverName': driverName,
            if (routeLabel != null) 'routeLabel': routeLabel,
            'readStatus': false,
            'timestamp': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      debugPrint('[EtaAlertService] fire error: $e');
    }
  }

  // ── 3 alert helpers ───────────────────────────────────────────────────────

  /// Alert 1 — fired when driver taps "Go Active"
  static Future<void> fireDriverStarted({
    required String driverName,
    required String routeLabel,
  }) => fire(
    title: '🚌 Driver started the trip',
    message: '$driverName has started: $routeLabel',
    type: typeStarted,
    driverName: driverName,
    routeLabel: routeLabel,
  );

  /// Alert 2 — fired once when bus comes within 1 km
  static Future<void> fireWithin1km({required String driverName}) => fire(
    title: '📍 Bus is within 1 km',
    message: '$driverName is less than 1 km away. Head to your stop!',
    type: typeApproaching,
    driverName: driverName,
  );

  /// Alert 3 — fired once when bus arrives (within 50 m)
  static Future<void> fireArrived({required String driverName}) => fire(
    title: '✅ Bus has arrived!',
    message: '$driverName is at your stop. Board now!',
    type: typeArrived,
    driverName: driverName,
  );

  // ── Read helpers ──────────────────────────────────────────────────────────

  static Stream<QuerySnapshot> notificationsStream(String uid) {
    return _db
        .collection('passengers')
        .doc(uid)
        .collection('notifications')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  static Stream<int> unreadCountStream(String uid) {
    return _db
        .collection('passengers')
        .doc(uid)
        .collection('notifications')
        .where('readStatus', isEqualTo: false)
        .snapshots()
        .map((s) => s.docs.length);
  }

  // ── Write helpers ─────────────────────────────────────────────────────────

  static Future<void> markRead(String uid, String notifId) async {
    try {
      await _db
          .collection('passengers')
          .doc(uid)
          .collection('notifications')
          .doc(notifId)
          .update({'readStatus': true});
    } catch (e) {
      debugPrint('[EtaAlertService] markRead error: $e');
    }
  }

  static Future<void> markAllRead(String uid) async {
    try {
      final snap =
          await _db
              .collection('passengers')
              .doc(uid)
              .collection('notifications')
              .where('readStatus', isEqualTo: false)
              .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.update(doc.reference, {'readStatus': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[EtaAlertService] markAllRead error: $e');
    }
  }

  static Future<void> delete(String uid, String notifId) async {
    try {
      await _db
          .collection('passengers')
          .doc(uid)
          .collection('notifications')
          .doc(notifId)
          .delete();
    } catch (e) {
      debugPrint('[EtaAlertService] delete error: $e');
    }
  }

  static Future<void> clearAll(String uid) async {
    try {
      final snap =
          await _db
              .collection('passengers')
              .doc(uid)
              .collection('notifications')
              .get();
      final batch = _db.batch();
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      debugPrint('[EtaAlertService] clearAll error: $e');
    }
  }
}
