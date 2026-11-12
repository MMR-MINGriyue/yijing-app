/// 用户称呼 — shared_preferences 实现 (仅 main.dart 注入)
library;

import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'prefs_io.dart';
import 'profile_store.dart';

class PrefsProfileStore implements ProfileStore {
  // iter72: 单例 — 设置页改称呼后首页立即读到同一份缓存
  factory PrefsProfileStore() => instance;
  static final PrefsProfileStore instance = PrefsProfileStore._();
  PrefsProfileStore._();

  static const _key = 'yijing.profile.name.v1';
  String _name = kDefaultGreetingName;

  @override
  String readName() => _name;

  @override
  Future<void> warmUp() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null && saved.trim().isNotEmpty) _name = saved.trim();
  }

  @override
  void writeName(String name) {
    _name = name.trim().isEmpty ? kDefaultGreetingName : name.trim();
    unawaited(enqueuePrefsWrite(_key, _name));
  }
}
