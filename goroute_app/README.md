# GoRoute Flutter App

The mobile application for GoRoute — built with Flutter (Dart). Runs on Android and iOS from a single codebase.

## What This App Does

- **Passengers** track live bus locations on a map, see real-time ETA and distance, and receive proximity alerts
- **Drivers** activate routes, stream GPS to Firebase, and manage their route list
- Both roles share the same APK — role selection happens at login

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/                      # Data classes (Firestore ↔ Dart)
│   ├── route_model.dart         # Bus route with isLive getter
│   ├── driver_location_model.dart # Live GPS data from Firestore
│   ├── notification_model.dart  # Passenger notification
│   └── onboarding_model.dart    # Onboarding card data
├── services/                    # Business logic (no UI here)
│   ├── auth_service.dart        # Login, register, role enforcement
│   ├── location_service.dart    # GPS streaming + Firestore writes
│   ├── route_service.dart       # Route CRUD + Firestore queries
│   ├── eta_service.dart         # ETA calculation (3-tier system)
│   ├── eta_alert_service.dart   # Proximity alert writes to Firestore
│   └── notification_service.dart # FCM setup + in-app popups
└── screens/                     # UI screens
    ├── splash_screen.dart        # 2.5s animated splash
    ├── onboarding_screen.dart    # 4-card first-launch onboarding
    ├── role_selection_screen.dart # Choose passenger or driver
    ├── auth_screen.dart          # Login + register
    ├── passenger_home.dart       # Bottom nav shell (passenger)
    ├── driver_dashboard.dart     # Bottom nav shell (driver)
    ├── passenger/
    │   ├── home_screen.dart      # Map with live bus markers
    │   ├── routes_screen.dart    # Active + saved routes list
    │   ├── bus_tracking_screen.dart # Full tracking map + ETA card
    │   ├── alerts_screen.dart    # Notification history
    │   ├── profile_screen.dart
    │   ├── saved_routes_screen.dart
    │   └── passenger_help_support_screen.dart
    └── driver/
        ├── driver_home_screen.dart  # Route list + activate/deactivate
        ├── driver_map_screen.dart   # Driver's own live map
        ├── add_route_screen.dart    # Create new route
        ├── trip_history_screen.dart
        └── help_support_screen.dart
```

## Running the App

```bash
# Install dependencies
flutter pub get

# Run on connected device
flutter run

# Build release APK
flutter build apk --release
```

## Firebase Setup

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Enable **Firestore**, **Authentication** (Email + Google), and **Cloud Messaging**
3. Download `google-services.json` → place in `android/app/`
4. Download `GoogleService-Info.plist` → place in `ios/Runner/`

## Enable AI ETA (optional)

Open `lib/services/eta_service.dart` and add your Google Maps API key:

```dart
static const String _googleApiKey = 'YOUR_KEY_HERE';
```

Enable **Directions API** in Google Cloud Console. Without a key, the Haversine formula is used automatically.

## Dependencies

| Package | Purpose |
|---------|---------|
| `firebase_core` | Firebase initialisation |
| `firebase_auth` | Authentication |
| `cloud_firestore` | Real-time database |
| `firebase_messaging` | Push notifications |
| `google_sign_in` | Google OAuth |
| `flutter_map` | OpenStreetMap rendering |
| `latlong2` | GPS coordinate types |
| `geolocator` | Device GPS access |
| `http` | REST API calls (ETA backend) |
| `provider` | State management |
| `shared_preferences` | Onboarding completion flag |
| `google_fonts` | Poppins typography |
| `url_launcher` | Email + phone links |
| `lottie` | Animations |

## How the ETA Works

```
calculateETASmart(passengerLatLng, driverLatLng, speed)
    │
    ├── Tier 1: ML Backend (POST /predict_eta)
    │     Returns predicted_eta_minutes + confidence_score
    │     Falls back if unavailable ↓
    │
    ├── Tier 2: Google Directions API
    │     Road-following distance + live traffic
    │     Falls back if no API key ↓
    │
    └── Tier 3: Haversine Formula
          Straight-line distance ÷ driver speed
          Always works, fully offline
```

## How Live Tracking Works

```
Driver taps "Go Active"
    ↓
LocationService.startTracking()
    ↓
Writes placeholder to live_locations/{driverId} immediately
    ↓
GPS stream fires every 10 metres
    ↓
live_locations/{driverId} updated: lat, lng, speed
    ↓
Passenger's StreamBuilder receives update
    ↓
Map marker moves, ETA recalculates
```

## Proximity Alerts

Three alerts fire per tracking session, each exactly once:

| Alert | Distance | Stored in Firestore |
|-------|----------|-------------------|
| Driver started trip | On first GPS fix | ✅ |
| Bus within 1 km | ≤ 1.0 km | ✅ |
| Bus arrived | ≤ 50 m | ✅ |
