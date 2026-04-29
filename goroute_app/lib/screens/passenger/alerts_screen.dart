import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Alert type config ─────────────────────────────────────────────────────────

class _AlertConfig {
  final IconData icon;
  final Color color;
  final String label;
  const _AlertConfig(this.icon, this.color, this.label);
}

const _alertTypes = <String, _AlertConfig>{
  'delay': _AlertConfig(Icons.schedule, Colors.red, 'Delay'),
  'start': _AlertConfig(Icons.play_circle, Colors.green, 'Started'),
  'arrival': _AlertConfig(Icons.location_on, Colors.blue, 'Arrival'),
  'emergency': _AlertConfig(
    Icons.warning_amber_rounded,
    Colors.deepOrange,
    'Emergency',
  ),
  'warning': _AlertConfig(
    Icons.warning_amber_rounded,
    Colors.orange,
    'Warning',
  ),
  'success': _AlertConfig(Icons.check_circle, Colors.green, 'Success'),
  'error': _AlertConfig(Icons.error, Colors.red, 'Error'),
  'info': _AlertConfig(Icons.info, Colors.blue, 'Info'),
  'bus_delay': _AlertConfig(Icons.schedule, Colors.red, 'Delay'),
  'bus_start': _AlertConfig(Icons.play_circle, Colors.green, 'Started'),
  'bus_arrival': _AlertConfig(Icons.location_on, Colors.blue, 'Arrival'),
  'bus_emergency': _AlertConfig(
    Icons.warning_amber_rounded,
    Colors.deepOrange,
    'Emergency',
  ),
  'driver_support': _AlertConfig(Icons.support_agent, Colors.purple, 'Support'),
  'passenger_feedback': _AlertConfig(Icons.feedback, Colors.indigo, 'Feedback'),
  'admin_reply': _AlertConfig(Icons.reply, Colors.teal, 'Reply'),
  'driver_added': _AlertConfig(Icons.person_add, Colors.purple, 'Driver'),
};

_AlertConfig _cfgFor(String type) =>
    _alertTypes[type.toLowerCase()] ??
    const _AlertConfig(Icons.notifications, Colors.blueGrey, 'Alert');

// ── Alert model ───────────────────────────────────────────────────────────────

class _Alert {
  final String id;
  final String title;
  final String message;
  final String type;
  final String? busId;
  final DateTime? time;
  final bool isUnread;
  final DocumentReference ref;

  const _Alert({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.busId,
    this.time,
    required this.isUnread,
    required this.ref,
  });

  factory _Alert.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final ts = d['timestamp'] ?? d['createdAt'];
    DateTime? time;
    if (ts != null) {
      try {
        time = (ts as Timestamp).toDate();
      } catch (_) {}
    }
    return _Alert(
      id: doc.id,
      title: d['title'] as String? ?? 'Alert',
      message: d['message'] as String? ?? '',
      type: d['type'] as String? ?? 'info',
      busId: d['busId'] as String?,
      time: time,
      isUnread: d['readStatus'] != true,
      ref: doc.reference,
    );
  }
}

// ── Screen ────────────────────────────────────────────────────────────────────

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  final _db = FirebaseFirestore.instance;
  StreamSubscription? _sub;
  List<_Alert> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _subscribe();
  }

  void _subscribe() {
    // Read ONLY from bus_alerts — single source of truth.
    // BusAlerts.tsx writes here; no duplicates.
    _sub = _db
        .collection('bus_alerts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
          (snap) {
            if (!mounted) return;
            setState(() {
              _alerts = snap.docs.map((d) => _Alert.fromDoc(d)).toList();
              _loading = false;
            });
          },
          onError: (e) {
            if (mounted) setState(() => _loading = false);
          },
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Alerts & Notifications'),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _alerts.isEmpty
              ? _emptyState()
              : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _alerts.length,
                itemBuilder: (context, i) {
                  final alert = _alerts[i];
                  return _AlertCard(
                    alert: alert,
                    onTap: () {
                      alert.ref.update({'readStatus': true}).catchError((_) {});
                      _showDetail(context, alert);
                    },
                  );
                },
              ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No alerts right now',
            style: TextStyle(fontSize: 17, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Alerts sent by admin will appear here',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, _Alert alert) {
    final cfg = _cfgFor(alert.type);
    showDialog(
      context: context,
      builder:
          (ctx) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: cfg.color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(cfg.icon, color: cfg.color, size: 28),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    alert.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    alert.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  if (alert.busId != null && alert.busId!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.directions_bus,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Bus: ${alert.busId}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
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
                        backgroundColor: cfg.color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(fontWeight: FontWeight.bold),
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

// ── Alert card ────────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final _Alert alert;
  final VoidCallback onTap;

  const _AlertCard({required this.alert, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cfg = _cfgFor(alert.type);
    final timeLabel = _timeAgo(alert.time);

    return Card(
      elevation: alert.isUnread ? 3 : 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              alert.isUnread
                  ? cfg.color.withValues(alpha: 0.5)
                  : Colors.transparent,
          width: alert.isUnread ? 1.5 : 0,
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: cfg.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(cfg.icon, color: cfg.color, size: 22),
              ),
              const SizedBox(width: 12),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            alert.title,
                            style: TextStyle(
                              fontWeight:
                                  alert.isUnread
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (alert.isUnread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: cfg.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      alert.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        // Type badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: cfg.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            cfg.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: cfg.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (alert.busId != null && alert.busId!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.directions_bus,
                            size: 12,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            alert.busId!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Text(
                          timeLabel,
                          style: TextStyle(
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
    );
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
