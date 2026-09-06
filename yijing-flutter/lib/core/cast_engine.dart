/// 起卦引擎 — 移植自易道 PWA data.js YijingEngine 起卦部分 (逐位对齐)
/// 三式: 铜钱 / 蓍草 / 数字 (梅花先天数) + 问题文本定数
library;

import 'dart:math';

import '../data/hex_library.dart';

/// 一卦起卦结果
class CastResult {
  final List<bool> lines; // 六爻 初→上, true=阳
  final List<int> moving; // 动爻索引 (0=初 … 5=上)
  final List<List<int>>? tosses; // 铜钱三枚明细 (1=背, 0=字), 供动画
  final String method; // coin/yarrow/numeric

  const CastResult({
    required this.lines,
    required this.moving,
    this.tosses,
    required this.method,
  });
}

/// 先天八卦数: 乾1 兑2 离3 震4 巽5 坎6 艮7 坤8
const Map<String, int> kXiantian = {
  '☰': 1, '☱': 2, '☲': 3, '☳': 4,
  '☴': 5, '☵': 6, '☶': 7, '☷': 8,
};

/// 由三枚铜钱背面数定爻: 3背=老阳(动), 2背=少阴, 1背=少阳, 0背=老阴(动)
CastResult castByCoins({double Function()? rand}) {
  final rnd = rand ?? _defaultRand;
  final lines = <bool>[];
  final moving = <int>[];
  final tosses = <List<int>>[];
  for (var i = 0; i < 6; i++) {
    final faces = <int>[];
    var backs = 0;
    for (var k = 0; k < 3; k++) {
      final b = rnd() < 0.5;
      faces.add(b ? 1 : 0);
      if (b) backs++;
    }
    tosses.add(faces);
    if (backs == 3) {
      lines.add(true);
      moving.add(i);
    } else if (backs == 2) {
      lines.add(false);
    } else if (backs == 1) {
      lines.add(true);
    } else {
      lines.add(false);
      moving.add(i);
    }
  }
  return CastResult(lines: lines, moving: moving, tosses: tosses, method: 'coin');
}

/// 蓍草起卦 (大衍之法): 老阳9=3/16 少阴8=7/16 少阳7=5/16 老阴6=1/16
CastResult castByYarrow({double Function()? rand}) {
  final rnd = rand ?? _defaultRand;
  final lines = <bool>[];
  final moving = <int>[];
  for (var i = 0; i < 6; i++) {
    final r = rnd();
    if (r < 3 / 16) {
      lines.add(true);
      moving.add(i);
    } else if (r < 10 / 16) {
      lines.add(false);
    } else if (r < 15 / 16) {
      lines.add(true);
    } else {
      lines.add(false);
      moving.add(i);
    }
  }
  return CastResult(lines: lines, moving: moving, method: 'yarrow');
}

/// 数字起卦 (梅花易数 · 先天数): 上卦=数1 mod 8, 下卦=数2 mod 8, 动爻=(数1+数2) mod 6
CastResult castByNumbers(int n1, int n2) {
  final a = n1.abs() == 0 ? 1 : n1.abs();
  final b = n2.abs() == 0 ? 1 : n2.abs();
  final upper = a % 8 == 0 ? 8 : a % 8;
  final lower = b % 8 == 0 ? 8 : b % 8;
  final mv = (a + b) % 6 == 0 ? 6 : (a + b) % 6;

  HexEntry? hex;
  for (final h in kHexLibrary) {
    if (kXiantian[h.triU] == upper && kXiantian[h.triD] == lower) {
      hex = h;
      break;
    }
  }
  hex ??= kHexLibrary.first;
  return CastResult(
    lines: hex.yangs,
    moving: [mv - 1],
    method: 'numeric',
  );
}

/// 由问题文本派生两个定数 (FNV-1a + DJB2 双哈希, UTF-16 码元)
/// 与 PWA numbersFromText 逐位一致 (示例: '近期事业运筹方向' → [4797, 2131]).
/// 注意 JS 语义三坑: ① `^` 是 Int32 有符号异或; ② `*` 是 double 乘
/// (|积| > 2^53 时 53 位舍入, 与精确整数模 2^32 不同); ③ `>>>0` 对负数取 mod 2^32.
List<int> numbersFromText(String text) {
  var h1 = 2166136261;
  var h2 = 5381;
  for (var i = 0; i < text.length; i++) {
    final c = text.codeUnitAt(i);
    // h1: Int32 异或 → 浮点乘舍入 → 截断 → 取低 32 位
    final xored = h1.toSigned(32) ^ c;
    h1 = (xored * 16777619).toDouble().truncate() & 0xFFFFFFFF;
    // h2: (h2<<5)+h2+c < 2^38, double 精确, mod 2^32 与位掩码等价
    h2 = ((h2 << 5) + h2 + c) & 0xFFFFFFFF;
  }
  return [h1 % 9973 + 1, h2 % 9973 + 1];
}

/// 统一入口: method = numeric / yarrow / coin (numeric 由问题文本派生定数)
CastResult cast(String method, String question, {double Function()? rand}) {
  if (method == 'yarrow') return castByYarrow(rand: rand);
  if (method == 'coin') return castByCoins(rand: rand);
  final n = numbersFromText(question);
  return castByNumbers(n[0], n[1]);
}

/// 中文数字 (PWA cnNumber): 1→一 10→十 15→十五 20→二十 64→六十四
const List<String> _kCn = ['零', '一', '二', '三', '四', '五', '六', '七', '八', '九'];

String cnNumber(int n) {
  if (n <= 10) return n == 10 ? '十' : _kCn[n];
  if (n < 20) return '十${_kCn[n - 10]}';
  final s = _kCn[n ~/ 10];
  final g = n % 10;
  return '$s十${g > 0 ? _kCn[g] : ''}';
}

/// 今日一卦: 时辰卦 — HEX_LIBRARY[hour % 16] (PWA 02-home-cast.js getByHour)
HexEntry hourHex(DateTime dt) => kHexLibrary[dt.hour % 16];

/// 刷新轮换: 第 n 次刷新 → HEX_LIBRARY[n % 64] (PWA getByRefresh)
HexEntry refreshHex(int refreshCount) =>
    kHexLibrary[refreshCount % kHexLibrary.length];

final Random _rng = Random();

double _defaultRand() => _rng.nextDouble();
