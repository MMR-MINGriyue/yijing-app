import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/theme/yijing_theme.dart';
import 'package:yijing_transform/view/widgets/casting_anim.dart';
import 'package:yijing_transform/view/widgets/pressable.dart';
import 'package:yijing_transform/view/widgets/stagger_in.dart';

/// iter38 动效组件 — 按压反馈 / 入场编排 / 推演动画
void main() {
  testWidgets('PressableScale: 点击触发 onTap', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: PressableScale(
          onTap: () => taps++,
          child: const SizedBox(width: 100, height: 44),
        ),
      ),
    ));
    await tester.tap(find.byType(PressableScale));
    expect(taps, 1);
  });

  testWidgets('PressableScale: onTap 为空时透传不拦截', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      home: Center(
        child: PressableScale(
          child: GestureDetector(
            onTap: () => taps++,
            child: Container(width: 100, height: 44, color: Colors.white12),
          ),
        ),
      ),
    ));
    await tester.tap(find.byType(GestureDetector));
    expect(taps, 1);
  });

  testWidgets('StaggerIn: 延迟后子级可见且动画收敛', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: StaggerIn(
          delay: Duration(milliseconds: 100),
          child: Text('入场'),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 100)); // 等延迟
    await tester.pump(YiMotion.slow); // 动画走完
    expect(find.text('入场'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CastingAnim: 六爻行 + 文案存在, 动画帧推进不抛异常', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Center(child: CastingAnim()))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('卦 象 推 演 中'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
