import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:goroute_app/screens/splash_screen.dart';
import 'package:goroute_app/screens/onboarding_screen.dart';
import 'package:goroute_app/screens/role_selection_screen.dart';
import 'package:goroute_app/screens/auth_screen.dart';
import 'package:goroute_app/screens/passenger_home.dart';
import 'package:goroute_app/screens/driver_dashboard.dart';
import 'package:goroute_app/screens/passenger/alerts_screen.dart';
import 'package:goroute_app/services/notification_service.dart';

// ── Global navigator key — needed for FCM tap navigation ─────────────────────
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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

  // Register background FCM handler before runApp
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  runApp(
    ChangeNotifierProvider(create: (_) => AppState(), child: const MyApp()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialise FCM after the widget tree is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().init(navigatorKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoRoute',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey, // ← required for FCM tap navigation
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B0000)),
        useMaterial3: true,
        textTheme: GoogleFonts.poppinsTextTheme(),
      ),
      home: const SplashScreen(),
      routes: {
        '/onboarding': (_) => const OnboardingScreen(),
        '/role-selection': (_) => const RoleSelectionScreen(),
        '/auth': (_) => const AuthScreen(),
        '/passenger-home': (_) => const PassengerHome(),
        '/driver-dashboard': (_) => const DriverDashboard(),
        '/alerts': (_) => const AlertsScreen(),
      },
    );
  }
}
