import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:goroute_app/models/route_model.dart';
import 'package:goroute_app/services/location_service.dart';
import 'package:goroute_app/services/route_service.dart';
import 'package:goroute_app/screens/driver/add_route_screen.dart';
import 'package:goroute_app/screens/driver/driver_help_support_screen.dart';
import 'package:goroute_app/screens/driver/trip_history_screen.dart';

/// Driver's home dashboard — shows status, active route, quick actions.
class DriverDashboardHome extends StatefulWidget {
  const DriverDashboardHome({super.key});

  @override
  State<DriverDashboardHome> createState() => _DriverDashboardHomeState();
}

class _DriverDashboardHomeState extends State<DriverDashboardHome> {
  final _routeService = RouteService();
  final _locationService = LocationService();

  User get _user => FirebaseAuth.instance.currentUser!;

  bool _togglingActive = false;

  // ── Toggle the currently active route on/off ──────────────────────────
  // Only ONE route can be active at a time.
  // Activating a route automatically deactivates any other active route.

  Future<void> _toggleRoute(RouteModel route) async {
    setState(() => _togglingActive = true);
    try {
      final newActive = !route.isActive;

      if (newActive) {
        // ── Going Active ──────────────────────────────────────────────
        final granted = await _locationService.requestPermission();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission required.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        // Deactivate any other currently active route for this driver
        final existing =
            await FirebaseFirestore.instance
                .collection('routes')
                .where('driverId', isEqualTo: _user.uid)
                .where('isActive', isEqualTo: true)
                .get();

        for (final doc in existing.docs) {
          if (doc.id != route.id) {
            await _routeService.setRouteActive(doc.id, false);
          }
        }

        // Stop any existing GPS tracking before starting fresh
        await _locationService.stopTracking(_user.uid);

        // Activate the selected route
        await _routeService.setRouteActive(route.id, true);
        _locationService.startTracking(
          driverId: _user.uid,
          driverName: _user.displayName ?? _user.email ?? 'Driver',
          routeId: route.id,
          routeLabel: '${route.from} → ${route.to}',
        );
      } else {
        // ── Going Inactive ────────────────────────────────────────────
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
      if (mounted) setState(() => _togglingActive = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not authenticated')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: StreamBuilder<QuerySnapshot>(
        stream: _routeService.driverRoutesStream(currentUser.uid),
        builder: (context, snapshot) {
          final rawDocs = snapshot.hasData ? snapshot.data!.docs : [];
          final routes =
              rawDocs.map((d) => RouteModel.fromDoc(d as dynamic)).toList();
          routes.sort((a, b) {
            final aT = a.createdAt ?? DateTime(0);
            final bT = b.createdAt ?? DateTime(0);
            return bT.compareTo(aT);
          });

          final activeRoute =
              routes.where((r) => r.isActive).isEmpty
                  ? null
                  : routes.where((r) => r.isActive).first;
          final totalRoutes = routes.length;

          return CustomScrollView(
            slivers: [
              // ── App bar ──────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 160,
                pinned: true,
                automaticallyImplyLeading: false,
                backgroundColor: const Color(0xFF8B0000),
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF8B0000), Color(0xFFB71C1C)],
                      ),
                    ),
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.2,
                                  ),
                                  child: Text(
                                    (currentUser.displayName ??
                                            currentUser.email ??
                                            'D')
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Welcome back,',
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        currentUser.displayName ??
                                            currentUser.email ??
                                            'Driver',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Online status badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        activeRoute != null
                                            ? Colors.green
                                            : Colors.white.withValues(
                                              alpha: 0.2,
                                            ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 8,
                                        color:
                                            activeRoute != null
                                                ? Colors.white
                                                : Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        activeRoute != null
                                            ? 'Online'
                                            : 'Offline',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Stats row ──────────────────────────────────
                      Row(
                        children: [
                          _statCard(
                            icon: Icons.route,
                            label: 'My Routes',
                            value: '$totalRoutes',
                            color: const Color(0xFF8B0000),
                          ),
                          const SizedBox(width: 12),
                          _statCard(
                            icon: Icons.check_circle,
                            label: 'Active Now',
                            value: activeRoute != null ? '1' : '0',
                            color:
                                activeRoute != null
                                    ? Colors.green
                                    : Colors.grey,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Active route card ──────────────────────────
                      if (activeRoute != null) ...[
                        const Text(
                          'Active Route',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _ActiveRouteCard(
                          route: activeRoute,
                          isToggling: _togglingActive,
                          onToggle: () => _toggleRoute(activeRoute),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // ── Quick actions ──────────────────────────────
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.6,
                        children: [
                          _actionCard(
                            icon: Icons.add_road,
                            label: 'Add Route',
                            color: const Color(0xFF8B0000),
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddRouteScreen(),
                                  ),
                                ),
                          ),
                          _actionCard(
                            icon: Icons.map_outlined,
                            label: 'Live Map',
                            color: Colors.blue.shade700,
                            onTap:
                                () =>
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Switch to Live Map tab below',
                                        ),
                                      ),
                                    ),
                          ),
                          _actionCard(
                            icon: Icons.history,
                            label: 'Trip History',
                            color: Colors.orange.shade700,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const TripHistoryScreen(),
                                  ),
                                ),
                          ),
                          _actionCard(
                            icon: Icons.help_outline,
                            label: 'Support',
                            color: Colors.teal,
                            onTap:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => const DriverHelpSupportScreen(),
                                  ),
                                ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── All routes list ────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Routes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          TextButton.icon(
                            onPressed:
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AddRouteScreen(),
                                  ),
                                ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF8B0000),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (snapshot.connectionState == ConnectionState.waiting)
                        const Center(child: CircularProgressIndicator())
                      else if (routes.isEmpty)
                        _emptyRoutes()
                      else
                        ...routes.map(
                          (route) => _RouteListItem(
                            route: route,
                            isToggling: _togglingActive,
                            onToggle: () => _toggleRoute(route),
                          ),
                        ),

                      // ── Recent trips preview ───────────────────────
                      const SizedBox(height: 20),
                      _RecentTripsPreview(uid: currentUser.uid),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyRoutes() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.route_outlined, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No routes yet',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddRouteScreen()),
                ),
            icon: const Icon(Icons.add),
            label: const Text('Add Your First Route'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B0000),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active route card ─────────────────────────────────────────────────────────

class _ActiveRouteCard extends StatelessWidget {
  final RouteModel route;
  final bool isToggling;
  final VoidCallback onToggle;

  const _ActiveRouteCard({
    required this.route,
    required this.isToggling,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B0000), Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B0000).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_bus, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${route.from} → ${route.to}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'Live',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            route.estimatedTime,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isToggling ? null : onToggle,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF8B0000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
              child:
                  isToggling
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text(
                        'Stop Trip',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Route list item ───────────────────────────────────────────────────────────

class _RouteListItem extends StatelessWidget {
  final RouteModel route;
  final bool isToggling;
  final VoidCallback onToggle;

  const _RouteListItem({
    required this.route,
    required this.isToggling,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side:
            route.isActive
                ? const BorderSide(color: Colors.green, width: 1.5)
                : BorderSide.none,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF8B0000).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.directions_bus,
            color: Color(0xFF8B0000),
            size: 20,
          ),
        ),
        title: Text(
          '${route.from} → ${route.to}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          route.estimatedTime,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing:
            isToggling
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                : Switch(
                  value: route.isActive,
                  onChanged: (_) => onToggle(),
                  activeColor: const Color(0xFF8B0000),
                ),
      ),
    );
  }
}

// ── Recent Trips Preview ──────────────────────────────────────────────────────

class _RecentTripsPreview extends StatelessWidget {
  final String uid;
  const _RecentTripsPreview({required this.uid});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Trips',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            TextButton(
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TripHistoryScreen(),
                    ),
                  ),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8B0000),
              ),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('trips')
                  .where('driverId', isEqualTo: uid)
                  .orderBy('startTime', descending: true)
                  .limit(3)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    'No trips yet. Complete a route to see history.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
              );
            }

            final trips =
                snapshot.data!.docs.map((d) => TripModel.fromDoc(d)).toList();

            return Column(
              children: trips.map((trip) => _MiniTripCard(trip: trip)).toList(),
            );
          },
        ),
      ],
    );
  }
}

// ── Mini trip card for dashboard preview ─────────────────────────────────────

class _MiniTripCard extends StatelessWidget {
  final TripModel trip;
  const _MiniTripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    switch (trip.status.toLowerCase()) {
      case 'completed':
        statusColor = Colors.green;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.orange;
    }

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF8B0000).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.directions_bus,
            color: Color(0xFF8B0000),
            size: 18,
          ),
        ),
        title: Text(
          trip.routeName,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${trip.startLocation} → ${trip.endLocation}',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                trip.status[0].toUpperCase() + trip.status.substring(1),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              trip.durationLabel,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
        onTap:
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip)),
            ),
      ),
    );
  }
}
