import 'package:flutter/material.dart';

import 'data/hex_repository.dart';
import 'theme/yijing_theme.dart';
import 'view/detail_screen.dart';
import 'view/transform_screen.dart';
import 'viewmodel/detail_viewmodel.dart';
import 'viewmodel/transform_viewmodel.dart';

void main() {
  HexRepository.instance.init(); // 加载 64 卦
  runApp(const YijingApp());
}

class YijingApp extends StatelessWidget {
  const YijingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '易道 · Flutter 实验田',
      debugShowCheckedModeBanner: false,
      theme: buildYiTheme(),
      home: const _HubScreen(),
    );
  }
}

/// 双屏导航 Hub: 屏 4 卦辞解析 / 屏 5 变卦推演
class _HubScreen extends StatefulWidget {
  const _HubScreen();

  @override
  State<_HubScreen> createState() => _HubScreenState();
}

class _HubScreenState extends State<_HubScreen> {
  int _screen = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YiColors.ink,
      appBar: AppBar(
        backgroundColor: YiColors.ink,
        foregroundColor: YiColors.gold,
        centerTitle: true,
        title: Text(_screen == 0 ? '卦 辞 解 析' : '变 卦 推 演',
            style: const TextStyle(letterSpacing: 6, fontSize: 17)),
      ),
      body: IndexedStack(
        index: _screen,
        children: [
          DetailScreen(vm: DetailViewModel(hexNo: 1)),
          TransformScreen(vm: TransformViewModel()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: YiColors.ink,
        selectedItemColor: YiColors.cinnabar,
        unselectedItemColor: YiColors.textTertiary,
        currentIndex: _screen,
        onTap: (i) => setState(() => _screen = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu_book_outlined), label: '卦辞解析'),
          BottomNavigationBarItem(icon: Icon(Icons.change_history_outlined), label: '变卦推演'),
        ],
      ),
    );
  }
}
