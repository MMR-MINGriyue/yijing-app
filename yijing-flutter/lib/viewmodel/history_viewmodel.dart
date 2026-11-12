import 'package:flutter/foundation.dart';

import '../data/favorites_store.dart';
import '../data/history_repository.dart';
import '../model/history.dart';

/// 屏 6 历史筛选态 (卦象 / 方向 / 占法 / 关键词)
class HistoryState {
  final int year;
  final int month;
  final int? hexFilter; // null = 全部
  final String dirFilter; // '' = 全部
  final String typeFilter; // '' = 全部
  final String keyword;
  final bool newestFirst; // true = 最新在前

  const HistoryState({
    required this.year, required this.month,
    this.hexFilter, this.dirFilter = '', this.typeFilter = '',
    this.keyword = '', this.newestFirst = true,
  });

  HistoryState copyWith({
    int? year, int? month, Object? hexFilter = _unset, String? dirFilter,
    String? typeFilter, String? keyword, bool? newestFirst,
  }) => HistoryState(
    year: year ?? this.year,
    month: month ?? this.month,
    hexFilter: hexFilter == _unset ? this.hexFilter : hexFilter as int?,
    dirFilter: dirFilter ?? this.dirFilter,
    typeFilter: typeFilter ?? this.typeFilter,
    keyword: keyword ?? this.keyword,
    newestFirst: newestFirst ?? this.newestFirst,
  );

  static const _unset = Object();
}

/// ViewModel — 屏 6 历史 (筛选 + 搜索 + 统计)
class HistoryViewModel extends ChangeNotifier {
  final HistoryRepository _repo;
  final FavoritesRepository _favs;
  late HistoryState _s;
  // 非 final: 删除记录后需按最新数据刷新月份范围 (iter41 修复 LateInitializationError)
  late ({int minY, int minM, int maxY, int maxM}) _range;

  HistoryViewModel({HistoryRepository? repo, FavoritesRepository? favs})
      : _repo = repo ?? HistoryRepository.instance,
        _favs = favs ?? FavoritesRepository.instance {
    _range = _repo.monthRange();
    final n = DateTime.now();
    _s = HistoryState(year: n.year, month: n.month);
  }

  HistoryState get state => _s;
  ({int minY, int minM, int maxY, int maxM}) get range => _range;

  // iter73: 派生数据缓存 — 原实现一帧内 monthAll/chips/filtered/统计 各遍历一次
  // 全表 (~10 次复制 + 聚合). 以 repository.version + 状态 + 当天日期为失效键,
  // 外部写入 (CastViewModel 落历史) 也能自动失效, 不会 stale.
  String _cacheKey = '';
  bool _cacheReady = false;
  late List<HistoryRecord> _monthAll;
  late List<({int no, String name, int count})> _hexChips;
  late List<({String dir, int count, String color})> _dirChips;
  late List<({String type, String label, int count})> _typeChips;
  late List<HistoryRecord> _filtered;
  late int _totalCount;
  late int _weekCount;
  late int _monthCount;

  void _sync() {
    final n = DateTime.now();
    final key = '${_repo.version}|${_s.year}|${_s.month}|${_s.hexFilter}|'
        '${_s.dirFilter}|${_s.typeFilter}|${_s.keyword}|${_s.newestFirst}|'
        '${n.year}-${n.month}-${n.day}';
    if (_cacheReady && key == _cacheKey) return;
    _cacheKey = key;
    _cacheReady = true;

    final all = _repo.load();
    _totalCount = all.length;
    final weekStart = DateTime(n.year, n.month, n.day - 6);
    _weekCount = all.where((r) => !r.ts.isBefore(weekStart)).length;
    final month = all
        .where((r) => r.ts.year == _s.year && r.ts.month == _s.month)
        .toList();
    _monthAll = month;
    _monthCount = month.length;

    final hexMap = <int, ({String name, int count})>{};
    final dirMap = <String, ({int count, String color})>{};
    final typeMap = <String, ({String label, int count})>{};
    for (final r in month) {
      if (r.hexNo != null && r.name != null) {
        final cur = hexMap[r.hexNo!] ?? (name: r.name!, count: 0);
        hexMap[r.hexNo!] = (name: cur.name, count: cur.count + 1);
      }
      final d = dirMap[r.direction] ?? (count: 0, color: r.directionColor);
      dirMap[r.direction] = (count: d.count + 1, color: r.directionColor);
      final t = typeMap[r.type] ?? (label: r.methodName, count: 0);
      typeMap[r.type] = (label: t.label, count: t.count + 1);
    }
    _hexChips = hexMap.entries
        .map((e) => (no: e.key, name: e.value.name, count: e.value.count))
        .toList()
      ..sort((a, b) => b.count - a.count);
    _dirChips = dirMap.entries
        .map((e) => (dir: e.key, count: e.value.count, color: e.value.color))
        .toList()
      ..sort((a, b) => b.count - a.count);
    _typeChips = typeMap.entries
        .map((e) =>
            (type: e.key, label: e.value.label, count: e.value.count))
        .toList();

    var list = month;
    if (_s.hexFilter != null) {
      list = list.where((r) => r.hexNo == _s.hexFilter).toList();
    }
    if (_s.dirFilter.isNotEmpty) {
      list = list.where((r) => r.direction == _s.dirFilter).toList();
    }
    if (_s.typeFilter.isNotEmpty) {
      list = list.where((r) => r.type == _s.typeFilter).toList();
    }
    if (_s.keyword.isNotEmpty) {
      final kw = _s.keyword.toLowerCase();
      list = list
          .where((r) =>
              (r.name?.toLowerCase().contains(kw) ?? false) ||
              r.question.toLowerCase().contains(kw) ||
              r.direction.contains(kw))
          .toList();
    }
    list.sort((a, b) =>
        _s.newestFirst ? b.ts.compareTo(a.ts) : a.ts.compareTo(b.ts));
    _filtered = list;
  }

  /// 以下派生结果按约定只读 (调用方不要就地修改缓存列表)
  List<HistoryRecord> get monthAll {
    _sync();
    return _monthAll;
  }

  /// 卦象筛选 chips (当月出现过的 hex)
  List<({int no, String name, int count})> get hexChips {
    _sync();
    return _hexChips;
  }

  /// 方向 chips
  List<({String dir, int count, String color})> get dirChips {
    _sync();
    return _dirChips;
  }

  /// 占法 chips
  List<({String type, String label, int count})> get typeChips {
    _sync();
    return _typeChips;
  }

  /// 筛选后的当月记录 (卦象 + 方向 + 占法 + 关键词 AND)
  List<HistoryRecord> get filtered {
    _sync();
    return _filtered;
  }

  // ---- 月份导航 ----
  bool get canPrev => _s.year > _range.minY || (_s.year == _range.minY && _s.month > _range.minM);
  bool get canNext => _s.year < _range.maxY || (_s.year == _range.maxY && _s.month < _range.maxM);

  void prevMonth() {
    if (!canPrev) return;
    var y = _s.year, m = _s.month - 1;
    if (m < 1) { m = 12; y--; }
    _s = _s.copyWith(year: y, month: m, hexFilter: null, dirFilter: '', typeFilter: '');
    notifyListeners();
  }

  void nextMonth() {
    if (!canNext) return;
    var y = _s.year, m = _s.month + 1;
    if (m > 12) { m = 1; y++; }
    _s = _s.copyWith(year: y, month: m, hexFilter: null, dirFilter: '', typeFilter: '');
    notifyListeners();
  }

  // ---- 筛选 ----
  void setHexFilter(int? no) { _s = _s.copyWith(hexFilter: no); notifyListeners(); }
  void setDirFilter(String d) { _s = _s.copyWith(dirFilter: d); notifyListeners(); }
  void setTypeFilter(String t) { _s = _s.copyWith(typeFilter: t); notifyListeners(); }
  void setKeyword(String kw) { _s = _s.copyWith(keyword: kw.trim()); notifyListeners(); }
  void toggleSort() { _s = _s.copyWith(newestFirst: !_s.newestFirst); notifyListeners(); }
  void clearFilters() {
    _s = _s.copyWith(hexFilter: null, dirFilter: '', typeFilter: '');
    notifyListeners();
  }

  bool get hasFilter => _s.hexFilter != null || _s.dirFilter.isNotEmpty || _s.typeFilter.isNotEmpty || _s.keyword.isNotEmpty;

  /// 删除选中的记录 (从 filtered 列表选取, 内部映射到 load() 索引降序删除)
  void removeRecords(List<HistoryRecord> records) {
    if (records.isEmpty) return;
    final all = _repo.load();
    final indices = <int>[];
    for (final r in records) {
      final idx = all.indexOf(r);
      if (idx >= 0) indices.add(idx);
    }
    if (indices.isEmpty) return;
    indices.sort((a, b) => b - a); // 降序删除避免索引偏移
    _repo.removeMany(indices);
    _range = _repo.monthRange(); // 刷新月份范围
    notifyListeners();
  }

  // ---- 统计 (iter73: 与派生缓存共用一次全表扫描) ----
  int get totalCount {
    _sync();
    return _totalCount;
  }

  int get weekCount {
    _sync();
    return _weekCount;
  }

  int get favCount => _favs.load().length;
  int get monthCount {
    _sync();
    return _monthCount;
  }
}
