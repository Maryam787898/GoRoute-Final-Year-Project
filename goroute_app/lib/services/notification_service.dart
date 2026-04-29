import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:goroute_app/screens/shared/support_chat_screen.dart';

// ── Background message handler (top-level, outside any class) ────────────────
// Must be a top-level function — Flutter requires this for background isolates.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase is already initialised by the time this runs.
  // No UI work here — just log or store locally if needed.
  debugPrint('[FCM Background] ${message.notification?.title}');
}

// ── NotificationService ───────────────────────────────────────────────────────

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _messaging = FirebaseMessaging.instance;
  final _db = FirebaseFirestore.instance;

  // ── Initialise ────────────────────────────────────────────────────────

  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    // 1. Request permission (iOS + Android 13+)
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // 2. Register background handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 3. Get and save FCM token
    await _saveToken();

    // 4. Listen for token refresh
    _messaging.onTokenRefresh.listen(_updateToken);

    // 5. Foreground messages — show popup for bus alerts, banner for others
    FirebaseMessaging.onMessage.listen((message) {
      final alertType = message.data['alertType'] as String?;
      if (alertType != null) {
        // Bus alert → show popup dialog
        _showBusAlertPopup(navigatorKey, message);
      } else {
        // Support/other → show snackbar banner
        _showInAppBanner(navigatorKey, message);
      }
    });

    // 6. Notification tap when app is in background (resumed)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(navigatorKey, message);
    });

    // 7. Notification tap when app was terminated
    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      // Delay slightly so the navigator is ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(navigatorKey, initial);
      });
    }
  }

  // ── Save FCM token to Firestore ───────────────────────────────────────

  Future<void> _saveToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final token = await _messaging.getToken();
    if (token == null) return;
    await _db.collection('users').doc(uid).update({'fcmToken': token});
    debugPrint('[FCM] Token saved: ${token.substring(0, 20)}…');
  }

  Future<void> _updateToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _db.collection('users').doc(uid).update({'fcmToken': token});
  }

  // ── Navigate to chat on notification tap ─────────────────────────────

  void _handleNotificationTap(
    GlobalKey<NavigatorState> navigatorKey,
    RemoteMessage message,
  ) {
    final alertType = message.data['alertType'] as String?;
    if (alertType != null) {
      // Bus alert tap → open alerts screen
      navigatorKey.currentState?.pushNamed('/alerts');
      return;
    }

    final requestId = message.data['requestId'] as String?;
    final subject = message.data['subject'] as String? ?? 'Support Chat';
    if (requestId == null || requestId.isEmpty) return;

    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder:
            (_) => SupportChatScreen(requestId: requestId, subject: subject),
      ),
    );
  }

  // ── Bus alert popup dialog ────────────────────────────────────────────

  void _showBusAlertPopup(
    GlobalKey<NavigatorState> navigatorKey,
    RemoteMessage message,
  ) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    final title =
        message.notification?.title ??
        message.data['title'] as String? ??
        'Bus Alert';
    final body =
        message.notification?.body ?? message.data['message'] as String? ?? '';
    final alertType =
        (message.data['alertType'] as String? ?? 'info').toLowerCase();

    // Determine icon + color from alert type
    IconData icon;
    Color color;
    switch (alertType) {
      case 'delay':
        icon = Icons.schedule;
        color = Colors.red;
        break;
      case 'start':
        icon = Icons.play_circle;
        color = Colors.green;
        break;
      case 'arrival':
        icon = Icons.location_on;
        color = Colors.blue;
        break;
      case 'emergency':
        icon = Icons.warning_amber_rounded;
        color = Colors.deepOrange;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.blueGrey;
    }

    showDialog(
      context: ctx,
      barrierDismissible: false,
      builder:
          (_) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon circle
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Message
                  Text(
                    body,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 8),

                  // Type badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      alertType.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('OK'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            navigatorKey.currentState?.pushNamed('/alerts');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('View Details'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // ── In-app banner for foreground messages ─────────────────────────────

  void _showInAppBanner(
    GlobalKey<NavigatorState> navigatorKey,
    RemoteMessage message,
  ) {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    final title = message.notification?.title ?? 'New Message';
    final body = message.notification?.body ?? '';
    final requestId = message.data['requestId'] as String?;
    final subject = message.data['subject'] as String? ?? 'Support Chat';

    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (body.isNotEmpty)
              Text(
                body,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF8B0000),
        duration: const Duration(seconds: 4),
        action:
            requestId != null
                ? SnackBarAction(
                  label: 'Open',
                  textColor: Colors.white,
                  onPressed: () {
                    navigatorKey.currentState?.push(
                      MaterialPageRoute(
                        builder:
                            (_) => SupportChatScreen(
                              requestId: requestId,
                              subject: subject,
                            ),
                      ),
                    );
                  },
                )
                : null,
      ),
    );
  }

  // ── Send FCM notification via HTTP v1 API ─────────────────────────────
  //
  // Called when admin replies to a support request.
  // Fetches the receiver's FCM token from Firestore, then sends the
  // notification using Firebase's HTTP v1 REST API.
  //
  // NOTE: For production, move this to a Cloud Function so the server
  // key is never exposed in the client. For development/FYP this works.

  static Future<void> sendSupportReplyNotification({
    required String receiverUid,
    required String requestId,
    required String subject,
    required String senderName,
  }) async {
    try {
      final db = FirebaseFirestore.instance;

      // 1. Get receiver's FCM token
      final userDoc = await db.collection('users').doc(receiverUid).get();
      final token = userDoc.data()?['fcmToken'] as String?;
      if (token == null || token.isEmpty) {
        debugPrint('[FCM] No token for user $receiverUid');
        return;
      }

      // 2. Send via FCM Legacy HTTP API (simple, no OAuth needed)
      //    Replace SERVER_KEY with your Firebase project's server key
      //    from Firebase Console → Project Settings → Cloud Messaging
      const serverKey = 'YOUR_FCM_SERVER_KEY'; // ← replace this

      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$serverKey',
        },
        body: jsonEncode({
          'to': token,
          'notification': {
            'title': 'New Support Message',
            'body': '$senderName replied to your request',
            'sound': 'default',
          },
          'data': {
            'requestId': requestId,
            'subject': subject,
            'screen': 'support_chat',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          },
          'priority': 'high',
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('[FCM] Notification sent successfully');
      } else {
        debugPrint('[FCM] Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('[FCM] sendSupportReplyNotification error: $e');
    }
  }
}
