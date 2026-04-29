# GoRoute — AI-Based Smart Public Transport Tracker

> **Final Year Project** | Flutter · Firebase · React · TypeScript · Python (ML)

GoRoute is a real-time bus tracking system built for Pakistan's public transport network. Passengers see live bus locations on a map, get AI-powered arrival time predictions, and receive proximity alerts. Drivers use a companion app to activate routes and stream their GPS. Admins manage the system through a web dashboard.

---

## Table of Contents

- [Project Overview](#project-overview)
- [System Architecture](#system-architecture)
- [Repository Structure](#repository-structure)
- [Technology Stack](#technology-stack)
- [Component 1 — Flutter Mobile App](#component-1--flutter-mobile-app)
- [Component 2 — Admin Web Panel](#component-2--admin-web-panel)
- [Component 3 — Firebase Backend](#component-3--firebase-backend)
- [Component 4 — ML ETA Backend (Planned)](#component-4--ml-eta-backend-planned)
- [Firebase Collections](#firebase-collections)
- [Getting Started](#getting-started)
- [Environment Setup](#environment-setup)
- [Key Features](#key-features)
- [App Flow](#app-flow)
- [ETA System](#eta-system)
- [Notification System](#notification-system)
- [Security Model](#security-model)

---

## Project Overview

**Problem:** Pakistani public buses have no real-time tracking. Passengers wait at stops with no idea when the next bus will arrive, leading to wasted time and low trust in public transport.

**Solution:** GoRoute turns every driver's smartphone into a GPS tracker. The driver app streams live location to Firebase every 10 metres. Passengers see the bus on a map in real time, with distance and ETA updating continuously. An ML backend (in development) will replace the formula-based ETA with a model trained on historical trip data, driver speed behaviour, and peak-hour traffic patterns.

---

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        GoRoute System                           │
│                                                                 │
│  ┌─────────────────┐    ┌──────────────────┐    ┌───────────┐  │
│  │  Flutter App    │◄──►│    Firebase       │◄──►│  Admin    │  │
│  │  (Dart)         │    │  Firestore        │    │  Panel    │  │
│  │  Passenger +    │    │  Auth             │    │  React/TS │  │
│  │  Driver         │    │  FCM              │    │           │  │
│  └─────────────────┘    └──────────────────┘    └───────────┘  │
│           │                                                     │
│           ▼                                                     │
│  ┌─────────────────┐                                           │
│  │  ML ETA Backend │  Python · FastAPI · scikit-learn          │
│  │  POST /predict  │  XGBoost · TensorFlow LSTM                │
│  └─────────────────┘  (planned — see /ml_backend)              │
└─────────────────────────────────────────────────────────────────┘
```

**Data flow:**
1. Driver activates route → GPS streams to `live_locations/{driverId}` every 10 m
2. Passenger opens app → Firestore real-time stream shows active routes instantly
3. Passenger taps Track → map shows both markers + dashed polyline + ETA
4. ETA calls ML backend → falls back to Google Directions → falls back to Haversine
5. Proximity alerts fire at: trip started, within 1 km, arrived (50 m)
6. Driver deactivates → route disappears from passenger view immediately

---

## Repository Structure

```
GoRoute/
├── goroute_app/              # Flutter mobile app (Dart)
│   ├── lib/
│   │   ├── main.dart         # Entry point, Firebase init, routing
│   │   ├── models/           # Firestore data models
│   │   │   ├── route_model.dart
│   │   │   ├── driver_location_model.dart
│   │   │   ├── notification_model.dart
│   │   │   └── onboarding_model.dart
│   │   ├── services/         # Business logic layer
│   │   │   ├── auth_service.dart
│   │   │   ├── location_service.dart
│   │   │   ├── route_service.dart
│   │   │   ├── eta_service.dart
│   │   │   ├── eta_alert_service.dart
│   │   │   └── notification_service.dart
│   │   └── screens/          # UI screens
│   │       ├── splash_screen.dart
│   │       ├── onboarding_screen.dart
│   │       ├── role_selection_screen.dart
│   │       ├── auth_screen.dart
│   │       ├── passenger_home.dart
│   │       ├── driver_dashboard.dart
│   │       ├── passenger/
│   │       │   ├── home_screen.dart        # Map + live bus list
│   │       │   ├── routes_screen.dart      # Active + saved routes
│   │       │   ├── bus_tracking_screen.dart # Full tracking map
│   │       │   ├── alerts_screen.dart      # Notification history
│   │       │   └── profile_screen.dart
│   │       └── driver/
│   │           ├── driver_home_screen.dart  # Route management
│   │           ├── driver_map_screen.dart   # Driver's own map
│   │           ├── add_route_screen.dart
│   │           └── trip_history_screen.dart
│   ├── android/              # Android platform config
│   ├── ios/                  # iOS platform config
│   └── pubspec.yaml          # Flutter dependencies
│
├── goroute-admin/            # React admin web panel (TypeScript)
│   └── src/
│       ├── pages/
│       │   ├── Dashboard.tsx
│       │   ├── Drivers.tsx        # Driver management
│       │   ├── Routes.tsx         # Route monitoring
│       │   ├── Passengers.tsx
│       │   ├── LiveTracking.tsx
│       │   ├── BusAlerts.tsx      # Send alerts to passengers
│       │   ├── SupportRequests.tsx # Chat with users
│       │   └── Notifications.tsx
│       ├── services/
│       │   └── firestore.ts       # All Firebase operations
│       └── firebase.ts            # Firebase config
│
├── .kiro/specs/              # Feature specifications
│   └── ml-eta-prediction/   # ML ETA system spec
│       ├── requirements.md
│       └── .config.kiro
│
└── README.md                 # This file
```

---

## Technology Stack

| Layer | Technology | Version | Purpose |
|-------|-----------|---------|---------|
| Mobile App | Flutter + Dart | SDK ^3.7.2 | Cross-platform iOS + Android |
| State Management | Provider | ^6.1.5 | App-wide state (role, user) |
| Maps | flutter_map + OpenStreetMap | ^7.0.2 | No API key required |
| GPS | geolocator | ^13.0.2 | Device GPS streaming |
| Database | Cloud Firestore | ^6.3.0 | Real-time NoSQL database |
| Authentication | Firebase Auth | ^6.3.0 | Email + Google Sign-In |
| Push Notifications | Firebase Messaging | ^16.2.0 | FCM push alerts |
| HTTP | http | ^1.6.0 | ML backend + Google Directions API |
| Local Storage | shared_preferences | ^2.3.3 | Onboarding state |
| Fonts | google_fonts (Poppins) | ^6.3.2 | Typography |
| Admin Panel | React + TypeScript | — | Web dashboard |
| Admin Styling | Tailwind CSS | — | Utility-first CSS |
| ML Backend | Python + FastAPI | planned | ETA prediction API |
| ML Models | scikit-learn, XGBoost, TensorFlow | planned | 5-model comparison |

---

## Component 1 — Flutter Mobile App

### Entry Point (`main.dart`)

The app starts in `main()`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Flutter engine ready
  await Firebase.initializeApp();            // Connect to Firebase
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(
    ChangeNotifierProvider(create: (_) => AppState(), child: const MyApp()),
  );
}
```

`AppState` is a `ChangeNotifier` that holds the selected role (`passenger`/`driver`) and the current Firebase `User`. Any widget that calls `Provider.of<AppState>(context)` rebuilds automatically when `notifyListeners()` is called.

### Screen Navigation

```
SplashScreen (2.5s)
    ├── First launch → OnboardingScreen → RoleSelectionScreen
    └── Returning   → RoleSelectionScreen
                            ↓
                       AuthScreen
                    ┌──────┴──────┐
                    ↓             ↓
             PassengerHome   DriverDashboard
           (Home/Routes/     (Routes/Map/
            Alerts/Profile)   History/Profile)
```

### Services Layer

All business logic lives in `lib/services/`. Screens never talk to Firebase directly — they go through services.

| Service | Responsibility |
|---------|---------------|
| `AuthService` | Login, register, Google Sign-In, role enforcement |
| `LocationService` | GPS permissions, driver tracking, Firestore writes |
| `RouteService` | Route CRUD, active/inactive toggling, passenger queries |
| `ETAService` | Haversine formula, Google Directions API, ML backend call |
| `EtaAlertService` | 3 proximity alerts, Firestore notification writes |
| `NotificationService` | FCM setup, foreground popups, background handler |

### Models Layer

Models convert between Firestore `DocumentSnapshot` and typed Dart objects:

```dart
// Reading from Firestore
final route = RouteModel.fromDoc(doc);

// Writing to Firestore
await db.collection('routes').add(route.toMap());
```

---

## Component 2 — Admin Web Panel

A React + TypeScript single-page application. Runs separately from the Flutter app.

### Pages

| Page | What it does |
|------|-------------|
| Dashboard | Overview stats — total drivers, active routes, passengers |
| Drivers | Add/delete drivers. Status is read-only (driver controls their own) |
| Routes | View all routes. Status is read-only. Delete only |
| Passengers | View registered passengers |
| Live Tracking | Real-time map of all active buses |
| Bus Alerts | Send delay/start/arrival/emergency alerts to all passengers |
| Support Requests | View, reply to, and delete support tickets from users |
| Notifications | Notification history |

### Key Design Decision

Admin cannot activate/deactivate driver routes or toggle driver online status. These are **driver-controlled only**. The admin panel is read-only for status — it can only observe, not control. This prevents admin from accidentally disrupting an active trip.

### Running the Admin Panel

```bash
cd goroute-admin
npm install
npm run dev
```

---

## Component 3 — Firebase Backend

Firebase replaces a traditional backend server entirely. No Node.js, no Django, no custom API needed for the core app.

### Authentication

- Email/password login with strict role enforcement
- Google Sign-In (OAuth 2.0)
- Role stored in Firestore `users/{uid}.role`
- A driver cannot log in as a passenger — the role is checked server-side after every login

### Firestore Real-Time Streams

The app uses `.snapshots()` everywhere instead of one-time `.get()` calls:

```dart
// This stream fires every time any active route changes in Firestore
Stream<QuerySnapshot> activeRoutesStream() {
  return _db
      .collection('routes')
      .where('routeStatus', isEqualTo: 'active')
      .snapshots();
}
```

Flutter's `StreamBuilder` widget listens to this stream and rebuilds the UI automatically — no polling, no manual refresh.

### Firebase Cloud Messaging (FCM)

Three types of notifications:
1. **Bus alerts** (from admin) — shown as popup dialogs
2. **Proximity alerts** (from ETA system) — shown as floating snackbars
3. **Support replies** (from admin chat) — shown as snackbar banners

---

## Component 4 — ML ETA Backend (Planned)

A Python FastAPI service that will replace the formula-based ETA with a trained ML model.

### API Contract

```
POST /predict_eta
Content-Type: application/json

Request:
{
  "current_lat": 31.5204,
  "current_lng": 74.3587,
  "destination_lat": 31.5500,
  "destination_lng": 74.3700,
  "speed": 35.0,
  "route_id": "route_abc123",
  "timestamp": "2025-04-29T12:05:00Z"
}

Response:
{
  "predicted_eta_minutes": 8,
  "confidence_score": 0.87,
  "model_used": "xgboost",
  "fallback_used": false
}
```

### Models to be Trained and Compared

1. Linear Regression (baseline)
2. Random Forest Regressor
3. XGBoost Regressor
4. Gradient Boosting Regressor
5. LSTM Neural Network (sequential GPS patterns)

### Flutter Integration Point

In `eta_service.dart`, `calculateETASmart()` will call the ML backend as Tier 1:

```
Tier 1: ML Backend (/predict_eta)
    ↓ fails or unavailable
Tier 2: Google Directions API (traffic-aware)
    ↓ fails or no API key
Tier 3: Haversine formula (offline, always works)
```

---

## Firebase Collections

```
users/{uid}
  role: 'passenger' | 'driver'
  name, email, isOnline, isActive
  fcmToken, createdAt, lastLogin

routes/{routeId}
  driverId, driverName
  from, to, estimatedTime
  isActive: bool
  routeStatus: 'active' | 'inactive'
  createdAt

live_locations/{driverId}
  lat, lng, speed (km/h)
  routeId, routeLabel, driverName
  routeStatus: 'active'
  updatedAt

passengers/{uid}/notifications/{notifId}
  title, message, type
  driverName, routeLabel
  readStatus: bool
  timestamp

support_requests/{requestId}
  senderId, senderRole, senderName, senderEmail
  subject, message
  status: 'pending' | 'open' | 'resolved'
  createdAt
  └── messages/{msgId}  (subcollection)
        senderId, senderRole, senderName, text, createdAt

bus_alerts/{alertId}
  title, message, type
  alertType: 'delay' | 'start' | 'arrival' | 'emergency'
  timestamp
```

---

## Getting Started

### Prerequisites

- Flutter SDK ^3.7.2
- Dart SDK (included with Flutter)
- Node.js 18+ (for admin panel)
- Firebase project with Firestore, Auth, and FCM enabled
- Android Studio or VS Code with Flutter extension

### Flutter App Setup

```bash
# 1. Navigate to the Flutter app
cd goroute_app

# 2. Install dependencies
flutter pub get

# 3. Add your Firebase config files
# Android: android/app/google-services.json
# iOS:     ios/Runner/GoogleService-Info.plist

# 4. Run on a connected device or emulator
flutter run
```

### Admin Panel Setup

```bash
# 1. Navigate to the admin panel
cd goroute-admin

# 2. Install dependencies
npm install

# 3. Add Firebase config to src/firebase.ts

# 4. Start development server
npm run dev
```

---

## Environment Setup

### Enable Google Maps Directions API (optional)

To enable traffic-aware ETA (Tier 1), add your Google Maps API key in `goroute_app/lib/services/eta_service.dart`:

```dart
static const String _googleApiKey = 'YOUR_KEY_HERE';
```

Enable **Directions API** in [Google Cloud Console](https://console.cloud.google.com). Without a key, the app uses the Haversine formula fallback automatically.

### Firebase Security Rules (recommended)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only read/write their own document
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }
    // Routes: drivers write their own, passengers read active only
    match /routes/{routeId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == resource.data.driverId;
    }
    // Live locations: drivers write their own, passengers read
    match /live_locations/{driverId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == driverId;
    }
  }
}
```

---

## Key Features

### For Passengers
- Real-time bus location on OpenStreetMap (no API key needed)
- Live distance and ETA updating every 15 seconds
- Pulsing blue dot showing passenger's own location
- Dashed polyline connecting passenger to bus
- 3 smart alerts: trip started, bus within 1 km, bus arrived
- Save favourite routes for quick access
- Notification history with read/unread status and swipe-to-delete
- Help & Support with email, phone, and feedback form

### For Drivers
- One-tap route activation — GPS streaming starts immediately
- Live map showing driver's own position and speed
- Route management — add, activate, deactivate, delete
- Trip history
- Help & Support with admin contact

### For Admins
- Real-time dashboard with live stats
- Driver management — create accounts, view status, delete
- Route monitoring — view all routes, delete
- Live tracking map of all active buses
- Send broadcast alerts (delay, start, arrival, emergency)
- Support chat — reply to and delete user requests

---

## App Flow

### First Launch
```
Install app → Splash (2.5s) → Onboarding (4 cards) → Role Selection
→ Auth (login/register) → Home Screen
```

### Returning User
```
Open app → Splash (2.5s) → Role Selection → Auth → Home Screen
```

### Passenger Tracking a Bus
```
Routes tab → See active routes with live ETA
→ Tap "Track Live" → Full map opens
→ Blue dot = you, Maroon bus = driver
→ Dashed line connects both
→ Bottom card: Distance | ETA | Speed | Driver name
→ Alert fires when bus within 1 km
→ Alert fires when bus arrives (50 m)
```

### Driver Starting a Trip
```
My Routes tab → Tap "Go Active" on a route
→ GPS permission requested
→ Route appears on passenger screens instantly
→ GPS streams every 10 metres to Firestore
→ Tap "Go Inactive" → route disappears from passengers
```

---

## ETA System

The ETA system has three tiers, tried in order:

```
Tier 1: ML Backend
  POST /predict_eta → predicted_eta_minutes + confidence_score
  (requires ML backend running and configured)
        ↓ unavailable or error
Tier 2: Google Directions API
  Road-following distance + live traffic (departure_time=now)
  (requires GOOGLE_API_KEY in eta_service.dart)
        ↓ unavailable or no key
Tier 3: Haversine Formula
  Straight-line distance ÷ driver speed
  Always works, fully offline
```

**Haversine formula** (what the app currently uses):
```
distance = 2 × R × arcsin(√(sin²(Δlat/2) + cos(lat1) × cos(lat2) × sin²(Δlng/2)))
ETA = (distance / speed) × 60 minutes
```
Where R = 6371 km (Earth's radius).

---

## Notification System

### 3 Proximity Alerts (per tracking session)

| Alert | Trigger | Type |
|-------|---------|------|
| 🚌 Driver started the trip | Passenger opens tracking screen, first real GPS fix received | `driver_start` |
| 📍 Bus is within 1 km | Distance drops below 1.0 km | `driver_approaching` |
| ✅ Bus has arrived | Distance drops below 50 m | `driver_arrived` |

Each alert fires **exactly once** per session. The `_firedAlerts` Set in `BusTrackingScreen` prevents duplicates.

All alerts are stored in `passengers/{uid}/notifications` and visible in the Notifications screen.

### Admin Broadcast Alerts

Admin can send alerts from the web panel:
- **Delay** — bus is running late
- **Start** — route has started
- **Arrival** — bus arriving soon
- **Emergency** — urgent situation

These go to all passengers via FCM and appear as popup dialogs.

---

## Security Model

| Action | Who can do it |
|--------|--------------|
| Create driver accounts | Admin only |
| Create passenger accounts | Self-registration |
| Activate/deactivate routes | Driver (their own routes only) |
| Toggle driver online status | Driver (their own status only) |
| View active routes | Any authenticated user |
| Send broadcast alerts | Admin only |
| Delete support requests | Admin only |
| Read passenger notifications | Passenger (their own only) |

**Role enforcement** happens in `AuthService._enforceRole()` — after every login, the Firestore role is checked against the selected role. A mismatch signs the user out immediately and throws `RoleMismatchException`.

---

## Project Info

**Project Name:** GoRoute — AI-Based Smart Public Transport Tracker  
**Type:** Final Year Project  
**Platform:** Android + iOS (Flutter), Web (React admin panel)  
**Backend:** Firebase (Firestore, Auth, FCM) + Python ML API (planned)  
**Target Market:** Pakistan urban public transport  
**Primary Users:** Bus passengers, bus drivers, transport administrators
