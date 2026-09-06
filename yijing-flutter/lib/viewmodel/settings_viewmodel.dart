import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/favorites_store.dart';
import '../data/history_repository.dart';
import '../model/history.dart';
import '../service/backup_service.dart';
import '../service/reminder_service.dart';

/// ViewModel — 设置面板 (导出 / 导入合并 / 清空 / 重置 / 每日提醒)
/// 数据格式与易道 PWA 互通: {app, exportedAt, history, favorites}
class SettingsViewModel extends ChangeNotifier {
  final HistoryRepository _history;
  final FavoritesRepository _favs;
  final ReminderService _reminder;
  final BackupService _backup;

  SettingsViewModel({
    HistoryRepository? history,
    FavoritesRepository? favs,
    ReminderService? reminder,
    BackupService? backup,
  })  : _history = history ?? HistoryRepository.instance,
        _favs = favs ?? FavoritesRepository.instance,
        _reminder = reminder ?? ReminderService(),
        _backup = backup ?? BackupService();

  bool _remindEnabled = false;
  int _remindHour = 8;
  int _remindMinute = 0;
  bool _remindLoaded = false;

  bool get remindEnabled => _remindEnabled;
  int get remindHour => _remindHour;
  int get remindMinute => _remindMinute;
  bool get remindLoaded => _remindLoaded;

  int get recordCount => _history.load().length;
  int get favCount => _favs.load().length;

  String get metaLine => '本地记录 $recordCount 条 · 收藏 $favCount 卦';

  /// 启动时载入提醒偏好 (落盘值即真相; 恢复调度由插件 boot receiver 负责)
  Future<void> loadReminderPrefs() async {
    final p = await _reminder.loadPrefs();
    _remindEnabled = p.enabled;
    _remindHour = p.hour;
    _remindMinute = p.minute;
    _remindLoaded = true;
    notifyListeners();
  }

  /// 开关每日提醒; 未授权时开关弹回 false
  Future<void> toggleReminder(bool on) async {
    final ok = await _reminder.setEnabled(on,
        hour: _remindHour, minute: _remindMinute);
    _remindEnabled = on && ok;
    notifyListeners();
  }

  /// 修改提醒时间
  Future<void> setReminderTime(int hour, int minute) async {
    _remindHour = hour;
    _remindMinute = minute;
    await _reminder.setTime(hour, minute, enabled: _remindEnabled);
    notifyListeners();
  }

  String get reminderTimeLabel =>
      '${_remindHour.toString().padLeft(2, '0')}:${_remindMinute.toString().padLeft(2, '0')}';

  /// 导出 JSON (PWA 兼容格式; 记录按时间倒序同 PWA load 顺序)
  String exportJson() {
    final payload = {
      'app': 'yijing-app',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'history': _history.load().map((r) => r.toJson()).toList(),
      'favorites': _favs.load(),
    };
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  /// 导出为本地文件 → 调起系统分享; 返回文件路径 (iter41)
  Future<String> shareBackupFile() => _backup.shareBackup(exportJson());

  /// 导出为本地文件 (不分享); 返回文件路径 (iter41)
  Future<String> exportToFile() => _backup.exportToFile(exportJson());

  /// 选取备份文件并导入; 用户取消 → null (iter41)
  Future<String?> importFromFile() async {
    final text = await _backup.pickBackupText();
    if (text == null) return null;
    try {
      return importJson(text);
    } on FormatException {
      return '导入失败：不是有效的 JSON';
    }
  }
  /// 返回结果文案; 抛 FormatException 表示 JSON 无效
  String importJson(String raw) {
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('顶层必须是 JSON 对象');
    }
    final incoming = (data['history'] as List?) ?? const [];
    final incomingFavs = (data['favorites'] as List?) ?? const [];
    final records = incoming
        .whereType<Map<String, dynamic>>()
        .map(HistoryRecord.fromJson)
        .toList();
    final favs = incomingFavs.whereType<num>().map((n) => n.toInt()).toList();
    if (records.isEmpty && favs.isEmpty) {
      return '没有可导入的数据';
    }
    final r = _history.mergeAll(records);
    final favAdded = _favs.mergeUnion(favs);
    notifyListeners();
    return '已导入：新增 ${r.added} 条记录${favAdded > 0 ? ' · $favAdded 卦收藏' : ''}';
  }

  /// 清空本地历史 (示例保留; 收藏不动)
  void clearReal() {
    _history.clearReal();
    notifyListeners();
  }

  /// 重置为示例数据 = 清空真实记录 (示例永远垫底展示, 收藏不动)
  void resetSamples() {
    _history.clearReal();
    notifyListeners();
  }
}
