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
  '乾': [1, 1, 1], '兑': [1, 1, 0], '离': [1, 0, 1], '震': [1, 0, 0],
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

// ---------- 体用生克断法 (iter44: 梅花断法核心, 超越 PWA 基线) ----------

/// 梅花体用分析结果
class MeiHuaAnalysis {
  final String tiName; // 体卦名 (静卦)
  final String tiWuxing;
  final String yongName; // 用卦名 (动爻所在卦)
  final String yongWuxing;
  final String relation; // 比和/用生体/体生用/体克用/用克体
  final String verdict; // 吉/凶/小凶/小吉
  final String verdictText; // 断语
  final int huNo; // 互卦序
  final String huName; // 互卦名
  final int bianNo; // 变卦序
  final String bianName; // 变卦名

  const MeiHuaAnalysis({
    required this.tiName,
    required this.tiWuxing,
    required this.yongName,
    required this.yongWuxing,
    required this.relation,
    required this.verdict,
    required this.verdictText,
    required this.huNo,
    required this.huName,
    required this.bianNo,
    required this.bianName,
  });
}

const Map<String, String> _kSheng = {'木': '火', '火': '土', '土': '金', '金': '水', '水': '木'};
const Map<String, String> _kKe = {'木': '土', '土': '水', '水': '火', '火': '金', '金': '木'};

/// 八卦名 → 五行 (乾兑金 / 离火 / 震巽木 / 坎水 / 艮坤土)
/// 注: model/hex.dart 的 kTriWuxing 以 ☰ 符号为键, 此处按卦名键
const Map<String, String> kTriNameWuxing = {
  '乾': '金', '兑': '金', '离': '火', '震': '木',
  '巽': '木', '坎': '水', '艮': '土', '坤': '土',
};

/// 体用生克关系与断语 (梅花心法: 体为主, 用为事应)
(String, String, String) _tiYongRelation(String ti, String yong) {
  if (ti == yong) {
    return ('比和', '吉', '体用比和，同气相求，所谋遂意，百事顺成。');
  }
  if (_kSheng[yong] == ti) {
    return ('用生体', '大吉', '用卦生体卦，外来相生，进益之喜，或得人扶助，事必有成。');
  }
  if (_kSheng[ti] == yong) {
    return ('体生用', '小凶', '体卦生用卦，气机外泄，有耗散之象，谋事费力，宜守不宜进。');
  }
  if (_kKe[yong] == ti) {
    return ('用克体', '凶', '用卦克体卦，外事相迫，主事多阻隔，防小人与损耗，不宜强求。');
  }
  if (_kKe[ti] == yong) {
    return ('体克用', '小吉', '体卦克用卦，我能制事，事可为但需费力，迟缓方得其利。');
  }
  return ('?', '?', '');
}

/// 六爻 (初→上) → 卦名 (本文件内置, 避免依赖 HexRepository)
String _hexName(List<bool> lines) {
  final key = lines.map((y) => y ? '1' : '0').join();
  for (final h in kHexLibrary) {
    if (h.bits == key) return h.name;
  }
  return '';
}

int _hexNo(List<bool> lines) {
  final key = lines.map((y) => y ? '1' : '0').join();
  for (final h in kHexLibrary) {
    if (h.bits == key) return h.no;
  }
  return 1;
}

/// 梅花体用互变分析:
/// - 动爻在上卦 (3,4,5) → 上卦为用, 下卦为体; 动爻在下卦 → 下卦为用, 上卦为体
/// - 互卦: 二三四爻为下互, 三四五爻为上互
/// - 变卦: 动爻阴阳翻转
MeiHuaAnalysis analyzeMeiHua(List<bool> lines, int movingIdx) {
  final lower = lines.sublist(0, 3);
  final upper = lines.sublist(3, 6);
  // 三爻 → 八卦名
  String triNameOf(List<bool> tri) {
    final key = tri.map((b) => b ? '1' : '0').join();
    for (final e in kTrigramLines.entries) {
      if (e.value.join() == key) return e.key;
    }
    return '';
  }

  final movingInUpper = movingIdx >= 3;
  final tiTri = movingInUpper ? lower : upper;
  final yongTri = movingInUpper ? upper : lower;
  final tiName = triNameOf(tiTri);
  final yongName = triNameOf(yongTri);
  final tiWx = kTriNameWuxing[tiName] ?? '';
  final yongWx = kTriNameWuxing[yongName] ?? '';
  final (relation, verdict, verdictText) = _tiYongRelation(tiWx, yongWx);

  // 互卦: 二三四爻 (idx 1,2,3) 为下互, 三四五爻 (idx 2,3,4) 为上互
  final huLower = [lines[1], lines[2], lines[3]];
  final huUpper = [lines[2], lines[3], lines[4]];
  final huLines = [...huLower, ...huUpper];

  // 变卦: 动爻翻转
  final bianLines = List.of(lines)..[movingIdx] = !lines[movingIdx];

  return MeiHuaAnalysis(
    tiName: tiName,
    tiWuxing: tiWx,
    yongName: yongName,
    yongWuxing: yongWx,
    relation: relation,
    verdict: verdict,
    verdictText: verdictText,
    huNo: _hexNo(huLines),
    huName: _hexName(huLines),
    bianNo: _hexNo(bianLines),
    bianName: _hexName(bianLines),
  );
}
