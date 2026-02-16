import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'message/chat_screen.dart';
import 'notification_detail_screen.dart';
import 'main.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: android);
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        final payload = response.payload;
        print('🔥 [onDidReceiveNotificationResponse] payload: $payload');

        if (payload != null) {
          if (payload.startsWith('id:')) {
            final id = int.tryParse(payload.substring(3));
            print('🔥 Parsed notification ID: $id');
            if (id != null) {
              final prefs = await SharedPreferences.getInstance();
              final accessToken = prefs.getString('access_token');
              print('🪪 accessToken: $accessToken');
              if (accessToken != null) {
                navigatorKey.currentState?.push(MaterialPageRoute(
                  builder: (_) => NotificationDetailScreen(
                    notificationId: id,
                    accessToken: accessToken,
                  ),
                ));
              }
            }
          } else if (payload.startsWith('conversation:')) {
            final id = payload.substring('conversation:'.length);
            print('💬 Parsed conversation ID: $id');
            final prefs = await SharedPreferences.getInstance();
            final accessToken = prefs.getString('access_token');
            print('🪪 accessToken: $accessToken');
            if (accessToken != null) {
              navigatorKey.currentState?.push(MaterialPageRoute(
                builder: (_) => ChatScreen(
                  conversationId: id,
                  accessToken: accessToken,
                ),
              ));
            }
          }
        }
      },
    );
  }

  Future<void> showNotification(String title, String body, {String? payload}) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'Channel for important notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      largeIcon: DrawableResourceAndroidBitmap('nks_logo'),
      icon: '@mipmap/ic_launcher',
      showWhen: true,
    );
    const platformDetails = NotificationDetails(android: androidDetails);
    await _plugin.show(
      0,
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }
}