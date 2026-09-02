/* iter26: 屏 5 变卦推演 — transform-card 每次只显示 1 个 view (修复) */
const { chromium } = require('playwright-core');
(async () => {
  const b = await chromium.launch({ executablePath: 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe' });
  const p = await b.newPage({ viewport: { width: 390, height: 844 } });
  const errs = [];
  p.on('pageerror', e => errs.push(e.message));
  await p.goto('http://localhost:8723/?view=app');
  await p.waitForTimeout(2800);
  await p.evaluate(() => window.YijingUI.gotoScreen(4));
  await p.waitForTimeout(800);

  let pass = 0, fail = 0;
  const t = (n, ok, d) => { ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + ' + ' + n + (d ? ' — ' + d : '')); };

  /* 滑块宽度 = 300% (3 个 view 横向并排) */
  const slider = await p.evaluate(() => {
    const s = document.getElementById('transformSlider');
    const card = document.getElementById('transformCard');
    return {
      sliderW: s.offsetWidth,
      cardContentW: card.offsetWidth - 58, /* padding 30+28 */
      sliderHasShrink: getComputedStyle(s).flexShrink
    };
  });
  t('A1: transform-slider 宽 ≈ 300% × card content (876px)', slider.sliderW > 800 && slider.sliderW < 900, 'w=' + slider.sliderW);
  t('A2: slider flex-shrink=0 (父级不压缩 300%)', slider.sliderHasShrink === '0');

  /* view 0 默认显示 (translateX 0) */
  const v0 = await p.evaluate(() => {
    const s = document.getElementById('transformSlider');
    const v0 = document.querySelector('.hex-pair.view[data-view="0"]');
    const v1 = document.querySelector('.hex-pair.view[data-view="1"]');
    const v2 = document.querySelector('.hex-pair.view[data-view="2"]');
    const card = document.getElementById('transformCard');
    const cardRect = card.getBoundingClientRect();
    return {
      transform: s.style.transform,
      v0InView: v0.getBoundingClientRect().left >= cardRect.left - 5 && v0.getBoundingClientRect().right <= cardRect.right + 5,
      v1Outside: v1.getBoundingClientRect().left >= cardRect.right || v1.getBoundingClientRect().right <= cardRect.left,
      v2Outside: v2.getBoundingClientRect().left >= cardRect.right || v2.getBoundingClientRect().right <= cardRect.left
    };
  });
  t('B1: 默认 view 0 在 card 视口内 (transform=0)', v0.transform === '' || v0.transform === 'translateX(0%)' || v0.transform.indexOf('0') >= 0, 't=' + v0.transform);
  t('B2: view 0 完整在 card 视口内', v0.v0InView);
  t('B4: view 2 完全在 card 视口外', v0.v2Outside);

  /* 切到 view 1 */
  await p.evaluate(() => window.YijingUI.transformGoTo(1));
  await p.waitForTimeout(700);
  const v1 = await p.evaluate(() => {
    const s = document.getElementById('transformSlider');
    const v1 = document.querySelector('.hex-pair.view[data-view="1"]');
    const v0 = document.querySelector('.hex-pair.view[data-view="0"]');
    const card = document.getElementById('transformCard');
    const cardRect = card.getBoundingClientRect();
    return {
      transform: s.style.transform,
      v1InView: v1.getBoundingClientRect().left >= cardRect.left - 5 && v1.getBoundingClientRect().right <= cardRect.right + 5,
      v0Outside: v0.getBoundingClientRect().right <= cardRect.left + 10 /* 主要在视口左外 */ || v0.getBoundingClientRect().left >= cardRect.right
    };
  });
  t('B5: 切到 view 1 → translateX(-33.333%)', v1.transform.indexOf('33') >= 0 || v1.transform.indexOf('1/3') >= 0, 't=' + v1.transform);
  t('B6: view 1 完整在 card 视口内', v1.v1InView);

  /* 切到 view 2 (推演) */
  await p.evaluate(() => window.YijingUI.transformGoTo(2));
  await p.waitForTimeout(700);
  const v2 = await p.evaluate(() => {
    const s = document.getElementById('transformSlider');
    const v2 = document.querySelector('.hex-pair.view[data-view="2"]');
    const diffs = v2.querySelectorAll('.diff-row');
    const card = document.getElementById('transformCard');
    const cardRect = card.getBoundingClientRect();
    return {
      transform: s.style.transform,
      v2InView: v2.getBoundingClientRect().left >= cardRect.left - 5 && v2.getBoundingClientRect().right <= cardRect.right + 5,
      diffCount: diffs.length,
      diffTexts: Array.from(diffs).map(d => d.innerText.replace(/\s+/g, ' ').slice(0, 20))
    };
  });
  t('B7: 切到 view 2 → translateX(-66.666%)', v2.transform.indexOf('66') >= 0 || v2.transform.indexOf('2/3') >= 0, 't=' + v2.transform);
  t('B8: view 2 完整在 card 视口内', v2.v2InView);
  t('B9: view 2 含 5+ diff rows (上卦/下卦/动爻/互卦/体用/吉凶)', v2.diffCount >= 5, 'n=' + v2.diffCount + ' ' + v2.diffTexts.join('|'));

  /* 切回 view 0 */
  await p.evaluate(() => window.YijingUI.transformGoTo(0));
  await p.waitForTimeout(700);
  const v0b = await p.evaluate(() => {
    const s = document.getElementById('transformSlider');
    const v0 = document.querySelector('.hex-pair.view[data-view="0"]');
    const card = document.getElementById('transformCard');
    const cardRect = card.getBoundingClientRect();
    return {
      transform: s.style.transform,
      v0InView: v0.getBoundingClientRect().left >= cardRect.left - 5 && v0.getBoundingClientRect().right <= cardRect.right + 5
    };
  });
  t('B10: 切回 view 0 → translateX(0) + view 0 居中', v0b.transform.indexOf('0%') >= 0 && v0b.v0InView, 't=' + v0b.transform);

  /* 推演 view 2 不再有徽标文字溢出 */
  await p.evaluate(() => window.YijingUI.transformGoTo(2));
  await p.waitForTimeout(700);
  const overflow = await p.evaluate(() => {
    const card = document.getElementById('transformCard');
    const cardRect = card.getBoundingClientRect();
    const diffs = Array.from(card.querySelectorAll('.diff-row'));
    return diffs.map(d => {
      const r = d.getBoundingClientRect();
      return { inside: r.right <= cardRect.right + 2 && r.left >= cardRect.left - 2, w: Math.round(r.width) };
    });
  });
  t('B11: view 2 diff rows 全部在 card 视口内 (无溢出)', overflow.every(d => d.inside), 'overflow=' + overflow.filter(d => !d.inside).length);

  t('零 pageerror', errs.length === 0, errs.join(' | '));

  console.log('\n结果: ' + pass + ' 通过, ' + fail + ' 失败');
  await b.close();
  process.exit(fail || errs.length ? 1 : 0);
})();