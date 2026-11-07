import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/yijing_theme.dart';
import '../theme/yi_ornament.dart';
import '../viewmodel/settings_viewmodel.dart';
import 'widgets/pressable.dart';

/// 设置面板 (iter62 分组重构) — 屏1 ⚙ / 屏7 ⚙ 共用
/// 三组: 数据管理 (导出/备份/导入) / 本地数据 (清空) / 每日提醒.
/// 危险操作双击确认 (3 秒内再点生效, 与 PWA 语义一致).
class SettingsPanel extends StatefulWidget {
  final SettingsViewModel vm;

  const SettingsPanel({super.key, required this.vm});

  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  bool _clearArmed = false;
  Timer? _clearTimer;

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

  /// 备份为 .json 文件 → 系统分享 (可存 Files/网盘/微信) (iter41)
  Future<void> _backupFile() async {
    try {
      final path = await widget.vm.shareBackupFile();
      if (!mounted) return;
      _toast('已生成备份文件: ${path.split(RegExp(r'[\\/]')).last}');
    } catch (e) {
      if (!mounted) return;
      _toast('备份失败：$e');
    }
  }

  /// 从 .json 文件导入 (iter41)
  Future<void> _importFile() async {
    try {
      final msg = await widget.vm.importFromFile();
      if (!mounted || msg == null) return; // 取消选择
      _toast(msg);
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      _toast('导入失败：$e');
    }
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
      setState(() => _clearArmed = false);
      widget.vm.clearReal();
      _toast('真实记录已清空，现显示内置示例');
    } else {
      setState(() => _clearArmed = true);
      _clearTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _clearArmed = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // iter62: 分组 + 滚动容器 (原平铺 Column 在矮屏会 RenderFlex 溢出)
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: YiColors.goldDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Row(children: [
            YiSeal(text: '易', size: 24),
            SizedBox(width: 10),
            Text('设 置',
                style: TextStyle(
                    fontSize: 16, letterSpacing: 6, color: YiColors.gold)),
          ]),
          const SizedBox(height: 12),
          _summaryCard(),
          const SizedBox(height: 14),
          _sectionTitle('数 据 管 理', Icons.storage_outlined),
          _item(
            icon: Icons.file_download_outlined,
            name: '导出历史数据',
            desc: '复制 JSON 到剪贴板，含起卦记录与收藏',
            onTap: _export,
          ),
          _item(
            icon: Icons.ios_share_outlined,
            name: '备份为文件',
            desc: '生成 .json 备份并调起系统分享 (可存网盘/微信)',
            onTap: _backupFile,
          ),
          _item(
            icon: Icons.file_upload_outlined,
            name: '导入历史数据',
            desc: '粘贴导出的 JSON，合并到本地（自动去重）',
            onTap: _import,
          ),
          _item(
            icon: Icons.folder_open_outlined,
            name: '从文件导入',
            desc: '选择 .json 备份文件，合并到本地（自动去重）',
            onTap: _importFile,
          ),
          _infoCard(),
          const SizedBox(height: 8),
          _sectionTitle('本 地 数 据', Icons.delete_outline, danger: true),
          _item(
            icon: Icons.delete_outline,
            name: _clearArmed ? '确认清空？再点一次' : '清空本地历史',
            desc: '移除全部真实占卜记录，界面回到内置示例（收藏不受影响）',
            danger: _clearArmed,
            onTap: _clear,
          ),
          const SizedBox(height: 8),
          _sectionTitle('每 日 提 醒', Icons.notifications_outlined),
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
          PressableScale(
            onTap: _pickRemindTime,
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
      ),
    );
  }

  /// 数据摘要卡 — 把原 metaLine 纯文本升级为双指标
  Widget _summaryCard() => Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: yiCardDecoration(radius: 12),
        child: Row(children: [
          Expanded(child: _metric('本地记录', widget.vm.recordCount, '条')),
          Container(width: 1, height: 34, color: YiColors.stroke),
          Expanded(child: _metric('收藏卦象', widget.vm.favCount, '卦')),
        ]),
      );

  Widget _metric(String label, int value, String unit) => Column(children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, letterSpacing: 2, color: YiColors.textTertiary)),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic, children: [
          Text('$value',
              style: const TextStyle(
                  fontSize: 20, color: YiColors.gold, fontWeight: FontWeight.w500)),
          const SizedBox(width: 3),
          Text(unit,
              style: const TextStyle(fontSize: 10, color: YiColors.textMuted)),
        ]),
      ]);

  Widget _sectionTitle(String text, IconData icon, {bool danger = false}) {
    final color = danger ? YiColors.cinnabar : YiColors.gold;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 6),
      child: Row(children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(text,
            style: TextStyle(
                fontSize: 11, letterSpacing: 3, color: color)),
        const SizedBox(width: 10),
        Expanded(
            child: Divider(
                color: color.withValues(alpha: 0.28), height: 1, thickness: 1)),
      ]),
    );
  }

  /// 导入导出说明 — 与 exportJson / importJson 实际语义一致
  Widget _infoCard() => Container(
        margin: const EdgeInsets.fromLTRB(4, 4, 4, 8),
        padding: const EdgeInsets.all(12),
        decoration: yiCardDecoration(radius: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('数据与备份说明',
              style: TextStyle(
                  fontSize: 11, letterSpacing: 2, color: YiColors.gold)),
          const SizedBox(height: 8),
          _infoLine('导出 / 备份生成 JSON：app · exportedAt · history · favorites，与易道 PWA 互通'),
          _infoLine('导入按合并语义去重合入，不覆盖、不删除现有记录'),
          _infoLine('备份可存网盘 / 微信 / 文件管理，换机后从文件导入恢复'),
          _infoLine('清空只移除真实占卜记录，内置示例与收藏不受影响'),
        ]),
      );

  Widget _infoLine(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            margin: const EdgeInsets.only(top: 5, right: 8),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
                color: YiColors.cinnabar, shape: BoxShape.circle),
          ),
          Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 10, height: 1.5, color: YiColors.textTertiary))),
        ]),
      );

  Widget _item({
    required IconData icon,
    required String name,
    required String desc,
    required VoidCallback onTap,
    bool danger = false,
  }) {
    final color = danger ? YiColors.cinnabar : YiColors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: PressableScale(
        onTap: onTap,
        child: AnimatedContainer(
          duration: YiMotion.base,
          curve: YiMotion.easeOutExpo,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
          decoration: BoxDecoration(
            color: danger
                ? YiColors.cinnabar.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: danger
                    ? YiColors.cinnabar.withValues(alpha: 0.45)
                    : Colors.transparent),
          ),
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
