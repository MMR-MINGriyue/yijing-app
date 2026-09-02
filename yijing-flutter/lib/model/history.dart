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
