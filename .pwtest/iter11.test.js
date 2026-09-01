/* 第十一轮冒烟测试: 导入 JSON / quick-row 历史 / 月干支 */
const { chromium } = require('playwright-core');

const BASE = 'http://localhost:8723';
let pass = 0, fail = 0;
function ok(cond, name, extra) {
  if (cond) { pass++; console.log('  PASS ' + name); }
  else { fail++; console.log('  FAIL ' + name + (extra ? ' | ' + extra : '')); }
}

(async () => {
  const browser = await chromium.launch({ channel: 'msedge' });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errors = [];
  page.on('console', m => { if (m.type() === 'error') errors.push(m.text()); });
  page.on('pageerror', e => errors.push(String(e)));

  await page.goto(BASE + '/?view=app');
  await page.waitForTimeout(2400);

  console.log('== 1. 加载无运行时错误 ==');
  ok(errors.length === 0, '无 console/page 错误', errors.join('; '));

  console.log('== 2. 月干支正确性 (年上起月法 + 节气界) ==');
  const mg = await page.evaluate(() => {
    const C = window.YijingCalendar;
    return {
      now: C.ganzhiMonth(new Date()),
      /* 2024-02-10: 甲辰年 正月丙寅 (立春后) */
      a: C.ganzhiMonth(new Date(2024, 1, 10)),
      /* 2024-01-20: 癸卯年 子月甲子? 乙丑月: 癸年正月甲寅 → 子月=癸亥, 丑月=甲子 */
      b: C.ganzhiMonth(new Date(2024, 0, 20)),
      /* 2024-12-25: 甲辰年 子月丙子 (大雪后) */
      c: C.ganzhiMonth(new Date(2024, 11, 25)),
      /* 2026-08-31: 丙午年 申月丙申 (立秋后) */
      d: C.ganzhiMonth(new Date(2026, 7, 31)),
      /* 2025-03-10: 乙巳年 卯月己卯 */
      e: C.ganzhiMonth(new Date(2025, 2, 10)),
      dateLine: document.getElementById('greetDate').textContent
    };
  });
  ok(mg.a === '丙寅', '2024-02-10 甲辰年正月丙寅', mg.a);
  ok(mg.b === '乙丑', '2024-01-20 癸卯年丑月乙丑', mg.b);
  ok(mg.c === '丙子', '2024-12-25 甲辰年子月丙子', mg.c);
  ok(mg.d === '丙申', '2026-08-31 丙午年申月丙申', mg.d);
  ok(mg.e === '己卯', '2025-03-10 乙巳年卯月己卯', mg.e);
  ok(mg.dateLine.split(' ')[1] === mg.now + '月', '问候行含当前月干支', mg.dateLine);

  console.log('== 3. quick-row 历史记录入口 ==');
  await page.evaluate(() => window.YijingUI.gotoScreen(0));
  await page.waitForTimeout(400);
  await page.click('.quick-item:nth-child(3)');
  await page.waitForTimeout(700);
  const histCur = await page.evaluate(() => window.YijingUI.appCurrent());
  ok(histCur === 5, '快捷「历史记录」→ 屏6', 'cur=' + histCur);

  console.log('== 4. 导入 JSON ==');
  await page.evaluate(() => {
    window.YijingHistory.clear();
    localStorage.setItem('yijing.favHexes', '[]');
    window.YijingUI.refreshHistory();
  });
  // 准备导入文件 (含 2 条新记录 + 1 条与现有重复 + 收藏)
  const importPayload = await page.evaluate(() => {
    const now = Date.now();
    return JSON.stringify({
      app: 'yijing-app',
      history: [
        { ts: now - 1, date: '昨日 10:00', month: '2026-08', day: 30, hexNo: 11, name: '泰卦', question: '问：导入A', direction: '事业', directionColor: 'cinnabar', lines: [], moving: [], method: 'coin' },
        { ts: now - 2, date: '昨日 11:00', month: '2026-08', day: 30, hexNo: 12, name: '否卦', question: '问：导入B', direction: '感情', directionColor: 'gold', lines: [], moving: [], method: 'numeric' },
        { ts: now, date: '今日', month: '2026-08', day: 31, hexNo: 13, name: '同人卦', question: '问：导入C', direction: '学业', directionColor: 'pine', lines: [], moving: [], method: 'yarrow' }
      ],
      favorites: [7, 9]
    });
  });
  // 先放一条已有记录, 验证去重: 用导入文件中同一条再导入
  await page.evaluate(p => {
    const data = JSON.parse(p);
    window.YijingHistory.save(data.history.slice(0, 2));
    localStorage.setItem('yijing.favHexes', JSON.stringify([7]));
    window.YijingUI.refreshHistory();
  }, importPayload);
  await page.waitForTimeout(200);
  // 打开设置面板, 上传文件
  await page.click('#settingsBtn');
  await page.waitForTimeout(300);
  const importInput = await page.evaluate(() => {
    const inp = document.querySelector('.settings-overlay input[type="file"]');
    return !!inp;
  });
  ok(importInput, '导入 file input 存在');
  const fileInput = await page.$('.settings-overlay input[type="file"]');
  await fileInput.setInputFiles({
    name: 'yijing-history-test.json',
    mimeType: 'application/json',
    buffer: Buffer.from(importPayload)
  });
  await page.waitForTimeout(600);
  const imported = await page.evaluate(() => ({
    count: window.YijingHistory.load().length,
    favs: JSON.parse(localStorage.getItem('yijing.favHexes')),
    meTotal: document.getElementById('meTotal').textContent,
    meFav: document.getElementById('meFav').textContent,
    meta: document.querySelector('.settings-overlay #settingsMeta').textContent
  }));
  ok(imported.count === 3, '去重后共 3 条 (2 已有 + 1 新增)', 'count=' + imported.count);
  ok(imported.favs.join(',') === '7,9', '收藏并集 [7,9]', JSON.stringify(imported.favs));
  ok(imported.meTotal === '3', '我的-起卦数联动', imported.meTotal);
  ok(imported.meFav === '2', '我的-收藏数联动', imported.meFav);
  ok(imported.meta.indexOf('本地记录 3 条') >= 0 && imported.meta.indexOf('收藏 2 卦') >= 0, '面板统计刷新', imported.meta);
  // 关闭面板
  await page.keyboard.press('Escape');
  await page.waitForTimeout(200);

  console.log('== 5. 导入非法文件提示 ==');
  await page.click('#settingsBtn');
  await page.waitForTimeout(300);
  const badInput = await page.$('.settings-overlay input[type="file"]');
  await badInput.setInputFiles({
    name: 'bad.json', mimeType: 'application/json', buffer: Buffer.from('not-json{')
  });
  await page.waitForTimeout(400);
  const toastText = await page.evaluate(() => document.getElementById('globalToast').textContent);
  ok(toastText.indexOf('导入失败') >= 0, '非法 JSON 提示', toastText);
  await page.keyboard.press('Escape');
  await page.waitForTimeout(200);

  console.log('== 6. 导出→导入闭环 ==');
  // 清空后导出再导入, 数据应完整恢复
  await page.evaluate(() => {
    window.YijingHistory.clear();
    localStorage.setItem('yijing.favHexes', '[]');
    window.YijingUI.refreshHistory();
  });
  const exportData = await page.evaluate(() => ({
    app: 'yijing-app',
    history: [{ ts: Date.now() - 100, date: '今日 09:00', month: '2026-08', day: 31, hexNo: 1, name: '乾卦', question: '问：闭环', direction: '事业', directionColor: 'cinnabar', lines: [], moving: [], method: 'coin' }],
    favorites: [1]
  }));
  const exportJson = JSON.stringify(exportData);
  await page.click('#settingsBtn');
  await page.waitForTimeout(300);
  const fileInput2 = await page.$('.settings-overlay input[type="file"]');
  await fileInput2.setInputFiles({ name: 'restore.json', mimeType: 'application/json', buffer: Buffer.from(exportJson) });
  await page.waitForTimeout(600);
  const restored = await page.evaluate(() => ({
    count: window.YijingHistory.load().length,
    q: (window.YijingHistory.load()[0] || {}).question,
    favs: JSON.parse(localStorage.getItem('yijing.favHexes'))
  }));
  ok(restored.count === 1 && restored.q === '问：闭环', '历史恢复', JSON.stringify(restored));
  ok(restored.favs.join(',') === '1', '收藏恢复', JSON.stringify(restored.favs));
  await page.keyboard.press('Escape');

  console.log('== 7. 最终无运行时错误 ==');
  ok(errors.length === 0, '全程无 console/page 错误', errors.join('; '));

  browser.close().catch(() => {});
  console.log('\n结果: ' + pass + ' 通过 / ' + fail + ' 失败');
  process.exit(fail ? 1 : 0);
})().catch(e => { console.error('FATAL', e); process.exit(1); });
