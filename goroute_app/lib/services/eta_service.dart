import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Calculates ETA and distance between two coordinates using the Haversine formula.
/// No external API or API key required — works offline.
class ETAService {
  /// Returns ETA in minutes based on straight-line distance and average speed.
  static int calculateETA(
    LatLng start,
    LatLng end, {
    double averageSpeedKmH = 30,
  }) {
    final distance = calculateDistanceKm(start, end);
    final timeHours = distance / averageSpeedKmH;
    return (timeHours * 60).round();
  }

  /// Returns straight-line distance in kilometres using the Haversine formula.
  static double calculateDistanceKm(LatLng start, LatLng end) {
    const double p = 0.017453292519943295; // π / 180
    final a =
        0.5 -
        cos((end.latitude - start.latitude) * p) / 2 +
        cos(start.latitude * p) *
            cos(end.latitude * p) *
            (1 - cos((end.longitude - start.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}
