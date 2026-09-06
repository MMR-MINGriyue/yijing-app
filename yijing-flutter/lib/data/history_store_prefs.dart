/// shared_preferences 持久化实现 — 仅 main.dart 引入 (保持核心层纯 Dart)
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/history.dart';
import 'favorites_store.dart';
import 'history_store.dart';

/// 历史 — shared_preferences 实现 (JSON 数组, 坏数据自动回退空)
class PrefsHistoryStore implements HistoryStore {
  static const _key = 'yijing.history.v1';
  List<HistoryRecord>? _cache;
  String? _rawCache;

  @override
  List<HistoryRecord> read() {
    if (_cache != null) return List.of(_cache!);
    try {
      if (_rawCache != null) {
        final list = jsonDecode(_rawCache!) as List;
        _cache = list
            .whereType<Map<String, dynamic>>()
            .map(HistoryRecord.fromJson)
            .toList();
      }
    } catch (_) {
      _cache = [];
    }
    return List.of(_cache ?? []);
  }

  @override
  Future<void> warmUp() async {
    final prefs = await SharedPreferences.getInstance();
    _rawCache = prefs.getString(_key);
  }

  @override
  void write(List<HistoryRecord> list) {
    _cache = List.of(list);
    _rawCache = jsonEncode(_cache!.map((r) => r.toJson()).toList());
    SharedPreferences.getInstance().then((p) => p.setString(_key, _rawCache!));
  }
}

/// 收藏 — shared_preferences 实现 (对应易道 yijing.favHexes)
class PrefsFavoritesStore implements FavoritesStore {
  static const _key = 'yijing.favHexes';
  List<int>? _cache;

  @override
  List<int> read() => List.of(_cache ?? []);

  @override
  Future<void> warmUp() async {
    final prefs = await SharedPreferences.getInstance();
    _cache = prefs.getStringList(_key)?.map(int.parse).toList() ?? [];
  }

  @override
  void write(List<int> hexNos) {
    _cache = List.of(hexNos);
    SharedPreferences.getInstance()
        .then((p) => p.setStringList(_key, _cache!.map((n) => '$n').toList()));
  }
}

/// main() 启动时调用: 把默认存储工厂切到 Prefs 实现 (真机持久化)
void installPrefsStores() {
  historyStoreFactory = () => PrefsHistoryStore();
  favoritesStoreFactory = () => PrefsFavoritesStore();
}
