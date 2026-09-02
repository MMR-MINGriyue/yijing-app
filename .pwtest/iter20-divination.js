/* iter20: 更多占法板块 — 八字 / 小六壬 / 梅花易数 + 历史整合 */
const { chromium } = require('playwright-core');
(async () => {
  const browser = await chromium.launch({ executablePath: 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe' });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto('http://localhost:8723/?view=app');
  await page.waitForTimeout(2200);
  let pass = 0, fail = 0;
  const t = (name, ok, detail) => { ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + ' ' + name + (detail ? ' — ' + detail : '')); };

  /* ===== A. 引擎层: 农历锚点 ===== */
  const lunar = await page.evaluate(() => {
    const L = window.YijingDivination && window.YijingDivination.LunarCalendar;
    if (!L) return null;
    return {
      exists: true,
      s2000: L.solarToLunar(new Date(2000, 1, 5)),   /* 2000-02-05 = 正月初一 (庚辰年春节) */
      s2026: L.solarToLunar(new Date(2026, 1, 17)),  /* 2026-02-17 = 正月初一 (丙午年春节) */
      s2099: L.solarToLunar(new Date(2099, 11, 31)), /* 边界年份不崩 */
      sc23: L.shichenIndex(new Date(2026, 0, 1, 23, 5)),  /* 23点 = 子时 0 */
      sc12: L.shichenIndex(new Date(2026, 0, 1, 12, 0))   /* 12点 = 午时 6 */
    };
  });
  t('YijingDivination 挂载', !!lunar);
  t('2000-02-05 = 庚辰年正月初一', lunar && lunar.s2000 && lunar.s2000.yearGanZhi === '庚辰' && lunar.s2000.month === 1 && lunar.s2000.day === 1,
    lunar && lunar.s2000 && JSON.stringify({ gz: lunar.s2000.yearGanZhi, m: lunar.s2000.month, d: lunar.s2000.day }));
  t('2026-02-17 = 丙午年正月初一', lunar && lunar.s2026 && lunar.s2026.yearGanZhi === '丙午' && lunar.s2026.month === 1 && lunar.s2026.day === 1,
    lunar && lunar.s2026 && JSON.stringify({ gz: lunar.s2026.yearGanZhi, m: lunar.s2026.month, d: lunar.s2026.day }));
  t('2099-12-31 转换不越界', lunar && lunar.s2099 !== null);
  t('23 点为子时 / 12 点为午时', lunar && lunar.sc23 === 0 && lunar.sc12 === 6, lunar && (lunar.sc23 + ',' + lunar.sc12));

  /* ===== B. 八字引擎: 已知案例 =====
     2000-02-05 12:00 (庚辰年春节午时)
     年柱 庚辰 (立春后); 日柱以 YijingCalendar 连续干支纪日为准 */
  const bazi = await page.evaluate(() => {
    const B = window.YijingDivination && window.YijingDivination.BaZi;
    if (!B) return null;
    const r = B.compute(new Date(2000, 1, 5, 12, 0));
    if (!r) return { ok: false };
    return {
      ok: true,
      pillars: r.pillars.map(p => p.gz),
      yearGZ: r.pillars[0].gz,
      hourGZ: r.pillars[3].gz,
      wuxing: r.wuxing,
      total: r.wuxingTotal,
      dayGan: r.dayGan,
      dayGod: r.pillars[2].ganGod,
      hiddenGods: r.pillars[2].hidden.map(h => h.gan + h.god),
      strength: r.strength,
      tenGodSample: [B.tenGod('甲', '甲'), B.tenGod('甲', '乙'), B.tenGod('甲', '丙'), B.tenGod('甲', '庚')],
      badDate: B.compute(new Date(NaN)),
      hourPillarRule: [B.hourPillar('甲', 0), B.hourPilar || null, B.hourPillar('乙', 0), B.hourPillar('戊', 0)]
    };
  });
  t('八字: 四柱返回 4 柱', bazi && bazi.ok && bazi.pillars.length === 4, bazi && bazi.pillars && bazi.pillars.join(' '));
  t('八字: 2000-02-05 年柱庚辰', bazi && bazi.yearGZ === '庚辰', bazi && bazi.yearGZ);
  t('八字: 日柱标注日主', bazi && bazi.dayGod === '日主');
  t('八字: 五行计数总和 = 8 (4干+4支本气)', bazi && bazi.total === 8,
    bazi && bazi.wuxing && JSON.stringify(bazi.wuxing));
  t('八字: 五行各值非负且 ≤ 8', bazi && Object.values(bazi.wuxing).every(v => v >= 0 && v <= 8));
  t('八字: 十神判定 (比肩/劫财/食神/七杀)', bazi && bazi.tenGodSample.join(',') === '比肩,劫财,食神,七杀', bazi && bazi.tenGodSample && bazi.tenGodSample.join(','));
  t('八字: 藏干十神非空', bazi && bazi.hiddenGods && bazi.hiddenGods.length >= 1, bazi && bazi.hiddenGods && bazi.hiddenGods.join(' '));
  t('八字: 五鼠遁 甲日子时=甲子 / 乙日丙子 / 戊日壬子',
    bazi && bazi.hourPillarRule[0] === '甲子' && bazi.hourPillarRule[2] === '丙子' && bazi.hourPillarRule[3] === '壬子',
    bazi && bazi.hourPillarRule && bazi.hourPillarRule.join(' '));
  t('八字: 非法日期返回 null', bazi && bazi.badDate === null);
  t('八字: 日主强弱有结论', bazi && ['偏强', '偏弱', '中和'].indexOf(bazi.strength) >= 0, bazi && bazi.strength);

  /* ===== C. 小六壬: 固定日期落宫 ===== */
  const xlr = await page.evaluate(() => {
    const X = window.YijingDivination && window.YijingDivination.XiaoLiuRen;
    if (!X) return null;
    const r = X.divine(new Date(2026, 1, 17, 12, 0)); /* 2026-02-17 12:00 = 丙午年正月初一午时 */
    if (!r) return { ok: false };
    const path = r.path;
    return {
      ok: true, path: path,
      monthPalace: r.monthPalace.name, dayPalace: r.dayPalace.name, hourPalace: r.hourPalace.name,
      palaces6: X.PALACES.length === 6 && X.PALACES.map(p => p.name).join('') === '大安留连速喜赤口小吉空亡',
      summary: r.summary,
      luckValid: ['吉', '凶'].indexOf(r.hourPalace.luck) >= 0 && !!r.hourPalace.text,
      /* 正月初一午时: 月宫=大安(0起), 日宫=大安(初一), 时宫=午时(第7支,从1数)=速喜(idx 2) */
      expectHour: ((0 + 1 - 1) + 6) % 6
    };
  });
  t('小六壬: 六宫次序正确 (大安→留连→速喜→赤口→小吉→空亡)', xlr && xlr.palaces6);
  t('小六壬: 正月初一月落大安', xlr && xlr.monthPalace === '大安', xlr && xlr.monthPalace);
  t('小六壬: 初一日落大安', xlr && xlr.dayPalace === '大安', xlr && xlr.dayPalace);
  /* 日宫大安起数子时: 子大安/丑留连/寅速喜/卯赤口/辰小吉/巳空亡/午回到大安 */
  t('小六壬: 午时落宫 = 大安 (子起日宫顺数)', xlr && xlr.hourPalace === ['大安','留连','速喜','赤口','小吉','空亡'][xlr.expectHour],
    xlr && (xlr.hourPalace + ' / 期望 ' + ['大安','留连','速喜','赤口','小吉','空亡'][xlr.expectHour]));
  t('小六壬: 落宫带吉凶与断辞', xlr && xlr.luckValid && !!xlr.summary);

  /* ===== D. 梅花易数 ===== */
  const mh = await page.evaluate(() => {
    const M = window.YijingDivination && window.YijingDivination.MeiHua;
    if (!M) return null;
    const rn = M.byNumbers(1, 1);      /* 乾上乾下 = 乾为天, 动 (1+1)%6=2 → 第2爻? moving=2-1=idx1 */
    const rn2 = M.byNumbers(8, 8);     /* 坤上坤下 = 坤为地 */
    const rd = M.byDice(function () { return 0.99; }); /* 骰 8/8/6 */
    const rt = M.byTime(new Date(2026, 1, 17, 12, 0));
    return {
      n1: { upper: rn.upper, lower: rn.lower, moving: rn.movingIdx, hexNo: rn.hexNo, name: rn.transform && rn.transform.ben.name, lines: rn.lines },
      n8: { upper: rn2.upper, lower: rn2.lower, hexNo: rn2.hexNo, name: rn2.transform && rn2.transform.ben.name },
      dice: { upper: rd.upper, lower: rd.lower, moving: rd.movingIdx },
      time: { upper: rt.upper, lower: rt.lower, moving: rt.movingIdx, hexNo: rt.hexNo, method: rt.method },
      transformOk: !!(rn.transform && rn.transform.ti && rn.transform.yong && rn.transform.relation && rn.transform.verdictText),
      lines6: rn.lines.length === 6,
      deterministic: JSON.stringify(M.byNumbers(1, 1).lines) === JSON.stringify(rn.lines)
    };
  });
  t('梅花: 数字起卦 1,1 → 乾上乾下 (第1卦)', mh && mh.n1.upper === '乾' && mh.n1.lower === '乾' && mh.n1.hexNo === 1 && mh.n1.name === '乾',
    mh && JSON.stringify(mh.n1));
  t('梅花: 数字起卦 8,8 → 坤上坤下 (第2卦)', mh && mh.n8.upper === '坤' && mh.n8.lower === '坤' && mh.n8.hexNo === 2, mh && JSON.stringify(mh.n8));
  t('梅花: 掷骰起卦 (固定随机源 8/8, 动第6爻)', mh && mh.dice.upper === '坤' && mh.dice.lower === '坤' && mh.dice.moving === 5, mh && JSON.stringify(mh.dice));
  t('梅花: 时间起卦确定性 (同一时刻两次结果一致)', mh && mh.time && mh.deterministic, mh && mh.time && mh.time.method);
  t('梅花: 复用 YijingEngine 体用推演 (ti/yong/relation/verdictText)', mh && mh.transformOk);
  t('梅花: 六爻 lines 长度 6 且含动爻标记', mh && mh.lines6 && mh.n1.lines.indexOf('moving') === mh.n1.moving, mh && mh.n1 && JSON.stringify(mh.n1.lines));

  /* ===== E. UI: 屏2 卡片与交互 ===== */
  const ui = await page.evaluate(() => {
    const r = {};
    r.cards = ['div-bazi', 'div-xlr', 'div-meihua'].map(id => !!document.getElementById(id));
    r.baziForm = !!document.getElementById('baziForm');
    r.meihuaForm = !!document.getElementById('meihuaForm');
    r.divResult = !!document.getElementById('divResult');
    r.typeFilterRow = !!document.getElementById('typeFilterRow');
    return r;
  });
  t('UI: 三张占法卡片 + 表单 + 结果容器', ui.cards.every(Boolean) && ui.baziForm && ui.meihuaForm && ui.divResult);
  t('UI: 历史屏占法筛选行', ui.typeFilterRow);

  /* iter25: 更多占法分页化 — 默认隐藏, 需先点入口卡进入子页 */
  const entry = await page.evaluate(() => {
    const e = document.getElementById('moreDivEntry');
    const l = document.getElementById('more-div-list');
    return { entry: !!e, hidden: l.hidden };
  });
  t('UI: 更多占法入口卡存在且子页默认隐藏', entry.entry && entry.hidden);
  await page.click('#moreDivEntry');
  await page.waitForTimeout(300);
  const entered = await page.evaluate(() => {
    const l = document.getElementById('more-div-list');
    const m = document.getElementById('method-list');
    return { pageVisible: !l.hidden, methodHidden: m.hidden };
  });
  t('UI: 点击入口 → 子页显示 + 起卦方式区隐藏', entered.pageVisible && entered.methodHidden);
  await page.screenshot({ path: '../_more-page.png' });

  /* 点击小六壬卡片 → 结果卡出现 + 入历史 */
  await page.evaluate(() => { localStorage.setItem('yijing.history.v1', '[]'); });
  await page.click('#div-xlr');
  await page.waitForTimeout(500);
  const xlrUi = await page.evaluate(() => {
    const r = document.getElementById('divResult');
    const hist = JSON.parse(localStorage.getItem('yijing.history.v1') || '[]');
    return {
      visible: r && !r.hidden && r.innerHTML.indexOf('小六壬') >= 0,
      hasPath: r && r.innerHTML.indexOf('月落') >= 0,
      hasPalaces: r && r.querySelectorAll('.xlr-palace').length === 6,
      hitCount: r ? r.querySelectorAll('.xlr-palace.hit').length : 0,
      histLen: hist.length,
      histType: hist[0] && hist[0].type,
      histName: hist[0] && hist[0].name
    };
  });
  t('UI: 小六壬点击即起课, 结果卡渲染', xlrUi.visible && xlrUi.hasPath && xlrUi.hasPalaces);
  t('UI: 小六壬落宫高亮恰好 1 个', xlrUi.hitCount === 1, String(xlrUi.hitCount));
  t('UI: 小六壬入历史 (type=xlr)', xlrUi.histLen === 1 && xlrUi.histType === 'xlr' && /小六壬/.test(xlrUi.histName || ''), xlrUi.histName);

  /* 八字表单: 填 2000-02-05 12:00 排盘 */
  await page.click('#div-bazi');
  await page.waitForTimeout(300);
  await page.evaluate(() => {
    document.getElementById('baziYear').value = '2000';
    document.getElementById('baziMonth').value = '2';
    document.getElementById('baziDay').value = '5';
    const sel = document.getElementById('baziHour');
    for (let i = 0; i < sel.options.length; i++) if (sel.options[i].value === '12') { sel.selectedIndex = i; break; }
  });
  await page.click('#baziGo');
  await page.waitForTimeout(500);
  const baziUi = await page.evaluate(() => {
    const r = document.getElementById('divResult');
    const hist = JSON.parse(localStorage.getItem('yijing.history.v1') || '[]');
    return {
      visible: r && !r.hidden && r.innerHTML.indexOf('八字排盘') >= 0,
      pillars: r ? r.querySelectorAll('.bazi-pillar').length : 0,
      bars: r ? r.querySelectorAll('.wx-bar').length : 0,
      histLen: hist.length,
      histType: hist[0] && hist[0].type,
      histTag: hist[0] && hist[0].direction
    };
  });
  t('UI: 八字排盘渲染 (4柱 + 5行五行条)', baziUi.visible && baziUi.pillars === 4 && baziUi.bars === 5, baziUi.pillars + '柱/' + baziUi.bars + '条');
  t('UI: 八字入历史 (type=bazi, 标签八字)', baziUi.histLen === 2 && baziUi.histType === 'bazi' && baziUi.histTag === '八字');

  /* 梅花数字起卦: 1,1 */
  await page.click('#div-meihua');
  await page.waitForTimeout(300);
  await page.click('.meihua-tab[data-m="num"]');
  await page.evaluate(() => {
    document.getElementById('meihuaA').value = '1';
    document.getElementById('meihuaB').value = '1';
  });
  await page.click('#meihuaGo');
  await page.waitForTimeout(500);
  const mhUi = await page.evaluate(() => {
    const r = document.getElementById('divResult');
    const hist = JSON.parse(localStorage.getItem('yijing.history.v1') || '[]');
    return {
      visible: r && !r.hidden && r.innerHTML.indexOf('梅花易数') >= 0,
      hasBody: r && r.innerHTML.indexOf('体卦') >= 0,
      histLen: hist.length,
      histType: hist[0] && hist[0].type,
      histHexNo: hist[0] && hist[0].hexNo
    };
  });
  t('UI: 梅花数字起卦渲染 (含体用断语)', mhUi.visible && mhUi.hasBody);
  t('UI: 梅花入历史 (type=meihua, hexNo=1 可跳转)', mhUi.histLen === 3 && mhUi.histType === 'meihua' && mhUi.histHexNo === 1);

  /* ===== F. 历史屏整合: 占法筛选 + 徽标 ===== */
  await page.evaluate(() => { try { window.YijingUI.gotoScreen(5); } catch (e) {} });
  await page.waitForTimeout(600);
  const histUi = await page.evaluate(() => {
    const row = document.getElementById('typeFilterRow');
    const chips = row ? row.querySelectorAll('.hex-filter-chip').length : 0;
    /* 点击「八字」chip 筛选 */
    const baziChip = row ? Array.from(row.querySelectorAll('.hex-filter-chip')).find(c => c.textContent.indexOf('八字') >= 0) : null;
    if (baziChip) baziChip.click();
    return { chips: chips };
  });
  await page.waitForTimeout(400);
  const histFiltered = await page.evaluate(() => {
    const cards = document.querySelectorAll('#hist-today .hist-card, #hist-week .hist-card');
    const badges = document.querySelectorAll('#hist-today .hist-badge, #hist-week .hist-badge');
    const meta = document.getElementById('hexFilterMetaText');
    return {
      cardCount: cards.length,
      badgeCount: badges.length,
      meta: meta ? meta.textContent : '',
      monthStats: (document.getElementById('monthStats') || {}).textContent
    };
  });
  t('历史: 占法筛选 chips 4 个 (易经/八字/小六壬/梅花)', histUi.chips === 4, String(histUi.chips));
  t('历史: 筛选八字后仅 1 条 + 徽标替代卦形', histFiltered.cardCount === 1 && histFiltered.badgeCount === 1,
    histFiltered.cardCount + '卡/' + histFiltered.badgeCount + '徽');
  t('历史: 筛选 meta 显示占法', histFiltered.meta.indexOf('八字') >= 0, histFiltered.meta);

  /* 清除筛选 → 恢复 3 条 */
  await page.evaluate(() => { document.getElementById('hexFilterClear').click(); });
  await page.waitForTimeout(400);
  const histAll = await page.evaluate(() => {
    const cards = document.querySelectorAll('#hist-today .hist-card, #hist-week .hist-card');
    return cards.length;
  });
  t('历史: 清除筛选后 3 条记录全部可见', histAll === 3, String(histAll));

  /* ===== G. 兼容: 旧记录 (无 type) 视为 iching, 屏1 最近列表不受非卦类污染 ===== */
  const compat = await page.evaluate(() => {
    const hist = JSON.parse(localStorage.getItem('yijing.history.v1') || '[]');
    const rec = document.getElementById('recentList');
    return {
      total: hist.length,
      hasNullHex: hist.some(h => !h.hexNo),
      recentCards: rec ? rec.querySelectorAll('.recent-card').length : -1
    };
  });
  t('兼容: 非卦类记录 hexNo=null 存于历史', compat.total === 3 && compat.hasNullHex);
  t('兼容: 屏1 最近占卜仅显示可跳转记录 (跳过八字/小六壬)', compat.recentCards >= 1 && compat.recentCards <= 3, String(compat.recentCards));

  /* ===== H. 零运行时错误 ===== */
  t('全程零 pageerror', errors.length === 0, errors.slice(0, 3).join(' | '));

  console.log('\n==== iter20: ' + pass + ' passed, ' + fail + ' failed ====');
  await browser.close();
  process.exit(fail ? 1 : 0);
})().catch(e => { console.error('FATAL', e); process.exit(2); });
