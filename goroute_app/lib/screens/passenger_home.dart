import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:async';
import 'package:goroute_app/models/bus.dart';
import 'package:goroute_app/screens/bus_tracking_screen.dart';
import 'package:location/location.dart' as loc;

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  final Completer<GoogleMapController> _controller = Completer();
  String searchQuery = "";
  bool delayAlert = true;

  static const CameraPosition _initialPosition = CameraPosition(
    target: LatLng(31.5204, 74.3587),
    zoom: 13,
  );

  List<Bus> buses = [
    Bus(
      id: "1",
      number: "45A",
      route: "Gulberg → DHA",
      lat: 31.5204,
      lng: 74.3587,
      eta: 3,
      status: BusStatus.active,
    ),
    Bus(
      id: "2",
      number: "67B",
      route: "Johar Town → Wapda Town",
      lat: 31.4697,
      lng: 74.2728,
      eta: 8,
      status: BusStatus.active,
    ),
    Bus(
      id: "3",
      number: "12C",
      route: "Model Town → Bahria Town",
      lat: 31.4826,
      lng: 74.3236,
      eta: 15,
      status: BusStatus.active,
    ),
    Bus(
      id: "4",
      number: "89D",
      route: "Garden Town → Cantt",
      lat: 31.5080,
      lng: 74.3340,
      eta: 22,
      status: BusStatus.delayed,
    ),
  ];

  late Timer _timer;

  Future<void> _checkLocationPermission() async {
    loc.Location location = loc.Location();
    bool serviceEnabled;
    loc.PermissionStatus permissionGranted;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == loc.PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != loc.PermissionStatus.granted) return;
    }
  }

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        for (var bus in buses) {
          bus.lat +=
              (0.5 - (0.5 + (0.001 * (0.5 - (0.5))))) * 0.001; // Mock movement
          bus.lng += (0.5 - (0.5 + (0.001 * (0.5 - (0.5))))) * 0.001;
          if (bus.eta > 1) bus.eta--;
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Color getEtaBadgeColor(int eta) {
    if (eta < 5) return Colors.green;
    if (eta < 15) return Colors.amber;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: _initialPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            markers:
                buses
                    .map(
                      (bus) => Marker(
                        markerId: MarkerId(bus.id),
                        position: LatLng(bus.lat, bus.lng),
                        infoWindow: InfoWindow(
                          title: 'Bus ${bus.number}',
                          snippet: bus.route,
                        ),
                      ),
                    )
                    .toSet(),
          ),

          // Delay Alert Banner
          if (delayAlert)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red[500],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Bus 89D delayed by 10 minutes',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                        onPressed: () => setState(() => delayAlert = false),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Search Bar
          Positioned(
            top: delayAlert ? 100 : 60,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (val) => setState(() => searchQuery = val),
                decoration: InputDecoration(
                  icon: const Icon(Icons.search, color: Color(0xFF6B7280)),
                  hintText: 'Search routes or stops...',
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.poppins(
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ),
          ),

          // Bottom Sheet (Simulation of DraggableScrollableSheet)
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.15,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Nearby Buses',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'See All',
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF8B0000),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: buses.length,
                        itemBuilder: (context, index) {
                          final bus = buses[index];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F4F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.directions_bus,
                                color: Color(0xFF8B0000),
                              ),
                            ),
                            title: Text(
                              'Bus ${bus.number}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              bus.route,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: getEtaBadgeColor(bus.eta),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${bus.eta} min',
                                    style: GoogleFonts.poppins(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (bus.status == BusStatus.delayed)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Delayed',
                                      style: GoogleFonts.poppins(
                                        color: Colors.red,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => BusTrackingScreen(bus: bus),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF8B0000),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.route), label: 'Routes'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Alerts',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
