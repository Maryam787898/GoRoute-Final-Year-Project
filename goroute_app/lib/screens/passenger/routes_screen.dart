import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:goroute_app/models/route_model.dart';
import 'package:goroute_app/models/driver_location_model.dart';
import 'package:goroute_app/services/route_service.dart';
import 'package:goroute_app/services/location_service.dart';
import 'package:goroute_app/services/eta_service.dart';
import 'package:goroute_app/screens/passenger/bus_tracking_screen.dart';
import 'package:goroute_app/screens/passenger/saved_routes_screen.dart';

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Routes'),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.directions_bus, size: 18), text: 'Active'),
            Tab(icon: Icon(Icons.bookmark, size: 18), text: 'Saved'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [_ActiveRoutesTab(), _SavedRoutesTab()],
      ),
    );
  }
}

// ── Active Routes Tab ─────────────────────────────────────────────────────────

class _ActiveRoutesTab extends StatefulWidget {
  const _ActiveRoutesTab();

  @override
  State<_ActiveRoutesTab> createState() => _ActiveRoutesTabState();
}

class _ActiveRoutesTabState extends State<_ActiveRoutesTab> {
  LatLng? _passengerLatLng;
  StreamSubscription<Position>? _posSub;

  @override
  void initState() {
    super.initState();
    _startPassengerLocation();
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }

  Future<void> _startPassengerLocation() async {
    final granted = await LocationService().requestPermission();
    if (!granted) return;

    // One-shot fix first
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() => _passengerLatLng = LatLng(pos.latitude, pos.longitude));
      }
    } catch (_) {}

    // Then stream updates every 20 m
    _posSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 20,
      ),
    ).listen((pos) {
      if (mounted) {
        setState(() => _passengerLatLng = LatLng(pos.latitude, pos.longitude));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: RouteService().activeRoutesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF8B0000)),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final routes =
            (snapshot.data?.docs ?? [])
                .map((doc) => RouteModel.fromDoc(doc))
                .where((r) => r.isLive)
                .toList()
              ..sort((a, b) {
                final aT = a.createdAt ?? DateTime(0);
                final bT = b.createdAt ?? DateTime(0);
                return bT.compareTo(aT);
              });

        if (routes.isEmpty) return _EmptyActiveRoutes();

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: routes.length,
          itemBuilder:
              (context, i) => _ActiveRouteCard(
                route: routes[i],
                passengerLatLng: _passengerLatLng,
              ),
        );
      },
    );
  }
}
// ── Active route card ─────────────────────────────────────────────────────────

class _ActiveRouteCard extends StatefulWidget {
  final RouteModel route;
  final LatLng? passengerLatLng;

  const _ActiveRouteCard({required this.route, this.passengerLatLng});

  @override
  State<_ActiveRouteCard> createState() => _ActiveRouteCardState();
}

class _ActiveRouteCardState extends State<_ActiveRouteCard> {
  bool _saving = false;

  // Live driver location for this route
  DriverLocationModel? _driverLoc;
  StreamSubscription<DocumentSnapshot>? _driverSub;

  @override
  void initState() {
    super.initState();
    _driverSub = LocationService()
        .driverLocationStream(widget.route.driverId)
        .listen((doc) {
          if (!doc.exists || !mounted) return;
          final data = DriverLocationModel.fromDoc(doc);
          // Skip placeholder (0,0)
          if (data.lat == 0.0 && data.lng == 0.0) return;
          setState(() => _driverLoc = data);
        });
  }

  @override
  void dispose() {
    _driverSub?.cancel();
    super.dispose();
  }

  // ── Distance + ETA ────────────────────────────────────────────────────

  String get _distanceLabel {
    if (widget.passengerLatLng == null || _driverLoc == null) return '';
    final dist = ETAService.calculateDistanceKm(
      widget.passengerLatLng!,
      LatLng(_driverLoc!.lat, _driverLoc!.lng),
    );
    final m = dist * 1000;
    return m < 1000
        ? '${m.toStringAsFixed(0)} m'
        : '${dist.toStringAsFixed(1)} km';
  }

  String get _etaLabel {
    if (widget.passengerLatLng == null || _driverLoc == null) return '';
    final speed = _driverLoc!.speed > 5 ? _driverLoc!.speed : 30.0;
    final eta = ETAService.calculateETA(
      widget.passengerLatLng!,
      LatLng(_driverLoc!.lat, _driverLoc!.lng),
      averageSpeedKmH: speed,
    );
    if (eta <= 0) return 'Arrived';
    return '$eta min';
  }

  Future<void> _saveRoute() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      final saved = await SavedRoutesService.saveRoute(
        userId: uid,
        routeId: widget.route.id,
        from: widget.route.from,
        to: widget.route.to,
        driverName: widget.route.driverName,
        estimatedTime: widget.route.estimatedTime,
        driverId: widget.route.driverId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            saved ? 'Route saved successfully!' : 'Route already saved.',
          ),
          backgroundColor: saved ? Colors.green : Colors.orange,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final dist = _distanceLabel;
    final eta = _etaLabel;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.green, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
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
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Driver: ${route.driverName}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Active badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: Colors.green),
                      SizedBox(width: 4),
                      Text(
                        'Live',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // ── Live distance + ETA chips ────────────────────────────────
            if (dist.isNotEmpty || eta.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  if (dist.isNotEmpty) ...[
                    const Icon(
                      Icons.straighten,
                      size: 13,
                      color: Color(0xFF8B0000),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dist,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8B0000),
                      ),
                    ),
                    const SizedBox(width: 14),
                  ],
                  if (eta.isNotEmpty) ...[
                    Icon(
                      Icons.access_time,
                      size: 13,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'ETA $eta',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                  if (_driverLoc != null) ...[
                    const SizedBox(width: 14),
                    Icon(Icons.speed, size: 13, color: Colors.green.shade700),
                    const SizedBox(width: 4),
                    Text(
                      '${_driverLoc!.speed.toStringAsFixed(0)} km/h',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ] else if (route.estimatedTime.isNotEmpty) ...[
              const SizedBox(height: 10),
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
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 14),

            // ── Action buttons ───────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _saveRoute,
                    icon:
                        _saving
                            ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(Icons.bookmark_add_outlined, size: 16),
                    label: const Text('Save'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8B0000),
                      side: const BorderSide(color: Color(0xFF8B0000)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => BusTrackingScreen(
                                  driverId: route.driverId,
                                  routeLabel: '${route.from} → ${route.to}',
                                ),
                          ),
                        ),
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
          ],
        ),
      ),
    );
  }
}

// ── Saved Routes Tab ──────────────────────────────────────────────────────────

class _SavedRoutesTab extends StatelessWidget {
  const _SavedRoutesTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: SavedRoutesService.stream(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Error loading saved routes.\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _EmptySavedRoutes();
        }

        final routes =
            snapshot.data!.docs.map((d) => SavedRoute.fromDoc(d)).toList();

        return ListView.builder(
          padding: const EdgeInsets.all(12),
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
    );
  }

  void _confirmDelete(BuildContext context, String uid, SavedRoute route) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Remove Saved Route'),
            content: Text('Remove "${route.routeLabel}"?'),
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

// ── Saved route card (inline in tab) ─────────────────────────────────────────

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
      margin: const EdgeInsets.symmetric(vertical: 6),
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

// ── Empty states ──────────────────────────────────────────────────────────────

class _EmptyActiveRoutes extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.route_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No active routes right now',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Check back when a driver goes online',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

class _EmptySavedRoutes extends StatelessWidget {
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
              'Tap the bookmark icon on any active route to save it.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
