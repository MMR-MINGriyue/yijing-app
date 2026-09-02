/* 从易道 data.js 提取 64 卦核心数据 → Dart map 文件 (v2: 按行号截取) */
const fs = require('fs');
const lines = fs.readFileSync('D:/workspace/yijing-app/data.js', 'utf8').split('\n');
/* HEX_LIBRARY 从第 25 行开始 (1-based), 数组闭合行 = 602 */
const block = lines.slice(24, 601).join('\n');

const entries = [];
const segs = block.split(/\{\s*no:/).slice(1);
segs.forEach(seg => {
  const no = parseInt(seg.match(/^(\d+)/)[1], 10);
  const name = seg.match(/name:'([^']+)'/);
  const tri = seg.match(/trigramU:'([^']+)',\s*trigramD:'([^']+)'/);
  const ls = seg.match(/lines:\[([^\]]*)\]/);
  if (!no || !name || !tri || !ls) return;
  const lArr = ls[1].split(',').map(s => s.trim().replace(/'/g, ''));
  entries.push({ no, name: name[1], triU: tri[1], triD: tri[2], lines: lArr });
});
console.log('parsed', entries.length, 'hexagrams');
if (entries.length !== 64) { console.error('expected 64, got', entries.length); process.exit(1); }
console.log('first:', JSON.stringify(entries[0]).slice(0, 120));
console.log('last:', JSON.stringify(entries[63]).slice(0, 120));

const dart = entries.map(h => {
  const bits = h.lines.map(l => l === 'yang' ? '1' : '0').join('');
  return `  const HexEntry(no: ${h.no}, name: '${h.name}', triU: '${h.triU}', triD: '${h.triD}', bits: '${bits}'),`;
}).join('\n');

const out = `// 由易道 data.js 提取自动生成 (iter30) — 64 卦核心数据
class HexEntry {
  final int no;
  final String name;
  final String triU; // 上卦符号
  final String triD; // 下卦符号
  final String bits; // 六爻 初→上, '1'=阳 '0'=阴
  const HexEntry({required this.no, required this.name, required this.triU, required this.triD, required this.bits});
  List<bool> get yangs => bits.split('').map((c) => c == '1').toList();
}

const List<HexEntry> kHexLibrary = [
${dart}
];
`;
fs.writeFileSync('D:/workspace/yijing-flutter/lib/data/hex_library.dart', out);
console.log('written lib/data/hex_library.dart,', out.split('\n').length, 'lines');
