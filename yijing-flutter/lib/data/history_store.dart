/// 历史存储抽象 — 纯 Dart 层 (零 Flutter / 零 pub 依赖)
/// Prefs 实现见 history_store_prefs.dart (仅 main.dart 引入)
library;

import '../model/history.dart';

/// 存储接口: 读全量 / 写全量 (记录级操作由 Repository 完成)
abstract class HistoryStore {
  List<HistoryRecord> read();
  void write(List<HistoryRecord> list);

  /// 启动预热 (Prefs 实现覆盖; 默认无操作)
  Future<void> warmUp() async {}
}


/// 内存实现 — 单元测试 / 默认实现
class MemoryHistoryStore implements HistoryStore {
  List<HistoryRecord> _records;
  MemoryHistoryStore([List<HistoryRecord>? seed]) : _records = seed ?? [];

  @override
  List<HistoryRecord> read() => List.of(_records);

  @override
  void write(List<HistoryRecord> list) => _records = List.of(list);

  @override
  Future<void> warmUp() async {}
}

/// 默认存储工厂 — main() 里由 installPrefsStores() 覆盖为 Prefs 实现
/// (保持核心层纯 Dart: verify_engine / 单测不拖入 dart:ui)
HistoryStore Function() historyStoreFactory = () => MemoryHistoryStore();
