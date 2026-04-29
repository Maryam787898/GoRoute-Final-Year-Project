import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:goroute_app/services/location_service.dart';

/// Shows the driver's own live position on an OpenStreetMap.
/// GPS is already being pushed to Firestore by LocationService.startTracking().
class DriverMapScreen extends StatefulWidget {
  const DriverMapScreen({super.key});

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  LatLng? _currentPosition;
  double _speed = 0;
  StreamSubscription<Position>? _positionSub;

  static const LatLng _defaultCenter = LatLng(31.5204, 74.3587);

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() async {
    final granted = await _locationService.requestPermission();
    if (!granted) return;

    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );

    _positionSub = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen((Position pos) {
      final latLng = LatLng(pos.latitude, pos.longitude);
      if (mounted) {
        setState(() {
          _currentPosition = latLng;
          _speed = (pos.speed * 3.6).clamp(0.0, 200.0);
        });
        // Animate map to follow driver — guard against map not ready
        try {
          _mapController.move(latLng, _mapController.camera.zoom);
        } catch (_) {
          // Map not ready yet — ignore
        }
      }
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = _currentPosition ?? _defaultCenter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Map'),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // ── OpenStreetMap ──────────────────────────────────────────────
          // SizedBox.expand gives FlutterMap a bounded constraint inside Stack.
          SizedBox.expand(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                // OSM tile layer — no API key required
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.goroute_app',
                  maxZoom: 19,
                ),

                // Driver position marker
                if (_currentPosition != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _currentPosition!,
                        width: 48,
                        height: 48,
                        child: const _BusMarker(label: 'You'),
                      ),
                    ],
                  ),
              ],
            ),
          ), // close SizedBox.expand
          // ── Speed chip ─────────────────────────────────────────────────
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.speed, color: Color(0xFF8B0000), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_speed.toStringAsFixed(0)} km/h',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Loading overlay ────────────────────────────────────────────
          if (_currentPosition == null)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Getting your location…'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── Reusable bus marker widget ────────────────────────────────────────────────

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
          ),
        ),
      ],
    );
  }
}
