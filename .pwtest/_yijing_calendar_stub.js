// 00-core.js YijingCalendar 精简 stub (公式与源一致, 供 node 对拍)
const GAN = ['甲','乙','丙','丁','戊','己','庚','辛','壬','癸'];
const ZHI = ['子','丑','寅','卯','辰','巳','午','未','申','酉','戌','亥'];
function jdn(y, m, d) {
  const a = Math.floor((14 - m) / 12);
  const yy = y + 4800 - a;
  const mm = m + 12 * a - 3;
  return d + Math.floor((153 * mm + 2) / 5) + 365 * yy + Math.floor(yy / 4) - Math.floor(yy / 100) + Math.floor(yy / 400) - 32045;
}
function ganzhiDay(date) {
  const idx = ((jdn(date.getFullYear(), date.getMonth() + 1, date.getDate()) - 11) % 60 + 60) % 60;
  return GAN[idx % 10] + ZHI[idx % 12];
}
function ganzhiYear(date) {
  let y = date.getFullYear();
  if (date.getMonth() + 1 < 2 || (date.getMonth() + 1 === 2 && date.getDate() < 4)) y -= 1;
  const idx = ((y - 1984) % 60 + 60) % 60;
  return GAN[idx % 10] + ZHI[idx % 12];
}
const TERMS = [[1,6,11],[2,4,0],[3,5,1],[4,4,2],[5,5,3],[6,5,4],[7,6,5],[8,7,6],[9,7,7],[10,8,8],[11,7,9],[12,7,10]];
function monthGanzhiIndex(date) {
  const curJDN = jdn(date.getFullYear(), date.getMonth() + 1, date.getDate());
  let mi = 10;
  TERMS.forEach(t => { if (curJDN >= jdn(date.getFullYear(), t[0], t[1])) mi = t[2]; });
  return mi;
}
function ganzhiMonth(date) {
  // 与 PWA 加载 terms.js 后一致: 分钟级节气表优先
  const ts = date.getTime();
  const y0 = date.getFullYear();
  const listY = window.PreciseTerms.jieList(y0);
  const listPrev = window.PreciseTerms.jieList(y0 - 1);
  if (listY && listPrev) {
    let idx = 11;
    for (let i = 11; i >= 0; i--) { if (ts >= listY[i].ts) { idx = i; break; } }
    const mi = (idx + 11) % 12;
    let y = y0;
    if (ts < listY[1].ts) y -= 1;
    const yearGanIdx = (((y - 1984) % 60 + 60) % 60) % 10;
    const monthGanStart = [2, 4, 6, 8, 0][yearGanIdx % 5];
    return GAN[(monthGanStart + mi) % 10] + ZHI[(2 + mi) % 12];
  }
  let y = date.getFullYear();
  if (date.getMonth() + 1 < 2 || (date.getMonth() + 1 === 2 && date.getDate() < 4)) y -= 1;
  const yearGanIdx = (((y - 1984) % 60 + 60) % 60) % 10;
  const monthGanStart = [2, 4, 6, 8, 0][yearGanIdx % 5];
  const mi = monthGanzhiIndex(date);
  return GAN[(monthGanStart + mi) % 10] + ZHI[(2 + mi) % 12];
}
global.window.YijingCalendar = { jdn, ganzhiDay, ganzhiYear, ganzhiMonth };
global.YijingCalendar = global.window.YijingCalendar;
