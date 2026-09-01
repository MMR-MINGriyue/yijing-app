// DaYun 引擎冒烟测试 (Node)
const fs = require('fs');
const path = require('path');
const root = path.join(__dirname, '..', '..');

global.window = global;

// 1) terms.js
eval(fs.readFileSync(path.join(root, 'terms.js'), 'utf8'));
if (!global.PreciseTerms) throw new Error('PreciseTerms 未挂载');
console.log('PreciseTerms OK, 2026 立春:', new Date(PreciseTerms.jieList(2026)[1].ts + 8 * 3600000).toISOString());

// 2) 从 index.html 抽取 YijingCalendar
const html = fs.readFileSync(path.join(root, 'index.html'), 'utf8');
const m = html.match(/const YijingCalendar = \(function \(\) \{[\s\S]*?\}\)\(\);\s*\n\s*window\.YijingCalendar = YijingCalendar;/);
if (!m) throw new Error('未找到 YijingCalendar 源码');
eval(m[0]);
if (!global.YijingCalendar) throw new Error('YijingCalendar 未挂载');
console.log('YijingCalendar OK, 2026-07-01 月柱:', YijingCalendar.ganzhiMonth(new Date(2026, 6, 1)));

// 3) divination.js
eval(fs.readFileSync(path.join(root, 'divination.js'), 'utf8'));
const D = global.YijingDivination;
if (!D || !D.DaYun) throw new Error('DaYun 未挂载');

// 4) 已知案例: 2000-02-05 12:00 乾造 (庚辰年 戊寅月 癸巳日 戊午时)
//    庚为阳干, 男命 → 顺行; 立春 2000-02-04 20:40 已过, 下一节 惊蛰 2000-03-05 14:42
//    间隔 = 29天2时42分 → 折算 ≈ 9岁8个月
const r = D.DaYun.analyze(new Date(2000, 1, 5, 12, 0), 'male');
console.log('\n=== 2000-02-05 12:00 乾造 ===');
console.log('forward(应true):', r.forward);
console.log('四柱:', r.bazi.pillars.map(p => p.gz).join(' '), '(应 庚辰 戊寅 癸巳 戊午)');
console.log('起运:', r.qiYun.years + '岁' + r.qiYun.months + '个月 (应≈9岁8个月), 至' + r.qiYun.termName + ' (应惊蛰), nearEdge:', r.qiYun.nearEdge);
console.log('大运序列:', r.steps.map(s => s.gz).join(' '), '(应 己卯 庚辰 辛巳 壬午 癸未 甲申 乙酉 丙戌)');
const cur = r.steps.find(s => s.current);
console.log('当前大运:', cur ? cur.gz + ' (' + cur.startYear + '-' + cur.endYear + ', ' + cur.ganGod + ')' : '无');
console.log('第一步流年:', r.steps[0].liuNian.map(l => l.year + l.gz).join(' '));
console.log('流年样例 (当前步当前年):', (function () {
  const ln = (cur || r.steps[0]).liuNian.find(l => l.current) || (cur || r.steps[0]).liuNian[0];
  return ln.year + ' ' + ln.gz + ' ' + ln.god + ' | ' + ln.text;
})());

// 5) 顺逆四象限: 2000 (庚阳) 与 2001 (辛阴) × 男女
const q = [
  [new Date(2000, 6, 1), 'male', true], [new Date(2000, 6, 1), 'female', false],
  [new Date(2001, 6, 1), 'male', false], [new Date(2001, 6, 1), 'female', true]
];
q.forEach(function (c) {
  const rr = D.DaYun.analyze(c[0], c[1]);
  const ok = rr.forward === c[2];
  console.log((ok ? 'PASS' : 'FAIL') + ' 顺逆: ' + c[0].getFullYear() + ' ' + (c[1] === 'male' ? '男' : '女') + ' → ' + (rr.forward ? '顺' : '逆'));
  if (!ok) process.exitCode = 1;
});

// 6) 时辰未知
const r2 = D.DaYun.analyze(new Date(1990, 5, 15, 12, 0), 'female', { hourUnknown: true });
console.log('hourUnknown 透传:', r2.hourUnknown === true ? 'PASS' : 'FAIL');
