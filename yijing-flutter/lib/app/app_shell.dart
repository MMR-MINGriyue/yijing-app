import 'package:flutter/material.dart';

import '../model/history.dart';
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

  void _openSettings() {
    showSettingsSheet(context, _settingsVm);
  }

  // ---------- 路由 ----------
  void _openDetail(int hexNo, {String? question, List<int> moving = const []}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => DetailScreen(
        vm: DetailViewModel(hexNo: hexNo, question: question ?? '', moving: moving),
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
      _openDetail(r.hexNo!, question: r.question, moving: r.moving ?? const []);
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
          onOpenDetail: (hex, {question}) => _openDetail(hex.no, question: question),
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
