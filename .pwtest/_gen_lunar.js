// 生成 yijing-flutter/lib/core/lunar_calendar.dart (一次性生成脚本)
const fs = require('fs');
const table = fs.readFileSync('D:/workspace/yijing-app/.pwtest/_lunar_data.txt', 'utf8').trim();

const dart = `/// 农历算法 — 移植自易道 PWA divination.js LunarCalendar (逐位对齐)
/// 1900-2100 紧凑表: 1900-01-31 = 农历 1900 正月初一
library;

import 'yi_calendar.dart' show kGan, kZhi;

/// 每年 16-bit: 高位闰月月份 (0=无闰) + 闰月大小 (0x10000) + 12 位大小月 (1=30天,0=29天)
const List<int> kLunarData = [
${table}
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

  String get monthLabel => (isLeap ? '闰' : '') + kMonthCn[month - 1] + '月';

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
`;

fs.writeFileSync('D:/workspace/yijing-app/yijing-flutter/lib/core/lunar_calendar.dart', dart);
console.log('written, table lines:', table.split('\n').length);
