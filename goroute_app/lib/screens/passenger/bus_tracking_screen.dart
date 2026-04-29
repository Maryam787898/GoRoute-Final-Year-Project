import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:goroute_app/models/driver_location_model.dart';
import 'package:goroute_app/services/location_service.dart';

/// Real-time bus tracking screen for passengers.
/// Listens to Firestore live_locations/{driverId} and updates the map marker.
class BusTrackingScreen extends StatefulWidget {
  final String driverId;
  final String? routeLabel;

  const BusTrackingScreen({super.key, required this.driverId, this.routeLabel});

  @override
  State<BusTrackingScreen> createState() => _BusTrackingScreenState();
}

class _BusTrackingScreenState extends State<BusTrackingScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  DriverLocationModel? _driverData;
  StreamSubscription<DocumentSnapshot>? _locationSub;
  bool _driverOffline = false;

  static const LatLng _defaultCenter = LatLng(31.5204, 74.3587);

  @override
  void initState() {
    super.initState();
    _subscribeToDriver();
  }

  void _subscribeToDriver() {
    _locationSub = _locationService
        .driverLocationStream(widget.driverId)
        .listen((doc) {
          if (!doc.exists) {
            if (mounted) setState(() => _driverOffline = true);
            return;
          }

          final data = DriverLocationModel.fromDoc(doc);
          if (mounted) {
            setState(() {
              _driverData = data;
              _driverOffline = false;
            });
            // Animate map to follow bus — only if map is ready
            try {
              _mapController.move(
                LatLng(data.lat, data.lng),
                _mapController.camera.zoom,
              );
            } catch (_) {
              // Map not ready yet — ignore
            }
          }
        });
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label =
        _driverData?.routeLabel ?? widget.routeLabel ?? 'Tracking Bus';

    final busLatLng =
        _driverData != null ? LatLng(_driverData!.lat, _driverData!.lng) : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(label),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // ── OpenStreetMap ────────────────────────────────────────────
          // SizedBox.expand ensures FlutterMap has a bounded height in Stack.
          SizedBox.expand(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: busLatLng ?? _defaultCenter,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.goroute_app',
                  maxZoom: 19,
                ),

                // Bus marker
                if (busLatLng != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: busLatLng,
                        width: 56,
                        height: 56,
                        child: _BusMarker(
                          label: _driverData?.driverName ?? 'Bus',
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ), // close SizedBox.expand
          // ── Driver offline banner ────────────────────────────────────
          if (_driverOffline)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade700,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.white),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Driver has gone offline',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Connecting state ─────────────────────────────────────────
          if (_driverData == null && !_driverOffline)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Connecting to bus…'),
                ],
              ),
            ),

          // ── Info card at bottom ──────────────────────────────────────
          if (_driverData != null)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.speed,
                            color: Colors.blue,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Speed',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            Text(
                              '${_driverData!.speed.toStringAsFixed(0)} km/h',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
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
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Color(0xFF8B0000),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _driverData!.driverName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Bus marker widget ─────────────────────────────────────────────────────────

class _BusMarker extends StatelessWidget {
  final String label;
  const _BusMarker({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: Color(0xFF8B0000),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_bus,
            color: Colors.white,
            size: 20,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
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
