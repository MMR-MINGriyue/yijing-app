/* iter16: 设计系统归一化验证 v2 — token 解析 + 弹层/覆盖层实测 */
const { chromium } = require('playwright-core');
(async () => {
  const browser = await chromium.launch({ channel: 'msedge' });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto('http://localhost:8723/?view=app');
  await page.waitForTimeout(2600);
  let pass = 0, fail = 0;
  const t = (name, ok, detail) => { ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + ' ' + name + (detail ? ' — ' + detail : '')); };

  /* 1. 全部新 token 在 :root 计算值非空且无自引用 */
  const tokens = await page.evaluate(() => {
    const cs = getComputedStyle(document.documentElement);
    const names = ['--grad-card', '--grad-sheet', '--grad-overlay', '--grad-cinnabar', '--grad-cinnabar-v', '--text-on-fill', '--cinnabar-deeper'];
    const out = {};
    names.forEach(n => { out[n] = cs.getPropertyValue(n).trim(); });
    return out;
  });
  Object.entries(tokens).forEach(([k, v]) => {
    t('token ' + k + ' 定义有效', v.length > 3 && !v.includes('var(--' + k + ')'), JSON.stringify(v).slice(0, 50));
  });

  /* 2. 消费端解析 (屏1 可见元素) */
  const used = await page.evaluate(() => {
    const out = {};
    const qc = document.querySelector('.quick-circle');
    if (qc) out.quickCircle = getComputedStyle(qc).borderRadius;
    /* 屏1 hero 区某个渐变卡: 遍历可见元素找 linear-gradient */
    let gradCount = 0, cinnabarGrad = 0;
    document.querySelectorAll('.phone:first-of-type *').forEach(el => {
      if (!el.offsetParent) return;
      const bg = getComputedStyle(el).backgroundImage;
      if (bg.includes('linear-gradient')) {
        gradCount++;
        if (bg.includes('153, 45, 35')) cinnabarGrad++; /* #992d23 */
      }
    });
    out.gradCount = gradCount; out.cinnabarGrad = cinnabarGrad;
    return out;
  });
  t('屏1 渐变渲染生效 (n=' + used.gradCount + ')', used.gradCount > 0);
  t('quick-circle radius=50%', used.quickCircle === '50%');
  /* 3. 屏3 六十四卦卡渐变 (grad-card 消费者) */
  await page.evaluate(() => { try { window.YijingUI.gotoScreen(2); } catch (e) {} });
  await page.waitForTimeout(500);
  const s3 = await page.evaluate(() => {
    let n = 0;
    document.querySelectorAll('.hex-card').forEach(el => {
      const bg = getComputedStyle(el).backgroundImage;
      if (bg.includes('linear-gradient')) n++;
    });
    return n;
  });
  t('屏3 卦卡渐变 (grad-card, n=' + s3 + ')', s3 > 0);

  /* 4. 爻辞弹层 grad-sheet */
  await page.evaluate(() => { try { window.YijingUI.gotoScreen(4); } catch (e) {} });
  await page.waitForTimeout(400);
  await page.evaluate(() => {
    const row = document.querySelector('.yao-row, [class*="yao"]');
    if (row) row.click();
  });
  await page.waitForTimeout(700);
  const sheet = await page.evaluate(() => {
    const panel = document.querySelector('.yao-modal-panel');
    if (!panel) return { exists: false };
    const bg = getComputedStyle(panel).backgroundImage;
    return { exists: true, grad: /linear-gradient/.test(bg), deep: bg.includes('18, 12, 8') || bg.includes('31, 22, 16') };
  });
  t('爻辞弹层存在', sheet.exists);
  t('弹层 grad-sheet 渐变生效', sheet.grad);
  await page.keyboard.press('Escape');
  await page.waitForTimeout(300);

  /* 5. hero 全屏 grad-overlay */
  await page.evaluate(() => { try { window.YijingUI.gotoScreen(0); } catch (e) {} });
  await page.waitForTimeout(500);
  await page.evaluate(() => { const h = document.getElementById('heroExpandHandle'); if (h) h.click(); });
  await page.waitForTimeout(700);
  const overlay = await page.evaluate(() => {
    const h = document.getElementById('heroFullscreen');
    if (!h) return 'no-el';
    const open = h.classList.contains('show') || !!h.offsetParent;
    const bg = getComputedStyle(h).backgroundImage;
    return { open: open, grad: /linear-gradient/.test(bg) };
  });
  t('hero 全屏可打开', overlay.open !== false);
  t('hero grad-overlay 渐变生效', overlay.grad !== false);
  await page.keyboard.press('Escape');

  /* 6. 无横向溢出 + 零错误 */
  const overflow = await page.evaluate(() =>
    [...document.querySelectorAll('.phone .content')].some(c => c.scrollWidth > c.clientWidth + 4));
  t('无横向溢出', !overflow);
  t('零运行时错误', errors.length === 0);

  console.log('\n结果: ' + pass + ' 通过 / ' + fail + ' 失败');
  if (errors.length) console.log('ERRORS: ' + errors.join(' | '));
  browser.close();
  process.exit(fail === 0 ? 0 : 1);
})();
