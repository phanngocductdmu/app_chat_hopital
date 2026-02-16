import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'message/chat_screen.dart';
import 'notification_detail_screen.dart';
import 'theme_mode_option.dart';
import 'theme_preferences.dart';
import 'notification_service.dart';
import 'splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

String currentScreen = 'out';
void Function(String)? onScreenChanged;
void Function()? onNewMessage;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await NotificationService().init();
  await initializeDateFormatting('vi_VN', null);

  //click out app notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) async {
    print('🔥 [onMessageOpenedApp] data: ${message.data}');
    final clickAction = message.data['click-action'];
    onNewMessage?.call();
    final extra = message.data['extra'];
    String? notificationId;
    if (extra != null && extra is String) {
      final parts = extra.split(',');
      if (parts.length >= 2) {
        notificationId = parts[1];
      }
    }
    print('🧩 clickAction: $clickAction, notificationId: $notificationId');
    if (clickAction == 'Notification' && notificationId != null) {
      final id = int.tryParse(notificationId);
      if (id != null) {
        final prefs = await SharedPreferences.getInstance();
        final accessToken = prefs.getString('access_token');

        if (accessToken != null) {
          // Đợi sau frame hiện tại để push route
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigatorKey.currentState?.push(MaterialPageRoute(
              builder: (_) => NotificationDetailScreen(
                notificationId: id,
                accessToken: accessToken,
              ),
            ));
          });
        } else {
          print('⚠️ Không tìm thấy accessToken trong SharedPreferences');
        }
      } else {
        print('❗ notificationId không hợp lệ: $notificationId');
      }
    }else if(clickAction == 'conversation' && notificationId != null){
      final id = int.tryParse(notificationId);
      if (id != null) {
        final prefs = await SharedPreferences.getInstance();
        final accessToken = prefs.getString('access_token');

        if (accessToken != null) {
          // Đợi sau frame hiện tại để push route
          WidgetsBinding.instance.addPostFrameCallback((_) {
            navigatorKey.currentState?.push(MaterialPageRoute(
              builder: (_) => ChatScreen(
                conversationId: id.toString(),
                accessToken: accessToken,
              ),
            ));
          });
        } else {
          print('⚠️ Không tìm thấy accessToken trong SharedPreferences');
        }
      } else {
        print('❗ notificationId không hợp lệ: $notificationId');
      }
    }
  });

  onScreenChanged = (screenName) {
    currentScreen = screenName;
    print('🔥 Đã đổi trạng thái màn hình: $screenName');
  };

  //click in app notification
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('📦 [onMessage] message.data: ${message.data}');
    print('✅ currentScreen: $currentScreen');
    onNewMessage?.call();
    if (currentScreen == 'out') {
      final clickAction = message.data['click-action'];
      final extra = message.data['extra'];
      print('➡ click-action: $clickAction, extra: $extra');
      String? conversationId;
      if (extra != null && extra is String) {
        final parts = extra.split(',');
        if (parts.length >= 2) {
          conversationId = parts[1];
        }
      }

      if (conversationId != null) {
        NotificationService().showNotification(
          message.notification?.title ?? '',
          message.notification?.body ?? '',
          payload: 'conversation:$conversationId',
        );
      }
    } else {
      print('🚫 Đang trong màn chat, không thông báo');
      onNewMessage?.call();
    }
  });

  // Yêu cầu quyền notification
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Lấy theme đã lưu
  final savedTheme = await ThemePreferences.loadTheme() ?? ThemeModeOption.system;

  // Đặt màu recent app
  setRecentAppColor("#FF0077BB");

  runApp(MyApp(savedTheme: savedTheme));

}

const platform = MethodChannel('com.example.app_chat_hospital/recent');

Future<void> setRecentAppColor(String colorHex) async {
  try {
    await platform.invokeMethod('setRecentColor', {'color': colorHex});
  } on PlatformException {
    // ignore lỗi
  }
}

class MyApp extends StatefulWidget {
  final ThemeModeOption savedTheme;
  const MyApp({super.key, required this.savedTheme});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late ThemeModeOption _themeMode;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.savedTheme;
  }

  Future<void> _updateTheme(ThemeModeOption newTheme) async {
    setState(() {
      _themeMode = newTheme;
    });
    await ThemePreferences.saveTheme(newTheme);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _getThemeMode(_themeMode),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(
          onThemeChanged: _updateTheme,
          currentTheme: _themeMode,
        ),
      },
    );
  }

  ThemeMode _getThemeMode(ThemeModeOption option) {
    switch (option) {
      case ThemeModeOption.light:
        return ThemeMode.light;
      case ThemeModeOption.dark:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}