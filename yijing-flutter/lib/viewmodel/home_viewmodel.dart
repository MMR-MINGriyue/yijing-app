import 'package:flutter/foundation.dart';

import '../core/cast_engine.dart';
import '../core/yi_calendar.dart';
import '../data/history_repository.dart';
import '../data/hex_repository.dart';
import '../model/hex.dart';
import '../model/history.dart';

/// ViewModel — 屏 1 今日一卦 (时辰卦 + 干支问候 + 最近占卜)
class HomeViewModel extends ChangeNotifier {
  final HexRepository _hexRepo;
  final HistoryRepository _history;
  final DateTime Function() _nowFn; // 可注入时钟 (测试)

  HomeViewModel({
    HexRepository? hexRepo,
    HistoryRepository? history,
    DateTime Function()? now,
  })  : _hexRepo = hexRepo ?? HexRepository.instance,
        _history = history ?? HistoryRepository.instance,
        _nowFn = now ?? DateTime.now;

  int _refreshCount = 0;
  bool _refreshed = false; // 刷新过则用 refreshHex 轮换, 否则时辰卦

  DateTime get _now => _nowFn();

  /// 今日一卦 (时辰卦 / 刷新轮换)
  Hex get todayHex => _refreshed
      ? _hexRepo.hexByNo(refreshHex(_refreshCount).no)
      : _hexRepo.hexByNo(hourHex(_now).no);

  bool get isHourHex => !_refreshed;

  /// 刷新轮换全部 64 卦 (PWA heroRefresh 行为)
  void refreshHero() {
    _refreshCount++;
    _refreshed = true;
    notifyListeners();
  }

  /// 问候 (时辰): 子夜安，慕白
  String get greeting {
    final sc = shichenOf(_now);
    return '${sc.greet}，慕白';
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
