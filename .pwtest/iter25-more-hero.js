/* iter25: 横屏 hero 紧凑 + 屏2 更多占法分页化 */
const { chromium } = require('playwright-core');
(async () => {
  const browser = await chromium.launch({ channel: 'msedge' });
  const errs = [];
  let pass = 0, fail = 0;
  const t = (name, ok, detail) => { ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + ' + ' + name + (detail ? ' — ' + detail : '')); };

  /* ===== A. 屏2 更多占法分页化 (竖屏 390×844) ===== */
  const p = await browser.newPage({ viewport: { width: 390, height: 844 } });
  p.on('pageerror', e => errs.push('竖屏: ' + e.message));
  await p.goto('http://localhost:8723/?view=app');
  await p.waitForTimeout(2600);

  /* 初始: 入口卡可见, 子页隐藏 */
  const init = await p.evaluate(() => {
    const e = document.getElementById('moreDivEntry');
    const l = document.getElementById('more-div-list');
    const m = document.getElementById('method-list');
    const back = document.getElementById('moreDivBack');
    const er = e.getBoundingClientRect();
    return {
      entryVisible: !e.hidden && er.width > 0 && er.height > 0,
      pageHidden: l.hidden, methodVisible: !m.hidden,
      back: !!back,
      entryText: e.innerText.replace(/\s+/g, ' ')
    };
  });
  t('A1: 屏2 默认显示更多占法入口卡', init.entryVisible, init.entryText);
  t('A2: 更多占法子页默认隐藏', init.pageHidden);
  t('A3: 起卦方式区默认可见', init.methodVisible);

  /* 点击入口 → 子页出现 + 起卦区隐藏 */
  await p.click('#moreDivEntry');
  await p.waitForTimeout(400);
  const entered = await p.evaluate(() => {
    const l = document.getElementById('more-div-list');
    const m = document.getElementById('method-list');
    const e = document.getElementById('moreDivEntry');
    const back = document.getElementById('moreDivBack');
    return {
      pageVisible: !l.hidden, methodHidden: m.hidden, entryHidden: e.hidden,
      backVisible: !back.hidden && back.offsetHeight > 0,
      cards: ['div-bazi', 'div-xlr', 'div-meihua'].map(id => {
        const el = document.getElementById(id);
        const r = el.getBoundingClientRect();
        return { id, w: Math.round(r.width), h: Math.round(r.height) };
      })
    };
  });
  t('A4: 点击入口 → 子页显示', entered.pageVisible);
  t('A5: 点击入口 → 起卦方式区隐藏', entered.methodHidden && entered.entryHidden);
  t('A6: 返回按钮可见', entered.backVisible);
  t('A7: 三张占法卡渲染 (可点击尺寸)', entered.cards.every(c => c.w > 300 && c.h >= 70), JSON.stringify(entered.cards));

  /* 返回 → 恢复 */
  await p.click('#moreDivBack');
  await p.waitForTimeout(400);
  const exited = await p.evaluate(() => {
    const l = document.getElementById('more-div-list');
    const m = document.getElementById('method-list');
    const e = document.getElementById('moreDivEntry');
    return { pageHidden: l.hidden, methodVisible: !m.hidden, entryVisible: !e.hidden };
  });
  t('A8: 返回 → 子页隐藏 + 起卦方式恢复', exited.pageHidden && exited.methodVisible && exited.entryVisible);

  /* 键盘可达性: 入口/返回 Enter 触发 */
  await p.evaluate(() => document.getElementById('moreDivEntry').focus());
  await p.keyboard.press('Enter');
  await p.waitForTimeout(300);
  const kb = await p.evaluate(() => !document.getElementById('more-div-list').hidden);
  t('A9: 入口卡 Enter 触发子页 (键盘可达)', kb);

  /* recallBazi 回看: 自动进入子页 + 展示排盘结果卡 */
  await p.evaluate(() => {
    window.YijingUI.recallBazi({ birthTs: new Date(2000, 1, 5, 12, 0).getTime(), gender: 'male' });
  });
  await p.waitForTimeout(600);
  const recall = await p.evaluate(() => {
    const l = document.getElementById('more-div-list');
    const r = document.getElementById('divResult');
    return {
      pageVisible: !l.hidden,
      resultVisible: !r.hidden && r.innerText.indexOf('八字排盘') >= 0,
      resultText: r.innerText.slice(0, 40)
    };
  });
  t('A10: recallBazi 自动进入子页 + 展示八字排盘结果', recall.pageVisible && recall.resultVisible, recall.resultText.replace(/\n/g, ' ').slice(0, 20));

  /* ===== B. 横屏 hero 紧凑 (844×390) ===== */
  const p2 = await browser.newPage({ viewport: { width: 844, height: 390 } });
  p2.on('pageerror', e => errs.push('横屏: ' + e.message));
  await p2.goto('http://localhost:8723/?view=app');
  await p2.waitForTimeout(2800);

  const ls = await p2.evaluate(() => {
    const ph = document.querySelector('.phone');
    const content = ph.querySelector('.content');
    const hero = ph.querySelector('.hero-card');
    const hr = hero.getBoundingClientRect();
    const contentR = content.getBoundingClientRect();
    return {
      heroH: Math.round(hr.height),
      heroTop: Math.round(hr.top),
      contentTop: Math.round(contentR.top),
      scrollTop: content.scrollTop,
      descVisible: getComputedStyle(ph.querySelector('.hero-desc')).display !== 'none',
      triLabelVisible: getComputedStyle(ph.querySelector('.hex-trigram-label')).display !== 'none',
      metaVisible: getComputedStyle(ph.querySelector('.hex-meta')).display !== 'none',
      enVisible: getComputedStyle(ph.querySelector('.hex-en')).display !== 'none',
      nameSize: getComputedStyle(ph.querySelector('.hex-name')).fontSize
    };
  });
  t('B1: 横屏 hero 高度 ≤ 215px (紧凑到 content 可视高度内)', ls.heroH <= 215, 'h=' + ls.heroH);
  t('B2: 横屏首屏 scrollTop=0 (不 auto-scroll 挤走 hero)', ls.scrollTop === 0, 'scrollTop=' + ls.scrollTop);
  t('B3: 横屏 hero 顶部在可视区内', ls.heroTop >= ls.contentTop - 1, 'top=' + ls.heroTop + ' contentTop=' + ls.contentTop);
  t('B4: 横屏隐藏 hero-desc (解读正文)', !ls.descVisible);
  t('B5: 横屏隐藏上下卦标注', !ls.triLabelVisible);
  t('B6: 横屏隐藏 hex-meta 装饰', !ls.metaVisible);
  t('B7: 横屏隐藏英文副名', !ls.enVisible);
  t('B8: 横屏卦名收敛至 26px', ls.nameSize === '26px', ls.nameSize);

  /* 横屏下进入更多占法子页仍可用 */
  await p2.evaluate(() => window.YijingUI.gotoScreen(1));
  await p2.waitForTimeout(400);
  await p2.evaluate(() => document.getElementById('moreDivEntry').click());
  await p2.waitForTimeout(300);
  const lsMore = await p2.evaluate(() => {
    const l = document.getElementById('more-div-list');
    return { visible: !l.hidden, cards: l.querySelectorAll('.method-card').length };
  });
  t('B9: 横屏下更多占法子页可用 (3 卡)', lsMore.visible && lsMore.cards === 3, 'cards=' + lsMore.cards);

  /* ===== C. 竖屏回归: iter23 屏1首屏 auto-scroll 仍生效 ===== */
  const p3 = await browser.newPage({ viewport: { width: 390, height: 844 } });
  p3.on('pageerror', e => errs.push('竖屏回归: ' + e.message));
  await p3.goto('http://localhost:8723/?view=app');
  await p3.waitForTimeout(2800);
  const home = await p3.evaluate(() => {
    const rec = document.getElementById('recentList');
    const tab = document.querySelector('.tabbar');
    const c = rec.closest('.content');
    return {
      scrollTop: c.scrollTop,
      recBottom: rec.getBoundingClientRect().bottom,
      tabTop: tab.getBoundingClientRect().top,
      n: rec.children.length
    };
  });
  t('C1: 竖屏 auto-scroll 仍生效 (scrollTop>0)', home.scrollTop > 0, 'scrollTop=' + home.scrollTop);
  t('C2: 竖屏最近占卜完整可见', home.recBottom <= home.tabTop + 1 && home.n >= 1,
    'recBottom=' + home.recBottom.toFixed(0) + ' tabTop=' + home.tabTop.toFixed(0));

  t('零 pageerror', errs.length === 0, errs.join(' | '));

  console.log('\n结果: ' + pass + ' 通过, ' + fail + ' 失败');
  await browser.close();
  process.exit(fail || errs.length ? 1 : 0);
})();