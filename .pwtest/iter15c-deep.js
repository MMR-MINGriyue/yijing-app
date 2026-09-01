/* iter15c: 用正确存储键重测 — XSS / 畸形记录渲染 / 导入落库 */
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
  const KEY = 'yijing.history.v1';

  /* 0. gotoScreen 可用性 (上轮异常) */
  const api = await page.evaluate(() => ({
    goto: typeof window.YijingUI.gotoScreen,
    settings: typeof window.YijingUI.openSettings,
    refresh: typeof window.YijingUI.refreshHistory
  }));
  console.log('  YijingUI API: ' + JSON.stringify(api));

  /* 1. 畸形 JSON 存储 */
  await page.evaluate(k => { try { localStorage.setItem(k, 'not-json{'); } catch (e) {} }, KEY);
  await page.reload(); await page.waitForTimeout(2600);
  const ok1 = await page.evaluate(() => document.querySelectorAll('#tag-row .tag').length === 5);
  t('坏 JSON 存储 → 回退空数组不崩', ok1);

  /* 2. XSS 注入 (正确键, 含 month 字段保证可见) */
  await page.evaluate(k => {
    const now = new Date();
    const mon = now.getFullYear() + '-' + String(now.getMonth() + 1).padStart(2, '0');
    try {
      localStorage.setItem(k, JSON.stringify([{
        id: 1, ts: Date.now(), hexNo: 1, name: '乾', month: mon, day: now.getDate(),
        question: '<img src=x onerror="window.__xss=1"><script>window.__xss=2<\/script>',
        direction: '事业', directionColor: 'career', method: '铜钱起卦'
      }]));
    } catch (e) {}
  }, KEY);
  await page.reload(); await page.waitForTimeout(2600);
  const xss = await page.evaluate(() => window.__xss);
  t('XSS payload 不执行 (xss=' + xss + ')', !xss);
  await page.evaluate(() => { try { window.YijingUI.gotoScreen(5); } catch (e) { console.log(e.message); } });
  await page.waitForTimeout(600);
  const esc = await page.evaluate(() => {
    const html = document.getElementById('histList') ? document.getElementById('histList').innerHTML : document.body.innerHTML;
    const txt = document.body.innerText;
    return { imgAsText: txt.includes('<img'), scriptAsText: txt.includes('script'), domScript: !!document.querySelector('.hist-card script') };
  });
  t('问题字段转义为纯文本 (img 文本=' + esc.imgAsText + ')', esc.imgAsText && !esc.domScript);

  /* 3. 畸形记录渲染 (缺字段) */
  await page.evaluate(k => {
    try { localStorage.setItem(k, JSON.stringify([{ id: 'x' }, { ts: 123, question: 'q' }])); } catch (e) {}
  }, KEY);
  await page.reload(); await page.waitForTimeout(2600);
  const render = await page.evaluate(() => {
    const txt = document.body.innerText;
    return { nan: txt.includes('NaN'), undef: txt.includes('undefined'), obj: txt.includes('[object') };
  });
  t('缺字段记录渲染无 NaN/undefined (JSON=' + JSON.stringify(render) + ')', !render.nan && !render.undef && !render.obj);

  /* 4. 导入落库 (正确键校验) */
  await page.evaluate(() => { try { localStorage.clear(); } catch (e) {} });
  await page.reload(); await page.waitForTimeout(2600);
  await page.evaluate(() => window.YijingUI.openSettings());
  await page.waitForTimeout(400);
  const legal = JSON.stringify({ history: [{ ts: 1700000000000, name: '乾', question: '导入Q', direction: '事业', directionColor: 'career', method: '铜钱起卦' }], favorites: [3, 200] });
  await page.evaluate(async ({ json }) => {
    const input = document.querySelector('input[type="file"][accept*="json"]');
    const blob = new Blob([json], { type: 'application/json' });
    const dt = new DataTransfer();
    dt.items.add(new File([blob], 'a.json', { type: 'application/json' }));
    input.files = dt.files;
    input.dispatchEvent(new Event('change', { bubbles: true }));
  }, { json: legal });
  await page.waitForTimeout(1000);
  const hist = await page.evaluate(k => JSON.parse(localStorage.getItem(k) || '[]'), KEY);
  t('导入记录写入正确键 (n=' + hist.length + ')', hist.length >= 1 && hist.some(x => x.question === '导入Q'));
  const favs = await page.evaluate(() => JSON.parse(localStorage.getItem('yijing.favHexes') || '[]'));
  t('导入收藏过滤越界 (favs=' + JSON.stringify(favs) + ')', favs.includes(3) && !favs.includes(200));

  await page.evaluate(() => { try { localStorage.clear(); } catch (e) {} });
  console.log('\n结果: ' + pass + ' 通过 / ' + fail + ' 失败');
  if (errors.length) console.log('RUNTIME ERRORS:\n' + [...new Set(errors)].join('\n'));
  browser.close();
  process.exit(fail === 0 && errors.length === 0 ? 0 : 1);
})();
