/* iter17: 动效优化验证 — 入场编排 / favPop / reduced-motion */
const { chromium } = require('playwright-core');
(async () => {
  const browser = await chromium.launch({ executablePath: 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe' });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto('http://localhost:8723/?view=app');
  await page.waitForTimeout(2800);
  let pass = 0, fail = 0;
  const t = (name, ok, detail) => { ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + ' ' + name + (detail ? ' — ' + detail : '')); };

  /* 1. 首屏 stagger: 四组元素 animation-delay 递增 */
  const stagger = await page.evaluate(() => {
    const phone = document.querySelector('.phone');
    const get = sel => {
      const el = phone.querySelector(sel);
      if (!el) return null;
      const cs = getComputedStyle(el);
      return { dur: cs.animationDuration, delay: cs.animationDelay, name: cs.animationName };
    };
    return {
      header: get('.header-row'),
      hero: get('.hero-card'),
      quick: get('.quick-row'),
      recent: get('.recent-section'),
      q1: get('.quick-item:nth-child(1)'),
      q3: get('.quick-item:nth-child(3)')
    };
  });
  t('header-row 入场动画 (' + stagger.header.name + ' ' + stagger.header.delay + ')', stagger.header && stagger.header.name === 'fadeUp' && stagger.header.delay !== '0s');
  t('hero-card 延迟 0.14s', stagger.hero && stagger.hero.delay === '0.14s');
  t('quick-row 延迟 0.26s', stagger.quick && stagger.quick.delay === '0.26s');
  t('recent-section 延迟 0.38s', stagger.recent && stagger.recent.delay === '0.38s');
  const monoInc = parseFloat(stagger.header.delay) < parseFloat(stagger.hero.delay)
    && parseFloat(stagger.hero.delay) < parseFloat(stagger.quick.delay)
    && parseFloat(stagger.quick.delay) < parseFloat(stagger.recent.delay);
  t('四段延迟单调递增 (编排有序)', monoInc);
  t('quick-item 内部递进 (q1 0.30s < q3 0.40s)', parseFloat(stagger.q1.delay) < parseFloat(stagger.q3.delay));

  /* 2. 入场完成后元素可见 (both 填充, 非卡在 opacity 0) */
  const visible = await page.evaluate(() => {
    const phone = document.querySelector('.phone');
    const bad = [];
    ['.header-row', '.hero-card', '.quick-row', '.recent-section'].forEach(sel => {
      const el = phone.querySelector(sel);
      if (el && parseFloat(getComputedStyle(el).opacity) < 0.99) bad.push(sel);
    });
    return bad;
  });
  t('入场完成全部可见', visible.length === 0, visible.join(','));

  /* 3. favPop: 进入屏4 触发收藏, class 与 keyframe 生效 */
  await page.evaluate(() => { try { window.YijingUI.openDetail(1); } catch (e) {} });
  await page.waitForTimeout(700);
  const fav = await page.evaluate(() => {
    const f = document.getElementById('detailFav');
    if (!f) return { exists: false };
    /* 确保未收藏状态 */
    let favs = [];
    try { favs = JSON.parse(localStorage.getItem('yijing.favHexes') || '[]'); } catch (e) {}
    const i = favs.indexOf(1);
    if (i >= 0) { favs.splice(i, 1); try { localStorage.setItem('yijing.favHexes', JSON.stringify(favs)); } catch (e) {} }
    f.click();
    const cs = getComputedStyle(f);
    let popRule = false;
    for (const sheet of document.styleSheets) {
      try { for (const r of sheet.cssRules) { if (r.selectorText && r.selectorText.includes('.fav.pop')) popRule = true; } } catch (e) {}
    }
    return { exists: true, on: f.classList.contains('on') && cs.animationName === 'favPop', glyph: f.textContent, popRule: popRule };
  });
  t('fav 按钮存在', fav.exists);
  t('收藏 pop 动画触发 (animationName=' + (fav.on ? 'favPop' : 'none') + ')', fav.on === true);
  t('.fav.pop CSS 规则存在', fav.popRule);
  t('心形字符切换 (♥)', fav.glyph === '♥');
  /* 再点一次取消, 再点一次确认重触发 */
  const retrigger = await page.evaluate(() => {
    const f = document.getElementById('detailFav');
    f.click(); /* 取消 */
    f.click(); /* 再收藏 */
    return f.classList.contains('pop') && getComputedStyle(f).animationName === 'favPop';
  });
  t('连续点击 pop 可重触发', retrigger);
  /* 清理 */
  await page.evaluate(() => {
    const f = document.getElementById('detailFav');
    if (f) f.click(); /* 取消收藏 */
    try { localStorage.setItem('yijing.favHexes', '[]'); } catch (e) {}
  });

  /* 4. reduced-motion: 动画全部归零 */
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.reload();
  await page.waitForTimeout(1200);
  const rm = await page.evaluate(() => {
    const hero = document.querySelector('.hero-card');
    const cs = getComputedStyle(hero);
    return { dur: cs.animationDuration, iter: cs.animationIterationCount };
  });
  t('reduced-motion 下动画时长≈0 (' + rm.dur + ')', rm.dur === '0.00001s' || rm.dur === '0.01s' || parseFloat(rm.dur) <= 0.02);
  await page.emulateMedia({ reducedMotion: 'no-preference' });

  /* 5. countUp 死代码已删 */
  const noCountUp = await page.evaluate(() => {
    for (const sheet of document.styleSheets) {
      try { for (const r of sheet.cssRules) { if (r.name === 'countUp') return false; } } catch (e) {}
    }
    return true;
  });
  t('countUp 死 keyframe 已移除', noCountUp);

  /* 6. 零错误 */
  t('零运行时错误', errors.length === 0);

  console.log('\n结果: ' + pass + ' 通过 / ' + fail + ' 失败');
  if (errors.length) console.log('ERRORS: ' + errors.join(' | '));
  browser.close();
  process.exit(fail === 0 ? 0 : 1);
})();
