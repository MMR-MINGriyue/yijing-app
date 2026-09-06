import '../model/history.dart';
import 'history_store.dart';

/// 历史数据 Repository — 真实落盘记录 (HistoryStore) + 内置示例数据
/// 与 PWA YijingHistory.all() 行为一致: 真实记录在前, 示例垫底
class HistoryRepository {
  HistoryRepository({HistoryStore? store, this._seedSamples = true})
      : _store = store ?? historyStoreFactory();

  /// 默认单例 (真机用); 测试请自行构造注入 MemoryHistoryStore
  static final HistoryRepository instance = HistoryRepository();

  final HistoryStore _store;
  final bool _seedSamples;
  bool _loaded = false;
  List<HistoryRecord> _real = [];
  List<HistoryRecord> _samples = [];

  /// 启动预热 (转发给存储实现; Prefs 实现读取一次 shared_preferences)
  Future<void> warmUp() => _store.warmUp();

  void _ensureLoaded() {
    if (_loaded) return;
    _real = _store.read();
    _samples = _seedSamples ? _mockData(DateTime.now()) : [];
    _loaded = true;
  }

  /// 全部记录 (真实 + 示例)
  List<HistoryRecord> load() {
    _ensureLoaded();
    return [..._real, ..._samples];
  }

  /// 新增一条 (置于最前, 落盘)
  HistoryRecord add(HistoryRecord rec) {
    _ensureLoaded();
    _real.insert(0, rec);
    _store.write(_real);
    return rec;
  }

  /// 按 load() 下标批量删除 (降序传入), 命中示例数据仅内存移除
  void removeMany(List<int> indicesDesc) {
    _ensureLoaded();
    for (final idx in indicesDesc) {
      if (idx < _real.length) {
        _real.removeAt(idx);
      } else {
        final j = idx - _real.length;
        if (j >= 0 && j < _samples.length) _samples.removeAt(j);
      }
    }
    _store.write(_real);
  }

  /// 清空真实记录 (示例保留, 收藏不受影响)
  void clearReal() {
    _ensureLoaded();
    _real = [];
    _store.write(_real);
  }

  /// 本月跨度: 最早记录月 ~ 最新
  ({int minY, int minM, int maxY, int maxM}) monthRange() {
    final list = load();
    if (list.isEmpty) {
      final n = DateTime.now();
      return (minY: n.year, minM: n.month, maxY: n.year, maxM: n.month);
    }
    var minY = list.first.ts.year, minM = list.first.ts.month;
    var maxY = list.first.ts.year, maxM = list.first.ts.month;
    for (final r in list) {
      final y = r.ts.year, m = r.ts.month;
      if (y * 12 + m < minY * 12 + minM) { minY = y; minM = m; }
      if (y * 12 + m > maxY * 12 + maxM) { maxY = y; maxM = m; }
    }
    final n = DateTime.now();
    if (n.year * 12 + n.month > maxY * 12 + maxM) { maxY = n.year; maxM = n.month; }
    return (minY: minY, minM: minM, maxY: maxY, maxM: maxM);
  }

  /// 某月记录
  List<HistoryRecord> ofMonth(int year, int month) => load()
      .where((r) => r.ts.year == year && r.ts.month == month)
      .toList();

  /// 内置示例数据: 覆盖本月 + 上月, 多种方向/占法, 便于筛选演示
  List<HistoryRecord> _mockData(DateTime now) {
    List<bool> yangs(List<int> ones) {
      final l = List<bool>.filled(6, false);
      for (final i in ones) { if (i >= 0 && i < 6) l[i] = true; }
      return l;
    }

    return [
      HistoryRecord(
        hexNo: 1, name: '乾', question: '近期事业运筹方向', direction: '事业',
        directionColor: 'cinnabar', ts: DateTime(now.year, now.month, 17, 9, 32),
        lines: yangs([0, 1, 2, 3, 4, 5]), moving: [2],
      ),
      HistoryRecord(
        hexNo: 5, name: '需', question: '近期事业运筹方向', direction: '事业',
        directionColor: 'cinnabar', ts: DateTime(now.year, now.month, 16, 21, 32),
        lines: yangs([0, 1, 2, 3, 5]), moving: [4],
      ),
      HistoryRecord(
        hexNo: 31, name: '咸', question: '与TA关系走向', direction: '感情',
        directionColor: 'pine', ts: DateTime(now.year, now.month, 15, 19, 8),
        lines: yangs([0]),
      ),
      HistoryRecord(
        hexNo: 14, name: '大有', question: '近期财运转机', direction: '财运',
        directionColor: 'gold', ts: DateTime(now.year, now.month, 14, 14, 22),
        lines: yangs([0, 1, 2, 3, 4, 5]), moving: [3],
      ),
      HistoryRecord(
        hexNo: 6, name: '讼', question: '项目推进节奏', direction: '事业',
        directionColor: 'cinnabar', ts: DateTime(now.year, now.month, 5, 9, 18),
        lines: yangs([0, 2, 4, 5]), moving: [1],
      ),
      // 非卦类占法: 八字 / 小六壬 (hexNo null, 用徽标)
      HistoryRecord(
        question: '个人运势总览', direction: '八字', directionColor: 'gold',
        type: 'bazi', ts: DateTime(now.year, now.month - 1, 28, 20, 10),
      ),
      HistoryRecord(
        question: '今日出门吉凶', direction: '六壬', directionColor: 'pine',
        type: 'xlr', ts: DateTime(now.year, now.month - 1, 20, 8, 40),
      ),
      // 上月易经
      HistoryRecord(
        hexNo: 53, name: '渐', question: '换工作机会评估', direction: '事业',
        directionColor: 'cinnabar', ts: DateTime(now.year, now.month - 1, 12, 15, 30),
        lines: yangs([1, 2, 3, 5]),
      ),
      HistoryRecord(
        hexNo: 60, name: '节', question: '节制开支计划', direction: '财运',
        directionColor: 'gold', ts: DateTime(now.year, now.month - 1, 3, 10, 5),
        lines: yangs([0, 1, 4]),
      ),
    ];
  }
}
