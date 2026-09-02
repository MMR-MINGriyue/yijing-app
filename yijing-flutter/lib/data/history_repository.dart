import '../model/history.dart';

/// 历史数据 Repository — 模拟易道 localStorage 记录
class HistoryRepository {
  HistoryRepository._();
  static final HistoryRepository instance = HistoryRepository._();

  List<HistoryRecord> _cache = [];
  bool _loaded = false;

  List<HistoryRecord> load() {
    if (_loaded) return _cache;
    final now = DateTime.now();
    _cache = _mockData(now);
    _loaded = true;
    return _cache;
  }

  /// 模拟数据: 覆盖本月 + 上月, 多种方向/占法, 便于筛选演示
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
}
