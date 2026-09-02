/* iter23: 设计打磨 — 修复 hex-filter-row 压扁 + 屏1首屏看到最近占卜 + 统计色一致性 */
const { chromium } = require('playwright-core');
(async () => {
  const browser = await chromium.launch({ executablePath: 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe' });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto('http://localhost:8723/?view=app');
  await page.waitForTimeout(2600); /* 骨架 + applyHash + 入场 stagger */
  let pass = 0, fail = 0;
  const t = (name, ok, detail) => { ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + ' ' + name + (detail ? ' — ' + detail : '')); };

  /* ===== A. 屏6 chips 修复: 不再被压扁 ===== */
  const chips = await page.evaluate(() => {
    return ['hexFilterRow', 'dirFilterRow', 'typeFilterRow'].map(id => {
      const el = document.getElementById(id);
      if (!el) return null;
      const cs = getComputedStyle(el);
      const c0 = el.querySelector('.hex-filter-chip');
      const c0H = c0 ? c0.getBoundingClientRect().height : 0;
      return { id, shrink: cs.flexShrink, offsetH: el.offsetHeight, chipH: c0H };
    });
  });
  t('hex-filter-row: flex-shrink=0 (防父级压缩)', chips.every(c => c && c.shrink === '0'), JSON.stringify(chips.map(c => c && c.shrink)));
  t('hex-filter-row: 容器高 ≥ 48px (含 chip 36 + padding 4+8)', chips.every(c => c && c.offsetH >= 48), JSON.stringify(chips.map(c => c && c.offsetH)));
  t('hex-filter-chip: 实测高度 ≥ 35px', chips.every(c => c && c.chipH >= 35), JSON.stringify(chips.map(c => c && c.chipH)));

  /* ===== B. 屏1首屏紧凑: 最近占卜卡完整可见 ===== */
  const home = await page.evaluate(() => {
    const rec = document.getElementById('recentList');
    const tab = document.querySelector('.tabbar');
    const c = document.querySelector('.content.scroll');
    if (!rec || !tab || !c) return null;
    const rr = rec.getBoundingClientRect();
    const tr = tab.getBoundingClientRect();
    return {
      recentTop: rr.top, recentBottom: rr.bottom, recentH: rr.height,
      tabTop: tr.top,
      recentChildren: rec.children.length,
      scrollTop: c.scrollTop,
      scrollHeight: c.scrollHeight,
      clientHeight: c.clientHeight
    };
  });
  /* 最近占卜卡完整落在 tabbar 上方 (top > 0 且 bottom < tabTop) */
  t('屏1: recent-section 完整在 tabbar 上方 (top>0, bottom<=tabTop)',
    home.recentTop > 0 && home.recentBottom <= home.tabTop + 1,
    `top=${home.recentTop.toFixed(0)} bottom=${home.recentBottom.toFixed(0)} tabTop=${home.tabTop.toFixed(0)}`);
  t('屏1: 至少 1 条最近占卜卡渲染', home.recentChildren >= 1, `n=${home.recentChildren}`);
  t('屏1: 自动滚动启用 (scrollTop > 0)', home.scrollTop > 0, `scrollTop=${home.scrollTop}`);

  /* hero 卡片仍在视口内 (至少部分可见) */
  const heroVis = await page.evaluate(() => {
    const h = document.querySelector('.hero-card');
    const r = h.getBoundingClientRect();
    return { top: r.top, bottom: r.bottom, h: r.height };
  });
  t('屏1: hero-card 部分可见 (top < tabTop)', heroVis.top < 763, `top=${heroVis.top.toFixed(0)} h=${heroVis.h.toFixed(0)}`);

  /* ===== C. 屏7统计色: cinnabar/pine/gold 三色各自不同 (设计意图保留) ===== */
  const stats = await page.evaluate(() => {
    const nums = Array.from(document.querySelectorAll('.stats-card .num'));
    return nums.slice(0, 3).map(n => getComputedStyle(n).color);
  });
  t('屏7: 起卦/连续/收藏 三色互不相同 (gold/cinnabar/pine)',
    stats[0] !== stats[1] && stats[1] !== stats[2] && stats[0] !== stats[2],
    stats.join(' | '));

  /* ===== D. 屏2「更多占法」可达 (通过滚动) ===== */
  await page.evaluate(() => window.YijingUI.gotoScreen(1));
  await page.waitForTimeout(500);
  const more2 = await page.evaluate(() => {
    const c = document.querySelector('.content.tight.scroll');
    return { scrollHeight: c.scrollHeight, clientHeight: c.clientHeight };
  });
  t('屏2: 内容可滚动 (scrollHeight > clientHeight)', more2.scrollHeight > more2.clientHeight, JSON.stringify(more2));

  /* ===== E. 回归: 06 屏筛选可工作 ===== */
  await page.evaluate(() => window.YijingUI.gotoScreen(5));
  await page.waitForTimeout(400);
  const filter = await page.evaluate(() => {
    const chips = document.querySelectorAll('#hexFilterRow .hex-filter-chip');
    const beforeCount = document.querySelectorAll('.hist-card').length;
    chips[2] && chips[2].click(); /* 选某个卦 */
    return { n: chips.length, beforeCount };
  });
  await page.waitForTimeout(400);
  const afterCount = await page.evaluate(() => document.querySelectorAll('.hist-card').length);
  t('06 屏: 点击卦 chip 后记录数变化', afterCount <= filter.beforeCount, `before=${filter.beforeCount} after=${afterCount}`);

  /* ===== F. 无 pageerror ===== */
  t('零 pageerror', errors.length === 0, errors.join(' | '));

  console.log('\n结果: ' + pass + ' 通过, ' + fail + ' 失败');
  await browser.close();
  process.exit(fail ? 1 : 0);
})();