import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/core/cast_engine.dart' show hourHex;
import 'package:yijing_transform/core/daily_hex.dart';

void main() {
  test('dailyHex 确定性且落 1..64 (iter63)', () {
    final dt = DateTime(2026, 9, 19, 10, 30);
    expect(dailyHex(dt).no, inInclusiveRange(1, 64));
    expect(dailyHex(dt).no, dailyHex(dt).no);
  });

  test('跨日连续推进 (含跨月), 不再只按小时循环 16 卦', () {
    final a = dailyHex(DateTime(2026, 9, 19, 10, 30));
    final b = dailyHex(DateTime(2026, 9, 20, 10, 30));
    expect(b.no, (a.no % 64) + 1); // 同一时辰, 日期 +1 → 卦序 +1

    final c = dailyHex(DateTime(2026, 9, 30, 10, 30));
    final d = dailyHex(DateTime(2026, 10, 1, 10, 30));
    expect(d.no, (c.no % 64) + 1); // 跨月仍连续

    final dayNos = <int>{};
    for (var i = 0; i < 60; i++) {
      dayNos.add(dailyHex(DateTime(2026, 9, 19, 10, 30)
              .add(Duration(days: i)))
          .no);
    }
    expect(dayNos.length, 60); // 60 天 60 卦, 旧实现最多 16
  });

  test('同一天不同时辰产生不同卦', () {
    final hourNos = <int>{};
    for (final h in const [1, 4, 8, 12, 16, 20, 23]) {
      hourNos.add(dailyHex(DateTime(2026, 9, 19, h, 30)).no);
    }
    expect(hourNos.length, greaterThan(1));
  });

  test('hourHex 保留不变 (PWA 对拍基线)', () {
    expect(hourHex(DateTime(2026, 9, 6, 10)).no, 11);
    expect(hourHex(DateTime(2026, 9, 6, 0)).no, 1);
  });
}
