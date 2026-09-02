import 'package:flutter/material.dart';

import 'data/hex_repository.dart';
import 'theme/yijing_theme.dart';
import 'view/transform_screen.dart';
import 'viewmodel/transform_viewmodel.dart';

void main() {
  HexRepository.instance.init(); // 加载 64 卦
  final vm = TransformViewModel();
  runApp(YijingApp(vm: vm));
}

class YijingApp extends StatelessWidget {
  final TransformViewModel vm;
  const YijingApp({super.key, required this.vm});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '易道 · 变卦推演 (Flutter 实验田)',
      debugShowCheckedModeBanner: false,
      theme: buildYiTheme(),
      home: TransformScreen(vm: vm),
    );
  }
}
