import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/core/bazi.dart';
import 'package:yijing_transform/core/dayun.dart';
import 'package:yijing_transform/core/meihua.dart';
import 'package:yijing_transform/core/solar_terms.dart';
import 'package:yijing_transform/core/xiaoliuren.dart';
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

  // ---------- iter44 增强: 纳音 / 神煞 / 十神统计 ----------
  group('BaZi 纳音 — 六十甲子', () {
    test('已知向量', () {
      expect(nayinOf('甲子'), '海中金');
      expect(nayinOf('乙丑'), '海中金');
      expect(nayinOf('庚辰'), '白蜡金');
      expect(nayinOf('戊午'), '天上火');
      expect(nayinOf('癸卯'), '金箔金');
      expect(nayinOf('壬戌'), '大海水');
      expect(nayinOf('癸亥'), '大海水');
    });

    test('覆盖 60 干支无缺漏', () {
      final seen = <String>{};
      for (var i = 0; i < 60; i++) {
        final gz = '${kGan[i % 10]}${kZhi[i % 12]}';
        final n = nayinOf(gz);
        expect(n, isNotEmpty, reason: '$gz 缺纳音');
        seen.add(gz);
      }
      expect(seen.length, 60);
    });

    test('排盘四柱带纳音 (1990-05-15: 庚午路旁土/辛巳白蜡金/庚辰白蜡金/癸未杨柳木)', () {
      final c = computeBaZi(DateTime(1990, 5, 15, 14, 30))!;
      expect(c.pillars.map((p) => nayinOf(p.gz)).join(','),
          '路旁土,白蜡金,白蜡金,杨柳木');
    });
  });

  group('BaZi 神煞 + 十神统计 (iter44)', () {
    test('1990-05-15 庚日: 天乙贵人(未) + 华盖(日支辰)', () {
      final c = computeBaZi(DateTime(1990, 5, 15, 14, 30))!; // 庚午 辛巳 庚辰 癸未
      expect(shenShaOf(c), ['天乙贵人', '华盖']);
    });

    test('甲日见丑未 → 天乙贵人; 甲日见巳/午 → 文昌', () {
      // 甲戌 甲戌 甲辰 甲子? 手工无; 直接用 1984-02-02? 构造: 甲辰日年支戌:
      // 1984-02-04 06:00 → 甲子年 丙寅月 戊辰日? 不猜, 用规则单测:
      expect(kTianYi['甲'], ['丑', '未']);
      expect(kWenChang['甲'], '巳');
      expect(kSanHe['辰'], ['寅', '酉', '辰']); // 申子辰: 马寅 花酉 盖辰
      expect(kSanHe['午'], ['申', '卯', '戌']); // 寅午戌
    });

    test('十神统计 (1990-05-15 庚日)', () {
      final c = computeBaZi(DateTime(1990, 5, 15, 14, 30))!; // 庚午 辛巳 庚辰 癸未
      final s = tenGodStats(c);
      // 天干: 年庚=比肩, 月辛=劫财, 时癸=伤官
      expect(s['比肩'], 1);
      expect(s['劫财'], 1);
      expect(s['伤官'], 1);
      // 藏干本气: 午丁=正官, 巳丙=七杀, 辰戊=偏印, 未己=正印
      expect(s['正官'], 1);
      expect(s['七杀'], 1);
      expect(s['偏印'], 1);
      expect(s['正印'], 1);
      expect(s.length, 7);
    });
  });

  group('MeiHua 体用互变 (iter44)', () {
    test('乾为天动初爻: 下卦为用, 比和吉; 变卦天风姤; 互卦乾为天', () {
      final lines = [true, true, true, true, true, true];
      final a = analyzeMeiHua(lines, 0);
      expect(a.tiName, '乾'); // 上卦静为体
      expect(a.yongName, '乾'); // 下卦动为用
      expect(a.relation, '比和');
      expect(a.verdict, '吉');
      expect(a.huNo, 1); // 互卦仍乾
      expect(a.bianNo, 44); // 初爻变 → 天风姤
      expect(a.bianName, '姤');
    });

    test('地天泰动上爻: 上卦为用 (坤土), 用生体 → 大吉; 互卦雷泽归妹; 变卦山天大畜', () {
      final lines = [true, true, true, false, false, false]; // 泰 bits 111000
      final a = analyzeMeiHua(lines, 5);
      expect(a.tiName, '乾'); // 下卦静
      expect(a.yongName, '坤'); // 上卦动
      expect(a.relation, '用生体'); // 土生金
      expect(a.verdict, '大吉');
      expect(a.huName, '归妹'); // 二三四=[1,1,0]=兑 下互, 三四五=[1,0,0]=震 上互 → 雷泽归妹
      expect(a.huNo, 54);
      expect(a.bianNo, 26); // 上爻变 → 山天大畜
      expect(a.bianName, '大畜');
    });

    test('体克用 → 小吉 (天风姤动初爻: 体乾金 克 用巽木)', () {
      final lines = [false, true, true, true, true, true]; // 姤 bits 011111
      final a = analyzeMeiHua(lines, 0);
      expect(a.tiName, '乾'); // 上卦静为体 (金)
      expect(a.yongName, '巽'); // 下卦动为用 (木)
      expect(a.relation, '体克用'); // 金克木
      expect(a.verdict, '小吉');
    });

    test('用克体 → 凶断语', () {
      // 火天大有 (111101): 上离下乾, 动上爻(idx5) → 用离火, 体乾金, 火克金
      final lines = [true, true, true, true, false, true];
      final a = analyzeMeiHua(lines, 5);
      expect(a.tiWuxing, '金');
      expect(a.yongWuxing, '火');
      expect(a.relation, '用克体');
      expect(a.verdict, '凶');
      expect(a.verdictText, contains('阻隔'));
    });
  });

  group('XiaoLiuRen 问事断语 (iter44)', () {
    test('六宫 × 六问 齐全且非空', () {
      expect(kXlrAskKinds.length, 6);
      for (final p in kXlrPalaces) {
        final row = kXlrAdvice[p.name];
        expect(row, isNotNull, reason: '${p.name} 缺问事断语');
        expect(row!.keys.toSet(), kXlrAskKinds.toSet(), reason: '${p.name} 问类不齐');
        for (final t in row.values) {
          expect(t.trim(), isNotEmpty, reason: '${p.name} 有空断语');
        }
      }
    });

    test('askAdvice: 大安谋事 / 空亡求财', () {
      final r = divineXiaoLiuRen(DateTime(2026, 9, 12, 10, 30), askKind: '谋事')!;
      expect(r.askKind, '谋事');
      expect(r.askAdvice, kXlrAdvice[r.result.name]!['谋事']);
      final r2 = divineXiaoLiuRen(DateTime(2026, 9, 12, 10, 30), askKind: '求财')!;
      expect(r2.askAdvice, kXlrAdvice[r2.result.name]!['求财']);
    });

    test('非法 askKind 回退谋事, 默认参数兼容旧调用', () {
      final r = divineXiaoLiuRen(DateTime(2026, 9, 12, 10, 30), askKind: ' bogus ')!;
      expect(r.askKind, '谋事');
      final r2 = divineXiaoLiuRen(DateTime(2026, 9, 12, 10, 30))!;
      expect(r2.askKind, '谋事');
      // 路径算法不变 (回归)
      expect(r.path.length, 3);
      expect(r.path, r2.path);
    });
  });
}
