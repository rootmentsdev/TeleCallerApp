import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initialize() async {
    tzdata.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/launcher_icon');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notificationsPlugin.initialize(initSettings);

    // Request FCM permissions
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('NotificationService: FCM Authorization status: ${settings.authorizationStatus}');

    // Get FCM Token
    String? token = await _firebaseMessaging.getToken();
    print('NotificationService: FCM Token: $token');
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("================ FCM_DEBUG (FOREGROUND) ================");
      print("Message ID: ${message.messageId}");
      print("Notification Data: ${message.notification?.toMap()}");
      print("Data Payload: ${message.data}");
      print("========================================================");

      if (message.notification != null) {
        print('NotificationService: Message also contained a notification: ${message.notification}');
        showChatNotification(
          title: message.notification!.title ?? 'New Message',
          body: message.notification!.body ?? '',
        );
      } else if (message.data.isNotEmpty) {
        if (message.data.containsKey('source')) {
          // Handle data-only messages for custom lead notifications
          handleDataMessage(message);
        } else {
          // Fallback for generic data messages
          String title = message.data['title'] ?? 'New Notification';
          String body = message.data['body'] ?? message.data['message'] ?? 'You have a new message';
          showChatNotification(title: title, body: body);
        }
      }
    });
  }

  /// Handle incoming data messages to construct custom local notifications
  Future<void> handleDataMessage(RemoteMessage message) async {
    print('NotificationService: ===== DEBUG: handleDataMessage called =====');
    print('NotificationService: Full data payload: ${message.data}');
    
    try {
      String source = message.data['source'] ?? 'Unknown';
      String leadName = message.data['leadName'] ?? 'Someone';

      print('NotificationService: Parsed source=$source, leadName=$leadName');

      String title = "New Lead!";
      String body = "You have a new lead.";

      if (source.toLowerCase() == 'whatsapp') {
        title = '🟢 New WhatsApp Lead';
        body = '$leadName just messaged on WhatsApp!';
      } else if (source.toLowerCase() == 'instagram') {
        title = '🟣 New Instagram Lead';
        body = '$leadName filled an Instagram form!';
      } else if (source.toLowerCase() == 'facebook') {
        title = '🔵 New Facebook Lead';
        body = '$leadName came from Facebook Ads!';
      }
      
      print('NotificationService: Final Title: "$title", Body: "$body"');

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'lead_channel',
        'Lead Notifications',
        channelDescription: 'Notifications for new incoming leads',
        importance: Importance.max,
        priority: Priority.high,
        enableVibration: true,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      print('NotificationService: Showing local notification using flutter_local_notifications plugin...');
      await _notificationsPlugin.show(
        DateTime.now().millisecond, // unique ID
        title,
        body,
        details,
      );
      print('NotificationService: Local notification triggered successfully!');
    } catch (e) {
      print('NotificationService: Error handling data message: $e');
    }
  }

  /// Show chat notification
  Future<void> showChatNotification({required String title, required String body}) async {
    print('NotificationService: ===== DEBUG: showChatNotification called =====');
    print('NotificationService: Title="$title", Body="$body"');
    try {
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'chat_channel',
            'Chat Notifications',
            channelDescription: 'Notifications for incoming chat messages',
            importance: Importance.max,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      print('NotificationService: Triggering fallback chat local notification...');
      await _notificationsPlugin.show(
        DateTime.now().millisecond, // unique ID for each message
        title,
        body,
        details,
      );
      print('NotificationService: Fallback chat local notification triggered successfully!');
    } catch (e) {
      print('NotificationService: Error showing chat notification: $e');
    }
  }

  /// Show immediate notification for today's follow-ups
  Future<void> showTodayFollowUpNotification(int count) async {
    try {
      print('NotificationService: Showing today notification for $count leads');
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'followup_channel',
            'Follow-up Notifications',
            channelDescription: 'Notifications for follow-up leads',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        1,
        'Follow-up Calls Today',
        'You have $count follow-up calls scheduled for today',
        details,
      );
      print('NotificationService: Today notification shown successfully');
    } catch (e) {
      print('NotificationService: Error showing today notification: $e');
    }
  }

  /// Show notification for upcoming follow-ups
  Future<void> showUpcomingFollowUpNotification(int count) async {
    try {
      print(
        'NotificationService: Showing upcoming notification for $count leads',
      );
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'followup_channel',
            'Follow-up Notifications',
            channelDescription: 'Notifications for follow-up leads',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: false,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.show(
        2,
        'Upcoming Follow-ups',
        'You have $count upcoming follow-up calls',
        details,
      );
      print('NotificationService: Upcoming notification shown successfully');
    } catch (e) {
      print('NotificationService: Error showing upcoming notification: $e');
    }
  }

  /// Schedule a notification for a specific follow-up date
  Future<void> scheduleFollowUpNotification({
    required int id,
    required String leadName,
    required DateTime followUpDate,
  }) async {
    try {
      final scheduledDate = followUpDate.subtract(const Duration(hours: 1));

      if (scheduledDate.isBefore(DateTime.now())) {
        return; // Don't schedule if time has passed
      }

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
            'followup_channel',
            'Follow-up Notifications',
            channelDescription: 'Notifications for follow-up leads',
            importance: Importance.high,
            priority: Priority.high,
            enableVibration: true,
            playSound: true,
          );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notificationsPlugin.zonedSchedule(
        id,
        'Follow-up Reminder',
        'Reminder: Call $leadName',
        tz.TZDateTime.from(scheduledDate, tz.local),
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dateAndTime,
      );
    } catch (e) {
      print('Error scheduling notification: $e');
    }
  }

  /// Cancel a scheduled notification
  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
