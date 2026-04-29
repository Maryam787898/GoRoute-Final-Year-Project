import 'package:flutter/material.dart';

/// Data model for a single onboarding card.
class OnboardingModel {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color backgroundColor;
  final Color accentColor;
  final Color iconColor;

  const OnboardingModel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.backgroundColor,
    required this.accentColor,
    required this.iconColor,
  });
}

/// The four onboarding cards for GoRoute.
final List<OnboardingModel> onboardingPages = [
  const OnboardingModel(
    title: 'Track Your Bus\nIn Real Time',
    subtitle:
        'See exactly where your bus is on the map — live updates every few seconds so you never miss a ride.',
    icon: Icons.directions_bus_rounded,
    backgroundColor: Color(0xFF8B0000),
    accentColor: Color(0xFFB71C1C),
    iconColor: Colors.white,
  ),
  const OnboardingModel(
    title: 'Know Your ETA\nInstantly',
    subtitle:
        'Get accurate arrival times based on live traffic and GPS data. Plan your day without the guesswork.',
    icon: Icons.access_time_filled_rounded,
    backgroundColor: Color(0xFF1A237E),
    accentColor: Color(0xFF283593),
    iconColor: Colors.white,
  ),
  const OnboardingModel(
    title: 'Smart Route\nPlanning',
    subtitle:
        'Browse all available routes, stops, and schedules in one place. Find the fastest path to your destination.',
    icon: Icons.alt_route_rounded,
    backgroundColor: Color(0xFF1B5E20),
    accentColor: Color(0xFF2E7D32),
    iconColor: Colors.white,
  ),
  const OnboardingModel(
    title: 'Instant Alerts &\nNotifications',
    subtitle:
        'Stay informed with real-time alerts for delays, route changes, and important updates — right on your phone.',
    icon: Icons.notifications_active_rounded,
    backgroundColor: Color(0xFF4A148C),
    accentColor: Color(0xFF6A1B9A),
    iconColor: Colors.white,
  ),
];
