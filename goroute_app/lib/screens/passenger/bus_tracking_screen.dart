import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'package:goroute_app/models/driver_location_model.dart';
import 'package:goroute_app/services/location_service.dart';
import 'package:goroute_app/services/eta_service.dart';
import 'package:goroute_app/services/eta_alert_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BusTrackingScreen
//
// Shows on a single map:
//   • Passenger's live GPS location  (blue pulsing marker)
//   • Driver's live Firestore location (maroon bus marker)
//   • Straight-line polyline between them
//   • Distance (km / m) + ETA card
//   • In-app proximity alerts at 2 km, 1 km, 500 m, arrival
// ─────────────────────────────────────────────────────────────────────────────

class BusTrackingScreen extends StatefulWidget {
  final String driverId;
  final String? routeLabel;

  const BusTrackingScreen({super.key, required this.driverId, this.routeLabel});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen>
    with TickerProviderStateMixin {
  // ── Services ────────────────────────────────────────────────────────────────
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  // ── Driver state ─────────────────────────────────────────────────────────
  DriverLocationModel? _driverData;
  StreamSubscription<DocumentSnapshot>? _driverSub;
  bool _driverOffline = false;

  // ── Passenger state ──────────────────────────────────────────────────────
  LatLng? _passengerLatLng;
  StreamSubscription<Position>? _passengerSub;
  bool _locationPermissionDenied = false;

  // ── Computed ─────────────────────────────────────────────────────────────
  double? _distanceKm;
  int? _etaMinutes;

  // ── Proximity alert tracking ─────────────────────────────────────────────
  // Thresholds in km — each fires once per session
  final Set<String> _firedAlerts = {};

  // ── Map follow mode ──────────────────────────────────────────────────────
  bool _followBus = true;

  // ── Pulse animation for passenger marker ────────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  static const LatLng _defaultCenter = LatLng(31.5204, 74.3587);

  // ── Lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _subscribeToDriver();
    _startPassengerTracking();
  }

  @override
  void dispose() {
    _driverSub?.cancel();
    _passengerSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ── Driver subscription ──────────────────────────────────────────────────

  void _subscribeToDriver() {
    bool startedAlertFired = false;

    _driverSub = _locationService.driverLocationStream(widget.driverId).listen((
      doc,
    ) {
      if (!doc.exists) {
        if (mounted) setState(() => _driverOffline = true);
        return;
      }
      final data = DriverLocationModel.fromDoc(doc);

      // Skip placeholder (0,0) written before first GPS fix
      final isPlaceholder = data.lat == 0.0 && data.lng == 0.0;

      // Alert 1 — fire "Driver started" once when we first get real data
      if (!isPlaceholder && !startedAlertFired) {
        startedAlertFired = true;
        if (!_firedAlerts.contains('started')) {
          _firedAlerts.add('started');
          EtaAlertService.fireDriverStarted(
            driverName: data.driverName,
            routeLabel: data.routeLabel,
          );
        }
      }

      if (mounted) {
        setState(() {
          _driverData = isPlaceholder ? _driverData : data;
          _driverOffline = false;
        });
        if (!isPlaceholder) {
          unawaited(_recalculate());
          if (_followBus) _moveMapToBus();
        }
      }
    });
  }

  // ── Passenger GPS tracking ───────────────────────────────────────────────

  Future<void> _startPassengerTracking() async {
    final granted = await _locationService.requestPermission();
    if (!granted) {
      if (mounted) setState(() => _locationPermissionDenied = true);
      return;
    }

    // Get immediate fix first
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    if (mounted) {
      setState(() => _passengerLatLng = LatLng(pos.latitude, pos.longitude));
      unawaited(_recalculate());
    }

    // Then stream updates every 15 m
    _passengerSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 15,
      ),
    ).listen((pos) {
      if (mounted) {
        setState(() => _passengerLatLng = LatLng(pos.latitude, pos.longitude));
        unawaited(_recalculate());
      }
    });
  }

  // ── Distance + ETA calculation ───────────────────────────────────────────

  Future<void> _recalculate() async {
    if (_passengerLatLng == null || _driverData == null) return;

    final driverLatLng = LatLng(_driverData!.lat, _driverData!.lng);

    // Straight-line distance (always available, used for proximity alerts)
    final dist = ETAService.calculateDistanceKm(
      _passengerLatLng!,
      driverLatLng,
    );

    // AI/traffic-aware ETA — uses Google Directions API if key is set,
    // falls back to Haversine + driver speed automatically
    final speed = _driverData!.speed > 5 ? _driverData!.speed : 30.0;
    final eta = await ETAService.calculateETASmart(
      _passengerLatLng!,
      driverLatLng,
      currentDriverSpeed: speed,
    );

    if (mounted) {
      setState(() {
        _distanceKm = dist;
        _etaMinutes = eta;
      });
    }

    _checkProximityAlerts(dist);
  }

  // ── Proximity alerts ─────────────────────────────────────────────────────
  // Exactly 2 alerts per tracking session:
  //   • Alert 2: Bus within 1 km  (fires once)
  //   • Alert 3: Bus arrived      (fires once at ≤50 m)

  void _checkProximityAlerts(double distKm) {
    final driverName = _driverData?.driverName ?? 'Driver';
    final distM = distKm * 1000;

    // Alert 3 — arrived (≤50 m)
    if (distM <= 50 && !_firedAlerts.contains('arrived')) {
      _firedAlerts.add('arrived');
      EtaAlertService.fireArrived(driverName: driverName);
      _showProximityBanner(
        '✅ Bus has arrived!',
        '$driverName is at your stop. Board now!',
        Colors.green,
      );
    }
    // Alert 2 — within 1 km (only if arrived hasn't fired yet)
    else if (distKm <= 1.0 && !_firedAlerts.contains('1km')) {
      _firedAlerts.add('1km');
      EtaAlertService.fireWithin1km(driverName: driverName);
      _showProximityBanner(
        '📍 Bus is within 1 km',
        '$driverName is less than 1 km away. Head to your stop!',
        const Color(0xFF8B0000),
      );
    }
  }

  void _showProximityBanner(String title, String body, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            const Icon(Icons.notifications_active, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    body,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Map helpers ──────────────────────────────────────────────────────────

  void _moveMapToBus() {
    if (_driverData == null) return;
    try {
      _mapController.move(
        LatLng(_driverData!.lat, _driverData!.lng),
        _mapController.camera.zoom,
      );
    } catch (_) {}
  }

  void _fitBothMarkers() {
    if (_passengerLatLng == null || _driverData == null) return;
    final bounds = LatLngBounds.fromPoints([
      _passengerLatLng!,
      LatLng(_driverData!.lat, _driverData!.lng),
    ]);
    try {
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(80)),
      );
    } catch (_) {}
  }

  // ── Distance display string ──────────────────────────────────────────────

  String get _distanceLabel {
    if (_distanceKm == null) return '—';
    final m = _distanceKm! * 1000;
    if (m < 1000) return '${m.toStringAsFixed(0)} m';
    return '${_distanceKm!.toStringAsFixed(2)} km';
  }

  String get _etaLabel {
    if (_etaMinutes == null) return '—';
    if (_etaMinutes! <= 0) return 'Arrived';
    if (_etaMinutes! < 1) return 'Less than 1 min';
    return '$_etaMinutes min';
  }

  String get _statusLabel {
    if (_driverOffline) return 'Offline';
    if (_distanceKm == null) return 'Locating…';
    final m = _distanceKm! * 1000;
    if (m <= 50) return 'Arrived';
    if (m <= 500) return 'Nearby';
    if (_distanceKm! <= 1) return 'Approaching';
    return 'En Route';
  }

  Color get _statusColor {
    switch (_statusLabel) {
      case 'Arrived':
        return Colors.green;
      case 'Nearby':
        return Colors.orange;
      case 'Approaching':
        return const Color(0xFF8B0000);
      case 'Offline':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final label =
        _driverData?.routeLabel ?? widget.routeLabel ?? 'Tracking Bus';
    final busLatLng =
        _driverData != null ? LatLng(_driverData!.lat, _driverData!.lng) : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────
          SizedBox.expand(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: busLatLng ?? _passengerLatLng ?? _defaultCenter,
                initialZoom: 15,
                onPositionChanged: (_, hasGesture) {
                  if (hasGesture && _followBus) {
                    setState(() => _followBus = false);
                  }
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                // OSM tiles
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.goroute_app',
                  maxZoom: 19,
                ),

                // Route line between passenger and bus
                if (_passengerLatLng != null && busLatLng != null)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [_passengerLatLng!, busLatLng],
                        color: const Color(0xFF8B0000),
                        strokeWidth: 3.0,
                        pattern: StrokePattern.dashed(segments: const [12, 6]),
                      ),
                    ],
                  ),

                // Markers
                MarkerLayer(
                  markers: [
                    // Passenger marker
                    if (_passengerLatLng != null)
                      Marker(
                        point: _passengerLatLng!,
                        width: 52,
                        height: 52,
                        child: _PassengerMarker(pulseAnim: _pulseAnim),
                      ),

                    // Bus marker
                    if (busLatLng != null)
                      Marker(
                        point: busLatLng,
                        width: 60,
                        height: 60,
                        child: _BusMarker(
                          label: _driverData?.driverName ?? 'Bus',
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ── App bar ──────────────────────────────────────────────────
          Positioned(top: 0, left: 0, right: 0, child: _buildAppBar(label)),

          // ── Permission denied banner ─────────────────────────────────
          if (_locationPermissionDenied)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: _buildBanner(
                icon: Icons.location_off,
                message:
                    'Location permission denied. Enable it in Settings to see your position.',
                color: Colors.orange.shade700,
              ),
            ),

          // ── Driver offline banner ────────────────────────────────────
          if (_driverOffline)
            Positioned(
              top: _locationPermissionDenied ? 160 : 100,
              left: 16,
              right: 16,
              child: _buildBanner(
                icon: Icons.wifi_off,
                message: 'Driver has gone offline.',
                color: Colors.grey.shade700,
              ),
            ),

          // ── Connecting spinner ───────────────────────────────────────
          if (_driverData == null && !_driverOffline)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF8B0000)),
                  SizedBox(height: 12),
                  Text('Connecting to bus…'),
                ],
              ),
            ),

          // ── Fit-both FAB ─────────────────────────────────────────────
          Positioned(
            bottom: 260,
            right: 16,
            child: Column(
              children: [
                _MapFab(
                  icon: Icons.fit_screen,
                  tooltip: 'Fit both',
                  onTap: () {
                    setState(() => _followBus = false);
                    _fitBothMarkers();
                  },
                ),
                const SizedBox(height: 10),
                _MapFab(
                  icon: _followBus ? Icons.gps_fixed : Icons.gps_not_fixed,
                  tooltip: _followBus ? 'Following bus' : 'Follow bus',
                  color: _followBus ? const Color(0xFF8B0000) : Colors.grey,
                  onTap: () {
                    setState(() => _followBus = !_followBus);
                    if (_followBus) _moveMapToBus();
                  },
                ),
              ],
            ),
          ),

          // ── Bottom info card ─────────────────────────────────────────
          if (_driverData != null)
            Positioned(bottom: 0, left: 0, right: 0, child: _buildInfoCard()),
        ],
      ),
    );
  }

  // ── App bar ───────────────────────────────────────────────────────────────

  Widget _buildAppBar(String label) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF8B0000), Color(0xFFB71C1C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                _driverOffline
                                    ? Colors.grey
                                    : Colors.greenAccent,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _driverOffline ? 'Offline' : 'Live',
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 11,
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

  // ── Info card ─────────────────────────────────────────────────────────────

  Widget _buildInfoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              children: [
                // ── Stats row ────────────────────────────────────────
                Row(
                  children: [
                    _StatChip(
                      icon: Icons.straighten,
                      label: 'Distance',
                      value: _distanceLabel,
                      color: const Color(0xFF8B0000),
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      icon: Icons.access_time_filled,
                      label: 'ETA',
                      value: _etaLabel,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 10),
                    _StatChip(
                      icon: Icons.speed,
                      label: 'Speed',
                      value: '${_driverData!.speed.toStringAsFixed(0)} km/h',
                      color: Colors.green.shade700,
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),

                // ── Driver info row ──────────────────────────────────
                Row(
                  children: [
                    // Avatar
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B0000),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Name + route
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _driverData!.driverName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            _driverData!.routeLabel,
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, size: 7, color: _statusColor),
                          const SizedBox(width: 4),
                          Text(
                            _statusLabel,
                            style: GoogleFonts.poppins(
                              color: _statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
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
        ],
      ),
    );
  }

  // ── Banner helper ─────────────────────────────────────────────────────────

  Widget _buildBanner({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.poppins(color: Colors.white, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Passenger marker — pulsing blue dot
// ─────────────────────────────────────────────────────────────────────────────

class _PassengerMarker extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _PassengerMarker({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pulseAnim,
      builder:
          (_, __) => Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulse ring
              Container(
                width: 44 * pulseAnim.value,
                height: 44 * pulseAnim.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withValues(alpha: 0.18 * pulseAnim.value),
                ),
              ),
              // Inner dot
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.shade600,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bus marker — maroon circle with bus icon + name label
// ─────────────────────────────────────────────────────────────────────────────

class _BusMarker extends StatelessWidget {
  final String label;
  const _BusMarker({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: Color(0xFF8B0000),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bus,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: Color(0xFF8B0000),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat chip — distance / ETA / speed tile
// ─────────────────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map FAB button
// ─────────────────────────────────────────────────────────────────────────────

class _MapFab extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color color;

  const _MapFab({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color = const Color(0xFF8B0000),
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 22),
        ),
      ),
    );
  }
}
