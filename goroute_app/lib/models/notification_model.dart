import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NotificationCategory — used for tab filtering
// ─────────────────────────────────────────────────────────────────────────────

enum NotificationCategory { all, eta, driver, delay, system }

extension NotificationCategoryExt on NotificationCategory {
  String get label {
    switch (this) {
      case NotificationCategory.all:
        return 'All';
      case NotificationCategory.eta:
        return 'ETA';
      case NotificationCategory.driver:
        return 'Driver';
      case NotificationCategory.delay:
        return 'Delay';
      case NotificationCategory.system:
        return 'System';
    }
  }

  IconData get icon {
    switch (this) {
      case NotificationCategory.all:
        return Icons.notifications;
      case NotificationCategory.eta:
        return Icons.access_time_filled;
      case NotificationCategory.driver:
        return Icons.directions_bus;
      case NotificationCategory.delay:
        return Icons.schedule;
      case NotificationCategory.system:
        return Icons.info;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NotificationModel
// ─────────────────────────────────────────────────────────────────────────────

class NotificationModel {
  final String id;
  final String title;
  final String message;

  /// Raw type string from Firestore: 'eta_update', 'driver_start',
  /// 'driver_approaching', 'driver_arrived', 'delay', 'start',
  /// 'arrival', 'emergency', 'info', etc.
  final String type;

  final String? busId;
  final String? driverName;
  final String? routeLabel;
  final DateTime? time;
  final bool isRead;
  final DocumentReference ref;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.busId,
    this.driverName,
    this.routeLabel,
    this.time,
    required this.isRead,
    required this.ref,
  });

  // ── Firestore deserialization ─────────────────────────────────────────────

  factory NotificationModel.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final ts = d['timestamp'] ?? d['createdAt'];
    DateTime? time;
    if (ts != null) {
      try {
        time = (ts as Timestamp).toDate();
      } catch (_) {}
    }
    return NotificationModel(
      id: doc.id,
      title: (d['title'] as String?) ?? 'Notification',
      message: (d['message'] as String?) ?? '',
      type: (d['type'] as String?) ?? 'info',
      busId: d['busId'] as String?,
      driverName: d['driverName'] as String?,
      routeLabel: d['routeLabel'] as String?,
      time: time,
      isRead: (d['readStatus'] as bool?) ?? false,
      ref: doc.reference,
    );
  }

  // ── Category mapping ──────────────────────────────────────────────────────

  NotificationCategory get category {
    final t = type.toLowerCase();
    if (t.contains('eta') || t.contains('arriving') || t.contains('arrived')) {
      return NotificationCategory.eta;
    }
    if (t.contains('delay') || t.contains('cancel')) {
      return NotificationCategory.delay;
    }
    if (t.contains('driver') ||
        t.contains('start') ||
        t.contains('route') ||
        t.contains('bus')) {
      return NotificationCategory.driver;
    }
    return NotificationCategory.system;
  }

  // ── Visual config ─────────────────────────────────────────────────────────

  IconData get icon {
    final t = type.toLowerCase();
    if (t.contains('arrived') || t.contains('arrival')) {
      return Icons.location_on;
    }
    if (t.contains('approaching') || t.contains('eta')) {
      return Icons.access_time_filled;
    }
    if (t.contains('start')) return Icons.play_circle;
    if (t.contains('delay') || t.contains('cancel')) return Icons.schedule;
    if (t.contains('emergency')) return Icons.warning_amber_rounded;
    if (t.contains('driver')) return Icons.directions_bus;
    return Icons.notifications;
  }

  Color get color {
    final t = type.toLowerCase();
    if (t.contains('arrived') || t.contains('start')) return Colors.green;
    if (t.contains('approaching') || t.contains('eta')) {
      return const Color(0xFF8B0000);
    }
    if (t.contains('delay') || t.contains('cancel')) return Colors.red;
    if (t.contains('emergency')) return Colors.deepOrange;
    if (t.contains('warning')) return Colors.orange;
    return Colors.blueGrey;
  }

  String get categoryLabel {
    switch (category) {
      case NotificationCategory.eta:
        return 'ETA Update';
      case NotificationCategory.driver:
        return 'Driver Alert';
      case NotificationCategory.delay:
        return 'Delay';
      case NotificationCategory.system:
        return 'System';
      default:
        return 'Alert';
    }
  }

  // ── Time formatting ───────────────────────────────────────────────────────

  String get timeAgo {
    if (time == null) return '';
    final diff = DateTime.now().difference(time!);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }

  String get fullTimeLabel {
    if (time == null) return '';
    final h = time!.hour.toString().padLeft(2, '0');
    final m = time!.minute.toString().padLeft(2, '0');
    final day = time!.day.toString().padLeft(2, '0');
    final month = time!.month.toString().padLeft(2, '0');
    return '$day/$month/${time!.year}  $h:$m';
  }
}
