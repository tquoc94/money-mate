import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:qlct/features/reminders/data/models/reminder_model.dart';

// Top-level entry point required by flutter_foreground_task
@pragma('vm:entry-point')
void startForegroundCallback() {
  FlutterForegroundTask.setTaskHandler(_ReminderTaskHandler());
}

class _ReminderTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();

  static const _channelId = 'payment_reminders';
  static const _channelName = 'Nhắc thanh toán';

  // Changed from const to final to avoid compile-time issues with v17.x
  static final _notifDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Nhắc nhở thanh toán hóa đơn hàng tháng',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  // ─────────────────── Init ───────────────────

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            description: 'Nhắc nhở thanh toán hóa đơn hàng tháng',
            importance: Importance.high,
          ),
        );

    _initForegroundTask();
  }

  // ─────────────────── Foreground Service ───────────────────

  static void _initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'moneymate_foreground',
        channelName: 'MoneyMate',
        channelDescription: 'Giữ hoạt động để nhắc nhở đúng hạn',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(60000),
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );
  }

  static Future<void> startForegroundService() async {
    final isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) return;

    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'MoneyMate',
      notificationText: 'Đang chạy để nhắc nhở đúng hạn',
      callback: startForegroundCallback,
    );
  }

  static Future<void> stopForegroundService() async {
    await FlutterForegroundTask.stopService();
  }

  // ─────────────────── Local Notifications ───────────────────

  static int _notifId(String reminderId) => reminderId.hashCode.abs() % 100000;

  static tz.TZDateTime _nextOccurrence(int dueDay) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, dueDay, 8, 0);
    if (scheduled.isBefore(now.add(const Duration(minutes: 1)))) {
      scheduled = tz.TZDateTime(
        tz.local,
        now.year,
        now.month + 1,
        dueDay,
        8,
        0,
      );
    }
    return scheduled;
  }

  static String _fmtAmount(double amount) =>
      NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(amount);

  static Future<void> scheduleMonthlyReminder(ReminderModel reminder) async {
    await _plugin.zonedSchedule(
      _notifId(reminder.id),
      '💰 Nhắc thanh toán hôm nay',
      '${reminder.title}: ${_fmtAmount(reminder.amount)}',
      _nextOccurrence(reminder.dueDay),
      _notifDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  static Future<void> cancelReminder(String reminderId) async {
    await _plugin.cancel(_notifId(reminderId));
  }

  static Future<void> scheduleAll(List<ReminderModel> reminders) async {
    for (final r in reminders) {
      if (r.isActive) await scheduleMonthlyReminder(r);
    }
  }
}
