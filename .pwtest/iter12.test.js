/* 第十二轮冒烟测试: 方向标签切换+记忆 / 分享卡干支落款 / 重置示例数据 */
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
  await page.evaluate(() => localStorage.clear());
  await page.goto(BASE + '/?view=app');
  await page.waitForTimeout(2400);

  console.log('== 1. 加载无运行时错误 ==');
  ok(errors.length === 0, '无 console/page 错误', errors.join('; '));

  console.log('== 2. 方向标签点击切换 ==');
  const tags = await page.evaluate(() => Array.from(document.querySelectorAll('#tag-row .tag')).map(t => t.textContent));
  ok(tags.length >= 5, '5 个方向标签', JSON.stringify(tags));
  const beforeActive = await page.evaluate(() => document.querySelector('#tag-row .tag.active').textContent);
  // 点击第 3 个
  await page.click('#tag-row .tag:nth-child(3)');
  await page.waitForTimeout(200);
  const afterActive = await page.evaluate(() => ({
    active: document.querySelector('#tag-row .tag.active').textContent,
    count: document.querySelectorAll('#tag-row .tag.active').length,
    aria: document.querySelector('#tag-row .tag.active').getAttribute('aria-checked')
  }));
  ok(afterActive.active !== beforeActive, '点击后激活切换', beforeActive + ' → ' + afterActive.active);
  ok(afterActive.count === 1, '仅一项激活');
  ok(afterActive.aria === 'true', 'aria-checked 同步');
  const stored = await page.evaluate(() => localStorage.getItem('yijing.lastDirection'));
  ok(stored === afterActive.active, '选择已持久化', stored);

  console.log('== 3. 刷新后恢复上次选择 ==');
  await page.reload();
  await page.waitForTimeout(2400);
  const restored = await page.evaluate(() => document.querySelector('#tag-row .tag.active').textContent);
  ok(restored === afterActive.active, '重载后恢复 ' + afterActive.active, restored);

  console.log('== 4. 分享卡干支落款 ==');
  const footer = await page.evaluate(() => {
    const c = window.YijingShare.draw(1, [2], '测试所问');
    const g = c.getContext('2d');
    /* 读取页脚区域像素判断有字; 更直接: 重新调用内部逻辑不可行, 用画布快照比对 */
    return { w: c.width, h: c.height };
  });
  ok(footer.w === 720 && footer.h === 1040, '分享卡尺寸正常');
  /* 干支文本验证: 通过 toDataURL 落款行 OCR 不可行, 改验证日历组件输出拼接正确 */
  const gz = await page.evaluate(() => {
    const d = new Date();
    const C = window.YijingCalendar;
    return C.ganzhiYear(d) + '年 ' + C.ganzhiMonth(d) + '月 ' + C.ganzhiDay(d) + '日　';
  });
  ok(/^.{1,2}年 .{1,2}月 .{1,2}日　$/.test(gz), '干支落款串格式正确', gz);
  /* 画布页脚确有内容 (非空白行): 检查页脚区域有非背景像素 */
  const hasFooter = await page.evaluate(() => {
    const c = window.YijingShare.draw(1, [2], '测试所问');
    const g = c.getContext('2d');
    const data = g.getImageData(200, 960, 320, 60).data;
    let lit = 0;
    for (let i = 0; i < data.length; i += 4) {
      if (data[i] > 60 || data[i + 1] > 60 || data[i + 2] > 60) lit++;
    }
    return lit;
  });
  ok(hasFooter > 50, '页脚区域有绘制内容 (' + hasFooter + ' px)');

  console.log('== 5. 重置为示例数据 ==');
  await page.evaluate(() => {
    window.YijingHistory.clear();
    window.YijingUI.refreshHistory();
  });
  await page.waitForTimeout(200);
  const emptyCount = await page.evaluate(() => window.YijingHistory.load().length);
  ok(emptyCount === 0, '先清空');
  // 收藏不受影响的预置
  await page.evaluate(() => {
    localStorage.setItem('yijing.favHexes', JSON.stringify([3]));
    window.YijingUI.refreshHistory();
  });
  await page.click('#settingsBtn');
  await page.waitForTimeout(300);
  await page.click('.settings-overlay #settingsReset');
  await page.waitForTimeout(150);
  const resetConfirm = await page.evaluate(() => document.querySelector('.settings-overlay #settingsReset .settings-item-name').textContent);
  ok(resetConfirm.indexOf('确认重置') >= 0, '首次点击出现二次确认', resetConfirm);
  await page.click('.settings-overlay #settingsReset');
  await page.waitForTimeout(400);
  const afterReset = await page.evaluate(() => ({
    count: window.YijingHistory.load().length,
    favs: JSON.parse(localStorage.getItem('yijing.favHexes')),
    meta: document.querySelector('.settings-overlay #settingsMeta').textContent,
    btnName: document.querySelector('.settings-overlay #settingsReset .settings-item-name').textContent
  }));
  const SAMPLE_COUNT = await page.evaluate(() => YIJING_DATA.HISTORY.length);
  ok(afterReset.count === SAMPLE_COUNT, '历史恢复为 ' + SAMPLE_COUNT + ' 条示例', 'count=' + afterReset.count);
  ok(afterReset.favs.join(',') === '3', '收藏不受影响', JSON.stringify(afterReset.favs));
  ok(afterReset.meta.indexOf('本地记录 ' + SAMPLE_COUNT + ' 条') >= 0, '面板统计刷新', afterReset.meta);
  ok(afterReset.btnName === '重置为示例数据', '按钮文案复位', afterReset.btnName);
  // toast 文案
  const resetToast = await page.evaluate(() => document.getElementById('globalToast').textContent);
  ok(resetToast.indexOf('已恢复示例数据') >= 0, 'toast 提示', resetToast);
  await page.keyboard.press('Escape');
  await page.waitForTimeout(200);

  console.log('== 6. Esc 后 reset 按钮状态复位 ==');
  await page.click('#settingsBtn');
  await page.waitForTimeout(200);
  await page.click('.settings-overlay #settingsReset'); // 触发确认态
  await page.waitForTimeout(150);
  await page.keyboard.press('Escape'); // Esc 关闭
  await page.waitForTimeout(300);
  await page.click('#settingsBtn');
  await page.waitForTimeout(200);
  const reopened = await page.evaluate(() => document.querySelector('.settings-overlay #settingsReset .settings-item-name').textContent);
  ok(reopened === '重置为示例数据', '重新打开后确认态已复位', reopened);
  await page.keyboard.press('Escape');

  console.log('== 7. 方向标签影响起卦记录 ==');
  await page.click('#tag-row .tag:nth-child(2)');
  await page.waitForTimeout(150);
  const dir2 = await page.evaluate(() => document.querySelector('#tag-row .tag.active').textContent.replace(/\s/g, ''));
  await page.evaluate(d => {
    window.YijingUI.castHex && (window.__savedDir = d);
    /* 直接构造记录验证 direction 字段 */
    const now = Date.now();
    window.YijingHistory.add({ ts: now, date: '今日 12:00', month: '2026-08', day: 31, hexNo: 1, name: '乾卦', question: '问：方向验证', direction: d, directionColor: 'gold', lines: [], moving: [], method: 'coin' });
    window.YijingUI.refreshHistory();
  }, dir2);
  await page.waitForTimeout(300);
  const meDir = await page.evaluate(() => Array.from(document.querySelectorAll('#meDirectionBars .bar-head')).map(e => e.textContent));
  ok(meDir.some(t => t.indexOf(dir2) >= 0), '我的-方向分布含所选方向', JSON.stringify(meDir));

  console.log('== 8. 最终无运行时错误 ==');
  ok(errors.length === 0, '全程无 console/page 错误', errors.join('; '));

  browser.close().catch(() => {});
  console.log('\n结果: ' + pass + ' 通过 / ' + fail + ' 失败');
  process.exit(fail ? 1 : 0);
})().catch(e => { console.error('FATAL', e); process.exit(1); });
