import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yijing_transform/view/settings_panel.dart';
import 'package:yijing_transform/viewmodel/settings_viewmodel.dart';

void main() {
  Widget panel(SettingsViewModel vm) => MaterialApp(
        home: Scaffold(body: SettingsPanel(vm: vm)),
      );

  testWidgets('设置面板分组 / 摘要卡 / 导入导出说明', (tester) async {
    await tester.pumpWidget(panel(SettingsViewModel()));
    await tester.pump(const Duration(milliseconds: 400));
    for (final t in const ['设 置', '数 据 管 理', '本 地 数 据', '每 日 提 醒']) {
      expect(find.text(t), findsOneWidget, reason: t);
    }
    expect(find.text('本地记录'), findsOneWidget);
    expect(find.text('收藏卦象'), findsOneWidget);
    expect(find.text('数据与备份说明'), findsOneWidget);
    expect(find.textContaining('app · exportedAt · history · favorites'),
        findsOneWidget);
    expect(find.textContaining('不覆盖、不删除现有记录'), findsOneWidget);
    expect(find.text('重置为示例数据'), findsNothing); // 与清空重复, 已合并
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('矮屏高度受限: 滚动容器保证不溢出', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 260,
          child: SettingsPanel(vm: SettingsViewModel()),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 400));
    expect(tester.takeException(), isNull);
    expect(find.text('每 日 提 醒'), findsOneWidget);
  });

  testWidgets('清空双击确认: 首次进入确认态, 再点执行', (tester) async {
    await tester.pumpWidget(panel(SettingsViewModel()));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('清空本地历史'), findsOneWidget);
    await tester.ensureVisible(find.text('清空本地历史'));
    await tester.pump();
    await tester.tap(find.text('清空本地历史'));
    await tester.pump();
    expect(find.text('确认清空？再点一次'), findsOneWidget);
    await tester.ensureVisible(find.text('确认清空？再点一次'));
    await tester.pump();
    await tester.tap(find.text('确认清空？再点一次'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('清空本地历史'), findsOneWidget);
    expect(find.textContaining('真实记录已清空'), findsOneWidget);
  });
}
