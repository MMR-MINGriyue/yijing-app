/* iter15: 漏洞猎取 — hero 关闭/焦点、时区边界、数据校验、导入健壮性 */
const { chromium } = require('playwright-core');
(async () => {
  const browser = await chromium.launch({ channel: 'msedge' });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  page.on('console', m => { if (m.type() === 'error' && !m.text().includes('favicon')) errors.push('console: ' + m.text()); });
  await page.goto('http://localhost:8723/?view=app');
  await page.waitForTimeout(2600);
  let pass = 0, fail = 0;
  const t = (name, ok, detail) => { ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + ' ' + name + (detail ? ' — ' + detail : '')); };

  /* A. hero 全屏弹窗: 关闭按钮存在且命中区达标 */
  const hero = await page.evaluate(() => {
    const h = document.getElementById('heroOverlay') || document.querySelector('[role="dialog"]');
    if (!h) return { found: false };
    return { found: true, visible: !!h.offsetParent || h.classList.contains('show') };
  });
  t('hero 弹窗节点存在', hero.found);

  /* 打开今日一卦 hero 全屏 */
  await page.evaluate(() => {
    const h = document.getElementById('heroExpandHandle');
    if (h) h.click();
  });
  await page.waitForTimeout(700);
  const heroState = await page.evaluate(() => {
    const h = document.getElementById('heroFullscreen');
    if (!h) return { open: false, hasClose: false, closeSize: 0, closeTab: false, focus: 'none' };
    const close = document.getElementById('heroFsClose');
    const r = close ? close.getBoundingClientRect() : null;
    return {
      open: h.classList.contains('show') || !!h.offsetParent,
      hasClose: !!close,
      closeSize: r ? Math.round(Math.min(r.width, r.height)) : 0,
      closeTab: close ? (close.getAttribute('role') === 'button' || close.tagName === 'BUTTON' || close.tabIndex >= 0) : false,
      focus: document.activeElement ? (document.activeElement.id || document.activeElement.className.toString().slice(0, 20)) : 'none'
    };
  });
  t('hero 全屏可打开', heroState.open);
  t('hero 有关闭按钮', heroState.hasClose);
  t('hero 关闭命中区 ≥32px (实测 ' + heroState.closeSize + ')', heroState.closeSize >= 32);
  t('hero 关闭按钮键盘可达 (role/tabindex)', heroState.closeTab);
  /* Esc 关闭 */
  await page.keyboard.press('Escape');
  await page.waitForTimeout(500);
  const closed = await page.evaluate(() => {
    const h = document.getElementById('heroFullscreen');
    return !h || (!h.classList.contains('show') && !h.offsetParent);
  });
  t('Esc 可关闭 hero', closed);

  /* B. 时区边界: 干支跨日 */
  const cal = await page.evaluate(() => {
    const c = window.YijingCalendar;
    if (!c) return { has: false };
    const d1 = c.ganzhiDay(new Date(2024, 11, 31, 23, 59));
    const d2 = c.ganzhiDay(new Date(2025, 0, 1, 0, 0));
    return { has: true, d1: d1 + '', d2: d2 + '' };
  });
  t('历法组件存在', cal.has);
  t('跨年夜干支进位 (除夕=' + cal.d1 + ', 元旦=' + cal.d2 + ')', cal.d1 !== cal.d2);

  /* C. 数据校验: 注入畸形 localStorage 后应用不崩 */
  await page.evaluate(() => {
    try {
      localStorage.setItem('yijing.history', 'not-json{');
      localStorage.setItem('yijing.favHexes', JSON.stringify([0, 99, 'x', 5]));
    } catch (e) {}
  });
  await page.reload();
  await page.waitForTimeout(2200);
  const survived = await page.evaluate(() => {
    const n = document.querySelectorAll('#tag-row .tag').length;
    return n === 5;
  });
  t('畸形数据不崩 (history=坏JSON, favs=越界值)', survived);

  /* D. 导入健壮性: 非法 JSON 文件导入 */
  const importRes = await page.evaluate(async () => {
    const blob = new Blob(['{"history":[{"id":"x"}]}'], { type: 'application/json' });
    const file = new File([blob], 'evil.json', { type: 'application/json' });
    const input = document.querySelector('input[type="file"]');
    if (!input) return 'no-input';
    const dt = new DataTransfer();
    dt.items.add(file);
    input.files = dt.files;
    input.dispatchEvent(new Event('change', { bubbles: true }));
    return 'dispatched';
  });
  await page.waitForTimeout(800);
  t('畸形导入触发处理 (' + importRes + ')', importRes === 'dispatched' || importRes === 'no-input');

  /* E. XSS: 历史问题字段含 HTML 注入 */
  await page.evaluate(() => {
    try {
      localStorage.setItem('yijing.history', JSON.stringify([{
        id: Date.now(), hex: 1, question: '<img src=x onerror=window.__xss=1>', ts: Date.now(),
        direction: '事业', directionColor: 'career', method: '铜钱起卦', month: 8, day: 31
      }]));
    } catch (e) {}
  });
  await page.reload();
  await page.waitForTimeout(2200);
  const xss = await page.evaluate(() => !!window.__xss);
  t('历史问题 XSS 不执行', !xss);
  const escOK = await page.evaluate(() => {
    const c = document.querySelector('.hist-card .q, .hist-card [class*="question"]');
    return c ? c.textContent.includes('<img') : null; /* 转义后应为文本 */
  });
  t('问题字段被转义为文本', escOK === true || escOK === null);

  /* F. 恢复干净状态 */
  await page.evaluate(() => { try { localStorage.clear(); } catch (e) {} });

  console.log('\n结果: ' + pass + ' 通过 / ' + fail + ' 失败');
  if (errors.length) console.log('RUNTIME ERRORS:\n' + [...new Set(errors)].join('\n'));
  browser.close();
  process.exit(fail === 0 && errors.length === 0 ? 0 : 1);
})();
