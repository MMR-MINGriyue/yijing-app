import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/core/bazi.dart';
import 'package:yijing_transform/core/dayun.dart';
import 'package:yijing_transform/core/meihua.dart';
import 'package:yijing_transform/core/solar_terms.dart';
import 'package:yijing_transform/core/yi_calendar.dart';

/// iter34 — 八字/大运/节气/梅花 测试
/// 参考向量: 用 node 直接运行 PWA divination.js + terms.js 对拍得出 (逐位对齐)
void main() {
  group('SolarTerms — 分钟级节气表 (PWA terms.js 逐位对齐)', () {
    test('2026 节气精确时刻', () {
      final l = jieList(2026)!;
      // 立春 2026-02-04 04:02 北京时间
      final lichun = DateTime.fromMillisecondsSinceEpoch(l[1].ts, isUtc: true)
          .add(const Duration(hours: 8));
      expect(l[1].name, '立春');
      expect('${lichun.year}-${lichun.month}-${lichun.day} ${lichun.hour}:${lichun.minute}',
          '2026-2-4 4:2');
      // 白露 2026-09-07 22:41 北京时间
      final bailu = DateTime.fromMillisecondsSinceEpoch(l[8].ts, isUtc: true)
          .add(const Duration(hours: 8));
      expect(l[8].name, '白露');
      expect(bailu.day, 7);
      expect(bailu.hour, 22);
    });

    test('jieIndexAt 落节判断', () {
      // 2026-02-05 00:00 北京 = 立春(02-04 04:02)后 → idx 1
      final tsAfterLichun = DateTime.utc(2026, 2, 4, 20, 2).millisecondsSinceEpoch;
      expect(jieIndexAt(tsAfterLichun), 1);
      // 2026-02-03 → 小寒之内 → idx 0
      final tsBeforeLichun = DateTime.utc(2026, 2, 2, 0, 0).millisecondsSinceEpoch;
      expect(jieIndexAt(tsBeforeLichun), 0);
      // 2026-01-01 00:00 北京 → 早于当年小寒, ≥ 上年大雪 → 11
      final tsNewYear = DateTime.utc(2025, 12, 31, 16, 0).millisecondsSinceEpoch;
      expect(jieIndexAt(tsNewYear), 11);
    });

    test('around: 前后节', () {
      final a = around(DateTime(2026, 9, 6, 10, 30).millisecondsSinceEpoch)!;
      expect(a.prev.name, '立秋');
      expect(a.next.name, '白露');
      final b = around(DateTime(1990, 5, 15, 14, 30).millisecondsSinceEpoch)!;
      expect(b.prev.name, '立夏');
      expect(b.next.name, '芒种');
    });

    test('ganzhiMonthPrecise 边界: 立春当日 04:02 前后换月柱', () {
      // 北京时刻 T = DateTime.utc(T 的 UTC 值): 北京 02-04 03:00 = UTC 02-03 19:00
      final before = DateTime.utc(2026, 2, 3, 19, 0); // 北京 02-04 03:00, 立春前
      expect(ganzhiMonthPrecise(before), '己丑');
      final after = DateTime.utc(2026, 2, 3, 21, 0); // 北京 02-04 05:00, 立春后
      expect(ganzhiMonthPrecise(after), '庚寅');
    });
  });

  group('BaZi — 四柱排盘 (PWA 对拍向量)', () {
    test('2026-09-06 10:30 → 丙午 丙申 癸未 丁巳', () {
      final c = computeBaZi(DateTime(2026, 9, 6, 10, 30))!;
      expect(c.pillars.map((p) => p.gz).join(' '), '丙午 丙申 癸未 丁巳');
      expect(c.pillars[2].ganGod, '日主');
      expect(c.pillars[3].ganGod, '偏财');
      expect(c.wuxing['火'], 5);
      expect(c.strength, '偏弱');
      expect(c.shichen, '巳时');
      // 藏干十神: 日支未 → 己七杀/丁偏财/乙食神
      expect(c.pillars[2].hidden.map((h) => '${h.gan}${h.god}').join('/'),
          '己七杀/丁偏财/乙食神');
    });

    test('1990-05-15 14:30 male → 庚午 辛巳 庚辰 癸未 偏强', () {
      final c = computeBaZi(DateTime(1990, 5, 15, 14, 30))!;
      expect(c.pillars.map((p) => p.gz).join(' '), '庚午 辛巳 庚辰 癸未');
      expect(c.pillars.map((p) => p.ganGod).join(','), '比肩,劫财,日主,伤官');
      expect(c.wuxing.values.join(','), '0,2,2,3,1'); // 木火土金水
      expect(c.strength, '偏强');
    });

    test('1985-12-03 23:10 → 乙丑 丁亥 丙子 戊子 (夜半子时)', () {
      final c = computeBaZi(DateTime(1985, 12, 3, 23, 10))!;
      expect(c.pillars.map((p) => p.gz).join(' '), '乙丑 丁亥 丙子 戊子');
      expect(c.strength, '中和');
    });

    test('2000-02-04 06:00 → 庚辰 丁丑 壬辰 癸卯 (立春当晨仍丑月)', () {
      final c = computeBaZi(DateTime(2000, 2, 4, 6, 0))!;
      // 立春 2000-02-04 08:40? 06:00 属立春前 → 月柱仍丑
      expect(c.pillars.map((p) => p.gz).join(' '), '庚辰 丁丑 壬辰 癸卯');
    });

    test('十神: 五类生克方向', () {
      // 日主甲(木): 乙=劫财, 丙=食神, 丁=伤官, 戊=偏财, 己=正财, 庚=七杀, 辛=正官, 壬=偏印, 癸=正印
      expect(tenGod('甲', '甲'), '比肩');
      expect(tenGod('甲', '乙'), '劫财');
      expect(tenGod('甲', '丙'), '食神');
      expect(tenGod('甲', '丁'), '伤官');
      expect(tenGod('甲', '戊'), '偏财');
      expect(tenGod('甲', '己'), '正财');
      expect(tenGod('甲', '庚'), '七杀');
      expect(tenGod('甲', '辛'), '正官');
      expect(tenGod('甲', '壬'), '偏印');
      expect(tenGod('甲', '癸'), '正印');
    });

    test('五鼠遁时柱', () {
      // 甲己日起甲子; 戊癸日起壬子 (癸日巳时 = 丁巳)
      expect(hourPillar('甲', 0), '甲子');
      expect(hourPillar('癸', 5), '丁巳');
      expect(hourPillar('庚', 6), '壬午');
    });
  });

  group('DaYun — 起运 + 大运 + 流年 (PWA 对拍向量)', () {
    test('1990-05-15 male: 顺排, 7岁3月起@芒种, 首运壬午@7', () {
      final d = analyzeDaYun(DateTime(1990, 5, 15, 14, 30), 'male',
          now: DateTime(2026, 9, 6))!;
      expect(d.forward, isTrue);
      expect(d.qiYunInfo!.years, 7);
      expect(d.qiYunInfo!.months, 3);
      expect(d.qiYunInfo!.termName, '芒种');
      expect(d.steps.map((s) => '${s.gz}@${s.startAge}').join(','),
          '壬午@7,癸未@17,甲申@27,乙酉@37,丙戌@47,丁亥@57,戊子@67,己丑@77');
      // 当前流年 2026 丙午 七杀
      final cur = d.steps.expand((s) => s.liuNian).where((l) => l.current).toList();
      expect(cur.length, 1);
      expect(cur.single.year, 2026);
      expect(cur.single.gz, '丙午');
      expect(cur.single.god, '七杀');
    });

    test('2026-09-06 female: 逆排 (阳女), 9岁10月起@立秋, 2026 无当前流年', () {
      final d = analyzeDaYun(DateTime(2026, 9, 6, 10, 30), 'female',
          now: DateTime(2026, 9, 6))!;
      expect(d.forward, isFalse);
      expect(d.qiYunInfo!.years, 9);
      expect(d.qiYunInfo!.months, 10);
      expect(d.qiYunInfo!.termName, '立秋');
      expect(d.steps.first.gz, '乙未');
      expect(d.steps.first.startAge, 9);
      // 出生当日: 所有大运都未开始 → 无当前流年
      expect(d.steps.expand((s) => s.liuNian).where((l) => l.current), isEmpty);
    });

    test('流年断语结构 (冲合刑 + 岁运关系)', () {
      final d = analyzeDaYun(DateTime(1990, 5, 15, 14, 30), 'male',
          now: DateTime(2026, 9, 6))!;
      // 2026 ∈ 第三步大运 甲申@27 (2017-2026)
      final ln2026 =
          d.steps.expand((s) => s.liuNian).firstWhere((l) => l.year == 2026);
      expect(ln2026.god, '七杀');
      // 断语结构: 十神主事 + 冲合刑事件 + 岁运关系 (丙火遇庚日主金: 七杀; 午合未? 时支未: 午未合)
      expect(ln2026.text, contains('七杀攻身'));
      expect(ln2026.text, contains('运生岁'));
    });
  });

  group('MeiHua — 梅花易数 (PWA 对拍向量)', () {
    test('时间式 2026-09-06 10:30 → 上艮下巽 = 山风蛊, 动三爻', () {
      final r = meiHuaByTime(DateTime(2026, 9, 6, 10, 30))!;
      // 年支序午6 + 1 + 月7 + 日25 = 39 → 上卦 39%8=7 艮; +时6 = 45 → 下卦 45%8=5 巽; 动 45%6=3
      expect(r.upper, '艮');
      expect(r.lower, '巽');
      expect(r.movingIdx, 2);
      expect(r.hexNo, 18); // 山风蛊
      expect(r.method, '时间起卦');
    });

    test('时间式 时辰核对 (10:30 = 巳时, sc=5, h=6)', () {
      // 注: 10:30 属巳时 (09-11点), source 应为 巳时
      final r = meiHuaByTime(DateTime(2026, 9, 6, 10, 30))!;
      expect(r.source, '农历七月廿五 巳时');
    });

    test('数字式 3/8 → 火地晋 动五爻', () {
      final r = meiHuaByNumbers(3, 8);
      expect(r.upper, '离');
      expect(r.lower, '坤');
      expect(r.movingIdx, 4);
      expect(r.hexNo, 35);
      expect(r.method, '数字起卦');
    });

    test('数字式 2/2 → 兑为泽 (兑三爻 [1,1,0] 回归)', () {
      final r = meiHuaByNumbers(2, 2);
      expect(r.upper, '兑');
      expect(r.lower, '兑');
      expect(r.hexNo, 58); // 兑为泽
      expect(r.lines, [true, true, false, true, true, false]);
    });

    test('数字式 0 取 1, 8/16 归 8', () {
      expect(meiHuaByNumbers(0, 0).upper, '乾'); // 0→1
      expect(meiHuaByNumbers(8, 16).upper, '坤'); // 8%8=0→8 坤
      expect(meiHuaByNumbers(16, 8).lower, '坤');
    });

    test('掷骰式 (固定随机)', () {
      var seq = 0;
      double rand() => [0.0, 0.5, 0.99][seq++ % 3]; // 1,5,6
      final r = meiHuaByDice(rand: rand);
      expect(r.upper, '乾'); // 1 + floor(0*8) = 1
      expect(r.lower, '巽'); // 1 + floor(0.5*8) = 5
      expect(r.movingIdx, 5); // 1 + floor(0.99*6) = 6 → idx 5
    });
  });
}
