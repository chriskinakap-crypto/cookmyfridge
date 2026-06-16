import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Background message: ${message.messageId}');
}

class FirebaseService {
  static final analytics = FirebaseAnalytics.instance;
  static final messaging = FirebaseMessaging.instance;
  static final _localNotifs = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    await _setupMessaging();
    await _setupLocalNotifications();
  }

  static Future<void> _setupMessaging() async {
    final settings = await messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
    print('Notification permission: ${settings.authorizationStatus}');
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(
        title: message.notification?.title ?? 'CookMyFridge',
        body: message.notification?.body ?? '',
      );
    });
    final token = await messaging.getToken();
    print('FCM Token: $token');
  }

  static Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _localNotifs.initialize(settings: const InitializationSettings(android: androidSettings, iOS: iosSettings));
  }

  static Future<void> _showLocalNotification({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'cookmyfridge_channel', 'CookMyFridge',
      channelDescription: 'CookMyFridge notifications',
      importance: Importance.high, priority: Priority.high,
    );
    await _localNotifs.show(id: 0, title: title, body: body, notificationDetails: const NotificationDetails(android: androidDetails));
  }

  static Future<void> scheduleMealReminder({required int hour, required int minute}) async {
    await _localNotifs.periodicallyShow(
      id: 1,
      title: "What is cooking tonight?",
      body: "Tap to discover recipes with what you have in your fridge!",
      repeatInterval: RepeatInterval.daily,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails('reminders', 'Meal Reminders', channelDescription: 'Daily meal planning reminders'),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
    );
  }

  static Future<void> cancelReminders() async {
    await _localNotifs.cancel(id: 1);
  }

  static Future<void> logEvent(String name, [Map<String, Object>? params]) async {
    await analytics.logEvent(name: name, parameters: params);
  }

  static Future<void> logRecipeSearch(List<String> ingredients) async {
    await analytics.logEvent(name: 'recipe_search', parameters: {
      'ingredient_count': ingredients.length,
      'ingredients': ingredients.take(5).join(','),
    });
  }

  static Future<void> logRecipeSaved(String recipeTitle) async {
    await analytics.logEvent(name: 'recipe_saved', parameters: {'recipe_title': recipeTitle});
  }

  static Future<void> logUpgradeView() async {
    await analytics.logEvent(name: 'upgrade_viewed');
  }

  static Future<void> setUserProperty(String name, String value) async {
    await analytics.setUserProperty(name: name, value: value);
  }
}
