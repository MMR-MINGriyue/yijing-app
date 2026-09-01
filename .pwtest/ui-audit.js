/* UI/UX 审计: 7 屏截图 */
const { chromium } = require('playwright-core');
(async () => {
  const browser = await chromium.launch({ channel: 'msedge' });
  const page = await browser.newPage({ viewport: { width: 390, height: 844 } });
  await page.goto('http://localhost:8723/?view=app');
  await page.waitForTimeout(2600);
  for (let i = 0; i < 7; i++) {
    await page.evaluate(n => window.YijingUI.gotoScreen(n), i);
    await page.waitForTimeout(500);
    await page.screenshot({ path: `.pwtest/ui-audit-s${i}.png` });
    console.log('screenshot s' + i);
  }
  /* 04 屏解析 (需造一卦) */
  await page.evaluate(() => window.YijingUI.openDetail(5));
  await page.waitForTimeout(600);
  await page.screenshot({ path: '.pwtest/ui-audit-s3.png' });
  browser.close();
})();
