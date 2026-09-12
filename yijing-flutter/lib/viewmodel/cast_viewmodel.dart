import 'package:flutter/foundation.dart';

import '../core/bazi.dart';
import '../core/cast_engine.dart';
import '../core/dayun.dart';
import '../core/meihua.dart';
import '../core/xiaoliuren.dart';
import '../data/history_repository.dart';
import '../data/hex_repository.dart';
import '../model/hex.dart';
import '../model/history.dart';

/// 屏 2 起卦阶段
enum CastPhase { form, casting, done }

/// 起卦方式 (易经三式)
enum CastMethod { numeric, yarrow, coin }

extension CastMethodX on CastMethod {
  String get id => switch (this) {
        CastMethod.numeric => 'numeric',
        CastMethod.yarrow => 'yarrow',
        CastMethod.coin => 'coin',
      };
  String get label => switch (this) {
        CastMethod.numeric => '数字起卦',
        CastMethod.yarrow => '蓍草起卦',
        CastMethod.coin => '铜钱起卦',
      };
  String get sub => switch (this) {
        CastMethod.numeric => '心念取数 · 梅花先天',
        CastMethod.yarrow => '大衍之数 · 古法蓍草',
        CastMethod.coin => '三枚铜钱 · 摇六次',
      };
}

/// 问卦方向
const List<({String dir, String color})> kDirections = [
  (dir: '事业', color: 'cinnabar'),
  (dir: '感情', color: 'pine'),
  (dir: '财运', color: 'gold'),
];

/// 屏 2 状态 (不可变快照)
class CastState {
  final CastPhase phase;
  final CastMethod method;
  final String question;
  final String direction;
  final CastResult? result;
  final Hex? hex;
  final XiaoLiuRenResult? xlr;
  final bool morePage; // 更多占法子页
  final BaZiChart? bazi;
  final DaYunChart? dayun;
  final int? selectedDayunStep; // 流年展开的大运步序

  const CastState({
    this.phase = CastPhase.form,
    this.method = CastMethod.numeric,
    this.question = '',
    this.direction = '事业',
    this.result,
    this.hex,
    this.xlr,
    this.morePage = false,
    this.bazi,
    this.dayun,
    this.selectedDayunStep,
  });

  CastState copyWith({
    CastPhase? phase, CastMethod? method, String? question,
    String? direction, CastResult? result, Hex? hex,
    XiaoLiuRenResult? xlr, bool? morePage, bool clearResult = false,
    bool clearXlr = false, BaZiChart? bazi, DaYunChart? dayun,
    bool clearBazi = false, int? selectedDayunStep,
  }) =>
      CastState(
        phase: phase ?? this.phase,
        method: method ?? this.method,
        question: question ?? this.question,
        direction: direction ?? this.direction,
        result: clearResult ? null : (result ?? this.result),
        hex: clearResult ? null : (hex ?? this.hex),
        xlr: clearXlr ? null : (xlr ?? this.xlr),
        morePage: morePage ?? this.morePage,
        bazi: clearBazi ? null : (bazi ?? this.bazi),
        dayun: clearBazi ? null : (dayun ?? this.dayun),
        selectedDayunStep: selectedDayunStep,
      );
}

/// ViewModel — 屏 2 起卦 (易经三式 + 小六壬 + 落历史)
class CastViewModel extends ChangeNotifier {
  final HexRepository _hexRepo;
  final HistoryRepository _history;
  final double Function()? _rand;
  final DateTime Function()? _now; // 测试注入时钟

  CastViewModel({
    HexRepository? hexRepo,
    HistoryRepository? history,
    this._rand,
    this._now,
  })  : _hexRepo = hexRepo ?? HexRepository.instance,
        _history = history ?? HistoryRepository.instance {
    _state = CastState(direction: kDirections.first.dir);
  }

  late CastState _state;
  CastState get state => _state;

  void setMethod(CastMethod m) {
    _state = _state.copyWith(method: m, phase: CastPhase.form, clearResult: true, clearXlr: true);
    notifyListeners();
  }

  void setQuestion(String q) {
    _state = _state.copyWith(question: q);
    notifyListeners();
  }

  void setDirection(String d) {
    _state = _state.copyWith(direction: d);
    notifyListeners();
  }

  void openMorePage() {
    _state = _state.copyWith(morePage: true, clearResult: true, clearXlr: true);
    notifyListeners();
  }

  void backToMain() {
    _state = _state.copyWith(morePage: false);
    notifyListeners();
  }

  DateTime get _clock => _now?.call() ?? DateTime.now();

  /// 起卦主流程: form → casting → done (真实结果 + 落历史)
  void startCast() {
    _state = _state.copyWith(phase: CastPhase.casting, clearResult: true, clearXlr: true);
    notifyListeners();
  }

  /// 推演动画结束后调用: 生成真实卦象 + 写入历史
  void finishCast() {
    final now = _clock;
    final res = cast(_state.method.id, _state.question, rand: _rand);
    final hexNo = _hexRepo.hexByBits(res.lines.map((y) => y ? '1' : '0').join()).no;
    final hex = _hexRepo.hexByNo(hexNo);
    final rec = HistoryRecord(
      hexNo: hex.no,
      name: hex.name,
      question: _state.question.trim().isEmpty ? '未记录问题' : _state.question.trim(),
      direction: _state.direction,
      directionColor: kDirections
          .firstWhere((d) => d.dir == _state.direction, orElse: () => kDirections.first)
          .color,
      type: 'iching',
      ts: now,
      lines: List.of(res.lines),
      moving: List.of(res.moving),
    );
    _history.add(rec);
    _state = _state.copyWith(phase: CastPhase.done, result: res, hex: hex);
    notifyListeners();
  }

  /// 小六壬一键起课 (农历真实数据 + 问事分类断语, 落历史)
  void castXlr([String askKind = '谋事']) {
    final now = _clock;
    final res = divineXiaoLiuRen(now, askKind: askKind);
    if (res == null) return;
    _history.add(HistoryRecord(
      question: res.summary,
      direction: _state.direction,
      directionColor: kDirections
          .firstWhere((d) => d.dir == _state.direction, orElse: () => kDirections.first)
          .color,
      type: 'xlr',
      ts: now,
    ));
    _state = _state.copyWith(xlr: res);
    notifyListeners();
  }

  /// 梅花易数 · 数字式 (两数起卦, 复用先天数引擎, 落历史)
  void castMeihua(int n1, int n2) {
    final now = _clock;
    final res = castByNumbers(n1, n2);
    final hexNo = _hexRepo.hexByBits(res.lines.map((y) => y ? '1' : '0').join()).no;
    final hex = _hexRepo.hexByNo(hexNo);
    _history.add(HistoryRecord(
      hexNo: hex.no,
      name: hex.name,
      question: '梅花易数 · $n1/$n2',
      direction: _state.direction,
      directionColor: kDirections
          .firstWhere((d) => d.dir == _state.direction, orElse: () => kDirections.first)
          .color,
      type: 'meihua',
      ts: now,
      lines: List.of(res.lines),
      moving: List.of(res.moving),
    ));
    _state = _state.copyWith(phase: CastPhase.done, result: res, hex: hex);
    notifyListeners();
  }

  /// 梅花易数 · 掷骰式 (两枚1-8骰 + 动爻1-6, 落历史)
  void castMeihuaDice() {
    final now = _clock;
    final res = meiHuaByDice();
    final hex = _hexRepo.hexByNo(res.hexNo);
    _history.add(HistoryRecord(
      hexNo: hex.no,
      name: hex.name,
      question: '梅花掷骰 · ${res.source}',
      direction: _state.direction,
      directionColor: kDirections
          .firstWhere((d) => d.dir == _state.direction, orElse: () => kDirections.first)
          .color,
      type: 'meihua',
      ts: now,
      lines: List.of(res.lines),
      moving: [res.movingIdx],
    ));
    _state = _state.copyWith(
      phase: CastPhase.done,
      hex: hex,
      result: CastResult(lines: res.lines, moving: [res.movingIdx], method: 'meihua'),
    );
    notifyListeners();
  }
  void computeBazi(DateTime birth, String gender) {
    final chart = computeBaZi(birth);
    if (chart == null) return;
    final dayun = analyzeDaYun(birth, gender, now: _clock);
    _history.add(HistoryRecord(
      question: '八字排盘 · ${chart.pillars.map((p) => p.gz).join(' ')}',
      direction: _state.direction,
      directionColor: kDirections
          .firstWhere((d) => d.dir == _state.direction, orElse: () => kDirections.first)
          .color,
      type: 'bazi',
      ts: _clock,
    ));
    _state = _state.copyWith(bazi: chart, dayun: dayun);
    notifyListeners();
  }

  /// 梅花易数 · 时间式 (农历真实数据; 落历史, 复用 done 结果视图)
  void castMeihuaTime() {
    final now = _clock;
    final res = meiHuaByTime(now);
    if (res == null) return;
    final hex = _hexRepo.hexByNo(res.hexNo);
    _history.add(HistoryRecord(
      hexNo: hex.no,
      name: hex.name,
      question: '梅花时间式 · ${res.source}',
      direction: _state.direction,
      directionColor: kDirections
          .firstWhere((d) => d.dir == _state.direction, orElse: () => kDirections.first)
          .color,
      type: 'meihua',
      ts: now,
      lines: List.of(res.lines),
      moving: [res.movingIdx],
    ));
    _state = _state.copyWith(
      phase: CastPhase.done,
      hex: hex,
      result: CastResult(lines: res.lines, moving: [res.movingIdx], method: 'meihua'),
    );
    notifyListeners();
  }

  /// 展开/收起某步大运的流年列表
  void selectDayunStep(int? i) {
    _state = _state.copyWith(selectedDayunStep: i);
    notifyListeners();
  }

  /// 重置回表单 (再占一卦)
  void reset() {
    _state = CastState(direction: _state.direction);
    notifyListeners();
  }

  Hex hexByNo(int no) => _hexRepo.hexByNo(no);
}
