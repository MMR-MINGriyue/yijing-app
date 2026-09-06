/// 梅花易数 — 移植自易道 PWA divination.js MeiHua (逐位对齐)
/// 时间式 (农历年支序+月+日定上卦, 加时辰定下卦) / 数字式 / 掷骰式
library;

import 'dart:math';

import '../data/hex_library.dart';
import 'lunar_calendar.dart';
import 'yi_calendar.dart';

/// 先天八卦数 → 卦名 (PWA NUM_TO_TRIGRAM: 乾1兑2离3震4巽5坎6艮7坤8)
const List<String> kNumToTrigram = ['', '乾', '兑', '离', '震', '巽', '坎', '艮', '坤'];

/// 八卦 → 三爻 (自下而上, 1=阳 0=阴)
const Map<String, List<int>> kTrigramLines = {
  '乾': [1, 1, 1], '兑': [0, 1, 1], '离': [1, 0, 1], '震': [1, 0, 0],
  '巽': [0, 1, 1], '坎': [0, 1, 0], '艮': [0, 0, 1], '坤': [0, 0, 0],
};

String trigramByNum(int n) => kNumToTrigram[((n - 1) % 8) + 1];

/// 由上下卦 (卦名) + 动爻组装六爻布尔 (初→上)
List<bool> buildLines(String lowerTri, String upperTri, int movingIdx) {
  return [...kTrigramLines[lowerTri]!, ...kTrigramLines[upperTri]!]
      .map((b) => b == 1)
      .toList();
}

/// 梅花起卦结果
class MeiHuaResult {
  final String upper; // 上卦名
  final String lower; // 下卦名
  final int movingIdx; // 动爻索引 (0=初)
  final String method; // 时间起卦/数字起卦/掷骰起卦
  final String source; // 一句话来源
  final List<bool> lines; // 六爻 初→上
  final int hexNo; // 本卦序
  final DateTime date;

  const MeiHuaResult({
    required this.upper,
    required this.lower,
    required this.movingIdx,
    required this.method,
    required this.source,
    required this.lines,
    required this.hexNo,
    required this.date,
  });
}

/// 六爻 (初→上) → 卦序 (与 YijingEngine.hexByLines 一致)
int _hexNoByLines(List<bool> lines) {
  final key = lines.map((y) => y ? '1' : '0').join();
  for (final h in kHexLibrary) {
    if (h.bits == key) return h.no;
  }
  return 1;
}

MeiHuaResult _assemble(
    String upper, String lower, int movingIdx, String method, String source, DateTime date) {
  final lines = buildLines(lower, upper, movingIdx);
  final no = _hexNoByLines(lines);
  return MeiHuaResult(
    upper: upper,
    lower: lower,
    movingIdx: movingIdx,
    method: method,
    source: source,
    lines: lines,
    hexNo: no,
    date: date,
  );
}

/// 时间起卦 (PWA byTime): 农历年支序+月+日 → 上卦, 加时辰 → 下卦, 合数%6 动爻
MeiHuaResult? meiHuaByTime(DateTime dt) {
  final lunar = solarToLunar(dt);
  if (lunar == null) return null;
  final yearZhiIdx = ((lunar.year - 1900) % 12 + 12) % 12; // 1900=子
  final sc = shichenIndex(dt);
  final m = lunar.month, d = lunar.day, h = sc + 1;
  var upperN = (yearZhiIdx + 1 + m + d) % 8;
  if (upperN == 0) upperN = 8;
  var lowerN = (yearZhiIdx + 1 + m + d + h) % 8;
  if (lowerN == 0) lowerN = 8;
  var moving = (yearZhiIdx + 1 + m + d + h) % 6;
  if (moving == 0) moving = 6;
  return _assemble(
    trigramByNum(upperN),
    trigramByNum(lowerN),
    moving - 1,
    '时间起卦',
    '农历${lunar.monthLabel}${lunar.dayLabel} ${kZhi[sc]}时',
    dt,
  );
}

/// 数字起卦 (PWA byNumbers): 前数取上卦, 后数取下卦, 合数%6 动爻
MeiHuaResult meiHuaByNumbers(int a, int b) {
  a = a.abs() == 0 ? 1 : a.abs();
  b = b.abs() == 0 ? 1 : b.abs();
  var upperN = a % 8;
  if (upperN == 0) upperN = 8;
  var lowerN = b % 8;
  if (lowerN == 0) lowerN = 8;
  var moving = (a + b) % 6;
  if (moving == 0) moving = 6;
  return _assemble(trigramByNum(upperN), trigramByNum(lowerN), moving - 1,
      '数字起卦', '以 $a、$b 两数取象', DateTime.now());
}

/// 掷骰起卦 (PWA byDice): 两枚 1-8 + 动爻 1-6
MeiHuaResult meiHuaByDice({double Function()? rand}) {
  final rnd = rand ?? _defaultRand;
  final a = 1 + (rnd() * 8).floor();
  final b = 1 + (rnd() * 8).floor();
  final moving = 1 + (rnd() * 6).floor();
  return _assemble(trigramByNum(a), trigramByNum(b), moving - 1, '掷骰起卦',
      '骰得 $a、$b, 动 $moving 爻', DateTime.now());
}

final Random _rng = Random();

double _defaultRand() => _rng.nextDouble();
