// 生成 terms.js: 1901-2100 年 12 节 (月柱切换节气) 的分钟级时刻表
// 数据编码: 每年一个数组, 12 个整数 = 自当年 1 月 1 日 00:00 (UTC+8) 起的分钟数
const fs = require('fs');
const path = require('path');
const { Solar } = require('lunar-typescript');

const FIRST = 1901, LAST = 2100;
// 按日历年内出现顺序 (1 月小寒 ... 12 月大雪)
const JIE = ['小寒', '立春', '惊蛰', '清明', '立夏', '芒种', '小暑', '立秋', '白露', '寒露', '立冬', '大雪'];

const data = {};
for (let y = FIRST; y <= LAST; y++) {
  // 用年中日期锚定当年表 (避开边界月份)
  const t = Solar.fromYmd(y, 7, 1).getLunar().getJieQiTable();
  const arr = [];
  for (const name of JIE) {
    const s = t[name];
    if (!s) throw new Error(`missing ${name} in ${y}`);
    if (s.getYear() !== y) throw new Error(`year drift: ${name} ${y} -> ${s.getYear()}`);
    // 分钟数 = 自 1 月 1 日 00:00 (UTC+8) 起; 用 UTC 日期分量避免本地时区干扰
    const jan1 = Date.UTC(y, 0, 1) - 8 * 3600000; // 当年 1 月 1 日 00:00 UTC+8 的 ts
    const ts = Date.UTC(s.getYear(), s.getMonth() - 1, s.getDay(), s.getHour(), s.getMinute(), 0, 0) - 8 * 3600000
      + Math.round(s.getSecond() / 60) * 60000; // 秒四舍五入到分
    const mins = Math.round((ts - jan1) / 60000);
    if (mins < 0 || mins > 366 * 1440) throw new Error(`range error ${name} ${y}: ${mins}`);
    arr.push(mins);
    // 顺序校验: 数组内严格递增
    if (arr.length > 1 && arr[arr.length - 1] <= arr[arr.length - 2]) throw new Error(`order error ${name} ${y}`);
  }
  data[y] = arr;
}

// 锚点核验 (对天文历公开值): 2026 立春 02-04 04:02, 2000 立春 02-04 20:32
function fmt(y, idx) {
  const m = data[y][idx];
  const d = new Date(Date.UTC(y, 0, 1) - 8 * 3600000 + m * 60000 + 8 * 3600000);
  return d.toISOString().replace('T', ' ').slice(0, 16);
}
const anchors = { '2026 立春': fmt(2026, 1), '2026 小寒': fmt(2026, 0), '2000 立春': fmt(2000, 1), '1901 立春': fmt(1901, 1) };
console.log('锚点:', JSON.stringify(anchors));
if (fmt(2026, 1) !== '2026-02-04 04:02') throw new Error('2026 立春锚点不符');
if (fmt(2000, 1) !== '2000-02-04 20:40') throw new Error('2000 立春锚点不符');

const lines = [];
lines.push('// 分钟级节气表 — 自动生成, 勿手改 (generator: .pwtest/.termgen/gen.js, 数据源 lunar-typescript 1.7.3)');
lines.push('// 12 节 = 月柱切换节气, 1901-2100 每年 12 项: 自当年 1 月 1 日 00:00 (UTC+8) 起的分钟数');
lines.push('// 顺序: ' + JIE.join(' '));
lines.push('window.PreciseTerms = (function () {');
lines.push("  var FIRST = " + FIRST + ", LAST = " + LAST + ";");
lines.push("  var NAMES = " + JSON.stringify(JIE) + ";");
lines.push('  var DATA = {');
for (let y = FIRST; y <= LAST; y++) {
  lines.push('    ' + y + ': [' + data[y].join(',') + ']' + (y < LAST ? ',' : ''));
}
lines.push('  };');
lines.push(`
  // 当年 1 月 1 日 00:00 (UTC+8) 时间戳
  function yearStart(y) { return Date.UTC(y, 0, 1) - 8 * 3600000; }

  // 北京时区下的日历年号
  function bjYear(ts) { return new Date(ts + 8 * 3600000).getUTCFullYear(); }

  // 某日历年的 12 节列表: [{ name, ts }]
  function jieList(y) {
    var arr = DATA[y];
    if (!arr) return null;
    var base = yearStart(y), out = [];
    for (var i = 0; i < 12; i++) out.push({ name: NAMES[i], ts: base + arr[i] * 60000 });
    return out;
  }

  // 判断 ts 落在哪个节之内 (即自哪个节起) — 月柱干支索引 0=小寒..11=大雪, 返回 -1 表示表外
  function jieIndexAt(ts) {
    var y = bjYear(ts);
    var list = jieList(y);
    if (!list) return -1;
    for (var i = 11; i >= 0; i--) { if (ts >= list[i].ts) return i; }
    // 早于当年小寒 → 落在上一年大雪内
    var prev = jieList(y - 1);
    return prev && ts >= prev[11].ts ? 11 : -1;
  }

  // 时刻 ts 的前后两个节 { prev: {name,ts}, next: {name,ts} } — 大运起运用
  function around(ts) {
    var y = bjYear(ts);
    var lists = [jieList(y - 1), jieList(y), jieList(y + 1)].filter(Boolean);
    if (!lists.length) return null;
    var flat = [];
    lists.forEach(function (l) { flat = flat.concat(l); });
    flat.sort(function (a, b) { return a.ts - b.ts; });
    var prev = null, next = null;
    for (var i = 0; i < flat.length; i++) {
      if (flat[i].ts <= ts) prev = flat[i];
      else { next = flat[i]; break; }
    }
    return prev && next ? { prev: prev, next: next } : null;
  }

  function available(ts) {
    var y = bjYear(ts);
    return y - 1 >= FIRST && y + 1 <= LAST;
  }

  return { NAMES: NAMES, jieList: jieList, jieIndexAt: jieIndexAt, around: around, available: available };
})();`);

fs.writeFileSync(path.join(__dirname, '..', '..', 'terms.js'), lines.join('\n') + '\n', 'utf8');
const stat = fs.statSync(path.join(__dirname, '..', '..', 'terms.js'));
console.log('terms.js written:', (stat.size / 1024).toFixed(1) + 'KB');
