/* 第八轮迭代冒烟测试: 统计动态化 / 排序 / 搜索 / 设置面板 / 头部分享 */
const { chromium } = require('playwright-core');

const BASE = 'http://localhost:8723';
let pass = 0, fail = 0;
function ok(cond, name, extra) {
  if (cond) { pass++; console.log('  PASS ' + name); }
  else { fail++; console.log('  FAIL ' + name + (extra ? ' | ' + extra : '')); }
}

(async () => {
  const browser = await chromium.launch({ channel: 'msedge' });
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 }, hasTouch: true });
  const page = await ctx.newPage();
  const errors = [];
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', e => errors.push(String(e)));

  await page.goto(BASE + '/?view=app');
  await page.waitForTimeout(2200);

  console.log('== 1. 加载无运行时错误 ==');
  ok(errors.length === 0, '无 console/page 错误', errors.join('; '));

  // 预置一条真实记录, 便于验证统计/排序/清空
  await page.evaluate(() => {
    window.YijingHistory.add({
      date: '今日 10:30', month: '2026-08', day: 30, hexNo: 1, name: '乾卦',
      question: '问：测试用例甲', direction: '事业', directionColor: 'cinnabar',
      highlight: true, lines: ['yang','yang','yang','yang','yang','yang'], moving: [2], method: 'coin'
    });
    localStorage.setItem('yijing.favHexes', JSON.stringify([1, 5, 8]));
    window.YijingUI.refreshHistory();
  });
  await page.waitForTimeout(300);

  console.log('== 2. 屏6 统计卡动态化 ==');
  const stats = await page.evaluate(() => ({
    total: document.getElementById('statTotal').textContent,
    week: document.getElementById('statWeek').textContent,
    fav: document.getElementById('statFav').textContent,
    head: document.getElementById('histTotalCount').textContent,
    real: window.YijingHistory.all().length
  }));
  ok(stats.total === String(stats.real), '总次数 = 真实记录数', JSON.stringify(stats));
  ok(stats.fav === '3', '收藏 = favHexes 数量', stats.fav);
  ok(stats.head.indexOf('共 ' + stats.real + ' 次') >= 0, '顶栏总数动态', stats.head);

  console.log('== 3. ⇅ 排序切换 (切到 2026-06 样例月, 多条记录) ==');
  await page.evaluate(() => window.YijingUI.changeMonth(2026, 6));
  await page.waitForTimeout(300);
  const firstCardSel = '#hist-today .hist-card, #hist-week .hist-card';
  const before = await page.evaluate(sel => {
    const cards = document.querySelectorAll(sel);
    return cards.length ? cards[0].dataset.hex : null;
  }, firstCardSel);
  const countBefore = await page.evaluate(sel => document.querySelectorAll(sel).length, firstCardSel);
  await page.click('#histSortBtn');
  await page.waitForTimeout(300);
  const after = await page.evaluate(sel => {
    const cards = document.querySelectorAll(sel);
    const btn = document.getElementById('histSortBtn');
    const cap = document.querySelector('#hist-today .group-cap');
    return { first: cards.length ? cards[0].dataset.hex : null, count: cards.length, flipped: btn.classList.contains('flipped'), cap: cap ? cap.textContent : '' };
  }, firstCardSel);
  ok(countBefore >= 2, '当月至少 2 条记录可验证排序', 'count=' + countBefore);
  ok(before !== null && after.first !== null, '排序后仍有卡片');
  ok(before !== after.first, '点击后顺序改变', before + ' -> ' + after.first);
  ok(after.flipped, '按钮翻转态');
  ok(after.cap.indexOf('早') >= 0, '分组标签切换', after.cap);
  await page.click('#histSortBtn'); // 恢复最新在前
  await page.waitForTimeout(200);

  console.log('== 4. 历史搜索 ==');
  await page.evaluate(() => window.YijingUI.changeMonth(2026, 8)); // 只含预置记录的月
  await page.waitForTimeout(300);
  await page.fill('#histSearchInput', '测试用例甲');
  await page.waitForTimeout(300);
  const searched = await page.evaluate(() => ({
    monthStats: document.getElementById('monthStats').textContent,
    hasTarget: !!Array.from(document.querySelectorAll('#hist-today .hist-card, #hist-week .hist-card')).find(c => c.textContent.indexOf('测试用例甲') >= 0)
  }));
  ok(searched.monthStats === '共 1 次', '搜索命中 1 条', searched.monthStats);
  ok(searched.hasTarget, '目标卡片可见');
  await page.fill('#histSearchInput', '不存在的关键词xyz');
  await page.waitForTimeout(300);
  const noneMsgText = await page.evaluate(() => {
    const el = document.querySelector('#hist-week .hist-empty, #hist-today .hist-empty');
    return el ? el.textContent : '';
  });
  ok(noneMsgText.indexOf('无 匹 配') >= 0, '无结果提示', noneMsgText);
  await page.fill('#histSearchInput', '');
  await page.waitForTimeout(300);
  const restored = await page.evaluate(() => document.getElementById('monthStats').textContent);
  ok(restored === '共 1 次', '清空关键词恢复当月计数', restored);

  console.log('== 5. ⚙ 设置面板 ==');
  await page.click('#settingsBtn');
  await page.waitForTimeout(300);
  const sheetVisible = await page.evaluate(() => {
    const s = document.querySelector('.settings-overlay');
    return s && !s.classList.contains('hidden');
  });
  ok(sheetVisible, '面板打开');
  const meta = await page.evaluate(() => document.querySelector('.settings-overlay #settingsMeta').textContent);
  ok(meta.indexOf('本地记录 1 条') >= 0 && meta.indexOf('收藏 3 卦') >= 0, '面板统计正确', meta);
  await page.click('.settings-overlay #settingsClear');
  await page.waitForTimeout(150);
  const confirmText = await page.evaluate(() => document.querySelector('.settings-overlay #settingsClear .settings-item-name').textContent);
  ok(confirmText.indexOf('确认清空') >= 0, '首次点击出现二次确认', confirmText);
  await page.click('.settings-overlay #settingsClear');
  await page.waitForTimeout(400);
  const afterClear = await page.evaluate(() => ({
    localCount: window.YijingHistory.load().length,
    total: document.getElementById('statTotal').textContent
  }));
  ok(afterClear.localCount === 0, 'localStorage 已清空');
  ok(afterClear.total === String(stats.real - 1), '统计卡联动刷新', afterClear.total);
  await page.keyboard.press('Escape');
  await page.waitForTimeout(300);
  const closed = await page.evaluate(() => {
    const s = document.querySelector('.settings-overlay');
    return !s || s.classList.contains('hidden');
  });
  ok(closed, 'Esc 关闭面板');

  console.log('== 6. 屏4 头部 ↗ 触发分享卡 ==');
  await page.evaluate(() => window.YijingUI.openDetail(1));
  await page.waitForTimeout(500);
  // 劫持 YijingShare.share 记录调用 (无头环境 navigator.share 返回 cancel, 不弹 toast 属正常)
  await page.evaluate(() => {
    window.__shareCalls = [];
    const orig = window.YijingShare.share;
    window.YijingShare.share = function () {
      window.__shareCalls.push(Array.from(arguments).slice(0, 2));
      return Promise.resolve({ ok: true, how: 'cancel' });
    };
    window.__origShare = orig;
  });
  await page.click('#phoneDetail .detail-header .icon-btn:nth-child(3)');
  await page.waitForTimeout(800);
  const shareInfo = await page.evaluate(() => window.__shareCalls);
  ok(shareInfo.length === 1, '头部 ↗ 触发分享卡生成', JSON.stringify(shareInfo));
  ok(shareInfo.length === 1 && String(shareInfo[0][0]) === '1', '分享目标为当前卦', JSON.stringify(shareInfo));
  await page.evaluate(() => { window.YijingShare.share = window.__origShare; });

  console.log('== 7. 导出下载 ==');
  const downloadPromise = page.waitForEvent('download', { timeout: 5000 }).catch(() => null);
  await page.click('#settingsBtn');
  await page.waitForTimeout(200);
  await page.click('.settings-overlay #settingsExport');
  const dl = await downloadPromise;
  ok(dl && dl.suggestedFilename().indexOf('yijing-history-') === 0, '下载 JSON 文件', dl ? dl.suggestedFilename() : 'no download');

  console.log('== 8. 最终无运行时错误 ==');
  ok(errors.length === 0, '全程无 console/page 错误', errors.join('; '));

  console.log('\n结果: ' + pass + ' 通过 / ' + fail + ' 失败');
  browser.close().catch(() => {});
  process.exit(fail ? 1 : 0);
})().catch(e => { console.error('FATAL', e); process.exit(1); });
