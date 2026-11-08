import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/data/hex_repository.dart';
import 'package:yijing_transform/view/widgets/share_card.dart';

/// iter68 (v1.60.0): 分享卡模板美化 — 渲染冒烟 + 落盘预览
void main() {
  setUp(() {
    HexRepository.instance.init();
  });

  ShareCardData demo() => ShareCardData(
        hex: HexRepository.instance.hexByNo(12), // 天地否
        moving: const [0],
        question: '近期事业运筹方向',
        now: DateTime(2026, 11, 8, 20, 30),
      );

  testWidgets('ShareCardPreview 冒烟: 美化模板可渲染无异常', (tester) async {
    await tester.pumpWidget(Center(
      child: SizedBox(
        width: 360,
        height: 520,
        child: FittedBox(child: ShareCardPreview(data: demo())),
      ),
    ));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  test('渲染 2x PNG 落盘 (视觉检视用, 输出 .dart_tool/)', () async {
    final img = await renderShareCardImage(demo());
    expect(img.width, 1440);
    expect(img.height, 2080);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    expect(bytes, isNotNull);
    final out = File('.dart_tool/share_card_v160.png');
    out.writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}
