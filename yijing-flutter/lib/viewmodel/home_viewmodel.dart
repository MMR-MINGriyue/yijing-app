import 'package:flutter/foundation.dart';

import '../core/cast_engine.dart';
import '../core/daily_hex.dart';
import '../core/yi_almanac.dart';
import '../core/yi_calendar.dart';
import '../data/history_repository.dart';
import '../data/hex_repository.dart';
import '../data/profile_store.dart';
import '../model/hex.dart';
import '../model/history.dart';

/// ViewModel — 屏 1 今日一卦 (日辰卦序 + 干支问候)
class HomeViewModel extends ChangeNotifier {
  final HexRepository _hexRepo;
  final HistoryRepository _history;
  final DateTime Function() _nowFn; // 可注入时钟 (测试)
  final ProfileStore _profile;

  HomeViewModel({
    HexRepository? hexRepo,
    HistoryRepository? history,
    DateTime Function()? now,
    ProfileStore? profile,
  })  : _hexRepo = hexRepo ?? HexRepository.instance,
        _history = history ?? HistoryRepository.instance,
        _profile = profile ?? profileStoreFactory(),
        _nowFn = now ?? DateTime.now;

  int _refreshCount = 0;
  bool _refreshed = false; // 刷新过则用 refreshHex 轮换, 否则时辰卦

  DateTime get _now => _nowFn();

  Hex? _quoteHex; // 当日卦语 (日期确定性抽取, iter54)
  DateTime? _quoteDay; // iter72: 缓存所属日期, 跨日自动失效

  /// 同日同卦: 日期哈希 → 64 卦之一
  Hex get quoteHex {
    final n = _now;
    final d = _quoteDay;
    if (_quoteHex == null ||
        d == null ||
        d.year != n.year ||
        d.month != n.month ||
        d.day != n.day) {
      _quoteHex = _computeQuote(n);
      _quoteDay = n;
    }
    return _quoteHex!;
  }

  Hex _computeQuote(DateTime n) {
    final idx = (n.year * 367 + n.month * 31 + n.day) % 64;
    return _hexRepo.hexByNo(idx + 1);
  }

  /// 今日一卦 (时辰卦 / 刷新轮换)
  Hex get todayHex => _refreshed
      ? _hexRepo.hexByNo(refreshHex(_refreshCount).no)
      : _hexRepo.hexByNo(dailyHex(_now).no); // iter63: 年月日时起卦

  bool get isHourHex => !_refreshed;

  /// 刷新轮换全部 64 卦 (PWA heroRefresh 行为)
  void refreshHero() {
    _refreshCount++;
    _refreshed = true;
    notifyListeners();
  }

  /// iter73: 黄历按「日期 + 时辰」缓存 — 原实现每次整屏重建都重算节气表 +
  /// 四柱 (around() 构造 3 年 × 12 JieMoment 并排序). 跨时辰自动失效.
  String? _almanacKey;
  AlmanacInfo? _almanacCache;

  AlmanacInfo get almanac {
    final n = _now;
    final key = '${n.year}-${n.month}-${n.day}-${(n.hour + 1) ~/ 2}';
    if (_almanacKey != key) {
      _almanacCache = almanacOf(n);
      _almanacKey = key;
    }
    return _almanacCache!;
  }

  /// 问候 (时辰): 子夜安，<称呼> (iter72: 称呼可在设置里改)
  String get greeting {
    final sc = shichenOf(_now);
    return '${sc.greet}，${_profile.readName()}';
  }

  String get shichenTip {
    final sc = shichenOf(_now);
    return '${sc.zhi} · ${sc.name}';
  }

  /// 干支日期行: 丙午年 丙申月 癸未日 · 9月6日
  String get dateLine => ganzhiFull(_now);

  /// 最近占卜 2 条 (过滤掉缺 name/question 的记录, PWA 行为)
  List<HistoryRecord> get recent => _history
      .load()
      .where((r) => r.hexNo != null && r.name != null && r.question.isNotEmpty)
      .take(2)
      .toList();

  /// 重新对时 (跨时辰刷新时辰卦与问候)
  void retime() => notifyListeners();

  Hex hexByNo(int no) => _hexRepo.hexByNo(no);
}
