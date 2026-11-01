import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';
import '../api/api_client.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM Background] Handling background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  void Function(String groupId)? onNotificationTap;

  static const String channelId = 'chindi_alerts';
  static const String channelName = 'Chindi Notifications';
  static const String channelDescription = 'Chindi app ke kharchon aur messages ke alerts';

  Future<void> init({
    required ApiClient apiClient,
    void Function(String groupId)? onOpenGroupChat,
  }) async {
    if (_isInitialized) return;
    onNotificationTap = onOpenGroupChat;

    try {
      // 1. Initialize local notifications (mobile/desktop only)
      if (!kIsWeb) {
        const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
        const darwinSettings = DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

        const initSettings = InitializationSettings(
          android: androidSettings,
          iOS: darwinSettings,
          macOS: darwinSettings,
        );

        await _localNotifications.initialize(
          initSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            final payload = response.payload;
            if (payload != null && payload.isNotEmpty) {
              try {
                final data = jsonDecode(payload) as Map<String, dynamic>;
                final groupId = data['groupId']?.toString();
                if (groupId != null && onNotificationTap != null) {
                  onNotificationTap!(groupId);
                }
              } catch (_) {
                if (onNotificationTap != null) {
                  onNotificationTap!(payload);
                }
              }
            }
          },
        );

        // Create Android Notification Channel
        final androidNotificationChannel = const AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );

        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(androidNotificationChannel);
      }

      // 2. Initialize Firebase Messaging with DefaultFirebaseOptions
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );

        if (!kIsWeb) {
          FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
        }

        final messaging = FirebaseMessaging.instance;
        final settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        if (settings.authorizationStatus == AuthorizationStatus.authorized ||
            settings.authorizationStatus == AuthorizationStatus.provisional) {
          try {
            final fcmToken = await messaging.getToken();
            if (fcmToken != null) {
              debugPrint('[FCM] Device Token: $fcmToken');
              // Register token with backend
              _registerTokenWithBackend(apiClient, fcmToken);
            }
          } catch (tokenErr) {
            debugPrint('[FCM] Device token notice: $tokenErr');
          }

          // Handle token refresh
          messaging.onTokenRefresh.listen((newToken) {
            _registerTokenWithBackend(apiClient, newToken);
          });
        }

        // Foreground messages from FCM
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          if (notification != null) {
            showLocalNotification(
              id: message.hashCode,
              title: notification.title ?? 'Chindi',
              body: notification.body ?? 'Naya notification aya hai',
              payload: jsonEncode(message.data),
            );
          }
        });

        // App opened from background notification
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          final groupId = message.data['groupId']?.toString();
          if (groupId != null && onNotificationTap != null) {
            onNotificationTap!(groupId);
          }
        });

        // Check if app was opened from terminated state
        final initialMessage = await messaging.getInitialMessage();
        if (initialMessage != null) {
          final groupId = initialMessage.data['groupId']?.toString();
          if (groupId != null && onNotificationTap != null) {
            onNotificationTap!(groupId);
          }
        }

        debugPrint('[NotificationService] Firebase Messaging initialized successfully!');
      } catch (fbErr) {
        debugPrint('[NotificationService] Firebase init notice (Local notifications active): $fbErr');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('[NotificationService] Error initializing notifications: $e');
    }
  }

  Future<void> _registerTokenWithBackend(ApiClient apiClient, String token) async {
    try {
      final savedJwt = await apiClient.getToken();
      if (savedJwt != null && savedJwt.isNotEmpty) {
        await apiClient.post('/auth/fcm-token', data: {'fcmToken': token});
        debugPrint('[FCM] Token registered with backend server');
      }
    } catch (e) {
      debugPrint('[FCM] Error saving token on server: $e');
    }
  }

  Future<void> registerDeviceToken(ApiClient apiClient) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final fcmToken = await messaging.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _registerTokenWithBackend(apiClient, fcmToken);
      }
    } catch (e) {
      debugPrint('[FCM] Error updating device token: $e');
    }
  }

  Future<void> removeDeviceToken(ApiClient apiClient) async {
    try {
      final messaging = FirebaseMessaging.instance;
      final fcmToken = await messaging.getToken();
      if (fcmToken != null && fcmToken.isNotEmpty) {
        await apiClient.delete('/auth/fcm-token', data: {'fcmToken': fcmToken});
        debugPrint('[FCM] Token removed from backend');
      }
    } catch (e) {
      debugPrint('[FCM] Error removing device token: $e');
    }
  }

  /// Displays an instant heads-up notification with sound, vibration, and Chindi icon
  Future<void> showLocalNotification({
    int id = 0,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (kIsWeb) return;
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'Chindi Alert',
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFC9A45C), // Luxury Gold
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      details,
      payload: payload,
    );
  }
}
