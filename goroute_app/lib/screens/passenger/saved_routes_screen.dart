import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goroute_app/screens/passenger/bus_tracking_screen.dart';

// ── Saved Route Model ─────────────────────────────────────────────────────────

class SavedRoute {
  final String id;
  final String routeId;
  final String from;
  final String to;
  final String driverName;
  final String estimatedTime;
  final String driverId;
  final DateTime? savedAt;

  const SavedRoute({
    required this.id,
    required this.routeId,
    required this.from,
    required this.to,
    required this.driverName,
    required this.estimatedTime,
    required this.driverId,
    this.savedAt,
  });

  factory SavedRoute.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return SavedRoute(
      id: doc.id,
      routeId: d['routeId'] as String? ?? '',
      from: d['from'] as String? ?? '',
      to: d['to'] as String? ?? '',
      driverName: d['driverName'] as String? ?? 'Unknown Driver',
      estimatedTime: d['estimatedTime'] as String? ?? '',
      driverId: d['driverId'] as String? ?? '',
      savedAt: (d['savedAt'] as Timestamp?)?.toDate(),
    );
  }

  String get routeLabel => '$from → $to';
}

// ── Service helpers ───────────────────────────────────────────────────────────

class SavedRoutesService {
  static final _db = FirebaseFirestore.instance;

  /// Save a route for the current user. Prevents duplicates.
  static Future<bool> saveRoute({
    required String userId,
    required String routeId,
    required String from,
    required String to,
    required String driverName,
    required String estimatedTime,
    required String driverId,
  }) async {
    // Check for duplicate
    final existing =
        await _db
            .collection('users')
            .doc(userId)
            .collection('saved_routes')
            .where('routeId', isEqualTo: routeId)
            .limit(1)
            .get();

    if (existing.docs.isNotEmpty) return false; // already saved

    await _db.collection('users').doc(userId).collection('saved_routes').add({
      'routeId': routeId,
      'from': from,
      'to': to,
      'driverName': driverName,
      'estimatedTime': estimatedTime,
      'driverId': driverId,
      'savedAt': FieldValue.serverTimestamp(),
    });
    return true;
  }

  /// Delete a saved route by its document id.
  static Future<void> deleteRoute(String userId, String docId) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('saved_routes')
        .doc(docId)
        .delete();
  }

  /// Real-time stream of saved routes for a user.
  static Stream<QuerySnapshot> stream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('saved_routes')
        .orderBy('savedAt', descending: true)
        .snapshots();
  }
}

// ── Saved Routes Screen ───────────────────────────────────────────────────────

class SavedRoutesScreen extends StatelessWidget {
  const SavedRoutesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Saved Routes'),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: SavedRoutesService.stream(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            // Composite index may be needed
            return _IndexNote();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _EmptyState();
          }

          final routes =
              snapshot.data!.docs.map((d) => SavedRoute.fromDoc(d)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: routes.length,
            itemBuilder: (context, i) {
              final route = routes[i];
              return _SavedRouteCard(
                route: route,
                onDelete: () => _confirmDelete(context, uid, route),
                onTrack:
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => BusTrackingScreen(
                              driverId: route.driverId,
                              routeLabel: route.routeLabel,
                            ),
                      ),
                    ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, String uid, SavedRoute route) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Remove Saved Route'),
            content: Text('Remove "${route.routeLabel}" from saved routes?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await SavedRoutesService.deleteRoute(uid, route.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Route removed')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Remove',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }
}

// ── Saved route card ──────────────────────────────────────────────────────────

class _SavedRouteCard extends StatelessWidget {
  final SavedRoute route;
  final VoidCallback onDelete;
  final VoidCallback onTrack;

  const _SavedRouteCard({
    required this.route,
    required this.onDelete,
    required this.onTrack,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: const Color(0xFF8B0000).withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B0000).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.bookmark,
                    color: Color(0xFF8B0000),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.routeLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Driver: ${route.driverName}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Remove',
                ),
              ],
            ),

            if (route.estimatedTime.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    route.estimatedTime,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onTrack,
                icon: const Icon(Icons.location_on, size: 16),
                label: const Text('Track Live'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B0000),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bookmark_border, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No saved routes yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Start exploring and save your favourite routes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

class _IndexNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: Colors.orange.shade300),
            const SizedBox(height: 12),
            const Text(
              'Index Required',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a Firestore composite index on '
              'users/{uid}/saved_routes:\n'
              '• savedAt (Descending)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
