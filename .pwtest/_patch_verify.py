# -*- coding: utf-8 -*-
# iter34: verify_engine 追加 节气/八字/大运/梅花 验证 (向量来自 node 对拍 PWA)
import io

p = 'tool/verify_engine.dart'
s = io.open(p, encoding='utf-8').read()

s = s.replace("""import 'package:yijing_transform/core/cast_engine.dart';""",
"""import 'package:yijing_transform/core/bazi.dart';
import 'package:yijing_transform/core/cast_engine.dart';
import 'package:yijing_transform/core/dayun.dart';
import 'package:yijing_transform/core/meihua.dart';""")

anchor = """  check('小六壬 六宫次序', kXlrPalaces.map((p) => p.name).join(',') == '大安,留连,速喜,赤口,小吉,空亡');

  print('\\n结果: $pass 通过, $fail 失败');"""

assert anchor in s, 'anchor not found'

addition = """  check('小六壬 六宫次序', kXlrPalaces.map((p) => p.name).join(',') == '大安,留连,速喜,赤口,小吉,空亡');

  // ---- iter34: 分钟级节气表 (solar_terms, PWA terms.js 机械提取) ----
  final lichun2026 = jieList(2026)![1];
  final lichunBj = DateTime.fromMillisecondsSinceEpoch(lichun2026.ts, isUtc: true)
      .add(const Duration(hours: 8));
  check('节气 2026 立春 = 02-04 04:02 (北京)',
      lichun2026.name == '立春' && lichunBj.day == 4 && lichunBj.hour == 4 && lichunBj.minute == 2,
      '${lichunBj.month}-${lichunBj.day} ${lichunBj.hour}:${lichunBj.minute}');
  check('jieIndexAt 立春次日 = 1',
      jieIndexAt(DateTime.utc(2026, 2, 4, 20, 2).millisecondsSinceEpoch) == 1);
  check('jieIndexAt 元旦 = 上年大雪 (11)',
      jieIndexAt(DateTime.utc(2025, 12, 31, 16, 0).millisecondsSinceEpoch) == 11);
  final around0906 = around(DateTime(2026, 9, 6, 10, 30).millisecondsSinceEpoch)!;
  check('around 2026-09-06 = 立秋/白露',
      around0906.prev.name == '立秋' && around0906.next.name == '白露',
      '${around0906.prev.name}/${around0906.next.name}');
  check('ganzhiMonthPrecise 立春界 (北京 02-04 05:00 → 庚寅)',
      ganzhiMonthPrecise(DateTime.utc(2026, 2, 3, 21, 0)) == '庚寅',
      ganzhiMonthPrecise(DateTime.utc(2026, 2, 3, 21, 0)));
  check('ganzhiMonthPrecise 立春前仍丑月 (北京 02-04 03:00 → 己丑)',
      ganzhiMonthPrecise(DateTime.utc(2026, 2, 3, 19, 0)) == '己丑',
      ganzhiMonthPrecise(DateTime.utc(2026, 2, 3, 19, 0)));

  // ---- iter34: 八字 (bazi, PWA divination.js 对拍) ----
  final bz0906 = computeBaZi(DateTime(2026, 9, 6, 10, 30))!;
  check('八字 2026-09-06 10:30 = 丙午 丙申 癸未 丁巳',
      bz0906.pillars.map((p) => p.gz).join(' ') == '丙午 丙申 癸未 丁巳',
      bz0906.pillars.map((p) => p.gz).join(' '));
  check('八字 日支未藏干 = 己七杀/丁偏财/乙食神',
      bz0906.pillars[2].hidden.map((h) => '${h.gan}${h.god}').join('/') == '己七杀/丁偏财/乙食神',
      bz0906.pillars[2].hidden.map((h) => '${h.gan}${h.god}').join('/'));
  check('八字 2026-09-06 火五 偏弱',
      bz0906.wuxing['火'] == 5 && bz0906.strength == '偏弱',
      '$bz0906.strength');
  final bz1990 = computeBaZi(DateTime(1990, 5, 15, 14, 30))!;
  check('八字 1990-05-15 = 庚午 辛巳 庚辰 癸未 偏强',
      bz1990.pillars.map((p) => p.gz).join(' ') == '庚午 辛巳 庚辰 癸未' && bz1990.strength == '偏强',
      '${bz1990.pillars.map((p) => p.gz).join(' ')} ${bz1990.strength}');
  final bz1985 = computeBaZi(DateTime(1985, 12, 3, 23, 10))!;
  check('八字 1985-12-03 夜半子时 = 乙丑 丁亥 丙子 戊子',
      bz1985.pillars.map((p) => p.gz).join(' ') == '乙丑 丁亥 丙子 戊子',
      bz1985.pillars.map((p) => p.gz).join(' '));
  check('十神 甲日主全表',
      tenGod('甲', '乙') == '劫财' && tenGod('甲', '己') == '正财' &&
      tenGod('甲', '庚') == '七杀' && tenGod('甲', '癸') == '正印');
  check('五鼠遁 癸日巳时 = 丁巳', hourPillar('癸', 5) == '丁巳');

  // ---- iter34: 大运流年 (dayun, PWA 对拍) ----
  final dy1990 = analyzeDaYun(DateTime(1990, 5, 15, 14, 30), 'male', now: DateTime(2026, 9, 6))!;
  check('起运 1990 male = 7岁3月@芒种 (顺排)',
      dy1990.forward && dy1990.qiYunInfo!.years == 7 && dy1990.qiYunInfo!.months == 3 &&
      dy1990.qiYunInfo!.termName == '芒种',
      '${dy1990.qiYunInfo!.years}岁${dy1990.qiYunInfo!.months}月@${dy1990.qiYunInfo!.termName}');
  check('大运 1990 = 壬午@7…己丑@77 (8步)',
      dy1990.steps.map((s) => '${s.gz}@${s.startAge}').join(',') ==
      '壬午@7,癸未@17,甲申@27,乙酉@37,丙戌@47,丁亥@57,戊子@67,己丑@77',
      dy1990.steps.map((s) => '${s.gz}@${s.startAge}').join(','));
  final cur2026 = dy1990.steps.expand((s) => s.liuNian).where((l) => l.current).toList();
  check('当前流年 2026 丙午 七杀',
      cur2026.length == 1 && cur2026.single.gz == '丙午' && cur2026.single.god == '七杀');
  final dy2026f = analyzeDaYun(DateTime(2026, 9, 6, 10, 30), 'female', now: DateTime(2026, 9, 6))!;
  check('起运 2026 female = 9岁10月@立秋 (逆排 首运乙未@9)',
      !dy2026f.forward && dy2026f.qiYunInfo!.years == 9 && dy2026f.qiYunInfo!.months == 10 &&
      dy2026f.qiYunInfo!.termName == '立秋' && dy2026f.steps.first.gz == '乙未' &&
      dy2026f.steps.first.startAge == 9,
      dy2026f.steps.first.gz);

  // ---- iter34: 梅花易数 (meihua, PWA 对拍) ----
  final mhTime = meiHuaByTime(DateTime(2026, 9, 6, 10, 30))!;
  check('梅花时间式 2026-09-06 10:30 = 上艮下巽 山风蛊 动三爻',
      mhTime.upper == '艮' && mhTime.lower == '巽' && mhTime.movingIdx == 2 && mhTime.hexNo == 18,
      '${mhTime.upper}${mhTime.lower} no=${mhTime.hexNo}');
  final mhNum = meiHuaByNumbers(3, 8);
  check('梅花数字式 3/8 = 火地晋 动五爻',
      mhNum.upper == '离' && mhNum.lower == '坤' && mhNum.movingIdx == 4 && mhNum.hexNo == 35,
      'no=${mhNum.hexNo}');

  print('\\n结果: $pass 通过, $fail 失败');"""

s = s.replace(anchor, addition)
io.open(p, 'w', encoding='utf-8', newline='').write(s)
print('patched verify_engine')
