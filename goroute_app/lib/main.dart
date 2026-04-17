import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:goroute_app/screens/splash_screen.dart';
import 'package:goroute_app/screens/role_selection_screen.dart';
import 'package:goroute_app/screens/auth_screen.dart';
import 'package:goroute_app/screens/passenger_home.dart';
import 'package:goroute_app/screens/driver_dashboard.dart';

class AppState extends ChangeNotifier {
  String? selectedRole;
  User? user;

  void setSelectedRole(String role) {
    selectedRole = role;
    notifyListeners();
  }

  void setUser(User? newUser) {
    user = newUser;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoRoute',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B0000),
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),

      home: const SplashScreen(),

      routes: {
        '/role-selection': (context) => const RoleSelectionScreen(),
        '/auth': (context) => const AuthScreen(),
        '/passenger-home': (context) => const PassengerHome(),
        '/driver-dashboard': (context) => const DriverDashboard(),
      },
    );
  }
}