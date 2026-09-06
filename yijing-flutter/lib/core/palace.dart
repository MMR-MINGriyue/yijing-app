/// 京房八宫 — 移植自易道 PWA data.js YijingEngine PALACES (逐位对齐)
/// 宫主纯卦按爻变序列生成每宫 8 卦: 本宫→一世…五世→游魂→归魂
library;

import '../data/hex_library.dart';

class PalaceInfo {
  final String palace; // 乾宫/坎宫…
  final String stage; // 本宫/一世…/游魂/归魂
  final int index; // 0..7 (宫内世位)
  final int head; // 宫主卦序
  const PalaceInfo({required this.palace, required this.stage, required this.index, required this.head});
}

const List<String> kPalaceOrder = ['☰', '☵', '☶', '☳', '☴', '☲', '☷', '☱'];
const List<String> kPalaceNames = ['乾宫', '坎宫', '艮宫', '震宫', '巽宫', '离宫', '坤宫', '兑宫'];
const List<String> kPalaceStages = ['本宫', '一世', '二世', '三世', '四世', '五世', '游魂', '归魂'];
const List<List<int>> _kPalaceFlips = [
  [], [0], [0, 1], [0, 1, 2], [0, 1, 2, 3], [0, 1, 2, 3, 4], [0, 1, 2, 4], [4],
];

String _bitsOf(HexEntry h) => h.yangs.map((y) => y ? '1' : '0').join();

String _flipKey(HexEntry head, List<int> flips) {
  final bits = _bitsOf(head).split('');
  for (final i in flips) {
    bits[i] = bits[i] == '1' ? '0' : '1';
  }
  return bits.join();
}

final Map<int, PalaceInfo> kPalaces = _build();

Map<int, PalaceInfo> _build() {
  final map = <int, PalaceInfo>{};
  for (var pi = 0; pi < kPalaceOrder.length; pi++) {
    final tri = kPalaceOrder[pi];
    HexEntry? head;
    for (final h in kHexLibrary) {
      if (h.triU == tri && h.triD == tri) {
        head = h;
        break;
      }
    }
    if (head == null) continue;
    for (var si = 0; si < _kPalaceFlips.length; si++) {
      final key = _flipKey(head, _kPalaceFlips[si]);
      for (final h in kHexLibrary) {
        if (_bitsOf(h) == key) {
          map[h.no] = PalaceInfo(
            palace: kPalaceNames[pi],
            stage: kPalaceStages[si],
            index: si,
            head: head.no,
          );
          break;
        }
      }
    }
  }
  return map;
}

PalaceInfo? palaceOf(int no) => kPalaces[no];

/// 某宫 8 卦按 本宫→归魂 顺序
List<int> palaceMembers(String palaceName) {
  final list = <int>[];
  kPalaces.forEach((no, info) {
    if (info.palace == palaceName) list.add(no);
  });
  list.sort((a, b) => kPalaces[a]!.index.compareTo(kPalaces[b]!.index));
  return list;
}
