// 交叉对拍: PWA divination.js BaZi/DaYun vs Dart 移植 (相同输入逐字段比对)
global.window = {};
const fs = require('fs');
require('./_yijing_calendar_stub.js'); // 最小干支历 stub (与 00-core 相同公式)
eval(fs.readFileSync('D:/workspace/yijing-app/terms.js', 'utf8')); // PreciseTerms
global.PreciseTerms = global.window.PreciseTerms;
eval(fs.readFileSync('D:/workspace/yijing-app/divination.js', 'utf8'));
const D = global.window.YijingDivination;

const cases = [
  [1990, 5, 15, 14, 30, 'male'],
  [1985, 12, 3, 23, 10, 'female'],
  [2000, 2, 4, 6, 0, 'male'],
  [2026, 9, 6, 10, 30, 'female'],
];
for (const [y, m, d, h, mi, g] of cases) {
  const dt = new Date(y, m - 1, d, h, mi);
  const b = D.BaZi.compute(dt);
  const pillars = b.pillars.map(p => p.gz + (p.ganGod === '日主' ? '(日主)' : `(${p.ganGod})`)).join(' ');
  const hidden = b.pillars.map(p => `${p.zhi}:${p.hidden.map(h2 => h2.gan + h2.god).join('/')}`).join(' | ');
  const wx = Object.entries(b.wuxing).map(([k, v]) => k + v).join('');
  const dy = D.DaYun.analyze(dt, g);
  const qy = dy.qiYun ? `${dy.qiYun.years}岁${dy.qiYun.months}月起@${dy.qiYun.termName}` : 'null';
  const steps = dy.steps.map(s => `${s.gz}@${s.startAge}`).join(',');
  const curLY = dy.steps.flatMap(s => s.liuNian).find(l => l.current);
  console.log(JSON.stringify({
    birth: `${y}-${m}-${d} ${h}:${mi}`,
    pillars, hidden, wx, strength: b.strength, shichen: b.shichen,
    forward: dy.forward, qiYun: qy, steps, curLiuNian: curLY ? `${curLY.year}${curLY.gz}(${curLY.god})` : null,
  }));
}
