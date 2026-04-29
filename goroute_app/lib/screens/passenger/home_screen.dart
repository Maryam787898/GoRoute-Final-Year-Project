import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:goroute_app/models/driver_location_model.dart';
import 'package:goroute_app/services/location_service.dart';
import 'package:goroute_app/screens/passenger/bus_tracking_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MapController _mapController = MapController();
  final LocationService _locationService = LocationService();

  static const LatLng _defaultCenter = LatLng(31.5204, 74.3587);

  List<DriverLocationModel> _liveDrivers = [];
  StreamSubscription<QuerySnapshot>? _locationSub;

  @override
  void initState() {
    super.initState();
    _subscribeToLiveLocations();
  }

  void _subscribeToLiveLocations() {
    _locationSub = _locationService.liveLocationsStream().listen((snapshot) {
      if (!mounted) return;
      setState(() {
        _liveDrivers =
            snapshot.docs
                .map((doc) => DriverLocationModel.fromDoc(doc))
                .toList();
      });
    });
  }

  void _openTracking(DriverLocationModel driver) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => BusTrackingScreen(
              driverId: driver.driverId,
              routeLabel: driver.routeLabel,
            ),
      ),
    );
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ── Full-screen OpenStreetMap ──────────────────────────────────
        // SizedBox.expand gives FlutterMap a bounded constraint inside Stack.
        SizedBox.expand(
          child: FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _defaultCenter,
              initialZoom: 13,
              interactionOptions: InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.goroute_app',
                maxZoom: 19,
              ),

              // Live driver markers
              MarkerLayer(
                markers:
                    _liveDrivers.map((d) {
                      return Marker(
                        point: LatLng(d.lat, d.lng),
                        width: 56,
                        height: 56,
                        child: GestureDetector(
                          onTap: () => _openTracking(d),
                          child: _BusMarker(label: d.driverName),
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ), // close SizedBox.expand
        // ── Search bar ─────────────────────────────────────────────────
        Positioned(
          top: 56,
          left: 16,
          right: 16,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(30),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search routes or stops…',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF8B0000)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ),

        // ── Live bus count badge ───────────────────────────────────────
        if (_liveDrivers.isNotEmpty)
          Positioned(
            top: 116,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.circle, size: 8, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    '${_liveDrivers.length} bus${_liveDrivers.length > 1 ? 'es' : ''} live',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // ── Draggable bottom sheet ─────────────────────────────────────
        DraggableScrollableSheet(
          initialChildSize: 0.28,
          minChildSize: 0.14,
          maxChildSize: 0.75,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Active Buses',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${_liveDrivers.length} online',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        _liveDrivers.isEmpty
                            ? _emptyState()
                            : ListView.separated(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              itemCount: _liveDrivers.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 4),
                              itemBuilder:
                                  (context, index) =>
                                      _driverTile(_liveDrivers[index]),
                            ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_bus_outlined,
            size: 48,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 8),
          Text(
            'No buses online right now',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _driverTile(DriverLocationModel d) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFF8B0000),
          child: Icon(Icons.directions_bus, color: Colors.white, size: 18),
        ),
        title: Text(
          d.routeLabel,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          '${d.speed.toStringAsFixed(0)} km/h  •  ${d.driverName}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Live',
            style: TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () => _openTracking(d),
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
