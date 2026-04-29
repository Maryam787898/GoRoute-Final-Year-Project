import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:goroute_app/models/notification_model.dart';
import 'package:goroute_app/services/eta_alert_service.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  List<NotificationModel> _all = [];
  bool _loading = true;
  StreamSubscription? _personalSub;
  final Map<String, NotificationModel> _map = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _subscribe();
    });
  }

  @override
  void dispose() {
    _personalSub?.cancel();
    super.dispose();
  }

  // ── Subscriptions ─────────────────────────────────────────────────────────

  void _subscribe() {
    // Only source: per-passenger notifications subcollection
    if (_uid == null) {
      setState(() => _loading = false);
      return;
    }
    _personalSub = EtaAlertService.notificationsStream(_uid).listen((snap) {
      _map.clear();
      for (final doc in snap.docs) {
        _map[doc.id] = NotificationModel.fromDoc(doc);
      }
      _rebuild();
    });
  }

  void _rebuild() {
    if (!mounted) return;
    final sorted =
        _map.values.toList()..sort((a, b) {
          final at = a.time ?? DateTime(0);
          final bt = b.time ?? DateTime(0);
          return bt.compareTo(at);
        });
    setState(() {
      _all = sorted;
      _loading = false;
    });
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  int get _unreadCount => _all.where((n) => !n.isRead).length;

  Future<void> _markAllRead() async {
    if (_uid == null) return;
    await EtaAlertService.markAllRead(_uid);
    setState(() {
      for (final key in _map.keys.toList()) {
        final n = _map[key];
        if (n != null && !n.isRead) {
          _map[key] = NotificationModel(
            id: n.id,
            title: n.title,
            message: n.message,
            type: n.type,
            busId: n.busId,
            driverName: n.driverName,
            routeLabel: n.routeLabel,
            time: n.time,
            isRead: true,
            ref: n.ref,
          );
        }
      }
      _rebuild();
    });
  }

  Future<void> _clearAll() async {
    final ok = await _confirm(
      title: 'Clear All Notifications',
      message: 'This will permanently delete all your notifications.',
      confirmLabel: 'Clear All',
      confirmColor: Colors.red,
    );
    if (!ok) return;
    if (_uid != null) await EtaAlertService.clearAll(_uid);
    // Clear local map completely so the list empties immediately
    setState(() {
      _map.clear();
      _all = [];
    });
  }

  Future<void> _deleteOne(NotificationModel n, String mapKey) async {
    if (_uid != null) await EtaAlertService.delete(_uid, n.id);
    setState(() {
      _map.remove(mapKey);
      _rebuild();
    });
  }

  Future<void> _markOneRead(NotificationModel n, String mapKey) async {
    if (_uid != null) await EtaAlertService.markRead(_uid, n.id);
    n.ref.update({'readStatus': true}).catchError((_) {});
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(message, style: GoogleFonts.poppins(fontSize: 14)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(confirmLabel, style: GoogleFonts.poppins()),
              ),
            ],
          ),
    );
    return result ?? false;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final unread = _unreadCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Text(
              'Notifications',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            if (unread > 0) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$unread',
                  style: GoogleFonts.poppins(
                    color: const Color(0xFF8B0000),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unread > 0)
            IconButton(
              icon: const Icon(Icons.done_all, color: Colors.white),
              tooltip: 'Mark all as read',
              onPressed: _markAllRead,
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onSelected: (v) {
              if (v == 'clear') _clearAll();
            },
            itemBuilder:
                (_) => [
                  PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_sweep,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Clear all',
                          style: GoogleFonts.poppins(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body:
          _loading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF8B0000)),
              )
              : _all.isEmpty
              ? _emptyState()
              : RefreshIndicator(
                color: const Color(0xFF8B0000),
                onRefresh:
                    () async =>
                        Future.delayed(const Duration(milliseconds: 600)),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                  itemCount: _all.length,
                  itemBuilder: (context, i) {
                    final notif = _all[i];
                    final mapKey =
                        _map.entries
                            .firstWhere(
                              (e) => e.value.id == notif.id,
                              orElse: () => MapEntry(notif.id, notif),
                            )
                            .key;

                    return _NotifCard(
                      notification: notif,
                      onTap: () {
                        _markOneRead(notif, mapKey);
                        _showDetail(notif);
                      },
                      onDismissed: () => _deleteOne(notif, mapKey),
                    );
                  },
                ),
              ),
    );
  }

  // ── Empty state ───────────────────────────────────────────────────────────

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'No notifications yet',
              style: GoogleFonts.poppins(
                fontSize: 17,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Alerts will appear here when your bus is nearby.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Detail dialog ─────────────────────────────────────────────────────────

  void _showDetail(NotificationModel n) {
    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: n.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(n.icon, color: n.color, size: 30),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: n.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      n.categoryLabel.toUpperCase(),
                      style: GoogleFonts.poppins(
                        color: n.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    n.title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    n.message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
                  ),
                  if (n.driverName != null || n.routeLabel != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          if (n.driverName != null)
                            _DetailRow(
                              icon: Icons.person,
                              label: 'Driver',
                              value: n.driverName!,
                            ),
                          if (n.routeLabel != null)
                            _DetailRow(
                              icon: Icons.route,
                              label: 'Route',
                              value: n.routeLabel!,
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (n.time != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 13,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          n.fullTimeLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: n.color,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Got it',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NotifCard
// ─────────────────────────────────────────────────────────────────────────────

class _NotifCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const _NotifCard({
    required this.notification,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final n = notification;

    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete, color: Colors.white, size: 26),
            SizedBox(height: 4),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      onDismissed: (_) => onDismissed(),
      child: Card(
        elevation: n.isRead ? 1 : 3,
        margin: const EdgeInsets.only(bottom: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color:
                n.isRead ? Colors.transparent : n.color.withValues(alpha: 0.4),
            width: n.isRead ? 0 : 1.5,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: n.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(n.icon, color: n.color, size: 22),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + unread dot
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              n.title,
                              style: GoogleFonts.poppins(
                                fontWeight:
                                    n.isRead
                                        ? FontWeight.w500
                                        : FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                          if (!n.isRead)
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: n.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),

                      // Message
                      Text(
                        n.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Footer: category badge + driver + time
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: n.color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              n.categoryLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: n.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (n.driverName != null) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.person,
                              size: 11,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(width: 2),
                            Flexible(
                              child: Text(
                                n.driverName!,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ],
                          const Spacer(),
                          Text(
                            n.timeAgo,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DetailRow
// ─────────────────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
