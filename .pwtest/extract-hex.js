/* iter31: 从易道 data.js 提取 64 卦完整数据 (含卦辞/爻辞/象传) → hex_library.dart */
const fs = require('fs');
const lines = fs.readFileSync('D:/workspace/yijing-app/data.js', 'utf8').split('\n');

/* 1) HEX_LIBRARY: no/name/en/desc/triU/triD/lines/yao */
const libBlock = lines.slice(24, 601).join('\n');
const segs = libBlock.split(/\{\s*no:/).slice(1);

const entries = [];
segs.forEach(seg => {
  const no = parseInt(seg.match(/^(\d+)/)[1], 10);
  const name = seg.match(/name:'([^']+)'/)[1];
  const en = (seg.match(/en:'([^']+)'/) || [])[1] || '';
  const desc = (seg.match(/desc:'([^']+)'/) || [])[1] || '';
  const tri = seg.match(/trigramU:'([^']+)',\s*trigramD:'([^']+)'/);
  const triUN = (seg.match(/trigramUName:'([^']+)'/) || [])[1] || '';
  const triDN = (seg.match(/trigramDName:'([^']+)'/) || [])[1] || '';
  const ls = seg.match(/lines:\[([^\]]*)\]/);
  const yaoBlock = (seg.match(/yao:\[([\s\S]*?)\]\s*\}/) || [])[1] || '';
  /* yao: {n, q, d} × 6 */
  const yao = [];
  const yaoRe = /\{\s*n:'([^']*)',\s*q:'((?:[^'\\]|\\.)*)',\s*d:'((?:[^'\\]|\\.)*)'\s*\}/g;
  let ym;
  while ((ym = yaoRe.exec(yaoBlock)) !== null) {
    yao.push({ n: ym[1], q: ym[2].replace(/\\'/g, "'"), d: ym[3].replace(/\\'/g, "'") });
  }
  if (!no || !name || !tri || !ls) { console.log('skip no', no); return; }
  const lArr = ls[1].split(',').map(s => s.trim().replace(/'/g, ''));
  entries.push({ no, name, en, desc, triU: tri[1], triD: tri[2], triUN, triDN, lines: lArr, yao });
});
console.log('HEX_LIBRARY parsed:', entries.length);
if (entries.length !== 64) { process.exit(1); }
console.log('no1 yao count:', entries[0].yao.length, entries[0].yao.map(y => y.n).join(','));
console.log('no1 guaci field from extra below');

/* 2) HEX_EXTRA: guaci/daxiang/intro (行 605-668 附近) */
const extraStart = lines.findIndex(l => l.trim().startsWith('1:{guaci')) - 1;
let extraBlock = '';
for (let i = extraStart; i < lines.length; i++) {
  extraBlock += lines[i] + '\n';
  if (lines[i].includes('64:{')) break; // 粗定位
}
const extraRe = /(\d+):\{guaci:'((?:[^'\\]|\\.)*)',daxiang:'((?:[^'\\]|\\.)*)',intro:'((?:[^'\\]|\\.)*)'\s*\}/g;
const extras = {};
let em;
while ((em = extraRe.exec(extraBlock)) !== null) {
  extras[parseInt(em[1], 10)] = {
    guaci: em[2].replace(/\\'/g, "'"),
    daxiang: em[3].replace(/\\'/g, "'"),
    intro: em[4].replace(/\\'/g, "'"),
  };
}
console.log('HEX_EXTRA parsed:', Object.keys(extras).length);
if (Object.keys(extras).length !== 64) {
  console.log('extra sample:', JSON.stringify(extras[1]).slice(0, 120));
  process.exit(1);
}

/* 3) 合并生成 Dart */
function esc(s) { return String(s).replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\n/g, ' '); }
const dart = entries.map(h => {
  const ex = extras[h.no] || { guaci: '', daxiang: '', intro: '' };
  const yaoStr = h.yao.map(y => `YaoEntry(n:'${esc(y.n)}', q:'${esc(y.q)}', d:'${esc(y.d)}')`).join(',\n    ');
  const bits = h.lines.map(l => l === 'yang' ? '1' : '0').join('');
  return `  HexEntry(\n`
    + `    no: ${h.no}, name: '${esc(h.name)}', en: '${esc(h.en)}', desc: '${esc(h.desc)}',\n`
    + `    triU: '${h.triU}', triD: '${h.triD}', triUN: '${esc(h.triUN)}', triDN: '${esc(h.triDN)}',\n`
    + `    bits: '${bits}',\n`
    + `    guaci: '${esc(ex.guaci)}', daxiang: '${esc(ex.daxiang)}', intro: '${esc(ex.intro)}',\n`
    + `    yao: [\n    ${yaoStr}\n    ],\n`
    + `  ),`;
}).join('\n');

const out = `// 由易道 data.js 提取自动生成 (iter31) — 64 卦完整数据 (含卦辞/爻辞/象传)
class YaoEntry {
  final String n; // 爻名 初九/六二…
  final String q; // 爻辞原文
  final String d; // 白话解读
  const YaoEntry({required this.n, required this.q, required this.d});
}

class HexEntry {
  final int no;
  final String name;
  final String en;
  final String desc;  // 乾为天 · 刚健中正
  final String triU;  // 上卦符号
  final String triD;  // 下卦符号
  final String triUN; // 上卦自然名 天/地…
  final String triDN;
  final String bits;  // 六爻 初→上 '1'=阳 '0'=阴
  final String guaci;   // 卦辞原文
  final String daxiang; // 大象传
  final String intro;   // 一句话白话解读
  final List<YaoEntry> yao; // 六爻辞

  const HexEntry({
    required this.no, required this.name, required this.en, required this.desc,
    required this.triU, required this.triD, required this.triUN, required this.triDN,
    required this.bits, required this.guaci, required this.daxiang, required this.intro,
    required this.yao,
  });

  List<bool> get yangs => bits.split('').map((c) => c == '1').toList();
  String get virtue => desc.contains('·') ? desc.split('·').last.trim() : '';
  String get title => desc.contains('·') ? desc.split('·').first.trim() : '';
}

const List<HexEntry> kHexLibrary = [
${dart}
];
`;
fs.writeFileSync('D:/workspace/yijing-flutter/lib/data/hex_library.dart', out);
console.log('written hex_library.dart,', out.split('\n').length, 'lines,', out.length, 'chars');
