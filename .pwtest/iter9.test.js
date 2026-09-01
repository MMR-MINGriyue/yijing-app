/* 第九轮迭代冒烟测试: 干支日期 / 实时时钟 / 最近占卜动态化 / ts 排序 */
const { chromium } = require('playwright-core');

const BASE = 'http://localhost:8723';
let pass = 0, fail = 0;
function ok(cond, name, extra) {
  if (cond) { pass++; console.log('  PASS ' + name); }
  else { fail++; console.log('  FAIL ' + name + (extra ? ' | ' + extra : '')); }
}

(async () => {
  const browser = await chromium.launch({ channel: 'msedge' });
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
  const page = await ctx.newPage();
  const errors = [];
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', e => errors.push(String(e)));

  await page.goto(BASE + '/?view=app');
  await page.waitForTimeout(2400);

  console.log('== 1. 加载无运行时错误 ==');
  ok(errors.length === 0, '无 console/page 错误', errors.join('; '));

  console.log('== 2. 状态栏实时时钟 ==');
  const clock = await page.evaluate(() => {
    const els = Array.from(document.querySelectorAll('.status-time'));
    const n = new Date();
    const expect = n.getHours() + ':' + String(n.getMinutes()).padStart(2, '0');
    return { count: els.length, texts: els.map(e => e.textContent), expect };
  });
  ok(clock.count >= 6, '6 屏状态栏都存在', 'count=' + clock.count);
  ok(clock.texts.every(t => t === clock.expect), '时间 = 当前真实时间', JSON.stringify(clock.texts) + ' expect ' + clock.expect);
  ok(!clock.texts.includes('9:41'), '静态 9:41 已消除');

  console.log('== 3. 干支日期真实化 ==');
  const cal = await page.evaluate(() => {
    const d = document.getElementById('greetDate').textContent;
    const ref = {
      day: window.YijingCalendar.ganzhiDay(new Date()),
      year: window.YijingCalendar.ganzhiYear(new Date()),
      greg: window.YijingCalendar.gregorian(new Date())
    };
    return { d, ref, jdn2000: window.YijingCalendar.jdn(2000, 1, 1), jdn2024: window.YijingCalendar.jdn(2024, 1, 1) };
  });
  ok(cal.jdn2000 === 2451545, 'JDN 公式: 2000-01-01 = 2451545', String(cal.jdn2000));
  ok(cal.jdn2024 === 2460311, 'JDN 公式: 2024-01-01 = 2460311', String(cal.jdn2024));
  ok(cal.d.indexOf(cal.ref.year + '年') >= 0 && cal.d.indexOf(cal.ref.day + '日') >= 0 && cal.d.indexOf(cal.ref.greg) >= 0,
    '问候日期含干支年/干支日/公历', cal.d);
  ok(cal.ref.year === '丙午', '2026-08 干支年为丙午', cal.ref.year);

  console.log('== 4. 最近占卜动态化 ==');
  const initialRecent = await page.evaluate(() => Array.from(document.querySelectorAll('#recentList .recent-card .recent-name')).map(e => e.textContent));
  ok(initialRecent.length === 2, '初始渲染 2 张卡', JSON.stringify(initialRecent));
  // 起卦一条真实记录
  await page.evaluate(() => {
    window.YijingHistory.add({
      date: '今日 10:30', ts: Date.now() - 3600000, month: '2026-08', day: 31, hexNo: 1, name: '乾卦',
      question: '问：时间真实性验证', direction: '事业', directionColor: 'cinnabar',
      highlight: true, lines: ['yang','yang','yin','yang','yang','yin'], moving: [2], method: 'coin'
    });
    window.YijingUI.refreshHistory();
  });
  await page.waitForTimeout(300);
  const afterRecent = await page.evaluate(() => {
    const cards = Array.from(document.querySelectorAll('#recentList .recent-card'));
    return {
      names: cards.map(c => c.querySelector('.recent-name').textContent),
      times: cards.map(c => c.querySelector('.recent-time').textContent),
      q: cards[0] ? cards[0].querySelector('.recent-q').textContent : ''
    };
  });
  ok(afterRecent.names[0] === '乾卦', '新记录出现在第 1 张卡', JSON.stringify(afterRecent.names));
  ok(afterRecent.q.indexOf('时间真实性验证') >= 0, '显示真实问题', afterRecent.q);
  ok(afterRecent.times[0].indexOf('今日') >= 0, 'ts 今日格式', afterRecent.times[0]);
  // 点击卡片直达 04 屏
  await page.click('#recentList .recent-card');
  await page.waitForTimeout(700);
  const navInfo = await page.evaluate(() => ({
    cur: window.YijingUI.appCurrent ? window.YijingUI.appCurrent() : -1,
    detailHex: window.YijingUI._detailHexNo
  }));
  ok(navInfo.cur === 3, '点击最近卡跳转到屏4', 'cur=' + navInfo.cur);
  ok(navInfo.detailHex === 1, '解析渲染目标卦', 'hex=' + navInfo.detailHex);
  // 屏4 顶栏 ← 返回来路屏 (屏0)
  await page.click('#phoneDetail .detail-header .icon-btn:nth-child(1)');
  await page.waitForTimeout(700);
  const backCur = await page.evaluate(() => window.YijingUI.appCurrent());
  ok(backCur === 0, '顶栏 ← 返回来路屏(屏0)', 'cur=' + backCur);
  await page.waitForTimeout(300);

  console.log('== 5. ts 排序 ==');
  await page.evaluate(() => {
    window.YijingHistory.add({
      date: '今日 11:30', ts: Date.now(), month: '2026-08', day: 31, hexNo: 5, name: '需卦',
      question: '问：更新的记录应排最前', direction: '综合', directionColor: 'pine',
      highlight: true, lines: ['yang','yang','yin','yang','yang','yang'], moving: [], method: 'num'
    });
    window.YijingUI.refreshHistory();
    window.YijingUI.changeMonth(2026, 8);
  });
  await page.waitForTimeout(300);
  const orderDesc = await page.evaluate(() => Array.from(document.querySelectorAll('#hist-today .hist-card .hist-name, #hist-week .hist-card .hist-name')).map(e => e.textContent));
  ok(orderDesc.length === 2 && /需/.test(orderDesc[0]) && /乾/.test(orderDesc[1]), '最新在前: 需卦先于乾卦', JSON.stringify(orderDesc));
  await page.click('#histSortBtn');
  await page.waitForTimeout(300);
  const orderAsc = await page.evaluate(() => Array.from(document.querySelectorAll('#hist-today .hist-card .hist-name, #hist-week .hist-card .hist-name')).map(e => e.textContent));
  ok(/乾/.test(orderAsc[0]) && /需/.test(orderAsc[1]), '最早在前: 乾卦先于需卦', JSON.stringify(orderAsc));
  await page.click('#histSortBtn');

  console.log('== 6. 清空后最近占卜降级为示例 ==');
  await page.evaluate(() => {
    window.YijingHistory.clear();
    window.YijingUI.refreshHistory();
  });
  await page.waitForTimeout(300);
  const fallback = await page.evaluate(() => Array.from(document.querySelectorAll('#recentList .recent-card .recent-q')).map(e => e.textContent));
  ok(fallback.length === 2 && fallback.every(q => q.indexOf('时间真实性验证') < 0 && q.indexOf('更新的记录应排最前') < 0), '降级为内置示例(问题文本非测试记录)', JSON.stringify(fallback));

  console.log('== 7. 最终无运行时错误 ==');
  ok(errors.length === 0, '全程无 console/page 错误', errors.join('; '));

  browser.close().catch(() => {});
  console.log('\n结果: ' + pass + ' 通过 / ' + fail + ' 失败');
  process.exit(fail ? 1 : 0);
})().catch(e => { console.error('FATAL', e); process.exit(1); });
