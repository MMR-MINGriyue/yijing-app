/* iter15b: 真实导入路径 + 畸形记录渲染 */
const { chromium } = require('playwright-core');
(async () => {
  const browser = await chromium.launch({ channel: 'msedge' });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  const errors = [];
  page.on('pageerror', e => errors.push(e.message));
  await page.goto('http://localhost:8723/?view=app');
  await page.waitForTimeout(2600);
  let pass = 0, fail = 0;
  const t = (name, ok, detail) => { ok ? pass++ : fail++; console.log((ok ? 'PASS' : 'FAIL') + ' ' + name + (detail ? ' — ' + detail : '')); };

  /* 打开设置面板拿 file input */
  await page.evaluate(() => window.YijingUI.openSettings());
  await page.waitForTimeout(500);

  /* 1. 合法文件 */
  const legal = JSON.stringify({
    history: [{ id: 1, ts: 1700000000000, hex: 1, name: '乾', question: '测试Q', direction: '事业', directionColor: 'career', method: '铜钱起卦' }],
    favorites: [3, 200, 'abc']
  });
  const r1 = await page.evaluate(async (json) => {
    const input = document.querySelector('#settingsSheet input[type="file"], .sheet input[type="file"], input[type="file"][accept*="json"]');
    if (!input) return 'no-input';
    const blob = new Blob([json], { type: 'application/json' });
    const dt = new DataTransfer();
    dt.items.add(new File([blob], 'a.json', { type: 'application/json' }));
    input.files = dt.files;
    input.dispatchEvent(new Event('change', { bubbles: true }));
    return 'ok';
  }, legal);
  await page.waitForTimeout(900);
  t('合法导入处理 (' + r1 + ')', r1 === 'ok');
  const hist1 = await page.evaluate(() => {
    const h = JSON.parse(localStorage.getItem('yijing.history') || '[]');
    return { n: h.length, hasQ: h.some(x => x.question === '测试Q') };
  });
  t('合法记录入库 (n=' + hist1.n + ')', hist1.n >= 1 && hist1.hasQ);
  const favs1 = await page.evaluate(() => JSON.parse(localStorage.getItem('yijing.favHexes') || '[]'));
  t('收藏越界值被过滤 (favs=' + JSON.stringify(favs1) + ')', favs1.includes(3) && !favs1.includes(200) && !favs1.includes(NaN));

  /* 2. 畸形记录文件 */
  const evil = JSON.stringify({ history: [{ id: 'x' }, { ts: 99, question: '<b>evil</b>' }, null, 'string'] });
  await page.evaluate(() => { try { localStorage.setItem('yijing.history', '[]'); } catch (e) {} });
  const r2 = await page.evaluate(async (json) => {
    const input = document.querySelector('input[type="file"][accept*="json"]');
    if (!input) return 'no-input';
    const blob = new Blob([json], { type: 'application/json' });
    const dt = new DataTransfer();
    dt.items.add(new File([blob], 'b.json', { type: 'application/json' }));
    input.files = dt.files;
    input.dispatchEvent(new Event('change', { bubbles: true }));
    return 'ok';
  }, evil);
  await page.waitForTimeout(900);
  const hist2 = await page.evaluate(() => JSON.parse(localStorage.getItem('yijing.history') || '[]'));
  console.log('  畸形导入后历史: ' + JSON.stringify(hist2));

  /* 3. 畸形记录对屏6渲染的影响 */
  await page.evaluate(() => { try { localStorage.setItem('yijing.history', JSON.stringify([{ id: 'x' }])); } catch (e) {} });
  await page.reload();
  await page.waitForTimeout(2200);
  await page.evaluate(() => window.YijingUI.gotoScreen(5));
  await page.waitForTimeout(500);
  const render = await page.evaluate(() => {
    const cards = document.querySelectorAll('.hist-card');
    const body = document.body.innerText;
    return { cards: cards.length, hasNaN: body.includes('NaN') || body.includes('undefined'), broken: body.includes('[object') };
  });
  t('畸形记录渲染不出现 NaN/undefined', !render.hasNaN && !render.broken);

  await page.evaluate(() => { try { localStorage.clear(); } catch (e) {} });
  console.log('\n结果: ' + pass + ' 通过 / ' + fail + ' 失败');
  if (errors.length) console.log('RUNTIME ERRORS:\n' + [...new Set(errors)].join('\n'));
  browser.close();
  process.exit(fail === 0 && errors.length === 0 ? 0 : 1);
})();
