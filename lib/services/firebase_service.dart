import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

// Background message handler — must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Background message: ${message.messageId}');
}

class FirebaseService {
  static final analytics = FirebaseAnalytics.instance;
  static final messaging = FirebaseMessaging.instance;
  static final _localNotifs = FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    await Firebase.initializeApp();
    await _setupMessaging();
    await _setupLocalNotifications();
  }

  static Future<void> _setupMessaging() async {
    // Request notification permission
    final settings = await messaging.requestPermission(
      alert: true, badge: true, sound: true,
    );
    print('Notification permission: ${settings.authorizationStatus}');

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(
        title: message.notification?.title ?? 'CookMyFridge',
        body: message.notification?.body ?? '',
      );
    });

    // Get FCM token for this device
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
    await _localNotifs.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
  }

  static Future<void> _showLocalNotification({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'cookmyfridge_channel', 'CookMyFridge',
      channelDescription: 'CookMyFridge notifications',
      importance: Importance.high, priority: Priority.high,
    );
    await _localNotifs.show(0, title, body, const NotificationDetails(android: androidDetails));
  }

  // Schedule daily meal reminder
  static Future<void> scheduleMealReminder({required int hour, required int minute}) async {
    // Using flutter_local_notifications for scheduled notifications
    await _localNotifs.periodicallyShow(
      1, "What's cooking tonight? 🍳",
      "Tap to discover recipes with what you have in your fridge!",
      RepeatInterval.daily,
      const NotificationDetails(
        android: AndroidNotificationDetails('reminders', 'Meal Reminders', channelDescription: 'Daily meal planning reminders'),
      ),
    );
  }

  static Future<void> cancelReminders() async {
    await _localNotifs.cancel(1);
  }

  // Analytics helpers
  static Future<void> logEvent(String name, [Map<String, dynamic>? params]) async {
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
