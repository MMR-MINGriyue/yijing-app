/// shared_preferences 落盘队列 — 纯 Dart 层 (零 Flutter 依赖)
///
/// iter72 (v1.63.0): 修 fire-and-forget 写入。
/// 原实现 `SharedPreferences.getInstance().then((p) => p.setString(...))` 是 void:
/// 无 await / 无错误处理 / 连续写入可能乱序覆盖, 失败静默丢数据。
/// 现在所有写入串行排队, 返回值 false 或异常都经 [onPersistenceError] 上报,
/// 测试可用 [flushPrefsWrites] 等到落盘完成。
library;

import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

/// 落盘失败回调 — main() 注入 FlutterError.reportError; 测试可拦截断言
void Function(Object error, StackTrace stack)? onPersistenceError;

Future<void> _tail = Future<void>.value();

/// 排队一次写入; 返回该次写入的 Future (调用方若不需要等待须显式 unawaited)
Future<void> enqueuePrefsWrite(String key, Object value) {
  final job = _tail.then<void>((_) async {
    try {
      if (value is! String && value is! List<String>) {
        throw ArgumentError.value(value, 'value', 'unsupported prefs value type');
      }
      final prefs = await SharedPreferences.getInstance();
      final bool ok;
      if (value is String) {
        ok = await prefs.setString(key, value);
      } else {
        ok = await prefs.setStringList(key, value as List<String>);
      }
      if (!ok) throw StateError('SharedPreferences write returned false: $key');
    } catch (e, st) {
      onPersistenceError?.call(e, st);
    }
  });
  _tail = job;
  return job;
}

/// 等待当前队列全部落盘 (单测 / 关键写路径)
Future<void> flushPrefsWrites() async {
  await _tail;
}
