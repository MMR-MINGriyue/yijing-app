/* iter28: 屏 6 历史搜索关键字高亮 (用独有标记隔离内置数据) */
const { chromium } = require('playwright-core');
(async () => {
  const b = await chromium.launch({ executablePath: 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe' });
  const p = await b.newPage({ viewport: { width: 390, height: 844 } });
  const errs = [];
  p.on('pageerror', e => errs.push(e.message));
  await p.goto('http://localhost:8723/?view=app');
  await p.waitForTimeout(2800);

  /* 注入 4 条带 TAG28 独有标记的测试记录 */
  await p.evaluate(() => {
    const records = [
      { hexNo: 1, name: '乾卦', direction: '事业', directionColor: 'gold', question: '问: TAG28近期事业运筹', date: '今日 09:32', ts: Date.now() - 100000, month: '2026-06', day: 17, lines: ['yang','yang','moving','yang','yang','yang'] },
      { hexNo: 6, name: '讼卦', direction: '事业', directionColor: 'gold', question: '问: TAG28发展方向', date: '今日 11:00', ts: Date.now() - 200000, month: '2026-06', day: 18, lines: ['yang','yin','yang','yin','yang','yang'] },
      { hexNo: 31, name: '咸卦', direction: '感情', directionColor: 'pine', question: '问: TAG28感情运筹', date: '昨日 21:32', ts: Date.now() - 300000, month: '2026-06', day: 16, lines: ['yin','yang','yang','yang','yang','yin'] },
      { hexNo: 14, name: '大有卦', direction: '财运', directionColor: 'cinnabar', question: '问: TAG28财运发展', date: '昨日 18:30', ts: Date.now() - 400000, month: '2026-06', day: 16, lines: ['yang','yang','yang','yin','yang','yang'] }
    ];
    localStorage.setItem('yijing.history.v1', JSON.stringify(records));
  });
  await p.evaluate(() => window.YijingUI.refreshHistory());
  await p.waitForTimeout(500);
  await p.evaluate(() => window.YijingUI.gotoScreen(5));
  await p.waitForTimeout(700);

  let pass = 0, fail = 0;
  const t = (n, ok, d) => { ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + ' + ' + n + (d ? ' — ' + d : '')); };

  /* 搜 TAG28 → 4 张匹配, 4 个 <mark> 包含 "TAG28" */
  await p.fill('#histSearchInput', 'TAG28');
  await p.waitForTimeout(500);
  const all = await p.evaluate(() => {
    const cards = document.querySelectorAll('.hist-card');
    const marks = Array.from(document.querySelectorAll('.hist-mark'));
    return {
      count: cards.length,
      hasMark: marks.length > 0,
      markTexts: marks.map(m => m.textContent),
      allHaveMark: Array.from(cards).every(c => c.querySelector('.hist-mark')),
      hasSearchHitClass: Array.from(cards).every(c => c.classList.contains('search-hit'))
    };
  });
  t('A1: 搜 "TAG28" → 4 张匹配 (独有标记)', all.count === 4, 'count=' + all.count);
  t('A2: 4 个 <mark> 存在', all.hasMark && all.markTexts.length === 4, 'marks=' + all.markTexts.length);
  t('A3: 所有 <mark> 文本 = "TAG28"', all.markTexts.every(s => s === 'TAG28'), JSON.stringify(all.markTexts));
  t('A4: 4 张卡都有 .search-hit class', all.hasSearchHitClass);
  t('A5: 4 张卡每张至少 1 个 <mark> (在 question 中)', all.allHaveMark);

  /* 搜 "感情" → 1 张匹配 (咸卦) — 独有关键字, 不被内置数据干扰 */
  await p.fill('#histSearchInput', 'TAG28感情');
  await p.waitForTimeout(500);
  const love = await p.evaluate(() => {
    const cards = document.querySelectorAll('.hist-card');
    return { count: cards.length, cardName: cards[0] && cards[0].querySelector('.hist-name').textContent, marks: document.querySelectorAll('.hist-mark').length };
  });
  t('B1: 搜 "TAG28感情" → 1 张匹配 = 咸卦', love.count === 1 && love.cardName === '咸卦', JSON.stringify(love));
  t('B2: 1 个 <mark>', love.marks === 1, 'marks=' + love.marks);

  /* 搜卦名独有关键字 "讼" + 限定为注入数据 → 但内置有讼卦匹配, 用纯独有 */
  /* 改用 question 含 "TAG28发展方向" 匹配讼卦 (独有) */
  await p.fill('#histSearchInput', '发展方向');
  await p.waitForTimeout(500);
  const dev = await p.evaluate(() => {
    const cards = document.querySelectorAll('.hist-card');
    return { count: cards.length, name: cards[0] && cards[0].querySelector('.hist-name').textContent };
  });
  t('C1: 搜 "发展方向" (独有) → 1 张 = 讼卦', dev.count === 1 && dev.name === '讼卦', JSON.stringify(dev));

  /* 搜不存在关键字 → 0 张 */
  await p.fill('#histSearchInput', 'XXXNOPE');
  await p.waitForTimeout(500);
  const none = await p.evaluate(() => ({
    cards: document.querySelectorAll('.hist-card').length,
    empty: document.querySelector('.hist-empty') && document.querySelector('.hist-empty').textContent
  }));
  t('D1: 搜不存在 → 0 张', none.cards === 0);
  t('D2: 显示空态', none.empty && /无 匹 配 记 录/.test(none.empty), none.empty && none.empty.slice(0, 30));

  /* 清空搜索 → 搜索框清空, <mark> 消失 (但卡仍显示) */
  await p.fill('#histSearchInput', '');
  await p.waitForTimeout(500);
  const cleared = await p.evaluate(() => ({
    marks: document.querySelectorAll('.hist-mark').length,
    searchHits: document.querySelectorAll('.hist-card.search-hit').length
  }));
  t('E1: 清空 → <mark> 消失', cleared.marks === 0, 'marks=' + cleared.marks);
  t('E2: 清空 → search-hit class 消失', cleared.searchHits === 0, 'hits=' + cleared.searchHits);

  /* XSS 防护 */
  await p.fill('#histSearchInput', '<script>alert(1)</script>');
  await p.waitForTimeout(500);
  t('XSS: <script> 搜索无 pageerror', errs.length === 0, errs.join('|') || 'ok');

  t('零 pageerror', errs.length === 0, errs.join(' | '));

  console.log('\n结果: ' + pass + ' 通过, ' + fail + ' 失败');
  await b.close();
  process.exit(fail || errs.length ? 1 : 0);
})();