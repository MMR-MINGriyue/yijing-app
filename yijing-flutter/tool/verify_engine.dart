// 引擎 + 屏4数据 + 屏6数据 + 核心历法/起卦 逻辑验证 (纯 Dart, 无 flutter 依赖)
// 运行: flutter/bin/dart run tool/verify_engine.dart
// 说明: ViewModel 测试见 test/ (需 flutter test)
// ignore_for_file: avoid_print
import 'package:yijing_transform/core/bazi.dart';
import 'package:yijing_transform/core/cast_engine.dart';
import 'package:yijing_transform/core/dayun.dart';
import 'package:yijing_transform/core/meihua.dart';
import 'package:yijing_transform/core/solar_terms.dart';
import 'package:yijing_transform/core/lunar_calendar.dart';
import 'package:yijing_transform/core/palace.dart';
import 'package:yijing_transform/core/xiaoliuren.dart';
import 'package:yijing_transform/core/yi_calendar.dart';
import 'package:yijing_transform/data/hex_repository.dart';
import 'package:yijing_transform/data/history_repository.dart';

int pass = 0, fail = 0;
void check(String name, bool ok, [String? detail]) {
  if (ok) {
    pass++;
    print('PASS $name');
  } else {
    fail++;
    print('FAIL $name ${detail ?? ''}');
  }
}

void main() {
  final repo = HexRepository.instance..init();

  // ---- 数据完整性 (新完整数据格式) ----
  check('64 卦加载', repo.hexByNo(64).name == '未济', repo.hexByNo(64).name);
  check('乾全阳', repo.hexByNo(1).yangs.every((y) => y));
  check('坤全阴', repo.hexByNo(2).yangs.every((y) => !y));

  // ---- 屏4 数据 (卦辞/爻辞/象传) ----
  final qian = repo.hexByNo(1);
  check('乾卦辞含元亨利贞', qian.guaci.contains('元'), qian.guaci);
  check('乾大象 = 天行健', qian.daxiang.contains('天行健'), qian.daxiang);
  check('乾 intro 非空', qian.intro.isNotEmpty);
  check('乾 6 爻辞', qian.yao.length == 6, qian.yao.length.toString());
  check('初九爻名/爻辞', qian.yao[0].n == '初九' && qian.yao[0].q.contains('潜龙'),
      '${qian.yao[0].n} ${qian.yao[0].q}');
  check('上九爻辞', qian.yao[5].q.contains('亢龙'), qian.yao[5].q);
  check('desc 拆分 title/virtue', qian.title == '乾为天' && qian.virtue == '刚健中正',
      '${qian.title}|${qian.virtue}');
  check('上卦/下卦自然名', qian.triUN == '天' && qian.triDN == '天');
  check('64 卦都有 6 爻辞', (() {
    for (var i = 1; i <= 64; i++) {
      if (repo.hexByNo(i).yao.length != 6) return false;
    }
    return true;
  })());
  check('64 卦卦辞全非空', (() {
    for (var i = 1; i <= 64; i++) {
      if (repo.hexByNo(i).guaci.isEmpty) return false;
    }
    return true;
  })());
  check('64 卦象传全非空', (() {
    for (var i = 1; i <= 64; i++) {
      if (repo.hexByNo(i).daxiang.isEmpty) return false;
    }
    return true;
  })());

  // ---- 屏5 引擎 (回归) ----
  final r1 = repo.transform(1, [2]);
  check('乾九三动 → 变履', r1.changed.name == '履',
      '${r1.changed.name}/${r1.changed.no}');
  check('互卦乾', r1.hu.name == '乾', r1.hu.name);
  final r2 = repo.transform(2, [0]);
  check('坤初六动 → 变复', r2.changed.name == '复', r2.changed.name);
  final r3 = repo.transform(11, [5]);
  check('泰上爻动 → 用生体大吉',
      r3.relation == '用生体' && r3.verdict == '大吉',
      '${r3.tiName}(${r3.tiWuxing}) ${r3.relation} ${r3.verdict}');
  final r4 = repo.transform(1, []);
  check('乾无动 → 比和吉',
      r4.relation == '比和' && r4.verdict == '吉', '${r4.relation}/${r4.verdict}');
  final r5 = repo.transform(3, [0, 4]);
  check('动爻排序', r5.moving.join(',') == '0,4', r5.moving.join(','));

  // ---- 屏6 历史数据 (repository 层) ----
  final histRepo = HistoryRepository.instance;
  final list = histRepo.load();
  check('历史 mock 数据 ≥ 8 条', list.length >= 8, list.length.toString());
  check('月份范围覆盖上月', histRepo.monthRange().minM <= DateTime.now().month - 1,
      '${histRepo.monthRange().minY}-${histRepo.monthRange().minM}');
  check('本月记录非空', histRepo.ofMonth(DateTime.now().year, DateTime.now().month).isNotEmpty);
  check('含非卦类占法 (type=bazi/xlr)', list.any((r) => r.type == 'bazi') && list.any((r) => r.type == 'xlr'));
  check('含卦象 lines (iching)', list.where((r) => r.type == 'iching').every((r) => r.lines != null && r.lines!.length == 6));
  check('方向覆盖事业/感情/财运', ['事业', '感情', '财运'].every((d) => list.any((r) => r.direction == d)));

  // ---- iter33: 干支历 (yi_calendar, PWA 逐位对齐) ----
  check('JDN 锚点 2026-09-06 = 2461290', jdn(2026, 9, 6) == 2461290, '${jdn(2026, 9, 6)}');
  check('干支纪日 2026-09-06 = 癸未', ganzhiDay(DateTime(2026, 9, 6)) == '癸未', ganzhiDay(DateTime(2026, 9, 6)));
  check('干支纪年 立春界 2026-02-03 = 乙巳', ganzhiYear(DateTime(2026, 2, 3)) == '乙巳', ganzhiYear(DateTime(2026, 2, 3)));
  check('干支纪年 1984-03-01 = 甲子', ganzhiYear(DateTime(1984, 3, 1)) == '甲子', ganzhiYear(DateTime(1984, 3, 1)));
  check('月干支 2026-09-06 = 丙申', ganzhiMonth(DateTime(2026, 9, 6)) == '丙申', ganzhiMonth(DateTime(2026, 9, 6)));
  check('月干支 立春前仍丑月', ganzhiMonth(DateTime(2026, 2, 3)) == '己丑', ganzhiMonth(DateTime(2026, 2, 3)));
  check('时辰 12点 = 午', shichenOf(DateTime(2026, 9, 6, 12)).zhi == '午', shichenOf(DateTime(2026, 9, 6, 12)).zhi);
  check('时辰 23点 = 子', shichenOf(DateTime(2026, 9, 6, 23)).zhi == '子', shichenOf(DateTime(2026, 9, 6, 23)).zhi);

  // ---- iter33: 农历 (lunar_calendar, PWA 逐位对齐) ----
  final cny2024 = solarToLunar(DateTime(2024, 2, 10));
  check('农历 2024 春节 = 2024-02-10 正月初一',
      cny2024 != null && cny2024.year == 2024 && cny2024.month == 1 && cny2024.day == 1,
      '${cny2024?.year}-${cny2024?.month}-${cny2024?.day}');
  final cny2025 = solarToLunar(DateTime(2025, 1, 29));
  check('农历 2025 春节 = 2025-01-29 正月初一',
      cny2025 != null && cny2025.month == 1 && cny2025.day == 1,
      '${cny2025?.year}-${cny2025?.month}-${cny2025?.day}');
  final l0906 = solarToLunar(DateTime(2026, 9, 6));
  check('农历 2026-09-06 = 七月廿五',
      l0906 != null && l0906.month == 7 && l0906.day == 25 && l0906.dayLabel == '廿五',
      '${l0906?.monthLabel}${l0906?.dayLabel}');
  final leap2023 = solarToLunar(DateTime(2023, 3, 22));
  check('农历 2023 闰二月 (2023-03-22 闰二月初一)',
      leap2023 != null && leap2023.isLeap && leap2023.month == 2,
      '${leap2023?.monthLabel}');
  check('农历早于 1900 → null', solarToLunar(DateTime(1899, 12, 31)) == null);
  check('农历晚于表尾 → null', solarToLunar(DateTime(2101, 6, 1)) == null);

  // ---- iter33: 起卦引擎 (cast_engine, PWA 逐位对齐) ----
  check('文本定数 事业 = [4797, 2131]',
      numbersFromText('近期事业运筹方向').join(',') == '4797,2131',
      numbersFromText('近期事业运筹方向').join(','));
  check('文本定数 空 = [662, 5382]', numbersFromText('').join(',') == '662,5382',
      numbersFromText('').join(','));
  check('文本定数 感情 = [7463, 8491]',
      numbersFromText('与TA关系走向').join(',') == '7463,8491',
      numbersFromText('与TA关系走向').join(','));
  final nCast = castByNumbers(3, 8);
  check('数字起卦 3/8 = 晋 (动爻5)', nCast.moving.join(',') == '4' && repo.hexByBits(nCast.lines.map((y) => y ? '1' : '0').join()).no == 35,
      'moving=${nCast.moving}');
  final coinAllYang = castByCoins(rand: () => 0.1);
  check('铜钱 全背 → 六爻老阳动', coinAllYang.lines.every((y) => y) && coinAllYang.moving.length == 6,
      'moving=${coinAllYang.moving.length}');
  final coinAllYin = castByCoins(rand: () => 0.9);
  check('铜钱 全字 → 六爻老阴动', coinAllYin.lines.every((y) => !y) && coinAllYin.moving.length == 6);
  final yinStable = castByYarrow(rand: () => 0.5);
  check('蓍草 0.5 → 少阴 (无动)', yinStable.lines.every((y) => !y) && yinStable.moving.isEmpty);
  check('numeric 起卦可复现', (() {
    final a = cast('numeric', '近期事业运筹方向');
    final b = cast('numeric', '近期事业运筹方向');
    return a.lines.join() == b.lines.join() && a.moving.join(',') == b.moving.join(',');
  })());
  check('时辰卦 hour10 = 泰(11)', hourHex(DateTime(2026, 9, 6, 10)).no == 11);
  check('时辰卦 hour0 = 乾(1)', hourHex(DateTime(2026, 9, 6, 0)).no == 1);
  check('刷新轮换 31 → 32', refreshHex(31).no == 32, 'no=${refreshHex(31).no}');

  // ---- iter33: 京房八宫 (palace) ----
  check('八宫 64 卦全覆盖', kPalaces.length == 64, '${kPalaces.length}');
  check('八宫各 8 卦', (() {
    final counts = <String, int>{};
    for (final info in kPalaces.values) {
      counts[info.palace] = (counts[info.palace] ?? 0) + 1;
    }
    return counts.length == 8 && counts.values.every((c) => c == 8);
  })());
  check('乾宫 = 乾姤遯否观剥晋大有',
      palaceMembers('乾宫').join(',') == '1,44,33,12,20,23,35,14',
      palaceMembers('乾宫').join(','));
  check('坎宫主 29 坎宫', palaceOf(29)!.palace == '坎宫' && palaceOf(29)!.stage == '本宫');
  check('兑宫主 58', palaceOf(58)!.palace == '兑宫' && palaceOf(58)!.head == 58);

  // ---- iter33: 小六壬 (xiaoliuren, PWA 逐位对齐) ----
  final xlr1 = divineXiaoLiuRen(DateTime(2026, 9, 6, 10));
  check('小六壬 2026-09-06 巳时 → 大安/大安/空亡',
      xlr1 != null && xlr1.path.join(',') == '大安,大安,空亡' && xlr1.shichen == '巳时',
      xlr1?.path.join(','));
  final xlr2 = divineXiaoLiuRen(DateTime(2024, 2, 10, 0, 30));
  check('小六壬 2024 春节 子时 → 全大安',
      xlr2 != null && xlr2.path.join(',') == '大安,大安,大安', xlr2?.path.join(','));
  check('小六壬 六宫次序', kXlrPalaces.map((p) => p.name).join(',') == '大安,留连,速喜,赤口,小吉,空亡');

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
  check('中文数字 cnNumber 1/10/20/64',
      cnNumber(1) == '一' && cnNumber(10) == '十' && cnNumber(20) == '二十' && cnNumber(64) == '六十四',
      cnNumber(64));
    check('梅花数字式 3/8 = 火地晋 动五爻',
      mhNum.upper == '离' && mhNum.lower == '坤' && mhNum.movingIdx == 4 && mhNum.hexNo == 35,
      'no=${mhNum.hexNo}');
  final mhDui = meiHuaByNumbers(2, 2);
  check('梅花数字式 2/2 = 兑为泽 (兑三爻回归)',
      mhDui.hexNo == 58 && mhDui.lines[0] && mhDui.lines[1] && !mhDui.lines[2],
      'no=${mhDui.hexNo} lines=${mhDui.lines}');

  print('\n结果: $pass 通过, $fail 失败');
  if (fail > 0) { throw StateError('$fail 项失败'); }
}
