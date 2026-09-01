const { Solar } = require('lunar-typescript');
const l = Solar.fromYmd(2026, 7, 1).getLunar();
const t = l.getJieQiTable();
for (const name of ['小寒', '立春', '惊蛰', '清明', '立夏', '芒种', '小暑', '立秋', '白露', '寒露', '立冬', '大雪']) {
  const s = t[name];
  console.log(name, s.toYmdHms(), '| h:', s.getHour(), 'm:', s.getMinute());
}
// late-December anchor check: table from Dec 20 should still map to same calendar year
const t2 = Solar.fromYmd(2026, 12, 20).getLunar().getJieQiTable();
console.log('from Dec 20 — 小寒:', t2['小寒'].toYmdHms(), '大雪:', t2['大雪'].toYmdHms(), 'DA_XUE(prev):', t2['DA_XUE'].toYmdHms());
