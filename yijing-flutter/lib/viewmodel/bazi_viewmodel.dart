/// 八字命盘 ViewModel (iter47) — 屏 3「八字」Tab
/// 职责: 出生输入 (记忆上次) + 排盘 + 大运流年 + 解读卡组
library;

import 'package:flutter/foundation.dart';

import '../core/bazi.dart';
import '../core/bazi_extra.dart';
import '../core/bazi_reading.dart';
import '../core/dayun.dart';
import '../data/bazi_store.dart';
import '../data/history_repository.dart';
import '../model/history.dart';

class BaziState {
  final DateTime? birth;
  final String gender; // male=乾造 female=坤造
  final BaZiChart? chart;
  final DaYunChart? dayun;
  final BaZiExtra? extra;
  final List<BaziReading> readings;
  final int? selectedStep; // 展开的大运步
  final bool restored; // 是否来自记忆

  const BaziState({
    this.birth,
    this.gender = 'male',
    this.chart,
    this.dayun,
    this.extra,
    this.readings = const [],
    this.selectedStep,
    this.restored = false,
  });

  bool get hasResult => chart != null;

  BaziState copyWith({
    DateTime? birth,
    String? gender,
    BaZiChart? chart,
    DaYunChart? dayun,
    BaZiExtra? extra,
    List<BaziReading>? readings,
    int? selectedStep,
    bool clearStep = false,
    bool clearResult = false,
    bool? restored,
  }) =>
      BaziState(
        birth: birth ?? this.birth,
        gender: gender ?? this.gender,
        chart: clearResult ? null : (chart ?? this.chart),
        dayun: clearResult ? null : (dayun ?? this.dayun),
        extra: clearResult ? null : (extra ?? this.extra),
        readings: clearResult ? const [] : (readings ?? this.readings),
        selectedStep: (clearResult || clearStep) ? null : (selectedStep ?? this.selectedStep),
        restored: restored ?? this.restored,
      );
}

class BaziViewModel extends ChangeNotifier {
  BaziViewModel(
      {BaziBirthStore? store, DateTime Function()? clock, HistoryRepository? historyRepo})
      : _store = store ?? baziBirthStoreFactory(),
        _now = clock,
        _history = historyRepo {
    _boot();
  }

  final BaziBirthStore _store;
  final DateTime Function()? _now;
  final HistoryRepository? _history;
  // 落记录: 优先注入的 history, 缺省用单例

  BaziState _state = const BaziState();
  BaziState get state => _state;

  DateTime _clock() => _now?.call() ?? DateTime.now();

  /// 启动: 载入记忆的出生信息并自动排盘
  Future<void> _boot() async {
    try {
      await _store.warmUp();
      final saved = _store.read();
      if (saved == null) return;
      _state = _state.copyWith(birth: saved.dt, gender: saved.gender, restored: true);
      compute();
    } catch (_) {} // 无存储环境静默
  }

  void setBirth(DateTime dt, {String? gender}) {
    _state = _state.copyWith(birth: dt, gender: gender, restored: false);
    notifyListeners();
  }

  void setGender(String gender) {
    _state = _state.copyWith(gender: gender, restored: false);
    notifyListeners();
  }

  /// 排盘 + 大运 + 解读 (落记忆)
  void compute() {
    final birth = _state.birth;
    if (birth == null) return;
    final chart = computeBaZi(birth);
    if (chart == null) return;
    final dayun = analyzeDaYun(birth, _state.gender, now: _clock());
    _state = _state.copyWith(
      chart: chart,
      dayun: dayun,
      extra: baziExtraOf(chart),
      readings: baziReadings(chart),
      selectedStep: null,
    );
    _store.write(BaziBirth(dt: birth, gender: _state.gender));
    // 落历史 (与旧 CastVM 行为一致)
    final repo = _history ?? HistoryRepository.instance;
    repo.add(HistoryRecord(
      question: '八字排盘 · ${chart.pillars.map((p) => p.gz).join(' ')}',
      direction: '事业',
      directionColor: 'cinnabar',
      type: 'bazi',
      ts: _clock(),
    ));
    notifyListeners();
  }

  void selectStep(int? i) {
    _state = i == null
        ? _state.copyWith(clearStep: true)
        : _state.copyWith(selectedStep: i);
    notifyListeners();
  }

  /// 清空当前盘 (保留输入)
  void clearResult() {
    _state = _state.copyWith(clearResult: true);
    notifyListeners();
  }
}
