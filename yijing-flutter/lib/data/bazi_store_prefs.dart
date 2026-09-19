/// BaziBirth — shared_preferences 实现 (iter47)
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'bazi_store.dart';

class PrefsBaziBirthStore implements BaziBirthStore {
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
    if (raw == null) return;
    try {
      final j = jsonDecode(raw);
      if (j is Map<String, dynamic>) _cache = BaziBirth.fromJson(j);
    } catch (_) {} // 坏数据静默
    // 命盘册
    final praw = prefs.getString(_profilesKey);
    if (praw != null) {
      try {
        final pj = jsonDecode(praw);
        if (pj is Map<String, dynamic>) {
          _profiles
            ..clear()
            ..addAll(pj.map((k, v) => MapEntry(
                k, BaziBirth.fromJson(v as Map<String, dynamic>)!)));
        }
      } catch (_) {}
    }
  }

  @override
  void write(BaziBirth birth) {
    _cache = birth;
    final raw = jsonEncode(birth.toJson());
    SharedPreferences.getInstance().then((p) => p.setString(_key, raw));
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
    SharedPreferences.getInstance().then((p) => p.setString(_profilesKey, raw));
  }
}
