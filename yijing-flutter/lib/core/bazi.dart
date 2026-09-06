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
class BaZiChart {
  final List<BaZiPillar> pillars; // 年/月/日/时
  final Map<String, int> wuxing; // 4 天干 + 4 地支本气
  final String dayGan;
  final String dayElement;
  final String strength; // 偏强/中和/偏弱
  final String shichen; // 子时/丑时…
  final LunarDate? lunar;

  const BaZiChart({
    required this.pillars,
    required this.wuxing,
    required this.dayGan,
    required this.dayElement,
    required this.strength,
    required this.shichen,
    required this.lunar,
  });
}

/// 排四柱 (PWA BaZi.compute; 月柱走分钟级节气精确路径)
BaZiChart? computeBaZi(DateTime dt) {
  final lunar = solarToLunar(dt);
  final scIdx = shichenIndex(dt);
  final yGz = ganzhiYear(dt);
  final mGz = ganzhiMonthPrecise(dt);
  final dGz = ganzhiDay(dt);
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
  );
}
