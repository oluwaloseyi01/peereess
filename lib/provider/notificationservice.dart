import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:peereess/provider/notificationprovider.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

class AppNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static GlobalKey<NavigatorState>? _navigatorKey;

  static Future<void> init({
    required GlobalKey<NavigatorState> navigatorKey,
  }) async {
    _navigatorKey = navigatorKey;

    const InitializationSettings initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        print('🔔 Tapped: ${response.payload}');
        // Payload is the full data map encoded as JSON
        if (response.payload == null || response.payload!.isEmpty) return;
        try {
          final data = jsonDecode(response.payload!) as Map<String, dynamic>;
          _handleTap(data['screen'] as String?, data);
        } catch (_) {
          // Fallback: treat payload as plain screen string
          _handleTap(response.payload, const {});
        }
      },
    );

    await (_localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>())
        ?.createNotificationChannel(
      const AndroidNotificationChannel(
        'peereess_channel',
        'Peereess Notifications',
        description: 'Peereess app notifications',
        importance: Importance.max,
      ),
    );

    // ✅ FOREGROUND — show local notification with full data as payload
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📩 Foreground: ${message.notification?.title}');
      _showLocalNotification(
        title: message.notification?.title ?? '',
        body: message.notification?.body ?? '',
        data: message.data,
      );
      _refreshNotifications(message.data);
    });

    // ✅ BACKGROUND — pass full data to _handleTap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📲 Opened from background notification');
      _refreshNotifications(message.data);
      _handleTap(message.data['screen'], message.data);
    });

    // ✅ TERMINATED — pass full data to _handleTap
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      print('🚀 Launched from terminated notification');
      _refreshNotifications(initialMessage.data);
      _handleTap(initialMessage.data['screen'], initialMessage.data);
    }
  }

  static void _refreshNotifications(Map<String, dynamic> data) {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    final userId = data['userId'] as String?;
    if (userId == null || userId.isEmpty) return;

    try {
      context.read<NotificationProvider>().fetchNotifications(userId: userId);
    } catch (e) {
      print('⚠️ Could not refresh notifications: $e');
    }
  }

  static Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'peereess_channel',
      'Peereess Notifications',
      channelDescription: 'Peereess app notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    // Encode full data map as payload so the tap handler can read all fields
    final payload = jsonEncode(data);

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  static void _handleTap(
    String? screen, [
    Map<String, dynamic> data = const {},
  ]) {
    if (screen == null || screen.isEmpty) return;

    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    switch (screen) {
      case 'order':
        Navigator.pushNamed(context, '/home');
        break;

      case 'chat':
        final productId = data['productId'] as String?;
        final userId = data['userId'] as String?;
        final productTitle = data['productTitle'] as String?;

        // If required fields are missing, fall back to home
        if (productId == null ||
            productId.isEmpty ||
            userId == null ||
            userId.isEmpty) {
          print('⚠️ chat tap missing productId or userId, going home');
          Navigator.pushNamed(context, '/home');
          break;
        }

        Navigator.pushNamed(
          context,
          '/chat',
          arguments: {
            'productId': productId,
            'userId': userId,
            'productTitle': productTitle ?? '',
            'imageUrl': data['imageUrl'] as String?,
            'firstVariantPrice': data['firstVariantPrice'] != null
                ? double.tryParse(data['firstVariantPrice'].toString())
                : null,
          },
        );
        break;

      case 'home':
        Navigator.pushNamed(context, '/home');
        break;

      default:
        print('⚠️ Unknown screen: $screen');
    }
  }
}
