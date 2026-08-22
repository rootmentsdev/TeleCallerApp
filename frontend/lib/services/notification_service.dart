import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

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
