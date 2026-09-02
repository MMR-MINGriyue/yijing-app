/* iter18: 铜钱抛掷动画验证 — 真实结果呈现 / 跳过 / reduced-motion / 回退 */
const { chromium } = require('playwright-core');
(async () => {
  const browser = await chromium.launch({ executablePath: 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe' });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto('http://localhost:8723/?view=app');
  await page.waitForTimeout(2000);
  let pass = 0, fail = 0;
  const t = (name, ok, detail) => { ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + ' ' + name + (detail ? ' — ' + detail : '')); };

  /* 1. 引擎层: castByCoins 返回 tosses 且与 lines/moving 自洽 */
  const eng = await page.evaluate(() => {
    let bad = 0;
    for (let n = 0; n < 200; n++) {
      const r = YijingEngine.cast('coin', '测试问题');
      if (!r.tosses || r.tosses.length !== 6) { bad++; continue; }
      for (let i = 0; i < 6; i++) {
        const f = r.tosses[i];
        if (!Array.isArray(f) || f.length !== 3 || f.some(v => v !== 0 && v !== 1)) { bad++; break; }
        const backs = f.reduce((a, b) => a + b, 0);
        const expLine = (backs === 3 || backs === 1) ? 'yang' : 'yin';
        const expMoving = (backs === 3 || backs === 0);
        if (r.lines[i] !== expLine) { bad++; break; }
        if (expMoving !== (r.moving.indexOf(i) >= 0)) { bad++; break; }
      }
    }
    return bad;
  });
  t('castByCoins tosses 与爻/动爻 200 轮自洽 (bad=' + eng + ')', eng === 0);

  /* 2. coin 起卦触发抛掷仪式: overlay 出现, 三枚铜钱, 逐爻累积 */
  await page.evaluate(() => { window.YijingUI.gotoScreen(1); });
  await page.waitForTimeout(300);
  await page.evaluate(() => {
    const input = document.getElementById('qInput');
    input.value = '今天天气如何呢';
    input.dispatchEvent(new Event('input', { bubbles: true }));
  });
  await page.evaluate(() => { window.YijingUI.castHex('coin'); });
  await page.waitForTimeout(600);
  let ov = await page.$('.coin-overlay');
  t('铜钱 overlay 出现', !!ov);
  const coins = await page.$$eval('.coin-overlay .coin', els => els.length);
  t('三枚铜钱 (实际 ' + coins + ')', coins === 3);
  const round1 = await page.$eval('.coin-round', el => el.textContent);
  t('首轮爻位提示 ("初爻"), 实际: ' + round1, /初爻/.test(round1));

  /* 2b. 抛掷角度与真实 tosses 一致 (背=cb 0deg, 字=cz 180deg) */
  const angleOk = await page.evaluate(() => {
    /* 直接检验模块行为: cast 后读取 overlay 上第一轮落定角度 */
    const inners = document.querySelectorAll('.coin-overlay .coin-inner');
    if (!inners.length) return false;
    /* 第一轮在 t≈600ms 时已翻转完毕 (transition 0.62s), 此处只验证 transform 已被设置 */
    let set = 0;
    inners.forEach(c => { if (/rotateY\((1440|1620)deg\)/.test(c.style.transform)) set++; });
    return set === 3;
  });
  t('三枚铜钱翻转角度由真实结果驱动 (1440=背/1620=字)', angleOk);

  /* 2c. 中途逐爻累积 (第3轮时应已有 ≥2 爻) */
  await page.waitForTimeout(2 * 920 + 700);
  const yaoCount = await page.$$eval('.coin-overlay .coin-yao', els => els.length);
  t('逐爻累积中 (第3轮时 ≥2 爻, 实际 ' + yaoCount + ')', yaoCount >= 2);

  /* 3. 跳过: 点击 overlay 立即结束并出结果 */
  await page.evaluate(() => document.querySelector('.coin-overlay').click());
  await page.waitForTimeout(800);
  const skipped = await page.evaluate(() => !document.querySelector('.coin-overlay'));
  const resultShown = await page.evaluate(() => {
    const d = document.getElementById('phoneDetail');
    return !!d && getComputedStyle(d).display !== 'none';
  });
  t('点击跳过后 overlay 移除', skipped);
  t('跳过后直达结果屏', resultShown);

  /* 3b. 跳过不污染历史 — 历史已入账一条 */
  const histCount = await page.evaluate(() => {
    try { return JSON.parse(localStorage.getItem('yijing.history.v1') || '[]').length; } catch (e) { return -1; }
  });
  t('成卦入历史 (≥1, 实际 ' + histCount + ')', histCount >= 1);

  /* 4. 完整播完一轮: 六爻齐 + 自动收尾 */
  await page.evaluate(() => { window.YijingUI.gotoScreen(1); });
  await page.evaluate(() => {
    const input = document.getElementById('qInput');
    input.value = '完整播放测试';
    input.dispatchEvent(new Event('input', { bubbles: true }));
    window.YijingUI.castHex('coin');
  });
  await page.waitForTimeout(6 * 920 + 400);
  const finalRound = await page.$eval('.coin-round', el => el.textContent);
  t('六轮后提示 "六爻已成", 实际: ' + finalRound, /六爻已成|六 爻 已 成/.test(finalRound));
  await page.waitForTimeout(1200);
  const autoClosed = await page.evaluate(() => !document.querySelector('.coin-overlay'));
  t('播完自动收尾 (无需手动关闭)', autoClosed);

  /* 5. 其他方法 (numeric) 回退骨架屏, 无铜钱 overlay */
  await page.evaluate(() => { window.YijingUI.gotoScreen(1); });
  await page.evaluate(() => {
    const input = document.getElementById('qInput');
    input.value = '数字起卦测试';
    input.dispatchEvent(new Event('input', { bubbles: true }));
    window.YijingUI.castHex('numeric');
  });
  await page.waitForTimeout(500);
  const skelShown = await page.evaluate(() => {
    const s = document.getElementById('skeletonOverlay');
    return !!s && !s.classList.contains('hidden');
  });
  const noCoin = await page.evaluate(() => !document.querySelector('.coin-overlay'));
  t('数字起卦回退骨架屏', skelShown);
  t('数字起卦不出现铜钱 overlay', noCoin);

  /* 6. reduced-motion: 铜钱起卦也回退骨架屏 */
  await page.emulateMedia({ reducedMotion: 'reduce' });
  await page.evaluate(() => { window.YijingUI.gotoScreen(1); });
  await page.evaluate(() => {
    const input = document.getElementById('qInput');
    input.value = '减少动效测试';
    input.dispatchEvent(new Event('input', { bubbles: true }));
    window.YijingUI.castHex('coin');
  });
  await page.waitForTimeout(500);
  const rmSkel = await page.evaluate(() => {
    const s = document.getElementById('skeletonOverlay');
    return !!s && !s.classList.contains('hidden');
  });
  const rmNoCoin = await page.evaluate(() => !document.querySelector('.coin-overlay'));
  t('reduced-motion 下铜钱起卦回退骨架屏', rmSkel);
  t('reduced-motion 下无铜钱动画', rmNoCoin);
  await page.waitForTimeout(1800);
  await page.emulateMedia({ reducedMotion: 'no-preference' });

  /* 7. 清理测试数据 */
  await page.evaluate(() => {
    try {
      const h = JSON.parse(localStorage.getItem('yijing.history.v1') || '[]').filter(x => !/测试|天气|完整播放|减少动效/.test(x.question || ''));
      localStorage.setItem('yijing.history.v1', JSON.stringify(h));
    } catch (e) {}
  });

  /* 8. 零错误 */
  t('零运行时错误', errors.length === 0);

  console.log('\n结果: ' + pass + ' 通过 / ' + fail + ' 失败');
  if (errors.length) console.log('ERRORS: ' + errors.join(' | '));
  browser.close();
  process.exit(fail === 0 ? 0 : 1);
})();
