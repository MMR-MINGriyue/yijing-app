const { Solar, Lunar } = require('lunar-typescript');

// 1) API surface
const s = Solar.fromYmdHms(2026, 2, 17, 12, 0, 0);
const l = s.getLunar();
const methods = [];
for (const k in Lunar.prototype) {
  if (typeof Lunar.prototype[k] === 'function' && /jieqi|term/i.test(k)) methods.push(k);
}
console.log('jieqi-related methods:', methods.join(', '));

// 2) table sample around 2026 立春
const t = l.getJieQiTable();
const keys = Object.keys(t);
console.log('table keys count:', keys.length);
console.log('keys:', keys.join(' '));
const liChun = t['立春'];
console.log('立春:', liChun ? liChun.toString() : 'N/A');

// 3) daily scan probe: what does getJieQi return on a jieqi day vs normal day
const s2 = Solar.fromYmd(2026, 2, 4);
console.log('2026-02-04 getJieQi:', JSON.stringify(s2.getLunar().getJieQi()));
const s3 = Solar.fromYmd(2026, 2, 20);
console.log('2026-02-20 getJieQi:', JSON.stringify(s3.getLunar().getJieQi()));

// 4) other year boundary check: does table for 2026 include 2026 小寒 (Jan) or 2027?
const s26jan = Solar.fromYmd(2026, 1, 5);
const t26 = s26jan.getLunar().getJieQiTable();
console.log('2026 table 小寒:', t26['小寒'] ? t26['小寒'].toString() : 'N/A');
console.log('2026 table 大雪:', t26['大雪'] ? t26['大雪'].toString() : 'N/A');
// cross-check with 2027's table
const s27 = Solar.fromYmd(2027, 1, 5);
const t27 = s27.getLunar().getJieQiTable();
console.log('2027 table 小寒:', t27['小寒'] ? t27['小寒'].toString() : 'N/A');
