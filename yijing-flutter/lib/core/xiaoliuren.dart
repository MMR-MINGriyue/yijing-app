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
  final String askKind; // 问事分类 (谋事/求财/失物/出行/健康/感情)

  const XiaoLiuRenResult({
    required this.lunar,
    required this.shichenIdx,
    required this.shichen,
    required this.path,
    required this.result,
    required this.summary,
    this.askKind = '谋事',
  });

  /// 落宫对该问事的断语 (iter44)
  String get askAdvice => kXlrAdvice[result.name]?[askKind] ?? '';
}

/// 问事分类 (iter44)
const List<String> kXlrAskKinds = ['谋事', '求财', '失物', '出行', '健康', '感情'];

/// 六宫 × 六问 断语 (依各宫吉凶本义撰写; 6×6=36 条)
const Map<String, Map<String, String>> kXlrAdvice = {
  '大安': {
    '谋事': '身安事昌，谋在东方，静待则成。',
    '求财': '财在坤方，固守正业，缓缓自得。',
    '失物': '失物不远，宅舍近处，寻之即见。',
    '出行': '出行平稳，路途无虞，早去早归。',
    '健康': '心安体泰，旧疾渐愈，宜静养。',
    '感情': '家宅安宁，两情相守，长久之象。',
  },
  '留连': {
    '谋事': '事难速成，纠缠反复，宜缓图之。',
    '求财': '财有阻滞，借贷纠缠，暂不宜取。',
    '失物': '失物未远，阴人藏之，急寻难见。',
    '出行': '行程有阻，因事羁留，改期为宜。',
    '健康': '病势缠绵，未可大意，宜调理。',
    '感情': '情有牵扯，藕断丝连，防暗昧事。',
  },
  '速喜': {
    '谋事': '喜信将至，谋事速成，当机立断。',
    '求财': '财向南方，有意外喜，速取可得。',
    '失物': '失物在午申未方，路上逢人可问。',
    '出行': '出行有喜，途中遇贵，行则吉。',
    '健康': '病虽急来亦易去，防虚火，可愈。',
    '感情': '喜讯临门，姻缘可成，宜速定。',
  },
  '赤口': {
    '谋事': '口舌是非，谋事宜慎，防争讼。',
    '求财': '财多争执，因财生非，不宜强求。',
    '失物': '失物急寻，迟则有失，防人隐匿。',
    '出行': '出行有惊，口角是非，结伴而行。',
    '健康': '病主急症，防炎症外伤，速医可解。',
    '感情': '口角相争，两不相让，宜各退步。',
  },
  '小吉': {
    '谋事': '谋事亨通，商量则成，贵人相扶。',
    '求财': '财在坤方，阴人相助，小利可得。',
    '失物': '失物可寻，在坤方阴处，迟几日见。',
    '出行': '出行吉利，路逢好事，平安顺遂。',
    '健康': '病势渐轻，药石有效，安心调养。',
    '感情': '阴人报喜，情意渐浓，好事将近。',
  },
  '空亡': {
    '谋事': '事落空亡，谋多不实，勿强求。',
    '求财': '求财无利，防欺诈空耗，守为上。',
    '失物': '失物难寻，恐不复得，防再失。',
    '出行': '出行不利，恐有灾殃，宜改期。',
    '健康': '病防反复，心神不宁，宜虔心调养。',
    '感情': '情有虚象，言多不实，静观其变。',
  },
};

/// 起课: 公历时刻 → 农历月/日 + 时辰三数连算 (PWA divine; askKind 定问事断语)
XiaoLiuRenResult? divineXiaoLiuRen(DateTime dt, {String askKind = '谋事'}) {
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
    askKind: kXlrAskKinds.contains(askKind) ? askKind : '谋事',
  );
}
