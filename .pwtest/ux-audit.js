/* UI/UX 程序化审计: 可量化的可用性指标 */
const { chromium } = require('playwright-core');
(async () => {
  const browser = await chromium.launch({ channel: 'msedge' });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  await page.goto('http://localhost:8723/?view=app');
  await page.waitForTimeout(2600);

  const audit = await page.evaluate(() => {
    const issues = [];
    const add = (cat, msg) => issues.push(cat + ' | ' + msg);
    /* 1. 交互目标尺寸: 当前可见屏内可点元素 < 40px 高 */
    const small = [];
    document.querySelectorAll('.phone:not([style*="display:none"]) button, .phone:not([style*="display:none"]) [role="button"], .phone [role="tab"], .phone .icon-btn').forEach(el => {
      if (!el.offsetParent) return;
      const r = el.getBoundingClientRect();
      if (r.height > 0 && r.height < 40) {
        const id = el.id || el.className.toString().slice(0, 30) || el.textContent.slice(0, 10);
        small.push(id + '(' + Math.round(r.height) + 'px)');
      }
    });
    if (small.length) add('tap-target', '小目标(<40px): ' + small.slice(0, 8).join(', '));

    /* 2. 水平溢出: 每屏 scroll 容器 scrollWidth > clientWidth + 4 */
    document.querySelectorAll('.phone .content').forEach((c, i) => {
      if (c.scrollWidth > c.clientWidth + 4) {
        const ph = c.closest('.phone');
        add('overflow', 'phone#' + (ph ? ph.id : i) + ' 横向溢出 ' + (c.scrollWidth - c.clientWidth) + 'px');
      }
    });

    /* 3. 对比度抽检: 主要文本色 vs 背景 */
    function lum(rgb) {
      const m = rgb.match(/\d+/g).map(Number);
      const f = v => { v /= 255; return v <= 0.03928 ? v / 12.92 : Math.pow((v + 0.055) / 1.055, 2.4); };
      return 0.2126 * f(m[0]) + 0.7152 * f(m[1]) + 0.0722 * f(m[2]);
    }
    function contrast(fg, bg) {
      const l1 = lum(fg), l2 = lum(bg);
      return ((Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05)).toFixed(1);
    }
    const samples = [
      ['.greet-sub', 'e.getComputedStyle(document.querySelector(sel).color'],
    ];
    const bg = 'rgb(245,240,230)';
    document.querySelectorAll('.greet-sub, .tab-text, .phone-label, .section-link, .me-sub, .stat .label, .chip-count, .bar-head .cnt, .hex-filter-meta span:first-child').forEach(el => {
      if (!el.offsetParent) return;
      const c = contrast(getComputedStyle(el).color, bg);
      if (parseFloat(c) < 3.0) add('contrast', (el.className.toString().slice(0, 24)) + ' 对比度 ' + c + ':1 (主文本 <4.5 不达 WCAG AA)');
    });

    /* 4. 焦点可见性: 有 tabindex 的元素 focus-visible 是否有 outline */
    const noFocusStyle = [];
    const probe = document.querySelector('[tabindex="0"]');
    if (probe) {
      probe.focus();
      const s = getComputedStyle(probe);
      /* 检查样式表里是否有任何 :focus-visible 规则 */
      let hasFocusRule = false;
      for (const sheet of document.styleSheets) {
        try {
          for (const rule of sheet.cssRules) {
            if (rule.selectorText && rule.selectorText.indexOf(':focus') >= 0) { hasFocusRule = true; break; }
          }
        } catch (e) {}
        if (hasFocusRule) break;
      }
      if (!hasFocusRule) add('a11y', '全站无 :focus-visible 样式, 键盘用户不可见焦点');
    }

    /* 5. 触屏反馈: 可点元素是否有 :active 态 (点击瞬间反馈) */
    let hasActiveRule = false;
    for (const sheet of document.styleSheets) {
      try {
        for (const rule of sheet.cssRules) {
          if (rule.selectorText && rule.selectorText.indexOf(':active') >= 0) { hasActiveRule = true; break; }
        }
      } catch (e) {}
      if (hasActiveRule) break;
    }
    if (!hasActiveRule) add('feedback', '无 :active 按压态, 移动端点击无瞬时反馈');

    /* 6. 过渡一致性: 统计 transition-duration 分布 */
    const durs = {};
    document.querySelectorAll('.phone *').forEach(el => {
      const d = getComputedStyle(el).transitionDuration;
      if (d && d !== '0s') { durs[d] = (durs[d] || 0) + 1; }
    });
    add('motion', 'transition 时长分布: ' + Object.entries(durs).sort((a, b) => b[1] - a[1]).slice(0, 6).map(e => e[0] + '×' + e[1]).join(', '));

    /* 7. 空态覆盖: 各屏空数据状态 */
    return issues;
  });
  console.log(audit.join('\n'));

  /* 8. 减少动效偏好 */
  const prm = await page.evaluate(() => {
    let has = false;
    for (const sheet of document.styleSheets) {
      try { for (const r of sheet.cssRules) { if (r.media && r.media.mediaText.indexOf('prefers-reduced-motion') >= 0) { has = true; break; } } } catch (e) {}
      if (has) break;
    }
    return has;
  });
  console.log('prefers-reduced-motion 支持: ' + prm);
  browser.close();
})();
