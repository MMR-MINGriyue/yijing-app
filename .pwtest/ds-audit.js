/* 设计系统一致性审计: 提取 CSS 声明, 统计偏离 token 的硬编码值 */
const fs = require('fs');
const html = fs.readFileSync('index.html', 'utf8');

/* 抽取 <style> 块 */
const styles = [...html.matchAll(/<style>([\s\S]*?)<\/style>/g)].map(m => m[1]).join('\n');

/* 1. token 盘点 (:root) */
const rootBlock = styles.match(/:root\s*{([\s\S]*?)}/)[1];
const tokens = {};
[...rootBlock.matchAll(/--([\w-]+):\s*([^;]+);/g)].forEach(m => { tokens[m[1]] = m[2].trim(); });
const tokenColors = new Set(Object.entries(tokens).filter(([k, v]) => /^#|rgba?\(/.test(v)).map(([k, v]) => v.toLowerCase()));

/* 2. 声明级扫描 (跳过 :root 块本身) */
const decls = styles.replace(/:root\s*{[\s\S]*?}/, '');
const result = { hex: {}, rgba: {}, radius: {}, shadow: {}, fontSize: {}, spacing: {}, lineHeight: {}, varUse: {} };

/* 逐声明 */
[...decls.matchAll(/([a-z-]+)\s*:\s*([^;{}]+);/g)].forEach(m => {
  const prop = m[1], val = m[2];
  /* hex 颜色 (非 token 定义处) */
  [...val.matchAll(/#[0-9a-fA-F]{3,8}\b/g)].forEach(h => {
    const k = h[0].toLowerCase();
    result.hex[k] = result.hex[k] || { n: 0, props: new Set() };
    result.hex[k].n++; result.hex[k].props.add(prop);
  });
  /* rgba */
  [...val.matchAll(/rgba?\([^)]+\)/g)].forEach(r => {
    const k = r[0].replace(/\s/g, '');
    result.rgba[k] = result.rgba[k] || { n: 0, props: new Set() };
    result.rgba[k].n++; result.rgba[k].props.add(prop);
  });
  if (/^border-radius/.test(prop)) {
    const k = val.trim();
    result.radius[k] = (result.radius[k] || 0) + 1;
  }
  if (/^box-shadow/.test(prop) && val !== 'none') {
    const k = val.trim().replace(/\s+/g, ' ');
    result.shadow[k] = (result.shadow[k] || 0) + 1;
  }
  if (prop === 'font-size') result.fontSize[val.trim()] = (result.fontSize[val.trim()] || 0) + 1;
  if (prop === 'line-height' && /^\d/.test(val.trim())) result.lineHeight[val.trim()] = (result.lineHeight[val.trim()] || 0) + 1;
  if (/^margin|padding|^gap/.test(prop)) {
    val.trim().split(/\s+/).forEach(v => { if (v !== '0' && !v.includes('calc') && !v.includes('var')) result.spacing[v] = (result.spacing[v] || 0) + 1; });
  }
  [...val.matchAll(/var\(--([\w-]+)/g)].forEach(v => { result.varUse[v[1]] = (result.varUse[v[1]] || 0) + 1; });
});

/* 3. 报告 */
console.log('=== TOKEN 色板 ===');
console.log(Object.entries(tokens).filter(([k, v]) => /^#|rgba?\(/.test(v)).map(([k, v]) => k + '=' + v).join('\n'));

console.log('\n=== 硬编码 hex (未走 token, 频次降序) ===');
Object.entries(result.hex).sort((a, b) => b[1].n - a[1].n).forEach(([c, d]) => {
  const inPalette = tokenColors.has(c);
  console.log((inPalette ? '[=token] ' : '[OFF] ') + c + ' ×' + d.n + '  props: ' + [...d.props].join(','));
});

console.log('\n=== rgba 颜色 (top 25) ===');
Object.entries(result.rgba).sort((a, b) => b[1].n - a[1].n).slice(0, 25).forEach(([c, d]) => {
  console.log(c + ' ×' + d.n + '  props: ' + [...d.props].slice(0, 3).join(','));
});

console.log('\n=== border-radius 分布 ===');
Object.entries(result.radius).sort((a, b) => b[1] - a[1]).forEach(([k, n]) => console.log(k + ' ×' + n));

console.log('\n=== box-shadow 分布 ===');
Object.entries(result.shadow).sort((a, b) => b[1] - a[1]).forEach(([k, n]) => console.log(JSON.stringify(k) + ' ×' + n));

console.log('\n=== font-size 分布 ===');
Object.entries(result.fontSize).sort((a, b) => b[1] - a[1]).forEach(([k, n]) => console.log(k + ' ×' + n));

console.log('\n=== spacing 值 top 30 ===');
Object.entries(result.spacing).sort((a, b) => b[1] - a[1]).slice(0, 30).forEach(([k, n]) => console.log(k + ' ×' + n));

console.log('\n=== token 使用次数 ===');
Object.entries(result.varUse).sort((a, b) => b[1] - a[1]).forEach(([k, n]) => console.log('--' + k + ' ×' + n));

/* 未被使用的 token */
const unused = Object.keys(tokens).filter(k => !result.varUse[k] && !['font-serif','font-sans','font-num','tap-min','fs-micro','fs-mini','fs-small','fs-body','fs-title','fs-large','fs-hero','phone-w','phone-h','content-w','ease-out','ease-spring','dur-fast','dur-base','dur-slow'].includes(k));
console.log('\n=== 定义但未直接使用的 token ===');
console.log(unused.join(', ') || '(无)');
