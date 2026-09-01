/* iter21: 八字大运流年 — 精确节气表 / 起运顺逆 / 大运序列 / 流年生克 / UI 时间轴 / 历史回看 */
const { chromium } = require('playwright-core');
(async () => {
  const browser = await chromium.launch({ channel: 'msedge' });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto('http://localhost:8723/?view=app');
  await page.waitForTimeout(2200);
  let pass = 0, fail = 0;
  const t = (name, ok, detail) => { ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + ' ' + name + (detail ? ' — ' + detail : '')); };

  /* ===== A. 精确节气表 ===== */
  const pt = await page.evaluate(() => {
    if (typeof PreciseTerms === 'undefined') return null;
    const iso = ts => new Date(ts + 8 * 3600000).toISOString().slice(0, 16).replace('T', ' ');
    const a = PreciseTerms.around(new Date(2026, 8, 1).getTime()); /* 2026-09-01 */
    return {
      mounted: true,
      liChun2026: iso(PreciseTerms.jieList(2026)[1].ts),   /* 2026-02-04 04:02 (天文历) */
      liChun2000: iso(PreciseTerms.jieList(2000)[1].ts),   /* 2000-02-04 20:40 (公开值) */
      names: PreciseTerms.NAMES.join(''),
      idxJan1: PreciseTerms.jieIndexAt(new Date(2026, 0, 1).getTime()),    /* 小寒前 → 上年大雪 11 */
      idxJan10: PreciseTerms.jieIndexAt(new Date(2026, 0, 10).getTime()),  /* 小寒后 → 0 */
      idxJul: PreciseTerms.jieIndexAt(new Date(2026, 6, 1).getTime()),     /* 小暑(7/7)前 → 芒种 5 */
      around: a ? { prev: a.prev.name, next: a.next.name } : null,
      outOfRange: PreciseTerms.jieList(1899) === null && PreciseTerms.jieList(2101) === null
    };
  });
  t('节气表: PreciseTerms 挂载', !!pt);
  t('节气表: 12 节顺序 (小寒…大雪)', pt && pt.names === '小寒立春惊蛰清明立夏芒种小暑立秋白露寒露立冬大雪', pt && pt.names);
  t('节气表: 2026 立春 02-04 04:02', pt && pt.liChun2026 === '2026-02-04 04:02', pt && pt.liChun2026);
  t('节气表: 2000 立春 02-04 20:40', pt && pt.liChun2000 === '2000-02-04 20:40', pt && pt.liChun2000);
  t('节气表: jieIndexAt 边界 (1/1→大雪11, 1/10→小寒0, 7/1→芒种5)',
    pt && pt.idxJan1 === 11 && pt.idxJan10 === 0 && pt.idxJul === 5, pt && [pt.idxJan1, pt.idxJan10, pt.idxJul].join(','));
  t('节气表: around 前后包夹 (9/1 前小暑后白露? → 前立秋/后白露)',
    pt && pt.around && pt.around.prev === '立秋' && pt.around.next === '白露', pt && pt.around && JSON.stringify(pt.around));
  t('节气表: 越界年份返回 null', pt && pt.outOfRange);

  /* ===== B. ganzhiMonth 精确化 (修节气交界日 ±1 天边界) ===== */
  const gm = await page.evaluate(() => {
    const C = window.YijingCalendar;
    return {
      beforeLC: C.ganzhiMonth(new Date(2026, 1, 4, 3, 0)),   /* 立春 04:02 前 → 乙巳年己丑月 */
      afterLC: C.ganzhiMonth(new Date(2026, 1, 4, 5, 0)),    /* 立春后 → 丙午年庚寅月 */
      jan1: C.ganzhiMonth(new Date(2026, 0, 1, 12, 0)),      /* 小寒前 → 乙巳年戊子月 */
      jul: C.ganzhiMonth(new Date(2026, 6, 1, 12, 0))        /* 与旧表一致 → 丙午年甲午月? */
    };
  });
  t('月柱: 立春前 03:00 → 己丑 (旧表会误判庚寅)', gm.beforeLC === '己丑', gm.beforeLC);
  t('月柱: 立春后 05:00 → 庚寅', gm.afterLC === '庚寅', gm.afterLC);
  t('月柱: 1 月 1 日 (小寒前) → 戊子', gm.jan1 === '戊子', gm.jan1);
  t('月柱: 年中回归一致', gm.jul === '甲午', gm.jul);

  /* ===== C. 大运引擎: 已知命例 =====
     2000-02-05 12:00 乾造: 庚辰 戊寅 癸巳 戊午
     庚阳男 → 顺行; 下一节 惊蛰 2000-03-05 14:42, 间隔 29天2时42分 → 9岁8个月起运 */
  const dy = await page.evaluate(() => {
    const DY = window.YijingDivination && window.YijingDivination.DaYun;
    if (!DY) return null;
    const r = DY.analyze(new Date(2000, 1, 5, 12, 0), 'male');
    if (!r) return { ok: false };
    const cur = r.steps.find(s => s.current);
    return {
      ok: true, mounted: true,
      forward: r.forward,
      qiYun: { y: r.qiYun.years, m: r.qiYun.months, term: r.qiYun.termName, nearEdge: r.qiYun.nearEdge, startYear: new Date(r.qiYun.startTs).getFullYear() },
      steps: r.steps.map(s => s.gz),
      stepCount: r.steps.length,
      gods: r.steps.map(s => s.ganGod),
      curIdx: r.steps.indexOf(cur), curGZ: cur && cur.gz, curRange: cur && (cur.startYear + '-' + cur.endYear),
      liuNian1: r.steps[0].liuNian.map(l => l.year + l.gz).join(' '),
      liuNianCount: r.steps.map(s => s.liuNian.length),
      ln2026: cur.liuNian.find(l => l.year === 2026),
      hourUnknownDefault: r.hourUnknown,
      badDate: DY.analyze(new Date(NaN), 'male')
    };
  });
  t('大运: DaYun 挂载', dy && dy.mounted);
  t('大运: 庚阳男顺行', dy && dy.forward === true);
  t('大运: 起运 9岁8个月 至惊蛰 2009 年起', dy && dy.qiYun.y === 9 && dy.qiYun.m === 8 && dy.qiYun.term === '惊蛰' && dy.qiYun.startYear === 2009,
    dy && JSON.stringify(dy.qiYun));
  t('大运: 出生紧邻立春 → 临界标注', dy && dy.qiYun.nearEdge === true);
  t('大运: 8 步序列 己卯→丙戌', dy && dy.steps.join(' ') === '己卯 庚辰 辛巳 壬午 癸未 甲申 乙酉 丙戌', dy && dy.steps.join(' '));
  t('大运: 每步干带十神 (癸日主: 己=七杀)', dy && dy.gods[0] === '七杀' && dy.gods.length === 8, dy && dy.gods.join(' '));
  /* 起运 2009-10 → 步1 己卯 2009-2018, 步2 庚辰 2019-2029 (2026 当前), 步3 辛巳 2029-2039 */
  t('大运: 当前步 庚辰 (2019-2029)', dy && dy.curGZ === '庚辰' && dy.curRange === '2019-2029', dy && dy.curGZ + ' ' + dy.curRange);
  t('大运: 第一步流年 2009-2018 干支正确', dy && dy.liuNian1 === '2009己丑 2010庚寅 2011辛卯 2012壬辰 2013癸巳 2014甲午 2015乙未 2016丙申 2017丁酉 2018戊戌', dy && dy.liuNian1);
  t('大运: 每步 10 个流年', dy && dy.liuNianCount.every(n => n === 10), dy && dy.liuNianCount.join(','));
  /* 2026 丙午 在庚辰运: 丙火克庚金 → 岁克运 */
  t('流年: 2026 丙午 vs 癸日主 → 正财 + 丙克庚岁运制衡', dy && dy.ln2026 && dy.ln2026.god === '正财' && dy.ln2026.gz === '丙午' && dy.ln2026.text.indexOf('岁克运') >= 0,
    dy && dy.ln2026 && dy.ln2026.god + ' / ' + dy.ln2026.text);
  t('流年: 2026 当前年标记', dy && dy.ln2026 && dy.ln2026.current === true);
  t('大运: hourUnknown 默认 false', dy && dy.hourUnknownDefault === false);
  t('大运: 非法日期返回 null', dy && dy.badDate === null);

  /* ===== D. 顺逆四象限 + 流年冲合刑 ===== */
  const quad = await page.evaluate(() => {
    const DY = window.YijingDivination.DaYun;
    const C = window.YijingCalendar;
    const q = [
      [2000, 'male', true], [2000, 'female', false],
      [2001, 'male', false], [2001, 'female', true]
    ].map(c => {
      const r = DY.analyze(new Date(c[0], 6, 1, 12, 0), c[1]);
      return { y: c[0], g: c[1], fwd: r.forward, exp: c[2], ok: r.forward === c[2] };
    });
    /* 冲合刑引擎 (analyzeYear 单测): 2000-02-05 命 (庚辰 戊寅 癸巳 戊午)
       乙酉年 + 己卯运: 酉合年支辰 (he@0) + 酉冲大运卯 (chong@-1)
       戊申年 + 辛巳运: 申冲月支寅 (chong@1) + 申合日支巳 (he@2) + 申合大运巳 (he@-1) */
    const base = DY.analyze(new Date(2000, 1, 5, 12, 0), 'male');
    const e2005 = DY.analyzeYear(base.bazi, ['乙', '酉'], ['己', '卯']);
    const e2028 = DY.analyzeYear(base.bazi, ['戊', '申'], ['辛', '巳']);
    return {
      quad: q,
      ev2005: e2005.events.map(e => e.type + '@' + e.palace).join(','),
      ev2028: e2028.events.map(e => e.type + '@' + e.palace).join(','),
      text2005: e2005.text
    };
  });
  quad.quad.forEach(c => t('顺逆: ' + c.y + (c.g === 'male' ? '男' : '女') + ' → ' + (c.exp ? '顺' : '逆'), c.ok, c.fwd + ''));
  t('冲合刑: 乙酉年 合年柱+冲大运 (酉合辰/酉冲卯)', quad.ev2005 === 'he@0,chong@-1', quad.ev2005);
  t('冲合刑: 戊申年 冲月柱+合日柱+合大运 (申冲寅/申合巳)', quad.ev2028 === 'chong@1,he@2,he@-1', quad.ev2028);
  t('冲合刑: 断语文本含事件句', quad.text2005.indexOf('冲动大运') >= 0, quad.text2005);

  /* ===== E. UI: 表单/排盘/时间轴/流年表 ===== */
  await page.evaluate(() => { localStorage.setItem('yijing.history.v1', '[]'); });
  /* iter25: 更多占法已分页化, 先进入子页 */
  await page.click('#moreDivEntry');
  await page.waitForTimeout(300);
  await page.click('#div-bazi');
  await page.waitForTimeout(300);
  const formUi = await page.evaluate(() => ({
    gender: !!document.getElementById('baziGender'),
    gBtns: document.querySelectorAll('#baziGender .g-btn').length,
    hourUnknown: !!document.getElementById('baziHourUnknown')
  }));
  t('UI: 性别分段 (2 键) + 时辰未知开关', formUi.gender && formUi.gBtns === 2 && formUi.hourUnknown);

  /* 坤造 + 时辰未知: 1990-06-15 12:00 */
  await page.evaluate(() => {
    document.getElementById('baziYear').value = '1990';
    document.getElementById('baziMonth').value = '6';
    document.getElementById('baziDay').value = '15';
    const sel = document.getElementById('baziHour');
    for (let i = 0; i < sel.options.length; i++) if (sel.options[i].value === '12') { sel.selectedIndex = i; break; }
  });
  await page.click('#baziGender .g-btn[data-g="female"]');
  await page.click('#baziHourUnknown');
  await page.click('#baziGo');
  await page.waitForTimeout(600);
  const femaleUi = await page.evaluate(() => {
    const r = document.getElementById('divResult');
    const hist = JSON.parse(localStorage.getItem('yijing.history.v1') || '[]');
    return {
      kun: r && r.innerHTML.indexOf('坤造') >= 0,
      approx: r ? r.querySelectorAll('.bazi-pillar.approx').length : 0,
      approxTag: r && r.innerHTML.indexOf('近似') >= 0,
      steps: r ? r.querySelectorAll('.dy-step').length : 0,
      curStep: r ? r.querySelectorAll('.dy-step.current').length : 0,
      pastSteps: r ? r.querySelectorAll('.dy-step.past').length : 0,
      dir: r ? (r.innerHTML.indexOf('逆行') >= 0) : false,
      panels: r ? r.querySelectorAll('.dy-liunian').length : 0,
      visiblePanel: r ? Array.from(r.querySelectorAll('.dy-liunian')).filter(p => !p.hidden).length : 0,
      rows: r ? r.querySelectorAll('.dy-liunian:not([hidden]) .ln-row').length : 0,
      nowBadge: r ? r.querySelectorAll('.ln-row .now').length : 0,
      histLen: hist.length,
      birthTs: hist[0] && typeof hist[0].birthTs,
      gender: hist[0] && hist[0].gender,
      hourUnknown: hist[0] && hist[0].hourUnknown
    };
  });
  t('UI: 坤造标注', femaleUi.kun);
  t('UI: 时辰未知 → 时柱近似 (1 个 approx + 标注)', femaleUi.approx === 1 && femaleUi.approxTag, femaleUi.approx + '');
  t('UI: 逆行显示 (庚午年? 1990 庚午 → 阳年女逆)', femaleUi.dir);
  t('UI: 大运时间轴 8 步', femaleUi.steps === 8, femaleUi.steps + '');
  t('UI: 当前步恰好 1 个高亮', femaleUi.curStep === 1, femaleUi.curStep + '');
  t('UI: 已过大运半透明 (≥1)', femaleUi.pastSteps >= 1, femaleUi.pastSteps + '');
  t('UI: 流年面板 8 个, 默认展开当前步 1 个', femaleUi.panels === 8 && femaleUi.visiblePanel === 1, femaleUi.panels + '/' + femaleUi.visiblePanel);
  t('UI: 当前步流年 10 行', femaleUi.rows === 10, femaleUi.rows + '');
  t('UI: 今岁徽标恰好 1 个', femaleUi.nowBadge === 1, femaleUi.nowBadge + '');
  t('历史: birthTs/gender/hourUnknown 入账', femaleUi.histLen === 1 && femaleUi.birthTs === 'number' && femaleUi.gender === 'female' && femaleUi.hourUnknown === true);

  /* 点击第 3 步大运 → 面板切换 */
  await page.click('.dy-step[data-step="2"]');
  await page.waitForTimeout(300);
  const switchUi = await page.evaluate(() => {
    const r = document.getElementById('divResult');
    const vis = Array.from(r.querySelectorAll('.dy-liunian')).filter(p => !p.hidden);
    return { vis: vis.length, step: vis[0] && vis[0].dataset.step, head: vis[0] && vis[0].querySelector('.ln-head').textContent };
  });
  t('UI: 点击大运切换流年面板', switchUi.vis === 1 && switchUi.step === '2', JSON.stringify(switchUi));

  /* 流年 chips 存在性: 造一个含冲的流年 (1990-06-15 庚午日?, 点开当前步扫 chips) */
  const chipsUi = await page.evaluate(() => {
    const r = document.getElementById('divResult');
    return r.querySelectorAll('.ln-chip').length;
  });
  t('UI: 冲合刑 chips 渲染 (≥1)', chipsUi >= 1, chipsUi + '');

  /* ===== F. 历史回看 ===== */
  await page.evaluate(() => { try { window.YijingUI.gotoScreen(5); } catch (e) {} });
  await page.waitForTimeout(600);
  await page.evaluate(() => {
    const card = document.querySelector('#hist-today .hist-card, #hist-week .hist-card');
    if (card) card.click();
  });
  await page.waitForTimeout(800);
  const recallUi = await page.evaluate(() => {
    const r = document.getElementById('divResult');
    const hist = JSON.parse(localStorage.getItem('yijing.history.v1') || '[]');
    return {
      rendered: r && !r.hidden && r.innerHTML.indexOf('八字排盘') >= 0 && r.innerHTML.indexOf('坤造') >= 0,
      hasDaYun: r && r.querySelectorAll('.dy-step').length === 8,
      histLen: hist.length, /* 回看不新增记录 */
      screen2: !!document.getElementById('baziForm')
    };
  });
  t('回看: 点击八字历史卡 → 屏2 重排 (坤造+8步大运)', recallUi.rendered && recallUi.hasDaYun);
  t('回看: 不重复入历史', recallUi.histLen === 1, recallUi.histLen + '');

  /* ===== G. 乾造顺行对照 (2000-02-05) ===== */
  await page.evaluate(() => { try { window.YijingUI.gotoScreen(1); } catch (e) {} }); /* 屏2 起卦 (index 1) */
  await page.waitForTimeout(500);
  /* iter25: 确保在更多占法子页 */
  const inMorePage = await page.evaluate(() => !document.getElementById('more-div-list').hidden);
  if (!inMorePage) {
    await page.click('#moreDivEntry');
    await page.waitForTimeout(300);
  }
  await page.click('#div-bazi');
  await page.waitForTimeout(300);
  await page.evaluate(() => {
    document.getElementById('baziYear').value = '2000';
    document.getElementById('baziMonth').value = '2';
    document.getElementById('baziDay').value = '5';
    const sel = document.getElementById('baziHour');
    for (let i = 0; i < sel.options.length; i++) if (sel.options[i].value === '12') { sel.selectedIndex = i; break; }
    document.getElementById('baziHourUnknown').checked = false;
  });
  await page.click('#baziGender .g-btn[data-g="male"]');
  await page.click('#baziGo');
  await page.waitForTimeout(500);
  const maleUi = await page.evaluate(() => {
    const r = document.getElementById('divResult');
    const meta = r.querySelector('.dy-meta-line');
    return {
      qian: r.innerHTML.indexOf('乾造') >= 0,
      meta: meta ? meta.textContent : '',
      histLen: JSON.parse(localStorage.getItem('yijing.history.v1') || '[]').length
    };
  });
  t('乾造: 顺行 + 9岁8个月起运 UI 元数据', maleUi.qian && maleUi.meta.indexOf('顺行') >= 0 && maleUi.meta.indexOf('9岁8个月') >= 0 && maleUi.meta.indexOf('惊蛰') >= 0, maleUi.meta.trim());
  t('历史: 累计 2 条八字记录', maleUi.histLen === 2, maleUi.histLen + '');

  t('零 pageerror', errors.length === 0, errors.join(' | '));
  console.log('\n结果: ' + pass + ' 通过, ' + fail + ' 失败');
  await browser.close();
  process.exit(fail ? 1 : 0);
})();
