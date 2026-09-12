/// 八字进阶推演 (iter47) — 十二长生 / 旬空 / 胎元 / 命宫
/// 依传统命理通例实现; 命宫/胎元属参考项, 各派略有出入 (见注释).
library;

import 'bazi.dart';
import 'yi_calendar.dart';

// ---------- 十二长生 ----------

/// 十二长生次序 (阳干顺行 / 阴干逆行共用本序)
const List<String> kChangShengSeq = [
  '长生', '沐浴', '冠带', '临官', '帝旺', '衰', '病', '死', '墓', '绝', '胎', '养',
];

/// 各天干长生之地: 甲亥 乙午 丙寅 丁酉 戊寅 己酉 庚巳 辛子 壬申 癸卯
const Map<String, String> kChangShengStart = {
  '甲': '亥', '乙': '午', '丙': '寅', '丁': '酉', '戊': '寅',
  '己': '酉', '庚': '巳', '辛': '子', '壬': '申', '癸': '卯',
};

/// 日干对某地支的十二长生状态 (阳干顺行, 阴干逆行)
String changShengOf(String dayGan, String zhi) {
  final start = kChangShengStart[dayGan];
  if (start == null) return '';
  final yang = kGan.indexOf(dayGan) % 2 == 0; // 甲丙戊庚壬 = 阳
  final sIdx = kZhi.indexOf(start);
  final zIdx = kZhi.indexOf(zhi);
  if (sIdx < 0 || zIdx < 0) return '';
  final step = yang ? (zIdx - sIdx + 12) % 12 : (sIdx - zIdx + 12) % 12;
  return kChangShengSeq[step];
}

// ---------- 旬空 (空亡) ----------

/// 六旬空亡: 甲子旬空戌亥 / 甲戌旬空申酉 / 甲申旬空午未 /
/// 甲午旬空辰巳 / 甲辰旬空寅卯 / 甲寅旬空子丑
const List<List<String>> kXunKong = [
  ['戌', '亥'], ['申', '酉'], ['午', '未'],
  ['辰', '巳'], ['寅', '卯'], ['子', '丑'],
];

/// 干支 → 旬空两支 (干支非法返回空)
List<String> xunKongOf(String gz) {
  if (gz.length != 2) return const [];
  final gi = kGan.indexOf(gz[0]);
  final zi = kZhi.indexOf(gz[1]);
  if (gi < 0 || zi < 0) return const [];
  // 由干支反推六十甲子序号 (索引 i%10=干, i%12=支)
  var idx = -1;
  for (var i = 0; i < 60; i++) {
    if (i % 10 == gi && i % 12 == zi) {
      idx = i;
      break;
    }
  }
  if (idx < 0) return const [];
  return kXunKong[idx ~/ 10];
}

// ---------- 胎元 / 命宫 (参考项) ----------

/// 胎元: 月柱天干进一位, 月柱地支进三位 (如 辛巳 → 壬申)
String taiYuanOf(String monthGz) {
  if (monthGz.length != 2) return '';
  final gi = kGan.indexOf(monthGz[0]);
  final zi = kZhi.indexOf(monthGz[1]);
  if (gi < 0 || zi < 0) return '';
  return kGan[(gi + 1) % 10] + kZhi[(zi + 3) % 12];
}

/// 命宫 (月支 + 时支 合数, 不足14者以14减, 过14者以26减, 得数顺数至命宫支).
/// [base] 起数法: yinFirst = 月数自寅起 (寅月=1, 通例, 默认);
/// ziFirst = 月数自子起 (子月=1). 命宫天干按年干五虎遁推得.
String mingGongOf(String yearGan, String monthZhi, String hourZhi,
    {MingGongBase base = MingGongBase.yinFirst}) {
  final mIdx = kZhi.indexOf(monthZhi);
  final hIdx = kZhi.indexOf(hourZhi);
  if (mIdx < 0 || hIdx < 0) return '';
  // 月数 / 时数 (时数恒自子起: 子=1 … 亥=12)
  final mv = base == MingGongBase.ziFirst
      ? mIdx + 1 // 子月=1
      : ((mIdx - 2 + 12) % 12) + 1; // 寅月=1
  final hv = hIdx + 1;
  final sum = mv + hv;
  var k = sum <= 14 ? 14 - sum : 26 - sum;
  if (k <= 0) k += 12; // 合数恰为 14/26 时循环取 12 (避免空值)
  // 自起点顺数 k 位: 寅首 → (2 + k - 1); 子首 → (0 + k - 1)
  final baseIdx = base == MingGongBase.ziFirst ? 0 : 2;
  final gongZhiIdx = (baseIdx + k - 1) % 12;
  final gongZhi = kZhi[gongZhiIdx];
  // 五虎遁: 年干甲己起丙寅, 乙庚起戊寅, 丙辛起庚寅, 丁壬起壬寅, 戊癸起甲寅
  final yIdx = kGan.indexOf(yearGan);
  if (yIdx < 0) return gongZhi;
  const yinGanStart = [2, 4, 6, 8, 0]; // 丙戊庚壬甲
  final startGan = yinGanStart[yIdx % 5];
  // 自寅起算命宫地支距寅的位数 (天干恒自寅起五虎遁)
  final monthsFromYin = (gongZhiIdx - 2 + 12) % 12;
  final gongGan = kGan[(startGan + monthsFromYin) % 10];
  return gongGan + gongZhi;
}

/// 命盘进阶要素聚合
class BaZiExtra {
  final List<String> changSheng; // 四柱地支的十二长生 (年月日时)
  final List<String> xunKong; // 日柱旬空
  final String taiYuan;
  final String mingGong;

  const BaZiExtra({
    required this.changSheng,
    required this.xunKong,
    required this.taiYuan,
    required this.mingGong,
  });
}

BaZiExtra baziExtraOf(BaZiChart c) {
  final dayGan = c.dayGan;
  return BaZiExtra(
    changSheng: c.pillars.map((p) => changShengOf(dayGan, p.zhi)).toList(),
    xunKong: xunKongOf(c.pillars[2].gz),
    taiYuan: taiYuanOf(c.pillars[1].gz),
    mingGong: mingGongOf(c.pillars[0].gan, c.pillars[1].zhi, c.pillars[3].zhi,
        base: c.options.mingGongBase),
  );
}
