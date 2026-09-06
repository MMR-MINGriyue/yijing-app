// 生成 yijing-flutter/lib/core/solar_terms.dart (一次性生成脚本, iter34)
const fs = require('fs');
const src = fs.readFileSync('D:/workspace/yijing-app/terms.js', 'utf8');

// 提取 DATA = { 1901: [...], ... 2100: [...] }
const m = src.match(/var DATA = \{([\s\S]*?)\n  \};/);
if (!m) throw new Error('DATA not found');
const body = m[1];
const lines = body.split('\n').map(l => l.trim()).filter(Boolean);
// "1901: [7673,50140,...]," → dart "1901: [7673, 50140, ...],"
const dartEntries = lines.map(l => {
  const mm = l.match(/^(\d+):\s*\[(.*?)\],?$/);
  if (!mm) throw new Error('bad line: ' + l);
  const nums = mm[2].split(',').map(s => s.trim()).filter(Boolean);
  if (nums.length !== 12) throw new Error('bad count in ' + mm[1] + ': ' + nums.length);
  return `  ${mm[1]}: [${nums.join(', ')}],`;
});
console.log('years:', dartEntries.length);
if (dartEntries.length !== 200) throw new Error('expected 200 years');

const dart = `/// 分钟级节气表 (12 节) — 移植自易道 PWA terms.js (机械提取, 逐位对齐)
/// 数据源: lunar-typescript 1.7.3 (PWA .pwtest/.termgen/gen.js 自动生成)
/// 12 节 = 月柱切换节气; 每项为自当年 1 月 1 日 00:00 (UTC+8) 起的分钟数
/// 顺序: 小寒 立春 惊蛰 清明 立夏 芒种 小暑 立秋 白露 寒露 立冬 大雪
library;

const int kTermsFirstYear = 1901;
const int kTermsLastYear = 2100;

const List<String> kJieNames = [
  '小寒', '立春', '惊蛰', '清明', '立夏', '芒种',
  '小暑', '立秋', '白露', '寒露', '立冬', '大雪',
];

/// 年 → 12 节分钟偏移 (1901-2100)
const Map<int, List<int>> kJieData = [
${dartEntries.join('\n')}
];

/// 某个节的时刻 { name, ts (ms since epoch) }
class JieMoment {
  final String name;
  final int ts; // ms since epoch (UTC)
  const JieMoment(this.name, this.ts);
}

/// 北京时区 (UTC+8) 下 ts 的日历年号
int bjYear(int ts) =>
    DateTime.fromMillisecondsSinceEpoch(ts + 8 * 3600000, isUtc: true).year;

/// 某日历年的 12 节列表 (表外返回 null)
List<JieMoment>? jieList(int y) {
  final arr = kJieData[y];
  if (arr == null) return null;
  final base = DateTime.utc(y).millisecondsSinceEpoch - 8 * 3600000;
  return [for (var i = 0; i < 12; i++) JieMoment(kJieNames[i], base + arr[i] * 60000)];
}

/// ts 落在哪个节之内 (0=小寒..11=大雪; 早于当年小寒但 ≥ 上年大雪 → 11; 表外 -1)
int jieIndexAt(int ts) {
  final y = bjYear(ts);
  final list = jieList(y);
  if (list == null) return -1;
  for (var i = 11; i >= 0; i--) {
    if (ts >= list[i].ts) return i;
  }
  final prev = jieList(y - 1);
  return (prev != null && ts >= prev[11].ts) ? 11 : -1;
}

/// ts 前后两个节 (大运起运用); 两端皆在表内才返回
({JieMoment prev, JieMoment next})? around(int ts) {
  final y = bjYear(ts);
  final flat = <JieMoment>[];
  for (final yy in [y - 1, y, y + 1]) {
    final l = jieList(yy);
    if (l != null) flat.addAll(l);
  }
  if (flat.isEmpty) return null;
  flat.sort((a, b) => a.ts - b.ts);
  JieMoment? prev, next;
  for (final j in flat) {
    if (j.ts <= ts) {
      prev = j;
    } else {
      next = j;
      break;
    }
  }
  if (prev == null || next == null) return null;
  return (prev: prev, next: next);
}

/// 节气表是否覆盖 ts 前后一年
bool termsAvailable(int ts) {
  final y = bjYear(ts);
  return y - 1 >= kTermsFirstYear && y + 1 <= kTermsLastYear;
}
`;

fs.writeFileSync('D:/workspace/yijing-app/yijing-flutter/lib/core/solar_terms.dart', dart);
console.log('written solar_terms.dart');
