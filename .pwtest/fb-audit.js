/* 交互反馈覆盖率审计: 每个可见可点元素是否具备瞬时反馈 (transition/active/hover) */
const { chromium } = require('playwright-core');
(async () => {
  const browser = await chromium.launch({ channel: 'msedge' });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  await page.goto('http://localhost:8723/?view=app');
  await page.waitForTimeout(2600);

  /* 收集样式表里所有 :active / :hover 选择器覆盖的类 */
  const feedbackSelectors = await page.evaluate(() => {
    const actives = [], hovers = [];
    for (const sheet of document.styleSheets) {
      try {
        for (const r of sheet.cssRules) {
          if (!r.selectorText) continue;
          if (r.selectorText.includes(':active')) actives.push(r.selectorText);
          if (r.selectorText.includes(':hover')) hovers.push(r.selectorText);
        }
      } catch (e) {}
    }
    return { actives, hovers };
  });

  const audit = await page.evaluate(({ actives, hovers }) => {
    /* 每屏扫描 */
    const gaps = [];
    document.querySelectorAll('.phone').forEach((ph, idx) => {
      /* 使该屏可见 */
      ph.style.display = 'block';
      ph.querySelectorAll('*').forEach(el => {
        if (!el.offsetParent && el !== ph) return;
        const cls = '.' + (el.className || '').toString().trim().split(/\s+/).filter(Boolean).join('.');
        const role = el.getAttribute('role');
        const clickable = el.tagName === 'BUTTON' || role === 'button' || role === 'tab' ||
                          el.tagName === 'A' || el.hasAttribute('tabindex') ||
                          (el.className && /btn|chip|card|tab|link|item|tag|circle/.test(el.className));
        if (!clickable) return;
        if (!el.className) return;
        const cs = getComputedStyle(el);
        if (cs.cursor !== 'pointer' && cs.pointerEvents === 'none') return;
        const hasTransition = cs.transitionDuration !== '0s' || cs.transitionProperty !== 'all';
        const clsList = el.className.toString().split(/\s+/);
        const coveredByActive = actives.some(sel => clsList.some(c => sel.includes('.' + c)));
        const coveredByHover = hovers.some(sel => clsList.some(c => sel.includes('.' + c)));
        if (!coveredByActive && !coveredByHover && !hasTransition) {
          gaps.push('s' + idx + ' ' + cls.slice(0, 50) + ' (no feedback)');
        } else if (!coveredByActive && hasTransition) {
          gaps.push('s' + idx + ' ' + cls.slice(0, 50) + ' (transition-only, no :active)');
        }
      });
      ph.style.display = '';
    });
    return gaps;
  }, feedbackSelectors);

  console.log('=== 无 :active / :hover 反馈的可点元素 ===');
  console.log([...new Set(audit)].join('\n') || '(全覆盖)');
  console.log('\n:active 规则数: ' + feedbackSelectors.actives.length + ' · :hover 规则数: ' + feedbackSelectors.hovers.length);
  browser.close();
})();
