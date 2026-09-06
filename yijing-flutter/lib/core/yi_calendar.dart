/// 干支历法 — 移植自易道 PWA js/00-core.js YijingCalendar (逐位对齐)
/// 纪日连续可靠 (锚点 JD 2458511 = 甲子日), 纪年/纪月以立春为界
library;

const List<String> kGan = ['甲', '乙', '丙', '丁', '戊', '己', '庚', '辛', '壬', '癸'];
const List<String> kZhi = ['子', '丑', '寅', '卯', '辰', '巳', '午', '未', '申', '酉', '戌', '亥'];

/// 十二时辰 (PWA js/02-home-cast.js bindHourGreeting HOURS 表)
class Shichen {
  final int hour; // 起始小时
  final String zhi; // 地支
  final String name; // 夜半/鸡鸣…
  final String greet; // 问候 (子夜安/午安…)
  final String desc; // 时辰描述
  const Shichen(this.hour, this.zhi, this.name, this.greet, this.desc);
}

const List<Shichen> kShichen = [
  Shichen(23, '子', '夜 半', '子夜安', '夜深人静，万物归藏'),
  Shichen(1, '丑', '鸡 鸣', '丑时安', '夜色将尽，鸡鸣待旦'),
  Shichen(3, '寅', '平 旦', '寅时安', '黎明破晓，万物苏醒'),
  Shichen(5, '卯', '日 出', '卯时安', '日出东方，朝气初升'),
  Shichen(7, '辰', '食 时', '辰安', '朝食之时，万物舒展'),
  Shichen(9, '巳', '隅 中', '巳时安', '日近中天，阳气正盛'),
  Shichen(11, '午', '日 中', '午安', '日正当中，阴气初生'),
  Shichen(13, '未', '日 昳', '未时安', '日过中天，渐西斜'),
  Shichen(15, '申', '哺 时', '申时安', '夕阳将下，归鸟入林'),
  Shichen(17, '酉', '日 入', '酉时安', '日落西山，万物归息'),
  Shichen(19, '戌', '黄 昏', '戌时安', '暮色四合，天地昏黄'),
  Shichen(21, '亥', '人 定', '亥时安', '人定归寝，万籁俱寂'),
];

/// 公历 → 当前时辰 (PWA: Math.floor((h+1)/2)%12)
Shichen shichenOf(DateTime dt) => kShichen[(dt.hour + 1) ~/ 2 % 12];

/// 格里历 → 儒略日数 (JDN)
int jdn(int y, int m, int d) {
  final a = (14 - m) ~/ 12;
  final yy = y + 4800 - a;
  final mm = m + 12 * a - 3;
  return d +
      ((153 * mm + 2) ~/ 5) +
      365 * yy +
      yy ~/ 4 -
      yy ~/ 100 +
      yy ~/ 400 -
      32045;
}

/// 干支纪日: 60 日一循环, 锚点 JD 2458511 = 甲子日 (PWA: (jdn-11)%60)
String ganzhiDay(DateTime dt) {
  final idx = ((jdn(dt.year, dt.month, dt.day) - 11) % 60 + 60) % 60;
  return kGan[idx % 10] + kZhi[idx % 12];
}

/// 干支纪年: 以立春 (~2月4日) 为界, 1984 = 甲子
String ganzhiYear(DateTime dt) {
  var y = dt.year;
  if (dt.month < 2 || (dt.month == 2 && dt.day < 4)) y -= 1;
  final idx = ((y - 1984) % 60 + 60) % 60;
  return kGan[idx % 10] + kZhi[idx % 12];
}

/// 月支序: [月, 日, 月序] 日期级节气表 (2024-2030 精度 ±1 天)
/// 月序 0=寅 … 10=子, 11=丑
const List<List<int>> _kTerms = [
  [1, 6, 11], // 小寒 → 丑月
  [2, 4, 0], // 立春 → 寅月
  [3, 5, 1], // 惊蛰 → 卯月
  [4, 4, 2], // 清明 → 辰月
  [5, 5, 3], // 立夏 → 巳月
  [6, 5, 4], // 芒种 → 午月
  [7, 6, 5], // 小暑 → 未月
  [8, 7, 6], // 立秋 → 申月
  [9, 7, 7], // 白露 → 酉月
  [10, 8, 8], // 寒露 → 戌月
  [11, 7, 9], // 立冬 → 亥月
  [12, 7, 10], // 大雪 → 子月
];

int _monthGanzhiIndex(DateTime dt) {
  final cur = jdn(dt.year, dt.month, dt.day);
  var mi = 10; // 1 月 1-5 日: 上一年大雪起的子月
  for (final t in _kTerms) {
    if (cur >= jdn(dt.year, t[0], t[1])) mi = t[2];
  }
  return mi;
}

/// 月干支: 年上起月法 — 甲己之年丙作首 (正月建寅)
String ganzhiMonth(DateTime dt) {
  var y = dt.year;
  if (dt.month < 2 || (dt.month == 2 && dt.day < 4)) y -= 1;
  final yearGanIdx = (((y - 1984) % 60 + 60) % 60) % 10;
  // 正月天干: 甲/己年=丙(2), 乙/庚年=戊(4), 丙/辛年=庚(6), 丁/壬年=壬(8), 戊/癸年=甲(0)
  const monthGanStart = [2, 4, 6, 8, 0];
  final start = monthGanStart[yearGanIdx % 5];
  final mi = _monthGanzhiIndex(dt);
  return kGan[(start + mi) % 10] + kZhi[(2 + mi) % 12]; // 寅=2
}

/// 公历短格式: 9月6日
String gregorian(DateTime dt) => '${dt.month}月${dt.day}日';

/// 完整干支落款: 丙午年 丙申月 癸未日 · 9月6日
String ganzhiFull(DateTime dt) =>
    '${ganzhiYear(dt)}年 ${ganzhiMonth(dt)}月 ${ganzhiDay(dt)}日 · ${gregorian(dt)}';
