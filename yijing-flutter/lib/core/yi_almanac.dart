/// 今日黄历 (iter54) — 节气进度 + 日辰宜忌 + 今日四柱
/// 宜忌为通书式参考: 依日干五行取用, 非权威黄历.
library;

import 'bazi.dart';
import 'lunar_calendar.dart';
import 'solar_terms.dart';
import 'yi_calendar.dart';

class AlmanacInfo {
  final String termName; // 当前节气
  final int termDayIndex; // 节气第几日 (1-based)
  final String nextTermName;
  final int daysToNext; // 距下一节气天数 (向上取整)
  final List<String> yi;
  final List<String> ji;
  final String yearGz, monthGz, dayGz, hourGz;
  final String dayElement; // 日干五行

  const AlmanacInfo({
    required this.termName,
    required this.termDayIndex,
    required this.nextTermName,
    required this.daysToNext,
    required this.yi,
    required this.ji,
    required this.yearGz,
    required this.monthGz,
    required this.dayGz,
    required this.hourGz,
    required this.dayElement,
  });
}

/// 日干五行 → 宜忌 (通书式简明规则, 各二)
const Map<String, List<List<String>>> _kYiJi = {
  '木': [['谋划', '立约', '学习'], ['争讼', '动怒']],
  '火': [['文书', '社交', '纳财'], ['急断', '冒进']],
  '土': [['置业', '迁居', '修造'], ['远行', ' 泅水']],
  '金': [['决断', '整肃', '收敛'], ['宴饮', '轻诺']],
  '水': [['出行', '贸易', '通渠'], ['立约', '动土']],
};

AlmanacInfo almanacOf(DateTime now) {
  // 节气进度 (around 为空时回退立春)
  final a = around(now.millisecondsSinceEpoch);
  final prev = a?.prev;
  final next = a?.next;
  final termName = prev?.name ?? '立春';
  final nextName = next?.name ?? '惊蛰';
  final prevTs = prev?.ts ?? DateTime(now.year, 2, 4).millisecondsSinceEpoch;
  final nextTs = next?.ts ??
      DateTime(now.year, 3, 5).millisecondsSinceEpoch;
  final dayMs = 86400000;
  final termDayIndex =
      ((now.millisecondsSinceEpoch - prevTs) ~/ dayMs + 1).clamp(1, 40);
  final daysToNext =
      ((nextTs - now.millisecondsSinceEpoch + dayMs - 1) ~/ dayMs).clamp(1, 40);

  // 四柱 (今日)
  final yGz = ganzhiYear(now);
  final mGz = ganzhiMonthPrecise(now);
  final dGz = ganzhiDay(now);
  final hGz = hourPillar(dGz[0], shichenIndex(now));
  final el = kGanWuxing[dGz[0]] ?? '木';
  final rule = _kYiJi[el] ?? const [['谋划'], ['静守']];

  return AlmanacInfo(
    termName: termName,
    termDayIndex: termDayIndex,
    nextTermName: nextName,
    daysToNext: daysToNext,
    yi: rule[0].take(2).toList(),
    ji: rule[1].take(2).toList(),
    yearGz: yGz,
    monthGz: mGz,
    dayGz: dGz,
    hourGz: hGz,
    dayElement: el,
  );
}
