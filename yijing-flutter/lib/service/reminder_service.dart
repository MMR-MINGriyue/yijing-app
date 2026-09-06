/// 每日占卜提醒 — flutter_local_notifications 定时通知 (iter39)
/// 抽象调度接口 (设置 VM 可测) + 插件实现
/// iter41: 通知点击 payload 总线 (点通知直达起卦屏) + iOS/macOS (Darwin) 初始化与授权
library;

import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// 通知点击 payload: 直达起卦屏 (屏2)
const String kRemindPayloadCast = 'cast';

/// 通知点击总线 — 插件回调 → 壳层路由
/// 单播广播流: UI 侧 listen, 插件侧 emit (含后台 isolate 回调)
class NotificationTapBus {
  NotificationTapBus._();
  static final NotificationTapBus instance = NotificationTapBus._();

  final StreamController<String> _controller =
      StreamController<String>.broadcast();

  Stream<String> get stream => _controller.stream;

  void emit(String payload) {
    if (!_controller.isClosed) _controller.add(payload);
  }
}

/// 后台 isolate 通知点击回调 (顶层函数, 必须 @pragma('vm:entry-point'))
@pragma('vm:entry-point')
void onBackgroundNotificationResponse(NotificationResponse response) {
  // 后台 isolate 无法直接操作 UI 树, 交由总线在主 isolate 侧处理
  NotificationTapBus.instance.emit(response.payload ?? '');
}

/// 提醒调度抽象 (测试用 Fake 替换)
abstract class ReminderScheduler {
  /// 请求通知权限 (Android 13+ / iOS); 返回是否已授权
  Future<bool> requestPermission();

  /// 安排每日 [hour]:[[minute]] 提醒 (目标受众锁定 Asia/Shanghai)
  Future<void> scheduleDaily({required int hour, required int minute});

  /// 取消每日提醒
  Future<void> cancel();

  /// 冷启动是否由通知拉起 (返回 payload, 非通知启动 → null)
  Future<String?> launchPayload();
}

/// 插件实现 — 真机通道
class PluginReminderScheduler implements ReminderScheduler {
  PluginReminderScheduler._();
  static final PluginReminderScheduler instance = PluginReminderScheduler._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _permissionGranted = false;

  static const _channel = AndroidNotificationChannel(
    'yijing_daily', // id
    '每日占卜提醒',
    description: '每天定时提醒来起今日一卦',
    importance: Importance.defaultImportance,
  );

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Shanghai')); // 目标受众锁定北京时区
    await _plugin.initialize(
      InitializationSettings(
        android: const AndroidInitializationSettings(
            'ic_notification'), // 专用白色卦象小图标
        iOS: const DarwinInitializationSettings(
          // 授权时机交给设置面板开关, 启动不弹系统授权框
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: const DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse:
          onBackgroundNotificationResponse,
    );
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(_channel);
    }
    _ready = true;
  }

  static void _onTap(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      NotificationTapBus.instance.emit(payload);
    }
  }

  @override
  Future<bool> requestPermission() async {
    if (!_ready) await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      _permissionGranted = await android.requestNotificationsPermission() ?? false;
      return _permissionGranted;
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      _permissionGranted = await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      return _permissionGranted;
    }
    final macos = _plugin.resolvePlatformSpecificImplementation<
        MacOSFlutterLocalNotificationsPlugin>();
    if (macos != null) {
      _permissionGranted = await macos.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
      return _permissionGranted;
    }
    return false; // 桌面/未知平台: 无通道即视为未授权
  }

  @override
  Future<void> scheduleDaily({required int hour, required int minute}) async {
    if (!_ready) await init();
    final now = tz.TZDateTime.now(tz.local);
    var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (!next.isAfter(now)) {
      next = next.add(const Duration(days: 1)); // 已过今日时点 → 明日
    }
    await _plugin.zonedSchedule(
      1, // id (每日提醒固定)
      '易道 · 今日一卦',
      '心诚则灵，来起今日一卦',
      next,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'yijing_daily',
          '每日占卜提醒',
          channelDescription: '每天定时提醒来起今日一卦',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      payload: kRemindPayloadCast, // 点击 → 直达起卦屏 (iter41)
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // 每日同一时刻
    );
  }

  @override
  Future<void> cancel() async {
    if (!_ready) await init();
    await _plugin.cancel(1);
  }

  @override
  Future<String?> launchPayload() async {
    try {
      if (!_ready) await init();
      final details = await _plugin.getNotificationAppLaunchDetails();
      final payload = details?.notificationResponse?.payload;
      if (payload == null || payload.isEmpty) return null;
      return payload;
    } catch (_) {
      return null; // 无通道环境 (测试/桌面) 静默
    }
  }
}

/// 提醒偏好持久化 + 调度编排 (VM 只依赖本类与 ReminderScheduler 抽象)
class ReminderService {
  ReminderService({ReminderScheduler? scheduler})
      : _scheduler = scheduler ?? PluginReminderScheduler.instance;

  static const _keyEnabled = 'yijing.remind.enabled';
  static const _keyHour = 'yijing.remind.hour';
  static const _keyMinute = 'yijing.remind.minute';

  final ReminderScheduler _scheduler;

  ReminderScheduler get scheduler => _scheduler;

  Future<({bool enabled, int hour, int minute})> loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      enabled: prefs.getBool(_keyEnabled) ?? false,
      hour: prefs.getInt(_keyHour) ?? 8,
      minute: prefs.getInt(_keyMinute) ?? 0,
    );
  }

  /// 开关提醒: 授权 → 落盘 → 调度/取消; 返回实际生效的开关状态
  Future<bool> setEnabled(bool enabled, {int hour = 8, int minute = 0}) async {
    if (enabled) {
      final granted = await _scheduler.requestPermission();
      if (!granted) return false; // 未授权 → 开关不生效
      await _scheduler.scheduleDaily(hour: hour, minute: minute);
    } else {
      await _scheduler.cancel();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, enabled);
    await prefs.setInt(_keyHour, hour);
    await prefs.setInt(_keyMinute, minute);
    return enabled;
  }

  /// 修改提醒时间 (仅在开关开启时有调度副作用)
  Future<void> setTime(int hour, int minute, {required bool enabled}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHour, hour);
    await prefs.setInt(_keyMinute, minute);
    if (enabled) {
      await _scheduler.scheduleDaily(hour: hour, minute: minute);
    }
  }

  /// 冷启动来源 payload (由通知拉起 → kRemindPayloadCast)
  Future<String?> launchPayload() => _scheduler.launchPayload();
}
