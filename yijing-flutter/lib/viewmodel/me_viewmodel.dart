import 'package:flutter/foundation.dart';

import '../data/favorites_store.dart';
import '../data/history_repository.dart';
import '../data/hex_repository.dart';
import '../model/hex.dart';

/// ViewModel — 屏 7 我的 (统计 + 收藏 + 分布)
class MeViewModel extends ChangeNotifier {
  final HexRepository _hexRepo;
  final HistoryRepository _history;
  final FavoritesRepository _favs;

  MeViewModel({HexRepository? hexRepo, HistoryRepository? history, FavoritesRepository? favs})
      : _hexRepo = hexRepo ?? HexRepository.instance,
        _history = history ?? HistoryRepository.instance,
        _favs = favs ?? FavoritesRepository.instance;

  int get totalCount => _history.load().length;

  /// 收藏卦列表 (按收藏顺序)
  List<Hex> get favorites => _favs.load().map(_hexRepo.hexByNo).toList();

  int get favCount => favorites.length;

  /// 连续占卜天数: 有记录的日期自今日 (否则昨日) 向前连数 (PWA js/07-extra.js)
  int get streak {
    final all = _history.load();
    if (all.isEmpty) return 0;
    final days = <String>{};
    String key(DateTime d) => '${d.year}-${d.month}-${d.day}';
    for (final r in all) {
      days.add(key(r.ts));
    }
    var streak = 0;
    var cursor = DateTime.now();
    if (!days.contains(key(cursor))) cursor = cursor.subtract(const Duration(days: 1));
    while (days.contains(key(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// 始于: 最早一条记录
  DateTime? get since {
    final all = _history.load();
    if (all.isEmpty) return null;
    var min = all.first.ts;
    for (final r in all) {
      if (r.ts.isBefore(min)) min = r.ts;
    }
    return min;
  }

  /// 方向分布 (按计数降序)
  List<({String dir, int count, String color})> get directionDist {
    final map = <String, ({int count, String color})>{};
    for (final r in _history.load()) {
      final cur = map[r.direction] ?? (count: 0, color: r.directionColor);
      map[r.direction] = (count: cur.count + 1, color: r.directionColor);
    }
    final list = map.entries
        .map((e) => (dir: e.key, count: e.value.count, color: e.value.color))
        .toList();
    list.sort((a, b) => b.count - a.count);
    return list;
  }

  /// 起卦方式分布 (按计数降序)
  List<({String method, int count})> get methodDist {
    final map = <String, int>{};
    for (final r in _history.load()) {
      map[r.methodName] = (map[r.methodName] ?? 0) + 1;
    }
    final list = map.entries.map((e) => (method: e.key, count: e.value)).toList();
    list.sort((a, b) => b.count - a.count);
    return list;
  }

  void toggleFav(int hexNo) {
    _favs.toggle(hexNo);
    notifyListeners();
  }

  Hex hexByNo(int no) => _hexRepo.hexByNo(no);
}
