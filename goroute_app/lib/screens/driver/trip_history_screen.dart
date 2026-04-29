import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Model ─────────────────────────────────────────────────────────────────────

class TripModel {
  final String id;
  final String routeName;
  final String busNumber;
  final DateTime? startTime;
  final DateTime? endTime;
  final String status;
  final String startLocation;
  final String endLocation;
  final double? distanceKm;

  const TripModel({
    required this.id,
    required this.routeName,
    required this.busNumber,
    this.startTime,
    this.endTime,
    required this.status,
    required this.startLocation,
    required this.endLocation,
    this.distanceKm,
  });

  factory TripModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return TripModel(
      id: doc.id,
      routeName: data['routeName']?.toString() ?? 'Unknown Route',
      busNumber: data['busNumber']?.toString() ?? 'N/A',
      startTime:
          data['startTime'] is Timestamp
              ? (data['startTime'] as Timestamp).toDate()
              : null,
      endTime:
          data['endTime'] is Timestamp
              ? (data['endTime'] as Timestamp).toDate()
              : null,
      status: data['status']?.toString() ?? 'completed',
      startLocation: data['startLocation']?.toString() ?? 'Unknown',
      endLocation: data['endLocation']?.toString() ?? 'Unknown',
      distanceKm:
          data['distanceKm'] != null
              ? (data['distanceKm'] as num).toDouble()
              : null,
    );
  }

  String get durationLabel {
    if (startTime == null || endTime == null) return 'N/A';

    final diff = endTime!.difference(startTime!);
    final hours = diff.inHours;
    final minutes = diff.inMinutes.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

// ── Main Screen ───────────────────────────────────────────────────────────────

class TripHistoryScreen extends StatelessWidget {
  const TripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Trip History"),
          backgroundColor: const Color(0xFF8B0000),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text("Driver not logged in.", style: TextStyle(fontSize: 16)),
        ),
      );
    }

    final uid = currentUser.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Trip History"),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('trips')
                .where('driverId', isEqualTo: uid)
                .orderBy('startTime', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error Handling
          if (snapshot.hasError) {
            debugPrint("Firestore Error: ${snapshot.error}");

            final error = snapshot.error.toString().toLowerCase();

            if (error.contains("index")) {
              return const _IndexNeededState();
            }

            return Center(
              child: Text(
                "Error loading trips:\n${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          // No data
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const _EmptyState();
          }

          // Parse Data
          final trips =
              snapshot.data!.docs.map((doc) => TripModel.fromDoc(doc)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final trip = trips[index];

              return _TripCard(
                trip: trip,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TripDetailScreen(trip: trip),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ── Trip Card ─────────────────────────────────────────────────────────────────

class _TripCard extends StatelessWidget {
  final TripModel trip;
  final VoidCallback onTap;

  const _TripCard({required this.trip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(trip.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.directions_bus, color: Color(0xFF8B0000)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      trip.routeName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  _StatusBadge(status: trip.status, color: statusColor),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      "Bus: ${trip.busNumber}",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    trip.durationLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.green.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      trip.startLocation,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(Icons.flag, color: Colors.red.shade600, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      trip.endLocation,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'in_progress':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

// ── Status Badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  final Color color;

  const _StatusBadge({required this.status, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// ── Detail Screen ─────────────────────────────────────────────────────────────

class TripDetailScreen extends StatelessWidget {
  final TripModel trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Trip Details"),
        backgroundColor: const Color(0xFF8B0000),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detail("Route", trip.routeName),
            _detail("Bus Number", trip.busNumber),
            _detail("Start Location", trip.startLocation),
            _detail("End Location", trip.endLocation),
            _detail("Status", trip.status),
            _detail(
              "Distance",
              trip.distanceKm != null ? "${trip.distanceKm} km" : "N/A",
            ),
            _detail("Duration", trip.durationLabel),
          ],
        ),
      ),
    );
  }

  Widget _detail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            "No trips found",
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            "Completed driver trips will appear here.",
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// ── Index Required State ──────────────────────────────────────────────────────

class _IndexNeededState extends StatelessWidget {
  const _IndexNeededState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 60, color: Colors.orange.shade300),
            const SizedBox(height: 16),
            const Text(
              "Firestore Index Required",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Please create composite index:\n\n'
              'Collection: trips\n'
              'driverId → Ascending\n'
              'startTime → Descending',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
