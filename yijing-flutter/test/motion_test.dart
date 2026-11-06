import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/app/app_shell.dart';
import 'package:yijing_transform/data/hex_repository.dart';
import 'package:yijing_transform/theme/yijing_theme.dart';
import 'package:yijing_transform/view/widgets/stagger_in.dart';

void main() {
  test('入场编排五段递增 (iter59)', () {
    expect(YiMotion.homeStagger.length, 5);
    for (var i = 1; i < YiMotion.homeStagger.length; i++) {
      expect(YiMotion.homeStagger[i] > YiMotion.homeStagger[i - 1], isTrue);
    }
  });

  testWidgets('系统减少动画: reduced 压零 + StaggerIn 直接落终态', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(MaterialApp(
      builder: (c, child) => MediaQuery(
        data: MediaQuery.of(c).copyWith(disableAnimations: true),
        child: child!,
      ),
      home: Builder(builder: (c) {
        ctx = c;
        return const StaggerIn(
          delay: Duration(milliseconds: 300),
          child: Text('STAGGER_CHILD'),
        );
      }),
    ));
    await tester.pump();
    expect(YiMotion.reduced(ctx, const Duration(milliseconds: 280)),
        Duration.zero);
    final fade = tester.widget<FadeTransition>(find.descendant(
        of: find.byType(StaggerIn),
        matching: find.byType(FadeTransition)));
    expect(fade.opacity.value, 1.0); // 不等 300ms 延迟
  });

  testWidgets('Tab 纵深切换: 活动页归位, 非活动页偏移+后退缩放', (tester) async {
    HexRepository.instance.init();
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.descendant(
        of: find.byType(BottomNavigationBar), matching: find.text('占卜')));
    await tester.pump(const Duration(milliseconds: 400));

    final slides = tester
        .widgetList<AnimatedSlide>(find.byType(AnimatedSlide, skipOffstage: false))
        .toList();
    expect(slides.length, 4);
    expect(slides.where((s) => s.offset == Offset.zero).length, 1);
    expect(slides.where((s) => s.offset.dx.abs() > 0.05).length, 3);

    // 壳层其他组件也用 AnimatedScale, 不断言总数, 只验证纵深状态存在
    final scales = tester
        .widgetList<AnimatedScale>(find.byType(AnimatedScale, skipOffstage: false))
        .toList();
    expect(scales.any((s) => s.scale == 1.0), isTrue);
    expect(scales.where((s) => s.scale < 1.0).length, greaterThanOrEqualTo(3));
  });
}
