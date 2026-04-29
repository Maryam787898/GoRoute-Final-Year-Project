import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ETAService
//
// Two-tier ETA system:
//
//   Tier 1 — AI / Traffic-aware (Google Maps Directions API)
//     • Road-following distance (not straight-line)
//     • Live traffic conditions via Google's ML traffic model
//     • Returns duration_in_traffic when departure_time=now
//     • Falls back to Tier 2 on any error or missing API key
//
//   Tier 2 — Offline fallback (Haversine formula)
//     • Straight-line distance × driver speed
//     • No API key, works fully offline
//     • Used when Tier 1 is unavailable
//
// HOW TO ENABLE TIER 1:
//   1. Go to https://console.cloud.google.com
//   2. Enable "Directions API" for your project
//   3. Copy your API key and paste it below
//   4. The app will automatically use traffic-aware ETA
// ─────────────────────────────────────────────────────────────────────────────

class ETAService {
  // ── API key ───────────────────────────────────────────────────────────────
  // Replace with your Google Maps API key to enable AI/traffic-aware ETA.
  // Leave empty to use the offline Haversine fallback only.
  static const String _googleApiKey = '';

  // ── Public API ────────────────────────────────────────────────────────────

  /// Returns ETA in minutes using the best available method.
  ///
  /// If [_googleApiKey] is set, calls Google Directions API with live traffic.
  /// Falls back to Haversine formula if the API call fails or key is missing.
  ///
  /// [currentDriverSpeed] is used only for the Haversine fallback.
  static Future<int> calculateETASmart(
    LatLng origin,
    LatLng destination, {
    double currentDriverSpeed = 30,
  }) async {
    // Try AI/traffic-aware ETA first
    if (_googleApiKey.isNotEmpty) {
      try {
        final aiEta = await _googleDirectionsETA(origin, destination);
        if (aiEta != null) return aiEta;
      } catch (e) {
        debugPrint(
          '[ETAService] Google Directions failed: $e — using fallback',
        );
      }
    }

    // Fallback: Haversine + driver speed
    return calculateETA(
      origin,
      destination,
      averageSpeedKmH: currentDriverSpeed,
    );
  }

  /// Returns road-following distance in km using Google Directions API.
  /// Returns null if the API call fails.
  static Future<double?> calculateRoadDistanceKm(
    LatLng origin,
    LatLng destination,
  ) async {
    if (_googleApiKey.isEmpty) return null;
    try {
      final result = await _fetchDirections(origin, destination);
      if (result == null) return null;
      final meters = result['distance_meters'];
      return meters != null ? meters / 1000.0 : null;
    } catch (_) {
      return null;
    }
  }

  // ── Google Directions API ─────────────────────────────────────────────────

  /// Calls Google Maps Directions API and returns ETA in minutes.
  /// Uses departure_time=now to get traffic-aware duration_in_traffic.
  static Future<int?> _googleDirectionsETA(
    LatLng origin,
    LatLng destination,
  ) async {
    final result = await _fetchDirections(origin, destination);
    if (result == null) return null;

    // Prefer traffic-aware duration, fall back to regular duration
    final seconds =
        result['duration_in_traffic_seconds'] ?? result['duration_seconds'];

    if (seconds == null) return null;
    return (seconds / 60).round();
  }

  /// Fetches a single route from Google Directions API.
  /// Returns a map with distance_meters, duration_seconds,
  /// and duration_in_traffic_seconds (if traffic data available).
  static Future<Map<String, int>?> _fetchDirections(
    LatLng origin,
    LatLng destination,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final uri = Uri.https('maps.googleapis.com', '/maps/api/directions/json', {
      'origin': '${origin.latitude},${origin.longitude}',
      'destination': '${destination.latitude},${destination.longitude}',
      'mode': 'driving',
      'departure_time': '$now', // enables traffic-aware ETA
      'traffic_model': 'best_guess', // Google's ML traffic prediction
      'key': _googleApiKey,
    });

    final response = await http.get(uri).timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      debugPrint('[ETAService] HTTP ${response.statusCode}');
      return null;
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final status = body['status'] as String?;

    if (status != 'OK') {
      debugPrint('[ETAService] Directions API status: $status');
      return null;
    }

    final routes = body['routes'] as List?;
    if (routes == null || routes.isEmpty) return null;

    final leg = (routes[0]['legs'] as List?)?.first as Map<String, dynamic>?;
    if (leg == null) return null;

    final distanceMeters = (leg['distance']?['value'] as num?)?.toInt();
    final durationSeconds = (leg['duration']?['value'] as num?)?.toInt();
    // duration_in_traffic is only present when departure_time is set
    final durationTrafficSeconds =
        (leg['duration_in_traffic']?['value'] as num?)?.toInt();

    return {
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (durationTrafficSeconds != null)
        'duration_in_traffic_seconds': durationTrafficSeconds,
    };
  }

  // ── Tier 2: Offline Haversine fallback ───────────────────────────────────

  /// Returns ETA in minutes using straight-line distance ÷ speed.
  /// Used when Google API is unavailable or key is not set.
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

  // ── Human-readable labels ─────────────────────────────────────────────────

  /// Formats a distance in km as a human-readable string.
  static String distanceLabel(LatLng start, LatLng end) {
    final km = calculateDistanceKm(start, end);
    final m = km * 1000;
    if (m < 1000) return '${m.toStringAsFixed(0)} m';
    return '${km.toStringAsFixed(2)} km';
  }

  /// Formats ETA minutes as a human-readable string.
  static String formatEtaMinutes(int minutes) {
    if (minutes <= 0) return 'Arrived';
    if (minutes < 1) return 'Less than 1 min';
    return '$minutes min';
  }

  /// Synchronous ETA label using Haversine (for places that can't await).
  static String etaLabel(LatLng start, LatLng end, {double speedKmH = 30}) {
    final minutes = calculateETA(start, end, averageSpeedKmH: speedKmH);
    return formatEtaMinutes(minutes);
  }
}
