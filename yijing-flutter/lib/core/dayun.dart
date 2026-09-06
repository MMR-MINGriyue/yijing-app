/// 大运流年 — 移植自易道 PWA divination.js DaYun (逐位对齐)
/// 起运: 分钟级节气表 around() + 3 日折 1 岁; 阳男阴女顺排 / 阴男阳女逆排
library;

import 'solar_terms.dart';
import 'bazi.dart';
import 'yi_calendar.dart';

/// 地支六冲
const Map<String, String> kChong = {
  '子': '午', '午': '子', '丑': '未', '未': '丑', '寅': '申', '申': '寅',
  '卯': '酉', '酉': '卯', '辰': '戌', '戌': '辰', '巳': '亥', '亥': '巳',
};

/// 地支六合
const Map<String, String> kHe = {
  '子': '丑', '丑': '子', '寅': '亥', '亥': '寅', '卯': '戌', '戌': '卯',
  '辰': '酉', '酉': '辰', '巳': '申', '申': '巳', '午': '未', '未': '午',
};

/// 地支相刑 (简化三刑表, 不含自刑)
const Map<String, List<String>> kXing = {
  '寅': ['巳', '申'], '巳': ['申', '寅'], '申': ['寅', '巳'],
  '丑': ['戌', '未'], '戌': ['未', '丑'], '未': ['丑', '戌'],
  '子': ['卯'], '卯': ['子'],
};

/// 天干五合
const Map<String, String> kGanHe = {
  '甲': '己', '己': '甲', '乙': '庚', '庚': '乙',
  '丙': '辛', '辛': '丙', '丁': '壬', '壬': '丁',
  '戊': '癸', '癸': '戊',
};

/// 宫位语义: 0年柱 1月柱 2日柱 3时柱, -1 = 大运
const List<String> kPalaceSemantics = ['年柱·根基', '月柱·父母事业', '日柱·自身婚姻', '时柱·子女'];

/// 十神主事句
const Map<String, String> kGodMain = {
  '比肩': '比肩主事，同侪助力与竞争并见，宜自立不宜依赖',
  '劫财': '劫财当值，破财分福之忧，忌合伙借贷',
  '食神': '食神主事，才艺生发，口福安逸，顺遂之年',
  '伤官': '伤官吐秀，才华显露，慎言辞招忌',
  '偏财': '偏财主事，意外之财可期，忌贪多',
  '正财': '正财主事，勤勉得财，婚姻家庭之象',
  '七杀': '七杀攻身，压力与机遇并存，宜静制不宜躁进',
  '正官': '正官主事，名分职守，功名可期',
  '偏印': '偏印主事，领悟独到，防孤僻多虑',
  '正印': '正印主事，学业文书有喜，贵人扶助',
};

const Map<String, String> _eventTpl = {
  'chong': '冲动{p}，主变动',
  'he': '合入{p}，主牵绊亦有成',
  'xing': '刑扰{p}，主是非烦扰',
};

bool isYangGan(String g) => kGan.indexOf(g) % 2 == 0;

DateTime _addMonths(DateTime d, int n) {
  var y = d.year;
  var mo = d.month + n;
  y += mo ~/ 12;
  mo = mo % 12;
  if (mo < 0) {
    mo += 12;
    y -= 1;
  }
  // 日期钳到目标月末
  final last = DateTime(y, mo + 1, 0).day;
  return DateTime(y, mo, d.day > last ? last : d.day, d.hour, d.minute);
}

DateTime _addYears(DateTime d, int n) {
  var y = d.year + n;
  var mo = d.month, da = d.day;
  if (mo == 2 && da == 29 && !(y % 4 == 0 && (y % 100 != 0 || y % 400 == 0))) {
    mo = 3;
    da = 1;
  }
  return DateTime(y, mo, da, d.hour, d.minute);
}

/// 时刻 ts 所属的立春年 (立春前属上一年)
int liChunYear(int ts) {
  final y = bjYear(ts);
  final list = jieList(y);
  if (list != null && ts < list[1].ts) return y - 1;
  return y;
}

class QiYun {
  final int years;
  final int months;
  final DateTime startTs;
  final String termName; // 取作起运基准的节名
  final bool nearEdge; // 出生贴近节界 (< 24h), 起运敏感

  const QiYun({
    required this.years,
    required this.months,
    required this.startTs,
    required this.termName,
    required this.nearEdge,
  });
}

/// 起运: 顺行取下一节, 逆行取上一节; 3 日折 1 岁精确到月 (PWA qiYun)
QiYun? qiYun(DateTime birth, bool fwd) {
  final tsMs = birth.millisecondsSinceEpoch;
  final a = around(tsMs);
  if (a == null) return null;
  final gapMin = ((fwd ? a.next.ts - tsMs : tsMs - a.prev.ts) / 60000).round();
  final totalMonths = (gapMin / (3 * 24 * 60) * 12).round();
  return QiYun(
    years: totalMonths ~/ 12,
    months: totalMonths % 12,
    startTs: _addMonths(birth, totalMonths),
    termName: fwd ? a.next.name : a.prev.name,
    nearEdge: (a.next.ts - tsMs).min(tsMs - a.prev.ts) < 24 * 3600000,
  );
}

extension _MinInt on int {
  int min(int other) => this < other ? this : other;
}

/// 单个流年分析: 十神主事 + 冲合刑事件 + 岁运天干关系 (PWA analyzeYear)
class LiuNianYear {
  final int year;
  final String gz;
  final String god; // 流年十神
  final String text; // 断语
  final bool current;

  const LiuNianYear({
    required this.year,
    required this.gz,
    required this.god,
    required this.text,
    required this.current,
  });
}

LiuNianYear analyzeYear(BaZiChart bazi, int year, String gzY, String stepGZ) {
  final god = tenGod(bazi.dayGan, gzY[0]);
  final zhiY = gzY[1];
  // 冲合刑事件: 对四柱 + 大运地支
  final events = <({String type, int palace})>[];
  final targets = <({String zhi, int palace})>[
    for (var i = 0; i < 4; i++) (zhi: bazi.pillars[i].zhi, palace: i),
    (zhi: stepGZ[1], palace: -1),
  ];
  for (final t in targets) {
    String? type;
    if (kChong[zhiY] == t.zhi) {
      type = 'chong';
    } else if (kHe[zhiY] == t.zhi) {
      type = 'he';
    } else if ((kXing[zhiY] ?? const []).contains(t.zhi)) {
      type = 'xing';
    }
    if (type != null && !events.any((e) => e.type == type && e.palace == t.palace)) {
      events.add((type: type, palace: t.palace));
    }
  }
  final eventText = events.map((e) {
    final p = e.palace == -1 ? '大运' : kPalaceSemantics[e.palace];
    return _eventTpl[e.type]!.replaceFirst('{p}', p);
  }).join('；');
  // 岁运天干关系
  final me = kGanWuxing[gzY[0]]!, dy = kGanWuxing[stepGZ[0]]!;
  String ganRel;
  if (kGanHe[gzY[0]] == stepGZ[0]) {
    ganRel = '岁运天干相合，情事牵绊';
  } else if (_shengOf(me) == dy) {
    ganRel = '岁生运，顺势';
  } else if (_shengOf(dy) == me) {
    ganRel = '运生岁，得助';
  } else if (_keOf(me) == dy) {
    ganRel = '岁克运，制衡';
  } else if (_keOf(dy) == me) {
    ganRel = '运克岁，受阻';
  } else {
    ganRel = '岁运比和';
  }
  final godMain = kGodMain[god] ?? '$god主事';
  final tail = eventText.isEmpty ? '' : '$eventText。';
  final text = '$godMain。$tail$ganRel。';
  return LiuNianYear(year: year, gz: gzY, god: god, text: text, current: false);
}

// analyzeYear 内用与我生/我克 (与 bazi.dart 的表同源)
String _shengOf(String w) =>
    {'木': '火', '火': '土', '土': '金', '金': '水', '水': '木'}[w]!;
String _keOf(String w) =>
    {'木': '土', '土': '水', '水': '火', '火': '金', '金': '木'}[w]!;

/// 一步大运
class DaYunStep {
  final String gz;
  final String ganGod;
  final DateTime startTs;
  final DateTime endTs;
  final int startYear;
  final int endYear;
  final int startAge;
  final bool current;
  final List<LiuNianYear> liuNian;

  const DaYunStep({
    required this.gz,
    required this.ganGod,
    required this.startTs,
    required this.endTs,
    required this.startYear,
    required this.endYear,
    required this.startAge,
    required this.current,
    required this.liuNian,
  });
}

/// 大运总分析 (PWA analyze): 8 步大运 × 每步 10 流年
class DaYunChart {
  final BaZiChart bazi;
  final bool forward;
  final QiYun? qiYunInfo;
  final List<DaYunStep> steps;

  const DaYunChart({
    required this.bazi,
    required this.forward,
    required this.qiYunInfo,
    required this.steps,
  });
}

DaYunChart? analyzeDaYun(DateTime birth, String gender, {DateTime? now}) {
  final bazi = computeBaZi(birth);
  if (bazi == null) return null;
  final fwd = (gender != 'female') == isYangGan(bazi.pillars[0].gan);
  final qy = qiYun(birth, fwd);
  final nowTs = (now ?? DateTime.now()).millisecondsSinceEpoch;
  final curLYear = liChunYear(nowTs);

  final mGz = bazi.pillars[1].gz;
  final mg = kGan.indexOf(mGz[0]), mz = kZhi.indexOf(mGz[1]);
  final dir = fwd ? 1 : -1;
  final steps = <DaYunStep>[];
  if (qy == null) {
    return DaYunChart(bazi: bazi, forward: fwd, qiYunInfo: null, steps: steps);
  }
  for (var i = 0; i < 8; i++) {
    final gz = kGan[(mg + dir * (i + 1) + 100) % 10] +
        kZhi[(mz + dir * (i + 1) + 120) % 12];
    final sTs = i == 0 ? qy.startTs : _addYears(steps[i - 1].startTs, 10);
    final eTs = _addYears(sTs, 10);
    final y0 = liChunYear(sTs.millisecondsSinceEpoch);
    final liuNian = <LiuNianYear>[];
    for (var k = 0; k < 10; k++) {
      final yy = y0 + k;
      if (yy > 2100) break; // 节气表上限
      final gzY = ganzhiYear(DateTime(yy, 7, 1));
      final ev = analyzeYear(bazi, yy, gzY, gz);
      liuNian.add(LiuNianYear(
        year: yy,
        gz: ev.gz,
        god: ev.god,
        text: ev.text,
        current: yy == curLYear,
      ));
    }
    steps.add(DaYunStep(
      gz: gz,
      ganGod: tenGod(bazi.dayGan, gz[0]),
      startTs: sTs,
      endTs: eTs,
      startYear: sTs.year,
      endYear: _addYears(eTs, -1).year,
      startAge: qy.years + 10 * i,
      current: nowTs >= sTs.millisecondsSinceEpoch &&
          nowTs < eTs.millisecondsSinceEpoch,
      liuNian: liuNian,
    ));
  }
  return DaYunChart(bazi: bazi, forward: fwd, qiYunInfo: qy, steps: steps);
}
