import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:goroute_app/screens/passenger/home_screen.dart';
import 'package:goroute_app/screens/passenger/routes_screen.dart';
import 'package:goroute_app/screens/passenger/alerts_screen.dart';
import 'package:goroute_app/screens/passenger/profile_screen.dart';
import 'package:goroute_app/services/eta_alert_service.dart';

class PassengerHome extends StatefulWidget {
  const PassengerHome({super.key});

  @override
  State<PassengerHome> createState() => _PassengerHomeState();
}

class _PassengerHomeState extends State<PassengerHome> {
  int _selectedIndex = 0;
  int _unreadCount = 0;
  StreamSubscription<int>? _unreadSub;

  static const List<Widget> _screens = [
    HomeScreen(),
    RoutesScreen(),
    AlertsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _subscribeUnread();
  }

  @override
  void dispose() {
    _unreadSub?.cancel();
    super.dispose();
  }

  void _subscribeUnread() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _unreadSub = EtaAlertService.unreadCountStream(uid).listen((count) {
      if (mounted) setState(() => _unreadCount = count);
    });
  }

  void _onTabTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF8B0000),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
        backgroundColor: Colors.white,
        elevation: 12,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.route_outlined),
            activeIcon: Icon(Icons.route),
            label: 'Routes',
          ),
          // Alerts tab with unread badge
          BottomNavigationBarItem(
            icon: _BadgeIcon(
              icon: Icons.notifications_outlined,
              count: _unreadCount,
            ),
            activeIcon: _BadgeIcon(
              icon: Icons.notifications,
              count: _unreadCount,
              active: true,
            ),
            label: 'Alerts',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Badge icon widget ─────────────────────────────────────────────────────────

class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  final bool active;

  const _BadgeIcon({
    required this.icon,
    required this.count,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            top: -4,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF8B0000),
                shape: BoxShape.circle,
              ),
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
