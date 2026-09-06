import 'package:flutter/material.dart';

import 'app/app_shell.dart';
import 'data/favorites_store.dart';
import 'data/history_repository.dart';
import 'data/hex_repository.dart';
import 'data/history_store_prefs.dart';
import 'theme/yijing_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HexRepository.instance.init(); // 加载 64 卦
  installPrefsStores(); // 真机持久化: 默认存储工厂 → shared_preferences 实现
  await HistoryRepository.instance.warmUp(); // 预热历史
  await FavoritesRepository.instance.warmUp(); // 预热收藏
  runApp(const YijingApp());
}

class YijingApp extends StatelessWidget {
  const YijingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '易道 · 卦象解读',
      debugShowCheckedModeBanner: false,
      theme: buildYiTheme(),
      home: const AppShell(),
    );
  }
}
