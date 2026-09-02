const fs = require('fs');
const path = require('path');
let fail = 0, total = 0;
/* 1) index.html 内联 script (若有) */
const html = fs.readFileSync('D:/workspace/yijing-app/index.html', 'utf8');
const re = /<script(?![^>]*src)[^>]*>([\s\S]*?)<\/script>/gi;
let m;
while ((m = re.exec(html))) {
  total++;
  try { new Function(m[1]); console.log('inline OK (' + m[1].length + ' chars)'); }
  catch (e) { fail++; console.log('inline FAIL: ' + e.message); }
}
/* 2) js/ 模块文件 (iter29 拆分) */
const jsDir = 'D:/workspace/yijing-app/js';
if (fs.existsSync(jsDir)) {
  fs.readdirSync(jsDir).filter(f => f.endsWith('.js')).sort().forEach(f => {
    total++;
    const src = fs.readFileSync(path.join(jsDir, f), 'utf8');
    try { new Function(src); console.log('js/' + f + ' OK (' + src.length + ' chars)'); }
    catch (e) { fail++; console.log('js/' + f + ' FAIL: ' + e.message); }
  });
}
/* 3) 独立数据文件 */
['data.js', 'terms.js', 'divination.js'].forEach(f => {
  total++;
  try { new Function(fs.readFileSync('D:/workspace/yijing-app/' + f, 'utf8')); console.log(f + ' OK'); }
  catch (e) { fail++; console.log(f + ' FAIL: ' + e.message); }
});
console.log(total + ' file(s), ' + fail + ' failure(s)');
process.exit(fail ? 1 : 0);
