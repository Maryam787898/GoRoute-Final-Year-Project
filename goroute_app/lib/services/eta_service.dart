import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Calculates ETA and distance between two GPS coordinates.
/// Uses the Haversine formula — no external API, works fully offline.
class ETAService {
  // ── ETA ────────────────────────────────────────────────────────────────────

  /// Returns ETA in minutes.
  /// Uses [averageSpeedKmH] (defaults to 30 km/h if driver speed unavailable).
  static int calculateETA(
    LatLng start,
    LatLng end, {
    double averageSpeedKmH = 30,
  }) {
    if (averageSpeedKmH <= 0) averageSpeedKmH = 30;
    final distance = calculateDistanceKm(start, end);
    final timeHours = distance / averageSpeedKmH;
    return (timeHours * 60).round();
  }

  // ── Distance ───────────────────────────────────────────────────────────────

  /// Returns straight-line distance in kilometres (Haversine formula).
  static double calculateDistanceKm(LatLng start, LatLng end) {
    const double p = 0.017453292519943295; // π / 180
    final a =
        0.5 -
        cos((end.latitude - start.latitude) * p) / 2 +
        cos(start.latitude * p) *
            cos(end.latitude * p) *
            (1 - cos((end.longitude - start.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a)); // 2 × R; R = 6371 km
  }

  /// Returns straight-line distance in metres.
  static double calculateDistanceMeters(LatLng start, LatLng end) {
    return calculateDistanceKm(start, end) * 1000;
  }

  // ── Human-readable label ───────────────────────────────────────────────────

  /// Returns a display string: "500 m" below 1 km, "2.40 km" above.
  static String distanceLabel(LatLng start, LatLng end) {
    final km = calculateDistanceKm(start, end);
    final m = km * 1000;
    if (m < 1000) return '${m.toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(2)} km';
  }

  /// Returns a human-readable ETA string.
  /// e.g. "Arrived", "Less than 1 min", "6 min"
  static String etaLabel(LatLng start, LatLng end, {double speedKmH = 30}) {
    final minutes = calculateETA(start, end, averageSpeedKmH: speedKmH);
    if (minutes <= 0) return 'Arrived';
    if (minutes < 1) return 'Less than 1 min';
    return '$minutes min';
  }
}
