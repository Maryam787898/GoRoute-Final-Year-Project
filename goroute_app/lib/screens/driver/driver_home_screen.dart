import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goroute_app/models/route_model.dart';
import 'package:goroute_app/services/location_service.dart';
import 'package:goroute_app/services/route_service.dart';
import 'package:goroute_app/screens/driver/add_route_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  final _routeService = RouteService();
  final _locationService = LocationService();

  // Safe: read currentUser inside methods, not at field-init time.
  User get _user => FirebaseAuth.instance.currentUser!;

  // routeId → loading flag
  final Map<String, bool> _loadingToggles = {};

  // ── Toggle Active / Inactive ──────────────────────────────────────────

  Future<void> _toggleRoute(RouteModel route) async {
    setState(() => _loadingToggles[route.id] = true);

    try {
      final newActive = !route.isActive;

      if (newActive) {
        // Ask for GPS permission before marking active
        final granted = await _locationService.requestPermission();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission required to go active.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        // Mark route active in Firestore
        await _routeService.setRouteActive(route.id, true);
        // Start pushing GPS to live_locations
        _locationService.startTracking(
          driverId: _user.uid,
          driverName: _user.displayName ?? _user.email ?? 'Driver',
          routeId: route.id,
          routeLabel: '${route.from} → ${route.to}',
        );
      } else {
        // Stop GPS first, then mark inactive
        await _locationService.stopTracking(_user.uid);
        await _routeService.setRouteActive(route.id, false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingToggles.remove(route.id));
    }
  }

  // ── Delete route ──────────────────────────────────────────────────────

  Future<void> _deleteRoute(RouteModel route) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Route'),
            content: Text('Delete "${route.from} → ${route.to}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      if (route.isActive) await _locationService.stopTracking(_user.uid);
      await _routeService.deleteRoute(route.id);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Guard: if somehow user is null, show error instead of crashing
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('My Routes'),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddRouteScreen()),
            ),
        backgroundColor: const Color(0xFF8B0000),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Route', style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _routeService.driverRoutesStream(currentUser.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading routes: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.route_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No routes yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap + Add Route to create your first route',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          // Sort client-side by createdAt descending (avoids composite index)
          final routes =
              snapshot.data!.docs.map((doc) => RouteModel.fromDoc(doc)).toList()
                ..sort((a, b) {
                  final aTime = a.createdAt ?? DateTime(0);
                  final bTime = b.createdAt ?? DateTime(0);
                  return bTime.compareTo(aTime);
                });

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: routes.length,
            itemBuilder: (context, index) {
              final route = routes[index];
              final isToggling = _loadingToggles.containsKey(route.id);
              return _RouteCard(
                route: route,
                isToggling: isToggling,
                onToggle: () => _toggleRoute(route),
                onDelete: () => _deleteRoute(route),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Route card widget ─────────────────────────────────────────────────────

class _RouteCard extends StatelessWidget {
  final RouteModel route;
  final bool isToggling;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _RouteCard({
    required this.route,
    required this.isToggling,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            route.isActive
                ? const BorderSide(color: Colors.green, width: 1.5)
                : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B0000).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: Color(0xFF8B0000),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${route.from} → ${route.to}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        route.estimatedTime,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Status + toggle row
            Row(
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        route.isActive
                            ? Colors.green.withValues(alpha: 0.12)
                            : Colors.grey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        route.isActive ? Icons.circle : Icons.circle_outlined,
                        size: 10,
                        color: route.isActive ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        route.isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: route.isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Toggle button
                isToggling
                    ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : ElevatedButton(
                      onPressed: onToggle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            route.isActive
                                ? Colors.grey.shade200
                                : const Color(0xFF8B0000),
                        foregroundColor:
                            route.isActive ? Colors.black87 : Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        route.isActive ? 'Go Inactive' : 'Go Active',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
