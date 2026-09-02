/* iter24: 横屏适配 — 手机横屏时改为网格模式 + 回归保证 */
const { chromium } = require('playwright-core');
(async () => {
  const browser = await chromium.launch({ executablePath: 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe' });
  const errs = [];
  let pass = 0, fail = 0;
  const t = (name, ok, detail) => { ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + ' + ' + name + (detail ? ' — ' + detail : '')); };

  /* ===== A. iPhone 12 横屏 844×390 ===== */
  const p1 = await browser.newPage({ viewport: { width: 844, height: 390 } });
  p1.on('pageerror', e => errs.push('844x390: ' + e.message));
  await p1.goto('http://localhost:8723/?view=app');
  await p1.waitForTimeout(2800);
  const a = await p1.evaluate(() => {
    const phones = document.querySelectorAll('.phone');
    const phonesInfo = Array.from(phones).map(x => {
      const r = x.getBoundingClientRect();
      return { w: Math.round(r.width), h: Math.round(r.height), x: Math.round(r.x), y: Math.round(r.y) };
    });
    const c = document.querySelector('.phones');
    const cs = getComputedStyle(c);
    const cols = new Set(phonesInfo.map(p => p.x)).size;
    /* 检测布局: flex-wrap 应为 wrap, snap 应关闭 */
    return {
      wrap: cs.flexWrap, snap: cs.scrollSnapType,
      display: cs.display, overflowX: cs.overflowX,
      count: phonesInfo.length, cols, sample: phonesInfo.slice(0, 4),
      labelDisplay: getComputedStyle(document.querySelector('.phone-label')).display,
      pagerDisplay: getComputedStyle(document.querySelector('.app-pager')).display
    };
  });
  t('横屏 844x390: flex-wrap=wrap (网格布局)', a.wrap === 'wrap', a.wrap);
  t('横屏 844x390: scroll-snap-type=none (关闭轮播)', a.snap === 'none', a.snap);
  t('横屏 844x390: overflow-x=visible', a.overflowX === 'visible', a.overflowX);
  t('横屏 844x390: 7 屏全部渲染', a.count === 7, 'n=' + a.count);
  t('横屏 844x390: 多列布局 (≥2 列)', a.cols >= 2, 'cols=' + a.cols);
  t('横屏 844x390: 每屏 ≈390px 宽 (竖屏比例)', a.sample.every(p => p.w === 390), JSON.stringify(a.sample.map(p => p.w)));
  t('横屏 844x390: 每屏 ≈844px 高 缩到 (390-32)', a.sample.every(p => p.h === 358 || p.h === 360 || p.h === 355 || p.h === 844 - 32), JSON.stringify(a.sample.map(p => p.h)));
  t('横屏 844x390: phone-label 显示 (画廊模式)', a.labelDisplay !== 'none', a.labelDisplay);
  t('横屏 844x390: app-pager 隐藏 (非轮播模式)', a.pagerDisplay === 'none', a.pagerDisplay);

  /* ===== B. iPhone SE 横屏 667×375 (单列) ===== */
  const p2 = await browser.newPage({ viewport: { width: 667, height: 375 } });
  p2.on('pageerror', e => errs.push('667x375: ' + e.message));
  await p2.goto('http://localhost:8723/?view=app');
  await p2.waitForTimeout(2800);
  const b = await p2.evaluate(() => {
    const phones = document.querySelectorAll('.phone');
    const info = Array.from(phones).map(x => {
      const r = x.getBoundingClientRect();
      return { x: Math.round(r.x), w: Math.round(r.width) };
    });
    const cols = new Set(info.map(p => p.x)).size;
    return { cols, count: info.length, w0: info[0] && info[0].w };
  });
  t('横屏 667x375: 7 屏全部渲染', b.count === 7, 'n=' + b.count);
  t('横屏 667x375: 每屏 ≈390px 宽', b.w0 === 390, 'w=' + b.w0);
  /* 667 < 390*2 + 16 + 32 = 828, 所以只能 1 列 */
  t('横屏 667x375: 单列布局 (容不下 2 列)', b.cols === 1, 'cols=' + b.cols);

  /* ===== C. 竖屏回归: 390×844 保持原 app 轮播 ===== */
  const p3 = await browser.newPage({ viewport: { width: 390, height: 844 } });
  p3.on('pageerror', e => errs.push('390x844: ' + e.message));
  await p3.goto('http://localhost:8723/?view=app');
  await p3.waitForTimeout(2800);
  const c = await p3.evaluate(() => {
    const phones = document.querySelectorAll('.phone');
    const info = Array.from(phones).slice(0, 3).map(x => {
      const r = x.getBoundingClientRect();
      return { x: Math.round(r.x), w: Math.round(r.width), h: Math.round(r.height) };
    });
    const cs = getComputedStyle(document.querySelector('.phones'));
    return {
      count: phones.length, sample: info,
      wrap: cs.flexWrap, snap: cs.scrollSnapType,
      firstW: info[0].w, secondX: info[1].x
    };
  });
  t('竖屏 390x844: 7 屏全部渲染', c.count === 7, 'n=' + c.count);
  t('竖屏 390x844: flex-wrap=nowrap (横向轮播)', c.wrap === 'nowrap', c.wrap);
  t('竖屏 390x844: scroll-snap 启用', c.snap.indexOf('x mandatory') >= 0 || c.snap.indexOf('mandatory') >= 0, c.snap);
  t('竖屏 390x844: 每屏全宽 390px', c.firstW === 390, 'w=' + c.firstW);
  t('竖屏 390x844: 第 2 屏 x=390 (紧随其后)', c.secondX === 390, 'x=' + c.secondX);

  /* iter23 屏1首屏回归 */
  const home = await p3.evaluate(() => {
    const rec = document.getElementById('recentList');
    const tab = document.querySelector('.tabbar');
    if (!rec || !tab) return null;
    const r = rec.getBoundingClientRect();
    return { top: r.top, bottom: r.bottom, tabTop: tab.getBoundingClientRect().top, n: rec.children.length };
  });
  t('竖屏回归: recent-section 完整可见', home.top > 0 && home.bottom <= home.tabTop + 1,
    'top=' + home.top.toFixed(0) + ' bottom=' + home.bottom.toFixed(0) + ' tabTop=' + home.tabTop.toFixed(0));

  /* ===== D. 平板横屏 1024×500 应走 grid 模式 (不被 landscape media query 干扰) ===== */
  const p4 = await browser.newPage({ viewport: { width: 1024, height: 500 } });
  p4.on('pageerror', e => errs.push('1024x500: ' + e.message));
  await p4.goto('http://localhost:8723/?view=app');
  await p4.waitForTimeout(2800);
  const d = await p4.evaluate(() => {
    const phones = document.querySelectorAll('.phone');
    const info = Array.from(phones).slice(0, 3).map(x => {
      const r = x.getBoundingClientRect();
      return { x: Math.round(r.x), w: Math.round(r.width) };
    });
    return { count: phones.length, w0: info[0].w, x0: info[0].x, x1: info[1].x };
  });
  t('平板横屏 1024x500: 7 屏全部渲染', d.count === 7, 'n=' + d.count);
  t('平板横屏 1024x500: 每屏 390px (grid 模式)', d.w0 === 390, 'w=' + d.w0);

  /* ===== E. 正方形视口 500×500 不触发横屏布局 ===== */
  const p5 = await browser.newPage({ viewport: { width: 500, height: 500 } });
  p5.on('pageerror', e => errs.push('500x500: ' + e.message));
  await p5.goto('http://localhost:8723/?view=app');
  await p5.waitForTimeout(2800);
  const e = await p5.evaluate(() => {
    const cs = getComputedStyle(document.querySelector('.phones'));
    return { wrap: cs.flexWrap, snap: cs.scrollSnapType };
  });
  t('500x500 (正方形): flex-wrap=nowrap (竖屏模式)', e.wrap === 'nowrap', e.wrap);
  t('500x500 (正方形): scroll-snap 启用', e.snap.indexOf('mandatory') >= 0, e.snap);

  /* ===== F. 滚动后能看到所有屏 ===== */
  const page = await browser.newPage({ viewport: { width: 844, height: 390 } });
  await page.goto('http://localhost:8723/?view=app');
  await page.waitForTimeout(2800);
  const scrollable = await page.evaluate(() => {
    const v = document.querySelector('.viewport');
    return { scrollH: v.scrollHeight, clientH: v.clientHeight };
  });
  t('横屏: viewport 纵向可滚动 (scrollH > clientH)',
    scrollable.scrollH > scrollable.clientH,
    'scrollH=' + scrollable.scrollH + ' clientH=' + scrollable.clientH);

  /* 滚到底部后 last screen 在视口内 */
  await page.evaluate(() => {
    const v = document.querySelector('.viewport');
    v.scrollTop = v.scrollHeight;
  });
  await page.waitForTimeout(300);
  const last = await page.evaluate(() => {
    const phones = document.querySelectorAll('.phone');
    const last = phones[phones.length - 1];
    const r = last.getBoundingClientRect();
    return { top: r.top, bottom: r.bottom, h: r.height, viewportH: innerHeight };
  });
  t('横屏: 滚到底后第 7 屏在视口内',
    last.top < last.viewportH && last.bottom > 0,
    'top=' + last.top.toFixed(0) + ' h=' + last.h.toFixed(0));

  t('零 pageerror', errs.length === 0, errs.join(' | '));

  console.log('\n结果: ' + pass + ' 通过, ' + fail + ' 失败');
  await browser.close();
  process.exit(fail || errs.length ? 1 : 0);
})();