import '../data/hex_library.dart';
import '../model/hex.dart';

/// Repository — 数据访问 + 推演引擎 (对应易道 YijingEngine.transform)
class HexRepository {
  HexRepository._();
  static final HexRepository instance = HexRepository._();

  final Map<int, Hex> _byNo = {};
  final Map<String, Hex> _byBits = {};

  void init() {
    for (final e in kHexLibrary) {
      final h = Hex.fromEntry(e);
      _byNo[h.no] = h;
      _byBits[h.yangs.map((y) => y ? '1' : '0').join()] = h;
    }
  }

  Hex hexByNo(int no) => _byNo[no] ?? _byNo[1]!;

  Hex hexByBits(String bits) => _byBits[bits] ?? _byNo[1]!;

  Hex flipYao(Hex hex, List<int> moving) {
    final flipped = hex.yangs.toList();
    for (final i in moving) {
      if (i >= 0 && i < 6) flipped[i] = !flipped[i];
    }
    return hexByBits(flipped.map((y) => y ? '1' : '0').join());
  }

  /// 三爻 → 八卦符号 (初→上)
  String triOfLines(List<bool> three) {
    const map = {
      '111': '☰', '110': '☱', '101': '☲', '100': '☳',
      '011': '☴', '010': '☵', '001': '☶', '000': '☷',
    };
    final key = three.map((y) => y ? '1' : '0').join();
    return map[key] ?? '☰';
  }

  /// 变卦推演 (动爻取反 → 变卦; 互卦 2-4/3-5 爻; 体用生克)
  TransformResult transform(int benNo, List<int> moving) {
    final ben = hexByNo(benNo);
    final mv = moving.where((i) => i >= 0 && i < 6).toSet().toList()..sort();

    final changed = flipYao(ben, mv);

    // 互卦: 二三四爻为下卦, 三四五爻为上卦
    final huLower = triOfLines([ben.yangs[1], ben.yangs[2], ben.yangs[3]]);
    final huUpper = triOfLines([ben.yangs[2], ben.yangs[3], ben.yangs[4]]);
    Hex? hu;
    for (final h in _byNo.values) {
      if (h.triU == huUpper && h.triD == huLower) { hu = h; break; }
    }
    hu ??= ben;

    // 体用: 动爻多的三爻卦为用, 另一方为体; 平手下卦为体
    final upperMv = mv.where((i) => i >= 3).length;
    final lowerMv = mv.where((i) => i < 3).length;
    String tiTri, yongTri;
    if (mv.isEmpty)      { tiTri = ben.triD; yongTri = ben.triU; }
    else if (upperMv > lowerMv) { yongTri = ben.triU; tiTri = ben.triD; }
    else if (lowerMv > upperMv) { yongTri = ben.triD; tiTri = ben.triU; }
    else                        { tiTri = ben.triD; yongTri = ben.triU; }

    final tiWx = kTriWuxing[tiTri]!;
    final yongWx = kTriWuxing[yongTri]!;
    const sheng = {'金': '水', '水': '木', '木': '火', '火': '土', '土': '金'};
    const ke = {'金': '木', '木': '土', '土': '水', '水': '火', '火': '金'};
    String relation, verdict, verdictText;
    if (yongWx == tiWx)             { relation = '比和';   verdict = '吉';   verdictText = '同气相应，人心相合，事易成。'; }
    else if (sheng[yongWx] == tiWx) { relation = '用生体'; verdict = '大吉'; verdictText = '外有助力，贵人扶持，顺势而成。'; }
    else if (ke[yongWx] == tiWx)    { relation = '用克体'; verdict = '凶';   verdictText = '外有阻力，事多牵制，宜守不宜进。'; }
    else if (ke[tiWx] == yongWx)    { relation = '体克用'; verdict = '小吉'; verdictText = '事可成而费力，须主动掌控。'; }
    else                            { relation = '体生用'; verdict = '平';   verdictText = '耗损精神财物，宜量力而行。'; }

    return TransformResult(
      ben: ben, changed: changed, hu: hu, moving: mv,
      tiName: kTriName[tiTri]!, tiWuxing: tiWx,
      yongName: kTriName[yongTri]!, yongWuxing: yongWx,
      relation: relation, verdict: verdict, verdictText: verdictText,
    );
  }
}
