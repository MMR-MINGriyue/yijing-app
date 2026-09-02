/* 截屏 4 (iter31) — Flutter 卦辞解析 UI */
const { chromium } = require('playwright-core');
(async () => {
  const b = await chromium.launch({ executablePath: 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe' });
  const p = await b.newPage({ viewport: { width: 420, height: 940 } });
  const errs = [];
  p.on('pageerror', e => errs.push(e.message));
  p.on('console', m => { if (m.type() === 'error') errs.push(m.text()); });
  await p.goto('http://localhost:8731/');
  await p.waitForTimeout(8000);
  await p.screenshot({ path: 'D:/workspace/yijing-app/_flutter-screen4.png' });
  console.log('errors:', errs.length ? JSON.stringify(errs.slice(0, 3)) : 'none');
  await b.close();
})();