import 'dart:async';

import 'package:flutter/material.dart';

import '../model/history.dart';
import '../service/reminder_service.dart';
import '../theme/yijing_theme.dart';
import '../view/cast_screen.dart';
import '../view/detail_screen.dart';
import '../view/hexgrid_screen.dart';
import '../view/history_screen.dart';
import '../view/home_screen.dart';
import '../view/me_screen.dart';
import '../view/settings_panel.dart';
import '../view/transform_screen.dart';
import '../viewmodel/cast_viewmodel.dart';
import '../viewmodel/detail_viewmodel.dart';
import '../viewmodel/hexgrid_viewmodel.dart';
import '../viewmodel/history_viewmodel.dart';
import '../viewmodel/home_viewmodel.dart';
import '../viewmodel/me_viewmodel.dart';
import '../viewmodel/settings_viewmodel.dart';
import '../viewmodel/transform_viewmodel.dart';

/// 应用壳层 — 5 Tab Hub (IndexedStack 保留各屏状态)
/// 详情/推演为 push 路由, 由壳层统一接线
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  late final HomeViewModel _homeVm = HomeViewModel();
  late final CastViewModel _castVm = CastViewModel();
  late final HexGridViewModel _gridVm = HexGridViewModel();
  late final HistoryViewModel _historyVm = HistoryViewModel();
  late final MeViewModel _meVm = MeViewModel();
  late final SettingsViewModel _settingsVm = SettingsViewModel();

  StreamSubscription<String>? _tapSub;

  @override
  void initState() {
    super.initState();
    // iter41: 点通知直达起卦屏 (前台/后台点击)
    _tapSub = NotificationTapBus.instance.stream.listen(_onNotificationPayload);
    _bootFromNotification(); // 冷启动 (通知拉起)
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    super.dispose();
  }

  /// 冷启动来源: 由每日提醒通知拉起 → 直接落到起卦屏
  Future<void> _bootFromNotification() async {
    try {
      final payload = await ReminderService().launchPayload();
      if (!mounted || payload == null) return;
      _onNotificationPayload(payload);
    } catch (_) {} // 无通道环境 (测试/桌面) 静默
  }

  void _onNotificationPayload(String payload) {
    if (payload == kRemindPayloadCast) _go(1); // 屏2 起卦
  }

  void _openSettings() {
    showSettingsSheet(context, _settingsVm);
  }

  // ---------- 路由 ----------
  void _openDetail(int hexNo,
      {String? question, List<int> moving = const [], String? direction}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DetailScreen(
        vm: DetailViewModel(
          hexNo: hexNo,
          question: question ?? '',
          moving: moving,
          direction: direction ?? '',
        ),
        onOpenTransform: (hex) => _openTransform(hex.no, moving),
      ),
    ));
  }

  void _openTransform(int hexNo, List<int> moving) {
    final vm = TransformViewModel()..selectHex(hexNo);
    for (final i in moving) {
      vm.toggleMoving(i);
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TransformScreen(vm: vm),
    ));
  }

  void _openRecord(HistoryRecord r) {
    if (r.hexNo != null) {
      _openDetail(r.hexNo!,
          question: r.question, moving: r.moving ?? const [], direction: r.direction);
    }
  }

  // ---------- 构建 ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YiColors.ink,
      body: IndexedStack(index: _tab, children: [
        HomeScreen(
          vm: _homeVm,
          onOpenDetail: (no, {question}) => _openDetail(no, question: question),
          onGoCast: () => _go(1),
          onGoGrid: () => _go(2),
          onGoHistory: () => _go(3),
          onOpenSettings: _openSettings,
        ),
        CastScreen(
          vm: _castVm,
          onOpenDetail: (hex, {question}) => _openDetail(hex.no,
              question: question, direction: _castVm.state.direction),
        ),
        HexGridScreen(vm: _gridVm, onOpenDetail: _openDetail),
        HistoryScreen(vm: _historyVm, onOpenRecord: _openRecord),
        MeScreen(
          vm: _meVm,
          onOpenDetail: _openDetail,
          onGoHistory: () => _go(3),
          onGoGrid: () => _go(2),
          onOpenSettings: _openSettings,
        ),
      ]),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: YiColors.ink,
        selectedItemColor: YiColors.cinnabar,
        unselectedItemColor: YiColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        currentIndex: _tab,
        onTap: (i) => _go(i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.wb_twilight_outlined), label: '今日'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome_outlined), label: '起卦'),
          BottomNavigationBarItem(icon: Icon(Icons.grid_view_outlined), label: '卦库'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: '历史'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '我的'),
        ],
      ),
    );
  }

  void _go(int i) => setState(() => _tab = i);
}
