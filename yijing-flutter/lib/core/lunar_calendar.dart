/// 农历算法 — 移植自易道 PWA divination.js LunarCalendar (逐位对齐)
/// 1900-2100 紧凑表: 1900-01-31 = 农历 1900 正月初一
library;

import 'yi_calendar.dart' show kGan, kZhi;

/// 每年 16-bit: 高位闰月月份 (0=无闰) + 闰月大小 (0x10000) + 12 位大小月 (1=30天,0=29天)
const List<int> kLunarData = [
0x04bd8, 0x04ae0, 0x0a570, 0x054d5, 0x0d260, 0x0d950, 0x16554, 0x056a0, 0x09ad0, 0x055d2,
  0x04ae0, 0x0a5b6, 0x0a4d0, 0x0d250, 0x1d255, 0x0b540, 0x0d6a0, 0x0ada2, 0x095b0, 0x14977,
  0x04970, 0x0a4b0, 0x0b4b5, 0x06a50, 0x06d40, 0x1ab54, 0x02b60, 0x09570, 0x052f2, 0x04970,
  0x06566, 0x0d4a0, 0x0ea50, 0x06e95, 0x05ad0, 0x02b60, 0x186e3, 0x092e0, 0x1c8d7, 0x0c950,
  0x0d4a0, 0x1d8a6, 0x0b550, 0x056a0, 0x1a5b4, 0x025d0, 0x092d0, 0x0d2b2, 0x0a950, 0x0b557,
  0x06ca0, 0x0b550, 0x15355, 0x04da0, 0x0a5b0, 0x14573, 0x052b0, 0x0a9a8, 0x0e950, 0x06aa0,
  0x0aea6, 0x0ab50, 0x04b60, 0x0aae4, 0x0a570, 0x05260, 0x0f263, 0x0d950, 0x05b57, 0x056a0,
  0x096d0, 0x04dd5, 0x04ad0, 0x0a4d0, 0x0d4d4, 0x0d250, 0x0d558, 0x0b540, 0x0b6a0, 0x195a6,
  0x095b0, 0x049b0, 0x0a974, 0x0a4b0, 0x0b27a, 0x06a50, 0x06d40, 0x0af46, 0x0ab60, 0x09570,
  0x04af5, 0x04970, 0x064b0, 0x074a3, 0x0ea50, 0x06b58, 0x05ac0, 0x0ab60, 0x096d5, 0x092e0,
  0x0c960, 0x0d954, 0x0d4a0, 0x0da50, 0x07552, 0x056a0, 0x0abb7, 0x025d0, 0x092d0, 0x0cab5,
  0x0a950, 0x0b4a0, 0x0baa4, 0x0ad50, 0x055d9, 0x04ba0, 0x0a5b0, 0x15176, 0x052b0, 0x0a930,
  0x07954, 0x06aa0, 0x0ad50, 0x05b52, 0x04b60, 0x0a6e6, 0x0a4e0, 0x0d260, 0x0ea65, 0x0d530,
  0x05aa0, 0x076a3, 0x096d0, 0x04afb, 0x04ad0, 0x0a4d0, 0x1d0b6, 0x0d250, 0x0d520, 0x0dd45,
  0x0b5a0, 0x056d0, 0x055b2, 0x049b0, 0x0a577, 0x0a4b0, 0x0aa50, 0x1b255, 0x06d20, 0x0ada0,
  0x14b63, 0x09370, 0x049f8, 0x04970, 0x064b0, 0x168a6, 0x0ea50, 0x06b20, 0x1a6c4, 0x0aae0,
  0x0a2e0, 0x0d2e3, 0x0c960, 0x0d557, 0x0d4a0, 0x0da50, 0x05d55, 0x056a0, 0x0a6d0, 0x055d4,
  0x052d0, 0x0a9b8, 0x0a950, 0x0b4a0, 0x0b6a6, 0x0ad50, 0x055a0, 0x0aba4, 0x0a5b0, 0x052b0,
  0x0b273, 0x06930, 0x07337, 0x06aa0, 0x0ad50, 0x14b55, 0x04b60, 0x0a570, 0x054e4, 0x0d160,
  0x0e968, 0x0d520, 0x0daa0, 0x16aa6, 0x056d0, 0x04ae0, 0x0a9d4, 0x0a2d0, 0x0d150, 0x0f252,
  0x0d520,
];

const int _baseYear = 1900, _baseMonth = 1, _baseDay = 31;
const List<String> kMonthCn = ['正', '二', '三', '四', '五', '六', '七', '八', '九', '十', '冬', '腊'];

/// 农历日期
class LunarDate {
  final int year;
  final int month; // 1-12
  final int day;
  final bool isLeap;
  final String yearGanZhi;
  final String animal;
  const LunarDate({
    required this.year, required this.month, required this.day,
    required this.isLeap, required this.yearGanZhi, required this.animal,
  });

  String get monthLabel => '${isLeap ? '闰' : ''}${kMonthCn[month - 1]}月';

  /// 农历日中文 (初一/十五/廿三…)
  String get dayLabel {
    const d10 = ['初', '十', '廿', '三'];
    const d1 = ['一', '二', '三', '四', '五', '六', '七', '八', '九', '十'];
    if (day == 10) return '初十';
    if (day == 20) return '二十';
    if (day == 30) return '三十';
    return d10[day ~/ 10] + d1[day % 10 - 1];
  }
}

int _lunarYearDays(int y) {
  var sum = 348;
  for (var i = 0x8000; i > 0x8; i >>= 1) {
    if ((kLunarData[y - 1900] & i) != 0) sum++;
  }
  return sum + _lunarLeapDays(y);
}

int _lunarLeapMonth(int y) => kLunarData[y - 1900] & 0xf;

int _lunarLeapDays(int y) =>
    _lunarLeapMonth(y) == 0 ? 0 : ((kLunarData[y - 1900] & 0x10000) != 0 ? 30 : 29);

int _lunarMonthDays(int y, int m) =>
    (kLunarData[y - 1900] & (0x10000 >> m)) != 0 ? 30 : 29;

/// 公历 → 农历 (PWA solarToLunar); 超出 1900-2100 或早于基准日返回 null
LunarDate? solarToLunar(DateTime dt) {
  var offset = jdnOf(dt.year, dt.month, dt.day) - jdnOf(_baseYear, _baseMonth, _baseDay);
  if (offset < 0) return null;
  var y = 1900;
  while (y <= 2100) {
    final yd = _lunarYearDays(y);
    if (offset < yd) break;
    offset -= yd;
    y++;
  }
  if (y > 2100) return null;
  final leap = _lunarLeapMonth(y);
  final months = <({int m, bool isLeap, int days})>[];
  for (var m = 1; m <= 12; m++) {
    months.add((m: m, isLeap: false, days: _lunarMonthDays(y, m)));
    if (leap == m) months.add((m: m, isLeap: true, days: _lunarLeapDays(y)));
  }
  ({int m, bool isLeap, int days})? cur;
  for (final mo in months) {
    if (offset < mo.days) {
      cur = mo;
      break;
    }
    offset -= mo.days;
  }
  if (cur == null) return null;
  final gzIdx = ((y - 1984) % 60 + 60) % 60;
  return LunarDate(
    year: y, month: cur.m, day: offset + 1, isLeap: cur.isLeap,
    yearGanZhi: kGan[gzIdx % 10] + kZhi[gzIdx % 12],
    animal: kZhi[((y - 1900) % 12 + 12) % 12],
  );
}

/// 时辰序号 (0=子时 23-1 点, 1=丑 1-3 点 …) (PWA shichenIndex)
int shichenIndex(DateTime dt) => ((dt.hour + 1) % 24) ~/ 2;

/// 儒略日数 (与 yi_calendar.jdn 相同公式, 本文件独立副本避免跨文件耦合)
int jdnOf(int y, int m, int d) {
  final a = (14 - m) ~/ 12;
  final yy = y + 4800 - a;
  final mm = m + 12 * a - 3;
  return d + ((153 * mm + 2) ~/ 5) + 365 * yy + yy ~/ 4 - yy ~/ 100 + yy ~/ 400 - 32045;
}
