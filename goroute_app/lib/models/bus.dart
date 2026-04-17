enum BusStatus { active, delayed }

class Bus {
  final String id;
  final String number;
  final String route;
  double lat;
  double lng;
  int eta;
  final BusStatus status;

  Bus({
    required this.id,
    required this.number,
    required this.route,
    required this.lat,
    required this.lng,
    required this.eta,
    required this.status,
  });
}
