/* 第十三轮冒烟测试: 方向筛选 + 图表跳转 */
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
  await page.evaluate(() => localStorage.clear());
  await page.goto(BASE + '/?view=app#history');
  await page.waitForTimeout(2400);

  console.log('== 1. 加载无运行时错误 ==');
  ok(errors.length === 0, '无 console/page 错误', errors.join('; '));

  console.log('== 2. 造数据: 本月 5 条含 3 个方向 ==');
  const now = new Date();
  const cur = now.getFullYear() + '-' + String(now.getMonth() + 1).padStart(2, '0');
  await page.evaluate(c => {
    const t = Date.now();
    const mk = (ts, hexNo, name, dir, m) => ({ ts, date: '今日', month: c, day: 30, hexNo, name, question: '问：' + dir, direction: dir, directionColor: 'cinnabar', lines: [], moving: [], method: m });
    window.YijingHistory.save([
      mk(t - 4, 1, '乾卦', '事业', 'coin'),
      mk(t - 3, 2, '坤卦', '事业', 'coin'),
      mk(t - 2, 5, '需卦', '感情', 'numeric'),
      mk(t - 1, 11, '泰卦', '学业', 'yarrow'),
      mk(t, 12, '否卦', '事业', 'coin')
    ]);
    window.YijingUI.refreshHistory();
  }, cur);
  await page.waitForTimeout(400);

  console.log('== 3. 方向 chips 渲染与筛选 ==');
  const chips = await page.evaluate(() => Array.from(document.querySelectorAll('#dirFilterRow .hex-filter-chip')).map(c => c.textContent));
  ok(chips.length === 4 && chips[0].indexOf('全方向') >= 0, 'chips: 全方向 + 3 方向', JSON.stringify(chips));
  // 点击 事业 (计数 3)
  await page.click('#dirFilterRow .hex-filter-chip:nth-child(2)');
  await page.waitForTimeout(300);
  const filtered = await page.evaluate(() => ({
    meta: document.getElementById('hexFilterMetaText').textContent,
    clearShown: document.getElementById('hexFilterClear').style.display !== 'none',
    cards: document.querySelectorAll('.hist-card').length,
    activeChips: document.querySelectorAll('#dirFilterRow .hex-filter-chip.active').length
  }));
  ok(filtered.meta.indexOf('事业') >= 0 && filtered.meta.indexOf('3') >= 0, 'meta 显示方向筛选', filtered.meta);
  ok(filtered.cards === 3, '3 条记录显示', 'cards=' + filtered.cards);
  ok(filtered.activeChips === 1, '仅 1 chip 激活');
  // 再点同 chip 取消
  await page.click('#dirFilterRow .hex-filter-chip:nth-child(2)');
  await page.waitForTimeout(300);
  const unfiltered = await page.evaluate(() => ({
    cards: document.querySelectorAll('.hist-card').length,
    meta: document.getElementById('hexFilterMetaText').textContent,
    clearShown: document.getElementById('hexFilterClear').style.display !== 'none'
  }));
  ok(unfiltered.cards === 5, '再点取消 → 5 条', 'cards=' + unfiltered.cards);
  ok(!unfiltered.clearShown && unfiltered.meta.indexOf('筛 选：') < 0, 'meta 复位', unfiltered.meta);

  console.log('== 4. 卦象 + 方向复合筛选 (AND) ==');
  // 先选方向 事业, 再选卦 乾
  await page.click('#dirFilterRow .hex-filter-chip:nth-child(2)');
  await page.waitForTimeout(200);
  await page.click('#hexFilterRow .hex-filter-chip[data-hex="1"]');
  await page.waitForTimeout(300);
  const combo = await page.evaluate(() => ({
    meta: document.getElementById('hexFilterMetaText').textContent,
    cards: document.querySelectorAll('.hist-card').length
  }));
  ok(combo.meta.indexOf('乾') >= 0 && combo.meta.indexOf('事业') >= 0, '复合 meta', combo.meta);
  ok(combo.cards === 1, '乾+事业 → 1 条', 'cards=' + combo.cards);
  // 清除筛选复位
  await page.click('#hexFilterClear');
  await page.waitForTimeout(300);
  const cleared = await page.evaluate(() => ({
    cards: document.querySelectorAll('.hist-card').length,
    meta: document.getElementById('hexFilterMetaText').textContent
  }));
  ok(cleared.cards === 5 && cleared.meta.indexOf('筛 选：') < 0, '清除 → 全部 5 条复位', cleared.cards + ' / ' + cleared.meta);

  console.log('== 5. 07 屏方向条点击跳转 ==');
  await page.evaluate(() => window.YijingUI.gotoScreen(6));
  await page.waitForTimeout(400);
  const meDirs = await page.evaluate(() => Array.from(document.querySelectorAll('#meDirectionBars .me-bar.clickable')).map(b => (b.querySelector('.bar-head span').textContent)));
  ok(meDirs.length === 3 && meDirs[0] === '事业', '07 屏方向条可点击渲染', JSON.stringify(meDirs));
  await page.click('#meDirectionBars .me-bar:first-child');
  await page.waitForTimeout(700);
  const jump = await page.evaluate(() => ({
    cur: window.YijingUI.appCurrent(),
    meta: document.getElementById('hexFilterMetaText').textContent,
    cards: document.querySelectorAll('.hist-card').length
  }));
  ok(jump.cur === 5, '跳转到 06 屏', 'cur=' + jump.cur);
  ok(jump.meta.indexOf('事业') >= 0 && jump.cards === 3, '自动应用方向筛选 3 条', jump.meta + ' / ' + jump.cards);

  console.log('== 6. 07 屏方式条点击跳转 (不筛选) ==');
  await page.evaluate(() => window.YijingUI.gotoScreen(6));
  await page.waitForTimeout(400);
  const clickableBars = await page.evaluate(() => document.querySelectorAll('#meMethodBars .me-bar.clickable').length);
  ok(clickableBars === 3, '方式条 3 项可点击');
  await page.click('#meMethodBars .me-bar:first-child');
  await page.waitForTimeout(700);
  const jump2 = await page.evaluate(() => ({
    cur: window.YijingUI.appCurrent(),
    cards: document.querySelectorAll('.hist-card').length,
    meta: document.getElementById('hexFilterMetaText').textContent
  }));
  ok(jump2.cur === 5 && jump2.cards === 5, '方式条跳转不筛选', 'cur=' + jump2.cur + ' cards=' + jump2.cards);
  ok(jump2.meta.indexOf('筛 选：') < 0, '无筛选态', jump2.meta);

  console.log('== 7. 月切换重置方向筛选 ==');
  await page.evaluate(() => window.YijingUI.filterByDirection('事业'));
  await page.waitForTimeout(200);
  const prevMonth = await page.evaluate(() => {
    const s = document.getElementById('monthLabel').textContent;
    return s;
  });
  await page.click('#monthPrev');
  await page.waitForTimeout(300);
  const afterSwitch = await page.evaluate(() => ({
    label: document.getElementById('monthLabel').textContent,
    dirRow: document.getElementById('dirFilterRow').style.display,
    meta: document.getElementById('hexFilterMetaText').textContent,
    chips: document.querySelectorAll('#dirFilterRow .hex-filter-chip').length
  }));
  ok(afterSwitch.label !== prevMonth, '月份切换生效', prevMonth + ' → ' + afterSwitch.label);
  ok(afterSwitch.chips === 0 && afterSwitch.dirRow === 'none', '上月无记录 → 方向行隐藏', JSON.stringify(afterSwitch));
  ok(afterSwitch.meta.indexOf('筛 选：') < 0, '方向筛选已重置', afterSwitch.meta);

  console.log('== 8. 空数据时方向行隐藏 ==');
  await page.evaluate(() => {
    window.YijingHistory.clear();
    window.YijingUI.refreshHistory();
  });
  await page.waitForTimeout(300);
  const emptyRow = await page.evaluate(() => ({
    display: document.getElementById('dirFilterRow').style.display,
    chips: document.querySelectorAll('#dirFilterRow .hex-filter-chip').length
  }));
  ok(emptyRow.display === 'none' && emptyRow.chips === 0, '空数据方向行隐藏', JSON.stringify(emptyRow));

  console.log('== 9. 最终无运行时错误 ==');
  ok(errors.length === 0, '全程无 console/page 错误', errors.join('; '));

  browser.close().catch(() => {});
  console.log('\n结果: ' + pass + ' 通过 / ' + fail + ' 失败');
  process.exit(fail ? 1 : 0);
})().catch(e => { console.error('FATAL', e); process.exit(1); });
