const fs = require('fs');
const html = fs.readFileSync('D:/workspace/yijing-app/index.html', 'utf8');
const re = /<script(?![^>]*src)[^>]*>([\s\S]*?)<\/script>/gi;
let m, i = 0, fail = 0;
while ((m = re.exec(html))) {
  i++;
  try { new Function(m[1]); console.log('script #' + i + ' OK (' + m[1].length + ' chars)'); }
  catch (e) { fail++; console.log('script #' + i + ' FAIL: ' + e.message); }
}
console.log(i + ' inline script(s), ' + fail + ' failure(s)');
process.exit(fail ? 1 : 0);
