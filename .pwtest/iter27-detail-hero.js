/* iter27: 屏 4 卦辞解析 detail-hero 紧凑化 */
const { chromium } = require('playwright-core');
(async () => {
  const b = await chromium.launch({ executablePath: 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe' });
  const p = await b.newPage({ viewport: { width: 390, height: 844 } });
  const errs = [];
  p.on('pageerror', e => errs.push(e.message));
  await p.goto('http://localhost:8723/?view=app');
  await p.waitForTimeout(2800);
  await p.evaluate(() => window.YijingUI.gotoScreen(3));
  await p.waitForTimeout(800);

  let pass = 0, fail = 0;
  const t = (n, ok, d) => { ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + ' + ' + n + (d ? ' — ' + d : '')); };

  const hero = await p.evaluate(() => {
    const ph = document.querySelector('#phoneDetail');
    const h = ph.querySelector('.detail-hero');
    const hm = h.querySelector('.hex-mini');
    const name = h.querySelector('.hex-name');
    const tabs = ph.querySelector('.detail-tabs');
    const pane = ph.querySelector('.tab-pane.active');
    const tc = pane && pane.querySelector('.text-card');
    return {
      heroH: Math.round(h.getBoundingClientRect().height),
      heroPad: getComputedStyle(h).padding,
      heroGap: getComputedStyle(h).gap,
      hexW: Math.round(hm.getBoundingClientRect().width),
      hexH: Math.round(hm.getBoundingClientRect().height),
      nameSize: getComputedStyle(name).fontSize,
      tabsY: Math.round(tabs.getBoundingClientRect().top),
      textCardBottom: tc ? Math.round(tc.getBoundingClientRect().bottom) : 0,
      textCardH: tc ? Math.round(tc.getBoundingClientRect().height) : 0
    };
  });

  t('A1: detail-hero 高度 ≤ 220px (紧凑)', hero.heroH <= 220, 'h=' + hero.heroH);
  t('A2: detail-hero padding 16/20px (紧凑)', hero.heroPad === '16px 20px', hero.heroPad);
  t('A3: detail-hero gap 8px', hero.heroGap === '8px', hero.heroGap);
  t('A4: hex-mini 宽 54px (紧凑)', hero.hexW === 54, 'w=' + hero.hexW);
  t('A5: hex-mini 高 66px (紧凑)', hero.hexH === 66, 'h=' + hero.hexH);
  t('A6: 卦名 24px (紧凑)', hero.nameSize === '24px', hero.nameSize);
  t('B1: tabs 上移 (y ≤ 380px)', hero.tabsY <= 380, 'y=' + hero.tabsY);

  /* 「个性化建议」+ 「本卦卦辞」两张卡应在首屏可见 (个性化建议在 tab-panes 外) */
  const visible = await p.evaluate(() => {
    const ph = document.querySelector('#phoneDetail');
    const guaciCard = ph.querySelector('.tab-pane.active .text-card');
    const advice = document.getElementById('detailAdvice');
    return {
      guaciBottom: guaciCard ? Math.round(guaciCard.getBoundingClientRect().bottom) : 0,
      adviceTop: advice ? Math.round(advice.getBoundingClientRect().top) : 0,
      adviceBottom: advice ? Math.round(advice.getBoundingClientRect().bottom) : 0
    };
  });
  t('B2: 本卦卦辞卡首屏可见 (bottom ≤ 780px)', visible.guaciBottom > 0 && visible.guaciBottom <= 780, 'b=' + visible.guaciBottom);
  t('B3: 个性化建议卡首屏可见 (top ≤ 780px)', visible.adviceTop > 0 && visible.adviceTop <= 780, 'top=' + visible.adviceTop + ' b=' + visible.adviceBottom);

  /* 切到爻辞 / 象传 tab 仍正常 */
  await p.click('.detail-tab[data-pane="yaoci"]');
  await p.waitForTimeout(800);
  const yaoOk = await p.evaluate(() => {
    const ph = document.querySelector('#phoneDetail');
    const pane = ph.querySelector('.tab-pane.active');
    /* 爻辞 tab 内 6 张 text-card (一爻一卡) + 6 个 yao-name (通用 yao-list) */
    return pane && pane.dataset.pane === 'yaoci' && pane.querySelectorAll('.text-card').length === 6;
  });
  t('C1: 切到爻辞 tab → 6 张爻辞卡可见', yaoOk);

  await p.click('.detail-tab[data-pane="xiangzhuan"]');
  await p.waitForTimeout(600);
  const xzOk = await p.evaluate(() => {
    const ph = document.querySelector('#phoneDetail');
    const pane = ph.querySelector('.tab-pane.active');
    return pane && pane.dataset.pane === 'xiangzhuan' && pane.offsetHeight > 0;
  });
  t('C2: 切到象传 tab → 内容渲染', xzOk);

  /* 切回卦辞 */
  await p.click('.detail-tab[data-pane="guaci"]');
  await p.waitForTimeout(600);
  const gcOk = await p.evaluate(() => {
    const ph = document.querySelector('#phoneDetail');
    const pane = ph.querySelector('.tab-pane.active');
    return pane && pane.dataset.pane === 'guaci';
  });
  t('C3: 切回卦辞 tab', gcOk);

  t('零 pageerror', errs.length === 0, errs.join(' | '));

  console.log('\n结果: ' + pass + ' 通过, ' + fail + ' 失败');
  await b.close();
  process.exit(fail || errs.length ? 1 : 0);
})();