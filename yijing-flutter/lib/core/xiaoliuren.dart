/// 小六壬 — 移植自易道 PWA divination.js XiaoLiuRen (逐位对齐)
/// 农历月/日/时三数, 经典路径法: 大安起数月 → 月宫起数日 → 日宫起数时
library;

import 'lunar_calendar.dart';
import 'yi_calendar.dart' show kZhi;

class XlrPalace {
  final String name;
  final String luck; // 吉/凶
  final String dir; // 吉凶方位
  final String text; // 六宫诗文
  const XlrPalace({required this.name, required this.luck, required this.dir, required this.text});
}

/// 固定次序: 大安→留连→速喜→赤口→小吉→空亡, 循环
const List<XlrPalace> kXlrPalaces = [
  XlrPalace(name: '大安', luck: '吉', dir: '东南', text: '大安事事昌，求谋在东方，失物去不远，宅舍保安康'),
  XlrPalace(name: '留连', luck: '凶', dir: '南', text: '留连事难成，求谋日未明，官事凡宜缓，去者未回程'),
  XlrPalace(name: '速喜', luck: '吉', dir: '南', text: '速喜喜来临，求财向南方，失物申未午，逢人路上寻'),
  XlrPalace(name: '赤口', luck: '凶', dir: '西', text: '赤口主口舌，官非切要防，失物急去寻，行人有惊慌'),
  XlrPalace(name: '小吉', luck: '吉', dir: '东北', text: '小吉最吉昌，路上好商量，阴人来报喜，失物在坤方'),
  XlrPalace(name: '空亡', luck: '凶', dir: '北', text: '空亡事不祥，阴人多乖张，求财无利益，行人有灾殃'),
];

/// 小六壬起课结果
class XiaoLiuRenResult {
  final LunarDate lunar;
  final int shichenIdx; // 0=子 …
  final String shichen; // 子时/丑时…
  final List<String> path; // 月宫/日宫/时宫 名
  final XlrPalace result; // 最终落宫
  final String summary; // 一句话落款

  const XiaoLiuRenResult({
    required this.lunar,
    required this.shichenIdx,
    required this.shichen,
    required this.path,
    required this.result,
    required this.summary,
  });
}

/// 起课: 公历时刻 → 农历月/日 + 时辰三数连算 (PWA divine)
XiaoLiuRenResult? divineXiaoLiuRen(DateTime dt) {
  final lunar = solarToLunar(dt);
  if (lunar == null) return null;
  final sc = shichenIndex(dt);
  // 经典路径法: 从大安(0)起数月 → 月宫; 从月宫起数日 → 日宫; 从日宫起数时 → 时宫
  final monthPalace = (lunar.month - 1) % 6;
  final dayPalace = (monthPalace + lunar.day - 1) % 6;
  final hourPalace = (dayPalace + sc) % 6;
  final hour = kXlrPalaces[hourPalace];
  return XiaoLiuRenResult(
    lunar: lunar,
    shichenIdx: sc,
    shichen: '${kZhi[sc]}时',
    path: [
      kXlrPalaces[monthPalace].name,
      kXlrPalaces[dayPalace].name,
      hour.name,
    ],
    result: hour,
    summary: '农历${lunar.monthLabel}${lunar.dayLabel} ${kZhi[sc]}时，落「${hour.name}」宫',
  );
}
