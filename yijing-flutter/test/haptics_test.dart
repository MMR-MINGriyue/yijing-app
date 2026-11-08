import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/view/widgets/coin_toss_anim.dart';

/// iter70 (v1.62.0): 触觉反馈 — 拦截 flutter/platform 通道验证触感序列
void main() {
  testWidgets('投币: 逐爻落定 6 次轻触感 + 完成落定 1 次中触感', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMessageHandler(
      'flutter/platform',
      (data) async {
        if (data != null) {
          final call = const JSONMethodCodec().decodeMethodCall(data);
          if (call.method == 'HapticFeedback.vibrate') calls.add(call);
        }
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMessageHandler('flutter/platform', null));

    final tosses = List.generate(CoinTossAnim.rounds, (_) => const [1, 1, 1]);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: Center(child: CoinTossAnim(tosses: tosses))),
    ));
    await tester.pump(const Duration(milliseconds: 50));
    expect(calls, isEmpty); // 尚未有爻落定

    // 逐爻推进: 每爻 430ms 一掷, round 递增 5 次各触发一次轻触感
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 440));
    }
    expect(calls.length, 5, reason: 'round 1..5 各一次轻触感');
    final kindsBefore = calls.map((c) => c.arguments as String).toSet();
    expect(kindsBefore, {'HapticFeedbackType.lightImpact'},
        reason: '落定前不应有完成触感');

    // 推完最后一爻 + 尾段 260ms → 完成触感 (总时长 6*430+260=2840ms, pump 至 3050ms)
    await tester.pump(const Duration(milliseconds: 800));
    expect(calls.length, 6);
    expect(
      calls.last.arguments as String,
      'HapticFeedbackType.mediumImpact',
    );
  });
}
