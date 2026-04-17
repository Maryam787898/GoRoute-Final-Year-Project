import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ETAService {
  // Simple ETA calculation based on distance and average speed
  static int calculateETA(LatLng start, LatLng end, {double averageSpeedKmH = 30}) {
    double distance = _calculateDistance(start, end);
    double timeHours = distance / averageSpeedKmH;
    return (timeHours * 60).round();
  }

  static double _calculateDistance(LatLng start, LatLng end) {
    const double p = 0.017453292519943295;
    var a = 0.5 - cos((end.latitude - start.latitude) * p) / 2 +
        cos(start.latitude * p) * cos(end.latitude * p) *
        (1 - cos((end.longitude - start.longitude) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }
}
