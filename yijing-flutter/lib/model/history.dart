/// 历史记录模型 — 对应易道 localStorage 历史卡
class HistoryRecord {
  final int? hexNo; // 非卦类占法 (八字/小六壬/梅花) 为 null
  final String? name; // 卦名
  final String question;
  final String direction; // 事业/感情/财运
  final String directionColor; // gold/pine/cinnabar
  final String type; // iching/bazi/xlr/meihua
  final DateTime ts;
  final List<bool>? lines; // 卦象 初→上 (仅 iching)
  final List<int>? moving; // 动爻

  const HistoryRecord({
    this.hexNo, this.name, required this.question, required this.direction,
    required this.directionColor, this.type = 'iching',
    required this.ts, this.lines, this.moving,
  });

  HistoryRecord copyWith({DateTime? ts}) => HistoryRecord(
        hexNo: hexNo, name: name, question: question, direction: direction,
        directionColor: directionColor, type: type, ts: ts ?? this.ts,
        lines: lines, moving: moving,
      );

  Map<String, dynamic> toJson() => {
        'hexNo': hexNo,
        'name': name,
        'question': question,
        'direction': direction,
        'directionColor': directionColor,
        'type': type,
        'ts': ts.millisecondsSinceEpoch,
        'lines': lines?.map((y) => y ? 1 : 0).toList(),
        'moving': moving?.toList(),
      };

  /// 容错反序列化 (PWA 数据健壮性原则: 缺字段按默认值渲染不崩溃)
  factory HistoryRecord.fromJson(Map<String, dynamic> j) => HistoryRecord(
        hexNo: j['hexNo'] is int ? j['hexNo'] as int : null,
        name: j['name'] is String ? j['name'] as String : null,
        question: j['question'] is String ? j['question'] as String : '',
        direction: j['direction'] is String ? j['direction'] as String : '事业',
        directionColor: j['directionColor'] is String ? j['directionColor'] as String : 'cinnabar',
        type: j['type'] is String ? j['type'] as String : 'iching',
        ts: j['ts'] is int
            ? DateTime.fromMillisecondsSinceEpoch(j['ts'] as int)
            : DateTime.now(),
        lines: j['lines'] is List
            ? (j['lines'] as List).map((e) => e == 1 || e == true).toList()
            : null,
        moving: j['moving'] is List
            ? (j['moving'] as List).whereType<int>().toList()
            : null,
      );

  String get month {
    final y = ts.year;
    final m = ts.month < 10 ? '0${ts.month}' : '${ts.month}';
    return '$y-$m';
  }

  int get day => ts.day;

  String get methodName => switch (type) {
    'iching' => '易经',
    'bazi' => '八字',
    'xlr' => '小六壬',
    'meihua' => '梅花',
    _ => '易经',
  };
}
