import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level background message handler for Firebase Cloud Messaging
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  if (kDebugMode) {
    debugPrint('[FCM Background] Title: ${message.notification?.title}, Body: ${message.notification?.body}');
  }
}

class FirebaseNotificationService {
  FirebaseNotificationService._();
  static final FirebaseNotificationService instance = FirebaseNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// High importance notification channel for Security & Real OTP alerts
  static const AndroidNotificationChannel _securityChannel = AndroidNotificationChannel(
    'service_hub_security_otp',
    'ServiceHub Security & Verification OTP',
    description: 'High priority channel for real authentication OTPs and verification alerts.',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Initialize Firebase Messaging and Local Heads-up Notifications
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Local Notification settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          if (kDebugMode) {
            debugPrint('[Notification] User tapped banner: ${response.payload}');
          }
        },
      );

      // 2. Create Android High Importance Channel
      final androidPlatform = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.createNotificationChannel(_securityChannel);
        await androidPlatform.requestNotificationsPermission();
      }

      // 3. Setup Firebase Messaging permissions & background handler
      try {
        final messaging = FirebaseMessaging.instance;
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        if (kDebugMode) {
          debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');
        }

        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // Listen for foreground FCM pushes
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          if (notification != null) {
            showNotificationBanner(
              title: notification.title ?? 'ServiceHub Notification',
              body: notification.body ?? '',
              payload: message.data.toString(),
            );
          }
        });

        // Fetch device token for targeted cloud pushes
        _fcmToken = await messaging.getToken();
        if (kDebugMode) {
          debugPrint('[FCM] Device FCM Token: $_fcmToken');
        }
      } catch (fcmErr) {
        if (kDebugMode) {
          debugPrint('[FCM Note] Messaging initialization note: $fcmErr');
        }
      }

      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FirebaseNotificationService] Error initializing: $e');
      }
    }
  }

  /// Show an instant high-priority native notification banner with the real OTP
  Future<void> showOtpNotification({
    required String otpCode,
    String? mobileNumber,
  }) async {
    const title = '🔐 ServiceHub Security OTP';
    final body = 'Your verification OTP is $otpCode. Valid for 60 seconds. Never share this code with anyone.';

    await showNotificationBanner(
      id: 9999,
      title: title,
      body: body,
      payload: otpCode,
    );
  }

  /// Display a heads-up notification banner
  Future<void> showNotificationBanner({
    int id = 1001,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        _securityChannel.id,
        _securityChannel.name,
        channelDescription: _securityChannel.description,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        styleInformation: BigTextStyleInformation(body),
      );

      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final notificationDetails = NotificationDetails(android: androidDetails, iOS: iosDetails);

      await _localNotifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[FirebaseNotificationService] Failed to show banner: $e');
      }
    }
  }
}
