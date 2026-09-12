/// BaziBirth — shared_preferences 实现 (iter47)
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'bazi_store.dart';

class PrefsBaziBirthStore implements BaziBirthStore {
  static const _key = 'yijing.bazi.birth.v1';
  BaziBirth? _cache;

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
  }

  @override
  void write(BaziBirth birth) {
    _cache = birth;
    final raw = jsonEncode(birth.toJson());
    SharedPreferences.getInstance().then((p) => p.setString(_key, raw));
  }
}
