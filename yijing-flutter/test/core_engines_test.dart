import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/core/cast_engine.dart';
import 'package:yijing_transform/core/lunar_calendar.dart';
import 'package:yijing_transform/core/palace.dart';
import 'package:yijing_transform/core/xiaoliuren.dart';
import 'package:yijing_transform/core/yi_calendar.dart';

void main() {
  group('YiCalendar — 干支历 (PWA 逐位对齐)', () {
    test('JDN 锚点', () {
      expect(jdn(2026, 9, 6), 2461290);
      expect(jdn(1984, 1, 1), 2445701);
    });

    test('干支纪日: 2026-09-06 = 癸未', () {
      expect(ganzhiDay(DateTime(2026, 9, 6)), '癸未');
      expect(ganzhiDay(DateTime(2026, 1, 1)), '乙亥');
    });

    test('干支纪年: 立春为界, 1984 = 甲子', () {
      expect(ganzhiYear(DateTime(2026, 9, 6)), '丙午');
      expect(ganzhiYear(DateTime(2026, 2, 3)), '乙巳'); // 立春前属上一年
      expect(ganzhiYear(DateTime(2026, 2, 5)), '丙午');
      expect(ganzhiYear(DateTime(1984, 3, 1)), '甲子');
    });

    test('月干支: 年上起月法', () {
      expect(ganzhiMonth(DateTime(2026, 9, 6)), '丙申');
      expect(ganzhiMonth(DateTime(2026, 2, 5)), '庚寅'); // 寅月
      expect(ganzhiMonth(DateTime(2026, 2, 3)), '己丑'); // 立春前仍丑月
      expect(ganzhiMonth(DateTime(2024, 1, 20)), '乙丑');
    });

    test('完整干支落款', () {
      expect(ganzhiFull(DateTime(2026, 9, 6)), '丙午年 丙申月 癸未日 · 9月6日');
    });

    test('时辰映射', () {
      expect(shichenOf(DateTime(2026, 9, 6, 23)).zhi, '子');
      expect(shichenOf(DateTime(2026, 9, 6, 0)).zhi, '子');
      expect(shichenOf(DateTime(2026, 9, 6, 1)).zhi, '丑');
      expect(shichenOf(DateTime(2026, 9, 6, 12)).zhi, '午');
      expect(shichenOf(DateTime(2026, 9, 6, 13)).greet, '未时安');
    });
  });

  group('LunarCalendar — 农历 (PWA 逐位对齐)', () {
    test('春节锚点', () {
      final cny2024 = solarToLunar(DateTime(2024, 2, 10))!;
      expect(cny2024.month, 1);
      expect(cny2024.day, 1);
      final cny2025 = solarToLunar(DateTime(2025, 1, 29))!;
      expect(cny2025.month, 1);
      expect(cny2025.day, 1);
    });

    test('2026-09-06 = 七月廿五', () {
      final l = solarToLunar(DateTime(2026, 9, 6))!;
      expect(l.year, 2026);
      expect(l.month, 7);
      expect(l.day, 25);
      expect(l.monthLabel, '七月');
      expect(l.dayLabel, '廿五');
    });

    test('闰月年 + 越界返回 null', () {
      // 2023 年闰二月
      final leap = solarToLunar(DateTime(2023, 3, 22))!;
      expect(leap.isLeap, isTrue);
      expect(leap.month, 2);
      expect(solarToLunar(DateTime(1899, 1, 1)), isNull);
      // 2101-01-01 仍在农历 2100 年腊月 (春节前), 属表内; 春节后才越界
      expect(solarToLunar(DateTime(2101, 1, 1)), isNotNull);
      expect(solarToLunar(DateTime(2101, 6, 1)), isNull);
    });

    test('时辰序号', () {
      expect(shichenIndex(DateTime(2026, 9, 6, 23)), 0); // 子
      expect(shichenIndex(DateTime(2026, 9, 6, 0)), 0);
      expect(shichenIndex(DateTime(2026, 9, 6, 1)), 1); // 丑
      expect(shichenIndex(DateTime(2026, 9, 6, 10)), 5); // 巳
    });
  });

  group('CastEngine — 起卦 (PWA 逐位对齐)', () {
    test('numbersFromText 哈希向量', () {
      expect(numbersFromText('近期事业运筹方向'), [4797, 2131]);
      expect(numbersFromText('与TA关系走向'), [7463, 8491]);
      expect(numbersFromText(''), [662, 5382]);
      expect(numbersFromText('abc'), [4030, 9764]);
    });

    test('数字起卦: 两数定卦 (确定性)', () {
      final r = castByNumbers(1, 1); // 乾上乾下, 动爻 (1+1)%6=2 → 爻2 (索引1)
      expect(r.lines.every((y) => y), isTrue); // 乾 111111
      expect(r.moving, [1]);
      final r2 = castByNumbers(3, 8); // 上离(3)下坤(8) → 火地晋; 动爻 (3+8)%6=5
      expect(r2.moving, [4]);
      expect(r2.lines, const [false, false, false, true, false, true]); // 坤下(000)离上(101)
    });

    test('numeric 起卦稳定可复现', () {
      final a = cast('numeric', '近期事业运筹方向');
      final b = cast('numeric', '近期事业运筹方向');
      expect(a.lines, b.lines);
      expect(a.moving, b.moving);
    });

    test('铜钱起卦: 结构合法', () {
      var seq = 0;
      double rand() => (seq++ * 0.618) % 1; // 伪随机确定序列
      final r = castByCoins(rand: rand);
      expect(r.lines.length, 6);
      expect(r.tosses!.length, 6);
      for (final t in r.tosses!) {
        expect(t.length, 3);
        expect(t.every((f) => f == 0 || f == 1), isTrue);
      }
    });

    test('铜钱规则: 固定背面数 → 爻', () {
      // 全字 (0背) 六次 → 6 个老阴动爻
      final allYin = castByCoins(rand: () => 0.9);
      expect(allYin.lines.every((y) => !y), isTrue);
      expect(allYin.moving, [0, 1, 2, 3, 4, 5]);
      // 全背 (1背? no 0.1<0.5 → 背) — rand<0.5 为背: 0.1 → 全背 3背 → 老阳
      final allYang = castByCoins(rand: () => 0.1);
      expect(allYang.lines.every((y) => y), isTrue);
      expect(allYang.moving, [0, 1, 2, 3, 4, 5]);
    });

    test('蓍草起卦: 概率区间规则', () {
      // r<3/16 老阳; 3/16..10/16 少阴; 10/16..15/16 少阳; ≥15/16 老阴
      final yang = castByYarrow(rand: () => 0.1);
      expect(yang.lines.every((y) => y), isTrue);
      expect(yang.moving.length, 6);
      final yin = castByYarrow(rand: () => 0.5); // 3/16 ≤ 0.5 < 10/16 → 少阴
      expect(yin.lines.every((y) => !y), isTrue);
      expect(yin.moving, isEmpty);
      final laoYin = castByYarrow(rand: () => 0.99);
      expect(laoYin.lines.every((y) => !y), isTrue);
      expect(laoYin.moving.length, 6);
    });

    test('时辰卦: hour % 16', () {
      expect(hourHex(DateTime(2026, 9, 6, 10)).no, 11); // 10 → 序号10 = 泰
      expect(hourHex(DateTime(2026, 9, 6, 0)).no, 1); // 乾
      expect(hourHex(DateTime(2026, 9, 6, 16)).no, 1); // 16 % 16 = 0 → 乾
      expect(hourHex(DateTime(2026, 9, 6, 17)).no, 2); // 坤
    });

    test('刷新轮换: n % 64', () {
      expect(refreshHex(0).no, 1);
      expect(refreshHex(64).no, 1);
      expect(refreshHex(31).no, 32);
    });
  });

  group('Palace — 京房八宫', () {
    test('64 卦全覆盖且各归一宫', () {
      expect(kPalaces.length, 64);
      final palaceCounts = <String, int>{};
      for (final info in kPalaces.values) {
        palaceCounts[info.palace] = (palaceCounts[info.palace] ?? 0) + 1;
      }
      expect(palaceCounts.length, 8);
      for (final c in palaceCounts.values) {
        expect(c, 8);
      }
    });

    test('乾宫序列: 乾姤遯否观剥晋大有', () {
      final members = palaceMembers('乾宫');
      expect(members, [1, 44, 33, 12, 20, 23, 35, 14]);
    });

    test('宫主为本宫卦', () {
      expect(palaceOf(1)!.stage, '本宫');
      expect(palaceOf(1)!.head, 1);
      expect(palaceOf(29)!.palace, '坎宫'); // 坎为水
      expect(palaceOf(2)!.palace, '坤宫');
      expect(palaceOf(58)!.palace, '兑宫');
    });
  });

  group('XiaoLiuRen — 小六壬 (PWA 逐位对齐)', () {
    test('2026-09-06 10:00 巳时: 农历七月廿五 → 大安/大安/空亡', () {
      final r = divineXiaoLiuRen(DateTime(2026, 9, 6, 10))!;
      expect(r.lunar.month, 7);
      expect(r.lunar.day, 25);
      expect(r.shichen, '巳时');
      // 月宫: (7-1)%6=0 大安; 日宫: (0+25-1)%6=0 大安; 时宫: (0+5)%6=5 空亡
      expect(r.path, ['大安', '大安', '空亡']);
      expect(r.result.name, '空亡');
      expect(r.summary, contains('空亡'));
    });

    test('路径法推进正确', () {
      // 2024-02-10 00:30 = 正月初一 子时(sc=0): 月宫大安, 日宫大安, 时宫大安
      final r = divineXiaoLiuRen(DateTime(2024, 2, 10, 0, 30))!;
      expect(r.path, ['大安', '大安', '大安']);
    });
  });
}
