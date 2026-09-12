/// 八字 (四柱 + 五行 + 十神) — 移植自易道 PWA divination.js BaZi (逐位对齐)
library;

import 'lunar_calendar.dart';
import 'yi_calendar.dart';

const Map<String, String> kGanWuxing = {
  '甲': '木', '乙': '木', '丙': '火', '丁': '火', '戊': '土',
  '己': '土', '庚': '金', '辛': '金', '壬': '水', '癸': '水',
};

const Map<String, String> kZhiWuxing = {
  '子': '水', '丑': '土', '寅': '木', '卯': '木', '辰': '土', '巳': '火',
  '午': '火', '未': '土', '申': '金', '酉': '金', '戌': '土', '亥': '水',
};

/// 地支藏干 (本气/中气/余气)
const Map<String, List<String>> kHidden = {
  '子': ['癸'],
  '丑': ['己', '癸', '辛'],
  '寅': ['甲', '丙', '戊'],
  '卯': ['乙'],
  '辰': ['戊', '乙', '癸'],
  '巳': ['丙', '庚', '戊'],
  '午': ['丁', '己'],
  '未': ['己', '丁', '乙'],
  '申': ['庚', '壬', '戊'],
  '酉': ['辛'],
  '戌': ['戊', '辛', '丁'],
  '亥': ['壬', '甲'],
};

const Map<String, String> _sheng = {'木': '火', '火': '土', '土': '金', '金': '水', '水': '木'};
const Map<String, String> _ke = {'木': '土', '土': '水', '水': '火', '火': '金', '金': '木'};
const Map<String, String> kShengIn = {'木': '水', '火': '木', '土': '火', '金': '土', '水': '金'};

/// 十神: 以日主天干为基准, 按五行生克 + 同异定十神
String tenGod(String dayGan, String otherGan) {
  if (dayGan == otherGan) return '比肩';
  final me = kGanWuxing[dayGan]!, other = kGanWuxing[otherGan]!;
  final sameYinYang =
      kGan.indexOf(dayGan) % 2 == kGan.indexOf(otherGan) % 2;
  if (_sheng[me] == other) return sameYinYang ? '食神' : '伤官';
  if (other == me) return sameYinYang ? '比肩' : '劫财';
  if (_ke[me] == other) return sameYinYang ? '偏财' : '正财';
  if (_ke[other] == me) return sameYinYang ? '七杀' : '正官';
  if (_sheng[other] == me) return sameYinYang ? '偏印' : '正印';
  return '?';
}

/// 时柱: 五鼠遁 — 甲己日甲子时起, 乙庚丙作初, 丙辛戊子起, 丁壬庚子行, 戊癸壬子头
String hourPillar(String dayGan, int shichenIdx) {
  final dIdx = kGan.indexOf(dayGan);
  const hourGanStart = [0, 2, 4, 6, 8];
  final start = hourGanStart[dIdx % 5];
  return kGan[(start + shichenIdx) % 10] + kZhi[shichenIdx % 12];
}

/// 一柱: 干支 + 藏干十神
class BaZiPillar {
  final String pos; // 年/月/日/时
  final String gan;
  final String zhi;
  final String ganGod; // 天干十神 (日柱 = 日主)
  final List<({String gan, String god, String weight})> hidden;

  const BaZiPillar({
    required this.pos,
    required this.gan,
    required this.zhi,
    required this.ganGod,
    required this.hidden,
  });

  String get gz => gan + zhi;
}

/// 排盘结果
/// 流派选项 (iter48) — 存在流派差异的算法点, 由用户选择后随盘计算
enum DayBoundary {
  midnight, // 子夜 0 时换日 (夜子时仍属当日, 默认)
  lateZi, // 夜半 23 时换日 (晚子时算次日)
}

enum MingGongBase {
  yinFirst, // 命宫月数自寅起 (寅月=1, 通例, 默认)
  ziFirst, // 命宫月数自子起 (子月=1)
}

enum ShenShaAnchor {
  yearDay, // 神煞以年支、日支并查 (默认)
  yearOnly, // 神煞仅以年支查
}

class BaZiOptions {
  final DayBoundary dayBoundary;
  final MingGongBase mingGongBase;
  final ShenShaAnchor shenShaAnchor;

  const BaZiOptions({
    this.dayBoundary = DayBoundary.midnight,
    this.mingGongBase = MingGongBase.yinFirst,
    this.shenShaAnchor = ShenShaAnchor.yearDay,
  });

  BaZiOptions copyWith({
    DayBoundary? dayBoundary,
    MingGongBase? mingGongBase,
    ShenShaAnchor? shenShaAnchor,
  }) =>
      BaZiOptions(
        dayBoundary: dayBoundary ?? this.dayBoundary,
        mingGongBase: mingGongBase ?? this.mingGongBase,
        shenShaAnchor: shenShaAnchor ?? this.shenShaAnchor,
      );

  Map<String, String> toJson() => {
        'day': dayBoundary.name,
        'gong': mingGongBase.name,
        'sha': shenShaAnchor.name,
      };

  static BaZiOptions fromJson(Map<String, dynamic> j) => BaZiOptions(
        dayBoundary: DayBoundary.values
            .firstWhere((e) => e.name == j['day'], orElse: () => DayBoundary.midnight),
        mingGongBase: MingGongBase.values
            .firstWhere((e) => e.name == j['gong'], orElse: () => MingGongBase.yinFirst),
        shenShaAnchor: ShenShaAnchor.values
            .firstWhere((e) => e.name == j['sha'], orElse: () => ShenShaAnchor.yearDay),
      );

  bool get isDefault =>
      dayBoundary == DayBoundary.midnight &&
      mingGongBase == MingGongBase.yinFirst &&
      shenShaAnchor == ShenShaAnchor.yearDay;
}

class BaZiChart {
  final List<BaZiPillar> pillars; // 年/月/日/时
  final Map<String, int> wuxing; // 4 天干 + 4 地支本气
  final String dayGan;
  final String dayElement;
  final String strength; // 偏强/中和/偏弱
  final String shichen; // 子时/丑时…
  final LunarDate? lunar;
  final BaZiOptions options; // 所用流派 (iter48)

  const BaZiChart({
    required this.pillars,
    required this.wuxing,
    required this.dayGan,
    required this.dayElement,
    required this.strength,
    required this.shichen,
    required this.lunar,
    this.options = const BaZiOptions(),
  });
}

/// 六十甲子纳音 (iter44) — 每 2 干支一组, 共 30 组
const List<(String, String)> _kNayinPairs = [
  ('甲子', '海中金'), ('乙丑', '海中金'), ('丙寅', '炉中火'), ('丁卯', '炉中火'),
  ('戊辰', '大林木'), ('己巳', '大林木'), ('庚午', '路旁土'), ('辛未', '路旁土'),
  ('壬申', '剑锋金'), ('癸酉', '剑锋金'), ('甲戌', '山头火'), ('乙亥', '山头火'),
  ('丙子', '涧下水'), ('丁丑', '涧下水'), ('戊寅', '城头土'), ('己卯', '城头土'),
  ('庚辰', '白蜡金'), ('辛巳', '白蜡金'), ('壬午', '杨柳木'), ('癸未', '杨柳木'),
  ('甲申', '泉中水'), ('乙酉', '泉中水'), ('丙戌', '屋上土'), ('丁亥', '屋上土'),
  ('戊子', '霹雳火'), ('己丑', '霹雳火'), ('庚寅', '松柏木'), ('辛卯', '松柏木'),
  ('壬辰', '长流水'), ('癸巳', '长流水'), ('甲午', '沙中金'), ('乙未', '沙中金'),
  ('丙申', '山下火'), ('丁酉', '山下火'), ('戊戌', '平地木'), ('己亥', '平地木'),
  ('庚子', '壁上土'), ('辛丑', '壁上土'), ('壬寅', '金箔金'), ('癸卯', '金箔金'),
  ('甲辰', '佛灯火'), ('乙巳', '佛灯火'), ('丙午', '天河水'), ('丁未', '天河水'),
  ('戊申', '大驿土'), ('己酉', '大驿土'), ('庚戌', '钗钏金'), ('辛亥', '钗钏金'),
  ('壬子', '桑柘木'), ('癸丑', '桑柘木'), ('甲寅', '大溪水'), ('乙卯', '大溪水'),
  ('丙辰', '沙中土'), ('丁巳', '沙中土'), ('戊午', '天上火'), ('己未', '天上火'),
  ('庚申', '石榴木'), ('辛酉', '石榴木'), ('壬戌', '大海水'), ('癸亥', '大海水'),
];

/// 干支 → 纳音五行 (如 庚辰 → 白蜡金); 未知干支返回空串
String nayinOf(String gz) {
  for (final (k, v) in _kNayinPairs) {
    if (k == gz) return v;
  }
  return '';
}

// ---------- 神煞 (iter44: 规则推算, 年支/日支查四柱地支) ----------

/// 天乙贵人: 日干查 — 甲戊庚牛羊, 乙己鼠猴乡, 丙丁猪鸡位, 壬癸兔蛇藏, 六辛逢马虎
const Map<String, List<String>> kTianYi = {
  '甲': ['丑', '未'], '戊': ['丑', '未'], '庚': ['丑', '未'],
  '乙': ['子', '申'], '己': ['子', '申'],
  '丙': ['亥', '酉'], '丁': ['亥', '酉'],
  '壬': ['卯', '巳'], '癸': ['卯', '巳'],
  '辛': ['午', '寅'],
};

/// 文昌贵人: 甲乙巳午报, 丙戊申宫扬, 丁己鸡同守, 庚猪辛鼠乡, 壬逢虎位至, 癸人见卯藏
const Map<String, String> kWenChang = {
  '甲': '巳', '乙': '午', '丙': '申', '戊': '申', '丁': '酉', '己': '酉',
  '庚': '亥', '辛': '子', '壬': '寅', '癸': '卯',
};

/// 三合局查表 (iter44): 值 = [驿马, 桃花(咸池), 华盖] 对应地支
/// 申子辰马在寅/花在酉/盖在辰 · 寅午戌马在申/花在卯/盖在戌 ·
/// 巳酉丑马在亥/花在午/盖在丑 · 亥卯未马在巳/花在子/盖在未
const Map<String, List<String>> kSanHe = {
  '申': ['寅', '酉', '辰'], '子': ['寅', '酉', '辰'], '辰': ['寅', '酉', '辰'],
  '寅': ['申', '卯', '戌'], '午': ['申', '卯', '戌'], '戌': ['申', '卯', '戌'],
  '巳': ['亥', '午', '丑'], '酉': ['亥', '午', '丑'], '丑': ['亥', '午', '丑'],
  '亥': ['巳', '子', '未'], '卯': ['巳', '子', '未'], '未': ['巳', '子', '未'],
};

/// 排盘神煞: 返回命中所见神煞名列表 (去重, 保序)
List<String> shenShaOf(BaZiChart chart) {
  final zhis = chart.pillars.map((p) => p.zhi).toList();
  final found = <String>[];
  void add(String name) {
    if (!found.contains(name)) found.add(name);
  }

  // 天乙贵人 / 文昌: 日干查四柱地支 (含日支自身)
  for (final z in zhis) {
    if ((kTianYi[chart.dayGan] ?? const []).contains(z)) add('天乙贵人');
    if (kWenChang[chart.dayGan] == z) add('文昌');
  }
  // 驿马 / 桃花 / 华盖: 依流派锚 (年日并查 / 仅年支) — iter48
  final anchors = chart.options.shenShaAnchor == ShenShaAnchor.yearOnly
      ? {zhis.first}
      : {zhis.first, zhis[2]};
  for (final anchor in anchors) {
    final hit = kSanHe[anchor];
    if (hit == null) continue;
    for (final z in zhis) {
      if (z == hit[0]) add('驿马');
      if (z == hit[1]) add('桃花');
      if (z == hit[2]) add('华盖');
    }
  }
  return found;
}

/// 十神统计: 天干十神 (年月时) + 地支藏干本气十神, 计数表
Map<String, int> tenGodStats(BaZiChart chart) {
  final stats = <String, int>{};
  void bump(String god) => stats[god] = (stats[god] ?? 0) + 1;
  for (final p in chart.pillars) {
    if (p.ganGod != '日主') bump(p.ganGod);
    final benqi = p.hidden.isNotEmpty ? p.hidden.first : null;
    if (benqi != null) bump(benqi.god);
  }
  return stats;
}

/// 排四柱 (PWA BaZi.compute; 月柱走分钟级节气精确路径)
BaZiChart? computeBaZi(DateTime dt, {BaZiOptions options = const BaZiOptions()}) {
  // 晚子时换日: 23:00-23:59 归次日 (年月日柱均以次日推算, 时柱仍子时)
  final calcDt = options.dayBoundary == DayBoundary.lateZi && dt.hour >= 23
      ? DateTime(dt.year, dt.month, dt.day + 1, dt.hour, dt.minute)
      : dt;
  final lunar = solarToLunar(dt);
  final scIdx = shichenIndex(dt);
  final yGz = ganzhiYear(calcDt);
  final mGz = ganzhiMonthPrecise(calcDt);
  final dGz = ganzhiDay(calcDt);
  final hGz = hourPillar(dGz[0], scIdx);

  final gzList = [yGz, mGz, dGz, hGz];
  const posNames = ['年', '月', '日', '时'];
  final pillars = <BaZiPillar>[];
  for (var i = 0; i < 4; i++) {
    final gz = gzList[i];
    final gan = gz[0], zhi = gz[1];
    final hidden = <({String gan, String god, String weight})>[];
    final hg = kHidden[zhi] ?? const ['癸'];
    for (var k = 0; k < hg.length; k++) {
      hidden.add((
        gan: hg[k],
        god: tenGod(dGz[0], hg[k]),
        weight: k == 0 ? '本气' : (k == 1 ? '中气' : '余气'),
      ));
    }
    pillars.add(BaZiPillar(
      pos: posNames[i],
      gan: gan,
      zhi: zhi,
      ganGod: i == 2 ? '日主' : tenGod(dGz[0], gan),
      hidden: hidden,
    ));
  }

  // 五行统计: 4 天干 + 4 地支本气 (简明版, 不含藏干加权)
  final wx = {'木': 0, '火': 0, '土': 0, '金': 0, '水': 0};
  for (final p in pillars) {
    wx[kGanWuxing[p.gan]!] = wx[kGanWuxing[p.gan]!]! + 1;
    wx[kZhiWuxing[p.zhi]!] = wx[kZhiWuxing[p.zhi]!]! + 1;
  }
  final dayEl = kGanWuxing[dGz[0]]!;
  // 日主强弱: 同党 (同我 + 生我) 计数
  final tong = wx[dayEl]! + (wx[kShengIn[dayEl]] ?? 0);
  final strength = tong >= 4 ? '偏强' : (tong <= 2 ? '偏弱' : '中和');

  return BaZiChart(
    pillars: pillars,
    wuxing: wx,
    dayGan: dGz[0],
    dayElement: dayEl,
    strength: strength,
    shichen: '${kZhi[scIdx]}时',
    lunar: lunar,
    options: options,
  );
}
