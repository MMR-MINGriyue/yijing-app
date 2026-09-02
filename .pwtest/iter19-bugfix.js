/* iter19: 漏洞修复验证 — XSS 转义 / 监听器泄漏 / CoinToss 竞态 */
const { chromium } = require('playwright-core');
(async () => {
  const browser = await chromium.launch({ executablePath: 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe' });
  const ctx = await browser.newContext({ viewport: { width: 390, height: 844 } });
  /* 在页面脚本运行前挂钩 document.addEventListener 计数 */
  await ctx.addInitScript(() => {
    window.__docListeners = {};
    const orig = document.addEventListener.bind(document);
    document.addEventListener = function (type) {
      window.__docListeners[type] = (window.__docListeners[type] || 0) + 1;
      return orig.apply(document, arguments);
    };
  });
  const page = await ctx.newPage();
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto('http://localhost:8723/?view=app');
  await page.waitForTimeout(2400);
  let pass = 0, fail = 0;
  const t = (name, ok, detail) => { ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + ' ' + name + (detail ? ' — ' + detail : '')); };

  /* ---- 1. XSS: 用户输入含恶意 HTML, toast 必须转义且不执行 ---- */
  await page.evaluate(() => {
    window.YijingUI.setQuestion('<img src=x onerror="window.__xssHit=1">占卜');
    window.YijingUI.submitQuestion();
  });
  await page.waitForTimeout(400);
  const xss = await page.evaluate(() => {
    const toast = document.getElementById('qToast') || document.querySelector('.q-toast');
    return {
      hit: typeof window.__xssHit !== 'undefined',
      hasImg: !!document.querySelector('.q-toast img, #qToast img'),
      text: toast ? toast.textContent : ''
    };
  });
  t('XSS payload 未执行 (window.__xssHit 未定义)', xss.hit === false);
  t('toast 内无注入的 <img> 元素', xss.hasImg === false);
  t('toast 以纯文本呈现 payload', /<img src=x/.test(xss.text), 'text=' + xss.text.slice(0, 40));

  /* ---- 2. 监听器泄漏: 历史列表多次重渲染, document 监听数不增长 ---- */
  const before = await page.evaluate(() => ({ mm: window.__docListeners.mousemove || 0, tm: window.__docListeners.touchmove || 0 }));
  /* 触发 12 次历史重渲染 (每次 renderCurrentMonth → bindLongPress) */
  await page.evaluate(() => {
    for (let i = 0; i < 12; i++) window.YijingUI.refreshHistory();
  });
  await page.waitForTimeout(300);
  const after = await page.evaluate(() => ({ mm: window.__docListeners.mousemove || 0, tm: window.__docListeners.touchmove || 0 }));
  t('12 次重渲染后 document mousemove 监听零增长 (' + before.mm + ' → ' + after.mm + ')', after.mm === before.mm);
  t('12 次重渲染后 document touchmove 监听零增长 (' + before.tm + ' → ' + after.tm + ')', after.tm === before.tm);

  /* 2b. 长按功能仍可用: DOM 派发 mousedown → 480ms 后进入选择模式 */
  await page.evaluate(() => { window.YijingUI.gotoScreen(5); });
  await page.waitForTimeout(500);
  const lp = await page.evaluate(() => {
    const c = document.querySelector('.hist-card[data-idx]');
    if (!c) return { ok: false, why: 'no-card' };
    const r = c.getBoundingClientRect();
    c.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, clientX: r.x + 10, clientY: r.y + 10 }));
    return new Promise(res => {
      const pressing = c.classList.contains('pressing');
      setTimeout(() => {
        const inSel = !!document.querySelector('.select-toolbar');
        c.dispatchEvent(new MouseEvent('mouseup', { bubbles: true }));
        res({ ok: inSel, pressing: pressing, why: inSel ? '' : 'select-mode-not-entered' });
      }, 700);
    });
  });
  t('长按仍可进入多选模式 (泄漏修复未破坏功能)', lp.ok, lp.why || '');
  t('长按即触按压态 (pressing)', lp.pressing !== false);
  await page.evaluate(() => {
    const tb = document.getElementById('selectToolbar');
    if (tb) tb.querySelector('.btn.cancel').click();
  });

  /* ---- 3. CoinToss 竞态: 动画播放中二次起卦被拒 ---- */
  await page.evaluate(() => {
    window.YijingUI.gotoScreen(1);
    window.YijingUI.setQuestion('竞态测试问题');
    window.YijingUI.castHex('coin');
  });
  await page.waitForTimeout(700);
  const ov1 = await page.$('.coin-overlay');
  t('第一场铜钱仪式进行中', !!ov1);
  await page.evaluate(() => { window.YijingUI.castHex('coin'); });
  await page.waitForTimeout(400);
  const state = await page.evaluate(() => ({
    coin: !!document.querySelector('.coin-overlay'),
    skel: (() => { const s = document.getElementById('skeletonOverlay'); return !!s && !s.classList.contains('hidden'); })(),
    toast: (() => { const t2 = document.getElementById('qToast'); return t2 ? t2.textContent : ''; })()
  }));
  t('二次起卦被拒: 铜钱动画仍在 (未被骨架屏覆盖)', state.coin);
  t('二次起卦未触发骨架屏', !state.skel);
  t('二次起卦给出提示', /仪式进行中/.test(state.toast), 'toast=' + state.toast);
  /* 清理: 跳过动画 */
  await page.evaluate(() => { const o = document.querySelector('.coin-overlay'); if (o) o.click(); });
  await page.waitForTimeout(800);

  /* ---- 4. 清理测试数据 + 零错误 ---- */
  await page.evaluate(() => {
    try {
      const h = JSON.parse(localStorage.getItem('yijing.history.v1') || '[]').filter(x => !/竞态|<img/.test(x.question || ''));
      localStorage.setItem('yijing.history.v1', JSON.stringify(h));
      sessionStorage.removeItem('yijing.qInput.lastValue');
    } catch (e) {}
  });
  t('零运行时错误', errors.length === 0, errors.join(' | '));

  console.log('\n结果: ' + pass + ' 通过 / ' + fail + ' 失败');
  browser.close();
  process.exit(fail === 0 ? 0 : 1);
})();
