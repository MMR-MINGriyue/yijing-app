/// BaziBirth — shared_preferences 实现 (iter47)
library;

import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'bazi_store.dart';
import 'prefs_io.dart';

class PrefsBaziBirthStore implements BaziBirthStore {
  // iter63: 单例 — 设置页导入命盘后八字页立即读到同一份缓存
  factory PrefsBaziBirthStore() => instance;
  static final PrefsBaziBirthStore instance = PrefsBaziBirthStore._();
  PrefsBaziBirthStore._();

  static const _key = 'yijing.bazi.birth.v1';
  static const _profilesKey = 'yijing.bazi.profiles.v1';
  BaziBirth? _cache;
  final Map<String, BaziBirth> _profiles = {};

  @override
  BaziBirth? read() => _cache;

  @override
  Future<void> warmUp() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    // iter63 修 bug: 原实现 raw==null 就 return, 当前盘为空时命盘册永远读不出
    if (raw != null) {
      try {
        final j = jsonDecode(raw);
        if (j is Map<String, dynamic>) _cache = BaziBirth.fromJson(j);
      } catch (_) {} // 坏数据静默
    }
    final praw = prefs.getString(_profilesKey);
    if (praw != null) {
      try {
        final pj = jsonDecode(praw);
        if (pj is Map<String, dynamic>) {
          final parsed = <String, BaziBirth>{};
          for (final e in pj.entries) {
            final v = e.value;
            if (v is Map<String, dynamic>) {
              final b = BaziBirth.fromJson(v);
              if (b != null) parsed[e.key] = b;
            }
          }
          _profiles
            ..clear()
            ..addAll(parsed);
        }
      } catch (_) {}
    }
  }

  @override
  void write(BaziBirth birth) {
    _cache = birth;
    unawaited(enqueuePrefsWrite(_key, jsonEncode(birth.toJson())));
  }

  @override
  Map<String, BaziBirth> readProfiles() => Map.of(_profiles);

  @override
  void writeProfiles(Map<String, BaziBirth> profiles) {
    _profiles
      ..clear()
      ..addAll(profiles);
    final raw = jsonEncode(
        profiles.map((k, v) => MapEntry(k, v.toJson())));
    unawaited(enqueuePrefsWrite(_profilesKey, raw));
  }
}
