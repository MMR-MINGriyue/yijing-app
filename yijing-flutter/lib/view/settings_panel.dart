import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/yijing_theme.dart';
import '../viewmodel/settings_viewmodel.dart';

/// 设置面板 — 屏1 ⚙ / 屏7 ⚙ 共用 (导出 / 导入合并 / 清空 / 重置)
/// 危险操作双击确认 (3 秒内再点生效, 与 PWA 语义一致)
class SettingsPanel extends StatefulWidget {
  final SettingsViewModel vm;

  const SettingsPanel({super.key, required this.vm});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  bool _clearArmed = false;
  bool _resetArmed = false;
  Timer? _clearTimer;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    widget.vm.addListener(_onVm);
    widget.vm.loadReminderPrefs(); // 载入提醒偏好 (开关/时间)
  }

  void _onVm() => setState(() {});

  @override
  void dispose() {
    widget.vm.removeListener(_onVm);
    _clearTimer?.cancel();
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickRemindTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: widget.vm.remindHour, minute: widget.vm.remindMinute),
      helpText: '选择提醒时间',
    );
    if (t == null || !mounted) return;
    await widget.vm.setReminderTime(t.hour, t.minute);
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(color: YiColors.textPrimary)),
        backgroundColor: const Color(0xFF231A11),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ));
  }

  Future<void> _export() async {
    await Clipboard.setData(ClipboardData(text: widget.vm.exportJson()));
    if (!mounted) return;
    _toast('已复制导出 JSON 到剪贴板 (${widget.vm.recordCount} 条记录 · ${widget.vm.favCount} 卦收藏)');
  }

  Future<void> _import() async {
    final controller = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: YiColors.inkCard,
        title: const Text('导入历史数据', style: TextStyle(fontSize: 16, color: YiColors.textPrimary)),
        content: SizedBox(
          width: 320,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('粘贴导出的 JSON (支持易道 PWA 导出文件)',
                style: TextStyle(fontSize: 12, color: YiColors.textTertiary)),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              maxLines: 6,
              style: const TextStyle(fontSize: 11, color: YiColors.textPrimary),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF161209),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: YiColors.strokeSoft),
                ),
                hintText: '{"app":"yijing-app", ...}',
                hintStyle: const TextStyle(fontSize: 10, color: YiColors.textMuted),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消', style: TextStyle(color: YiColors.textTertiary)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: YiColors.cinnabar),
            child: const Text('导入合并', style: TextStyle(color: Color(0xFFFFF6EC))),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      _toast(widget.vm.importJson(controller.text));
    } on FormatException {
      _toast('导入失败：不是有效的 JSON');
    }
    setState(() {});
  }

  void _clear() {
    if (_clearArmed) {
      _clearTimer?.cancel();
      setState(() {
        _clearArmed = false;
      });
      widget.vm.clearReal();
      _toast('历史记录已清空');
    } else {
      setState(() => _clearArmed = true);
      _clearTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _clearArmed = false);
      });
    }
  }

  void _reset() {
    if (_resetArmed) {
      _resetTimer?.cancel();
      setState(() => _resetArmed = false);
      widget.vm.resetSamples();
      _toast('已恢复示例数据 (收藏不受影响)');
    } else {
      setState(() => _resetArmed = true);
      _resetTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _resetArmed = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('设 置',
            style: TextStyle(fontSize: 16, letterSpacing: 6, color: YiColors.gold)),
        const SizedBox(height: 6),
        ListenableBuilder(
          listenable: widget.vm,
          builder: (_, _) => Text(widget.vm.metaLine,
              style: const TextStyle(fontSize: 11, color: YiColors.textTertiary)),
        ),
        const SizedBox(height: 12),
        _item(
          icon: Icons.file_download_outlined,
          name: '导出历史数据',
          desc: '复制 JSON 到剪贴板，含起卦记录与收藏',
          onTap: _export,
        ),
        _item(
          icon: Icons.file_upload_outlined,
          name: '导入历史数据',
          desc: '粘贴导出的 JSON，合并到本地（自动去重）',
          onTap: _import,
        ),
        _item(
          icon: Icons.delete_outline,
          name: _clearArmed ? '确认清空？再点一次' : '清空本地历史',
          desc: '移除全部真实占卜记录 (收藏不受影响)',
          danger: _clearArmed,
          onTap: _clear,
        ),
        _item(
          icon: Icons.restart_alt,
          name: _resetArmed ? '确认重置？再点一次' : '重置为示例数据',
          desc: '清空真实记录，恢复内置示例 (收藏不受影响)',
          danger: _resetArmed,
          onTap: _reset,
        ),
        const Divider(color: YiColors.strokeSoft, height: 20),
        // iter39: 每日占卜提醒
        Row(children: [
          const Icon(Icons.notifications_outlined, size: 20, color: YiColors.gold),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('每日占卜提醒',
                style: TextStyle(fontSize: 14, color: YiColors.textPrimary)),
            const SizedBox(height: 2),
            Text('每天 ${widget.vm.reminderTimeLabel} 提醒来起今日一卦',
                style: const TextStyle(fontSize: 11, color: YiColors.textTertiary)),
          ])),
          Switch(
            value: widget.vm.remindEnabled,
            activeThumbColor: YiColors.cinnabar,
            onChanged: (on) async {
              await widget.vm.toggleReminder(on);
              if (!mounted) return;
              if (on && !widget.vm.remindEnabled) {
                _toast('未获得通知权限，请在系统设置中开启');
              }
            },
          ),
        ]),
        InkWell(
          onTap: _pickRemindTime,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            child: Row(children: [
              const SizedBox(width: 32),
              Expanded(child: Text('提醒时间',
                  style: TextStyle(
                      fontSize: 13,
                      color: widget.vm.remindEnabled
                          ? YiColors.textPrimary
                          : YiColors.textMuted))),
              Text(widget.vm.reminderTimeLabel,
                  style: const TextStyle(fontSize: 14, color: YiColors.gold)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18, color: YiColors.textMuted),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _item({
    required IconData icon,
    required String name,
    required String desc,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? YiColors.cinnabar : YiColors.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        child: Row(children: [
          Icon(icon, size: 20, color: danger ? YiColors.cinnabar : YiColors.gold),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: TextStyle(fontSize: 14, color: color)),
            const SizedBox(height: 2),
            Text(desc, style: const TextStyle(fontSize: 11, color: YiColors.textTertiary)),
          ])),
        ]),
      ),
    );
  }
}

/// 打开设置面板 (屏1/屏7 共用)
void showSettingsSheet(BuildContext context, SettingsViewModel vm) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: YiColors.inkCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (_) => SettingsPanel(vm: vm),
  );
}
