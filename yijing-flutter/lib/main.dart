import 'package:flutter/material.dart';

import 'app/app_shell.dart';
import 'data/favorites_store.dart';
import 'data/history_repository.dart';
import 'data/hex_repository.dart';
import 'data/history_store_prefs.dart';
import 'service/reminder_service.dart';
import 'theme/yijing_theme.dart';
import 'view/splash/bagua_splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HexRepository.instance.init(); // 加载 64 卦
  installPrefsStores(); // 真机持久化: 默认存储工厂 → shared_preferences 实现
  await HistoryRepository.instance.warmUp(); // 预热历史
  await FavoritesRepository.instance.warmUp(); // 预热收藏
  try {
    await PluginReminderScheduler.instance.init(); // 通知通道 + 时区 (iter39)
  } catch (_) {} // 桌面/测试环境无通道, 静默
  // 通知冷启动直达起卦屏: 不播放启动动画 (iter57)
  String? bootPayload;
  try {
    bootPayload = await PluginReminderScheduler.instance.launchPayload();
  } catch (_) {}
  runApp(YijingApp(skipSplash: bootPayload != null));
}

class YijingApp extends StatelessWidget {
  const YijingApp({super.key, this.skipSplash = false});

  final bool skipSplash;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '易道 · 卦象解读',
      debugShowCheckedModeBanner: false,
      theme: buildYiTheme(),
      home: skipSplash ? const AppShell() : const BaguaSplash(),
    );
  }
}
