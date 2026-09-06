import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../data/favorites_store.dart';
import '../data/history_repository.dart';
import '../model/history.dart';

/// ViewModel — 设置面板 (导出 / 导入合并 / 清空 / 重置示例)
/// 数据格式与易道 PWA 互通: {app, exportedAt, history, favorites}
class SettingsViewModel extends ChangeNotifier {
  final HistoryRepository _history;
  final FavoritesRepository _favs;

  SettingsViewModel({
    HistoryRepository? history,
    FavoritesRepository? favs,
  })  : _history = history ?? HistoryRepository.instance,
        _favs = favs ?? FavoritesRepository.instance;

  int get recordCount => _history.load().length;
  int get favCount => _favs.load().length;

  String get metaLine => '本地记录 $recordCount 条 · 收藏 $favCount 卦';

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

  /// 导入合并: 历史按 ts 去重 + 收藏并集
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
