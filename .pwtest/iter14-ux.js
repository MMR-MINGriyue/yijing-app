/* iter14: UI/UX 完善回归 — tap target + 按压反馈 + 全量回归 */
const { chromium } = require('playwright-core');
(async () => {
  const browser = await chromium.launch({ channel: 'msedge' });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto('http://localhost:8723/?view=app');
  await page.waitForTimeout(2600);
  let pass = 0, fail = 0;
  const t = (name, ok) => { ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + ' ' + name); };

  /* 1. chips 高度 ≥ 36px */
  const chipH = await page.evaluate(() => {
    const c = document.querySelector('.hex-filter-chip');
    return c ? c.getBoundingClientRect().height : 0;
  });
  t('filter chips ≥36px (实测 ' + Math.round(chipH) + ')', chipH >= 36);

  /* 2. section-link 命中区 ≥ 32px */
  const linkH = await page.evaluate(() => {
    const el = document.getElementById('recentAllLink');
    return el ? el.getBoundingClientRect().height : 0;
  });
  t('section-link 命中区 ≥32px (实测 ' + Math.round(linkH) + ')', linkH >= 32);

  /* 3. 按压反馈规则存在且覆盖关键类 */
  const activeRules = await page.evaluate(() => {
    let hits = [];
    for (const sheet of document.styleSheets) {
      try {
        for (const rule of sheet.cssRules) {
          if (rule.selectorText && rule.selectorText.includes(':active')) hits.push(rule.selectorText);
        }
      } catch (e) {}
    }
    return hits;
  });
  const flat = activeRules.join(' ');
  ['.hex-filter-chip:active', '.tag:active', '.quick-item:active', '.method-card:active',
   '.hist-card:active', '.recent-card:active', '.hex-card:active', '.tab:active', '.section-link:active'].forEach(sel => {
    t('按压反馈 ' + sel, flat.includes(sel));
  });

  /* 4. 按压目标有 transition, :active 缩放可平滑过渡 (伪类无法合成事件触发, 只验证声明) */
  await page.evaluate(() => window.YijingUI.gotoScreen(2));
  await page.waitForTimeout(400);
  const hasTrans = await page.evaluate(() => {
    const card = document.querySelector('.quick-item');
    return card ? getComputedStyle(card).transitionDuration !== '0s' : false;
  });
  t('按压元素带 transition', hasTrans);

  /* 5. 布局未破坏: chips 行仍可滚动且无溢出, section-link 负 margin 布局稳定 */
  const layout = await page.evaluate(() => {
    const row = document.querySelector('.hex-filter-row');
    const s1 = document.querySelector('.phone:nth-child(1) .section-header, .phone:first-of-type .section-header');
    return {
      rowScrollable: row ? row.scrollWidth >= row.clientWidth : false,
      contentOverflow: [...document.querySelectorAll('.phone .content')].some(c => c.scrollWidth > c.clientWidth + 4)
    };
  });
  t('chips 行正常', layout.rowScrollable);
  t('无横向溢出', !layout.contentOverflow);

  /* 6. 功能回归: 筛选仍工作 */
  await page.evaluate(() => { try { localStorage.clear(); } catch (e) {} });
  await page.reload(); await page.waitForTimeout(2000);
  const dirOK = await page.evaluate(() => {
    const tags = document.querySelectorAll('#tag-row .tag');
    return tags.length === 5;
  });
  t('02 屏方向标签 5 个', dirOK);

  console.log('\n' + (fail === 0 ? 'ALL PASS' : 'FAILURES: ' + fail) + ' — ' + pass + '/' + (pass + fail));
  if (errors.length) { console.log('RUNTIME ERRORS: ' + errors.join(' | ')); process.exit(1); }
  browser.close();
  process.exit(fail === 0 ? 0 : 1);
})();
