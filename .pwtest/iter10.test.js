/* 第十轮冒烟测试: 07 屏「我的」个人页 */
const { chromium } = require('playwright-core');

const BASE = 'http://localhost:8723';
let pass = 0, fail = 0;
function ok(cond, name, extra) {
  if (cond) { pass++; console.log('  PASS ' + name); }
  else { fail++; console.log('  FAIL ' + name + (extra ? ' | ' + extra : '')); }
}

(async () => {
  const browser = await chromium.launch({ channel: 'msedge' });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errors = [];
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', e => errors.push(String(e)));

  await page.goto(BASE + '/?view=app');
  await page.waitForTimeout(2400);

  console.log('== 1. 加载无运行时错误 ==');
  ok(errors.length === 0, '无 console/page 错误', errors.join('; '));

  console.log('== 2. 屏7 存在且接入导航 ==');
  const structure = await page.evaluate(() => ({
    meExists: !!document.getElementById('phoneMe'),
    slideCount: window.YijingUI.appSlideCount,
    hint: document.getElementById('appHint').textContent,
    dots: document.querySelectorAll('#appPager .pg-dot').length,
    tabGoto: document.querySelector('.tabbar .tab[data-goto="6"]') ? 'ok' : 'missing',
    tabLabel: (document.querySelector('.tabbar .tab[data-goto="6"] .tab-text') || {}).textContent
  }));
  ok(structure.meExists, 'phoneMe 屏存在');
  ok(structure.slideCount === 7, '共 7 屏', 'slides=' + structure.slideCount);
  ok(structure.dots === 7, '7 个屏序圆点', 'dots=' + structure.dots);
  ok(structure.hint.indexOf('共 7 屏') >= 0, '滑动提示动态屏数', structure.hint);
  ok(structure.tabGoto === 'ok' && structure.tabLabel === '我 的', 'tab 我 的 → 屏7');

  console.log('== 3. tab 导航到屏7 ==');
  await page.click('.tabbar .tab[data-goto="6"]');
  await page.waitForTimeout(700);
  const cur = await page.evaluate(() => window.YijingUI.appCurrent());
  ok(cur === 6, '点击 tab 到达屏7', 'cur=' + cur);

  console.log('== 4. 统计与收藏 ==');
  await page.evaluate(() => {
    const now = Date.now();
    window.__testEarliest = now - 86400000 * 2;
    window.YijingHistory.add({ ts: now, date: '今日 10:00', month: '2026-08', day: 31, hexNo: 1, name: '乾卦', question: '问：A', direction: '事业', directionColor: 'cinnabar', lines: ['yang','yang','yang','yang','yang','yang'], moving: [], method: 'coin' });
    window.YijingHistory.add({ ts: now - 86400000, date: '昨日', month: '2026-08', day: 30, hexNo: 2, name: '坤卦', question: '问：B', direction: '感情', directionColor: 'gold', lines: ['yin','yin','yin','yin','yin','yin'], moving: [], method: 'numeric' });
    window.YijingHistory.add({ ts: window.__testEarliest, date: '前日', month: '2026-08', day: 29, hexNo: 3, name: '屯卦', question: '问：C', direction: '事业', directionColor: 'cinnabar', lines: ['yin','yang','yang','yang','yang','yang'], moving: [], method: 'coin' });
    localStorage.setItem('yijing.favHexes', JSON.stringify([5, 1]));
    window.YijingUI.refreshMe();
  });
  await page.waitForTimeout(300);
  const stats = await page.evaluate(() => {
    const d = new Date(window.__testEarliest);
    const expectSince = '始于 ' + (d.getMonth() + 1) + '月' + d.getDate() + '日';
    return {
      total: document.getElementById('meTotal').textContent,
      streak: document.getElementById('meStreak').textContent,
      fav: document.getElementById('meFav').textContent,
      since: document.getElementById('meSince').textContent,
      expectSince: expectSince,
      chips: Array.from(document.querySelectorAll('#meFavRow .me-fav-chip .fname')).map(e => e.textContent),
      dirBars: Array.from(document.querySelectorAll('#meDirectionBars .bar-head')).map(e => e.textContent),
      methodBars: Array.from(document.querySelectorAll('#meMethodBars .bar-head')).map(e => e.textContent)
    };
  });
  ok(stats.total === '3', '起卦总数 3', stats.total);
  ok(stats.streak === '3', '连续 3 天 (今日/昨/前日)', stats.streak);
  ok(stats.fav === '2', '收藏 2 卦', stats.fav);
  ok(stats.since.indexOf(stats.expectSince) >= 0, '始于最早记录日', stats.since + ' expect ' + stats.expectSince);
  ok(stats.chips.length === 2 && stats.chips[0] === '乾' && stats.chips[1] === '需', '收藏 chips 按卦序渲染', JSON.stringify(stats.chips));
  ok(stats.dirBars.length === 2 && stats.dirBars[0].indexOf('事业') >= 0 && stats.dirBars[0].indexOf('2') >= 0, '方向分布排序正确', JSON.stringify(stats.dirBars));
  ok(stats.methodBars.length === 2 && stats.methodBars[0].indexOf('铜钱起卦') >= 0, '方式偏好统计', JSON.stringify(stats.methodBars));

  console.log('== 5. 收藏 chip 点击直达解析 ==');
  await page.evaluate(() => window.YijingUI.gotoScreen(6));
  await page.waitForTimeout(400);
  await page.click('#meFavRow .me-fav-chip:nth-child(2)'); // 需卦
  await page.waitForTimeout(700);
  const chipNav = await page.evaluate(() => ({
    cur: window.YijingUI.appCurrent(),
    hex: window.YijingUI._detailHexNo
  }));
  ok(chipNav.cur === 3 && chipNav.hex === 5, 'chip → 屏4 需卦', JSON.stringify(chipNav));

  console.log('== 6. 屏7 ⚙ 设置面板 + 快捷入口 ==');
  await page.evaluate(() => window.YijingUI.gotoScreen(6));
  await page.waitForTimeout(400);
  await page.click('#meSettingsBtn');
  await page.waitForTimeout(300);
  const sheetOpen = await page.evaluate(() => {
    const s = document.querySelector('.settings-overlay');
    return s && !s.classList.contains('hidden');
  });
  ok(sheetOpen, '屏7 ⚙ 打开设置面板');
  const meta = await page.evaluate(() => document.querySelector('.settings-overlay #settingsMeta').textContent);
  ok(meta.indexOf('本地记录 3 条') >= 0 && meta.indexOf('收藏 2 卦') >= 0, '面板统计正确', meta);
  await page.keyboard.press('Escape');
  await page.waitForTimeout(300);
  await page.evaluate(() => window.YijingUI.gotoScreen(6));
  await page.click('#meHistoryLink');
  await page.waitForTimeout(700);
  const histCur = await page.evaluate(() => window.YijingUI.appCurrent());
  ok(histCur === 5, '历史入口 → 屏6', 'cur=' + histCur);

  console.log('== 7. 收藏变化联动 ==');
  await page.evaluate(() => {
    localStorage.setItem('yijing.favHexes', JSON.stringify([11]));
    document.dispatchEvent(new CustomEvent('yijing:favchange'));
  });
  await page.waitForTimeout(200);
  const favAfter = await page.evaluate(() => ({
    fav: document.getElementById('meFav').textContent,
    chips: document.querySelectorAll('#meFavRow .me-fav-chip').length
  }));
  ok(favAfter.fav === '1' && favAfter.chips === 1, 'favchange 联动刷新', JSON.stringify(favAfter));

  console.log('== 8. 深链 #me ==');
  await page.goto(BASE + '/?view=app#me');
  await page.waitForTimeout(2000);
  const hashCur = await page.evaluate(() => window.YijingUI.appCurrent());
  ok(hashCur === 6, '#me 深链直达屏7', 'cur=' + hashCur);

  console.log('== 9. 最终无运行时错误 ==');
  ok(errors.length === 0, '全程无 console/page 错误', errors.join('; '));

  browser.close().catch(() => {});
  console.log('\n结果: ' + pass + ' 通过 / ' + fail + ' 失败');
  process.exit(fail ? 1 : 0);
})().catch(e => { console.error('FATAL', e); process.exit(1); });
