import '../data/hex_library.dart';

/// 卦模型 — 由 HexEntry 派生, 提供显示辅助
class Hex {
  final int no;
  final String name;
  final String triU;
  final String triD;
  final List<bool> yangs; // 初→上

  Hex({required this.no, required this.name, required this.triU, required this.triD, required List<bool> yangs})
      : yangs = List.unmodifiable(yangs);

  factory Hex.fromEntry(HexEntry e) => Hex(
        no: e.no, name: e.name, triU: e.triU, triD: e.triD, yangs: e.yangs);

  bool isYang(int i) => yangs[i];
  String yaoName(int i) {
    const pos = ['初', '二', '三', '四', '五', '上'];
    final nine = yangs[i] ? '九' : '六';
    return (i == 0 || i == 5) ? pos[i] + nine : nine + pos[i];
  }

  /// 上三爻 / 下三爻
  List<bool> get upper => yangs.sublist(3);
  List<bool> get lower => yangs.sublist(0, 3);
}

/// 八卦名称映射
const Map<String, String> kTriName = {
  '☰': '乾', '☱': '兑', '☲': '离', '☳': '震',
  '☴': '巽', '☵': '坎', '☶': '艮', '☷': '坤',
};
const Map<String, String> kTriWuxing = {
  '☰': '金', '☱': '金', '☲': '火', '☳': '木',
  '☴': '木', '☵': '水', '☶': '土', '☷': '土',
};
const Map<String, String> kTriNature = {
  '☰': '天', '☱': '泽', '☲': '火', '☳': '雷',
  '☴': '风', '☵': '水', '☶': '山', '☷': '地',
};

/// 变卦推演结果 (对应易道 YijingEngine.transform)
class TransformResult {
  final Hex ben;      // 本卦
  final Hex changed;  // 变卦
  final Hex hu;       // 互卦
  final List<int> moving; // 动爻索引 (0=初 … 5=上)
  final String tiName;    // 体卦名 (乾/坤…)
  final String tiWuxing;  // 体卦五行
  final String yongName;
  final String yongWuxing;
  final String relation; // 比和/用生体/用克体/体克用/体生用
  final String verdict;  // 吉/凶…
  final String verdictText;

  TransformResult({
    required this.ben, required this.changed, required this.hu,
    required this.moving, required this.tiName, required this.tiWuxing,
    required this.yongName, required this.yongWuxing,
    required this.relation, required this.verdict, required this.verdictText,
  });
}

/// 爻变明细行 (推演视图)
class YaoChange {
  final int idx;
  final String from;
  final String to;
  final bool fromYang;
  YaoChange({required this.idx, required this.from, required this.to, required this.fromYang});
}
