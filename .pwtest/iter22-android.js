/* iter22: Android 规范适配 — viewport-fit / theme-color / 48dp 触控 / 返回键历史栈 */
const { chromium } = require('playwright-core');
(async () => {
  const browser = await chromium.launch({ channel: 'msedge' });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto('http://localhost:8723/?view=app');
  await page.waitForTimeout(2400); /* 骨架屏 + applyHash + replaceState (1600ms) */
  let pass = 0, fail = 0;
  const t = (name, ok, detail) => { ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + ' ' + name + (detail ? ' — ' + detail : '')); };

  /* ===== A. 壳层 meta 与触控规范 ===== */
  const shell = await page.evaluate(async () => {
    const vp = document.querySelector('meta[name="viewport"]');
    const tc = document.querySelector('meta[name="theme-color"]');
    let manifest = null;
    try { manifest = await (await fetch('./manifest.webmanifest')).json(); } catch (e) {}
    const tap = getComputedStyle(document.documentElement).getPropertyValue('--tap-min').trim();
    return {
      viewport: vp && vp.content,
      cover: !!vp && vp.content.indexOf('viewport-fit=cover') >= 0,
      themeColor: tc && tc.content,
      manifestTheme: manifest && manifest.theme_color,
      tap: tap
    };
  });
  t('viewport: 含 viewport-fit=cover (刘海屏 edge-to-edge)', shell.cover, shell.viewport);
  t('theme-color: #14100b 与 App 底色一致', shell.themeColor === '#14100b', shell.themeColor);
  t('manifest theme_color 同步 #14100b', shell.manifestTheme === '#14100b', shell.manifestTheme);
  t('触控: --tap-min = 48px (Material 3)', shell.tap === '48px', shell.tap);

  /* ===== B. 返回键历史栈 ===== */
  const hist = await page.evaluate(() => {
    const r = {};
    r.start0 = window.YijingUI.appCurrent();
    window.YijingUI.gotoScreen(1);
    r.h1 = location.hash;
    r.s1 = window.YijingUI.appCurrent();
    window.YijingUI.gotoScreen(2);
    r.h2 = location.hash;
    r.s2 = window.YijingUI.appCurrent();
    window.YijingUI.gotoScreen(3); /* 详情屏: 不压栈 */
    r.h3 = location.hash;
    r.s3 = window.YijingUI.appCurrent();
    r.len3 = history.length;
    return r;
  });
  await page.waitForTimeout(400);
  t('历史栈: gotoScreen(1) 压 #start 且切屏', hist.h1 === '#start' && hist.s1 === 1, JSON.stringify({ h: hist.h1, s: hist.s1 }));
  t('历史栈: gotoScreen(2) 压 #hexagrams', hist.h2 === '#hexagrams' && hist.s2 === 2, JSON.stringify({ h: hist.h2, s: hist.s2 }));
  t('历史栈: 详情屏(3) 同 URL 压栈 (hash 不变)', hist.h3 === '#hexagrams' && hist.s3 === 3, JSON.stringify({ h: hist.h3, s: hist.s3 }));

  /* 返回键 → 详情回屏3 → 屏2 → 屏1 (共 3 层栈, 第 4 次将离开页面 = Android 退出) */
  await page.goBack();
  await page.waitForTimeout(500);
  let back1 = await page.evaluate(() => ({ s: window.YijingUI.appCurrent(), h: location.hash }));
  t('返回键: 第 1 次回退 → 屏3 (卦象)', back1.s === 2 && back1.h === '#hexagrams', JSON.stringify(back1));
  await page.goBack();
  await page.waitForTimeout(500);
  let back2 = await page.evaluate(() => ({ s: window.YijingUI.appCurrent(), h: location.hash }));
  t('返回键: 第 2 次回退 → 屏2 (起卦)', back2.s === 1 && back2.h === '#start', JSON.stringify(back2));
  await page.goBack();
  await page.waitForTimeout(500);
  let back3 = await page.evaluate(() => ({ s: window.YijingUI.appCurrent(), h: location.hash }));
  t('返回键: 第 3 次回退 → 屏1 (今日, 入口 state)', back3.s === 0 && back3.h === '#today', JSON.stringify(back3));

  /* ===== C. hash 深链不回归 ===== */
  await page.evaluate(() => { location.hash = '#history'; });
  await page.waitForTimeout(600);
  const dl1 = await page.evaluate(() => ({ s: window.YijingUI.appCurrent(), h: location.hash }));
  t('深链: #history hashchange → 屏6 (历史)', dl1.s === 5 && dl1.h === '#history', JSON.stringify(dl1));
  await page.evaluate(() => { window.YijingUI.gotoScreen(0); });
  await page.waitForTimeout(400);
  const dl2 = await page.evaluate(() => location.hash);
  t('导航: gotoScreen(0) → #today', dl2 === '#today', dl2);

  /* 刷新后 #me 深链直达 */
  await page.evaluate(() => { location.hash = '#me'; });
  await page.waitForTimeout(600);
  await page.reload();
  await page.waitForTimeout(2400);
  const dl3 = await page.evaluate(() => ({ s: window.YijingUI.appCurrent(), h: location.hash, st: JSON.stringify(history.state) }));
  t('深链: 刷新 #me → 直达屏7 且入口 state 补齐', dl3.s === 6 && dl3.h === '#me' && dl3.st.indexOf('"screen":6') >= 0, JSON.stringify(dl3));

  t('零 pageerror', errors.length === 0, errors.join(' | '));
  console.log('\n结果: ' + pass + ' 通过, ' + fail + ' 失败');
  await browser.close();
  process.exit(fail ? 1 : 0);
})();
