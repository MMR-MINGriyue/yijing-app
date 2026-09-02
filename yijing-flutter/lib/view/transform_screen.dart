import 'package:flutter/material.dart';

import '../model/hex.dart';
import '../theme/yijing_theme.dart';
import '../viewmodel/transform_viewmodel.dart';

/// 屏 5 变卦推演 — View 层 (纯 UI, 一切状态来自 ViewModel)
class TransformScreen extends StatefulWidget {
  final TransformViewModel vm;
  const TransformScreen({super.key, required this.vm});

  @override
  State<TransformScreen> createState() => _TransformScreenState();
}

class _TransformScreenState extends State<TransformScreen> {
  @override
  void initState() {
    super.initState();
    widget.vm.addListener(_onVm);
  }

  @override
  void dispose() {
    widget.vm.removeListener(_onVm);
    super.dispose();
  }

  void _onVm() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final s = widget.vm.state;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: YiColors.ink,
        foregroundColor: YiColors.gold,
        centerTitle: true,
        title: const Text('变 卦 推 演', style: TextStyle(letterSpacing: 6, color: YiColors.textPrimary, fontSize: 17)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _hexPairCard(context, s),
          const SizedBox(height: 14),
          _movingNote(s),
          const SizedBox(height: 14),
          _detailCard(context, s),
          const SizedBox(height: 14),
          _adviceCard(s),
          const SizedBox(height: 20),
          _hexPicker(context),
        ],
      ),
    );
  }

  // ---------- 本卦 / 变卦 / 互卦 三卡片 ----------
  Widget _hexPairCard(BuildContext context, TransformState s) {
    final r = s.result;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDeco(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _hexCol('本 卦 · ${r.ben.name}', r.ben, s.moving, isCurrent: true, onTap: (i) => widget.vm.toggleMoving(i)),
          _hexCol('变 卦 · ${r.changed.name}', r.changed, const [], isCurrent: false, onTap: null),
          _hexCol('互 卦 · ${r.hu.name}', r.hu, const [], isCurrent: false, onTap: null),
        ],
      ),
    );
  }

  Widget _hexCol(String label, Hex hex, List<int> moving, {required bool isCurrent, void Function(int)? onTap}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, letterSpacing: 2,
            color: isCurrent ? YiColors.textTertiary : YiColors.cinnabar)),
        const SizedBox(height: 10),
        _YaoStack(hex: hex, moving: moving, onTap: onTap),
        const SizedBox(height: 8),
        Text(hex.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500,
            letterSpacing: 6, color: YiColors.textPrimary)),
      ],
    );
  }

  Widget _movingNote(TransformState s) {
    final r = s.result;
    final mvText = r.moving.isEmpty ? '无 动 爻'
        : r.moving.map((i) => r.ben.yaoName(i) + ' 动').join(' · ');
    return Row(
      children: [
        Container(width: 7, height: 7, decoration: const BoxDecoration(color: YiColors.cinnabar, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(mvText, style: const TextStyle(color: YiColors.textPrimary, fontSize: 13, letterSpacing: 1)),
      ],
    );
  }

  // ---------- 推演明细卡 ----------
  Widget _detailCard(BuildContext context, TransformState s) {
    final r = s.result;
    final changes = widget.vm.yaoChanges();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${r.ben.name}卦 · ${kTriNature[r.ben.triU]}${kTriNature[r.ben.triD]}', style: const TextStyle(fontSize: 16, letterSpacing: 2, color: YiColors.textPrimary)),
          const SizedBox(height: 12),
          for (final c in changes) _diffRow(c),
          if (changes.isEmpty)
            const Text('点击上方本卦任意爻，生成变卦推演', style: TextStyle(color: YiColors.textTertiary, fontSize: 12)),
          const SizedBox(height: 12),
          _relationRow(r),
        ],
      ),
    );
  }

  Widget _diffRow(YaoChange c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(width: 48, child: Text(c.from, style: const TextStyle(color: YiColors.textTertiary, fontSize: 12))),
        const Text('→', style: TextStyle(color: YiColors.gold, fontSize: 13)),
        const SizedBox(width: 10),
        Text('第 ${c.idx + 1} 爻', style: const TextStyle(color: YiColors.textSecondary, fontSize: 12)),
        const SizedBox(width: 10),
        Container(width: 26, height: 3, color: c.fromYang ? YiColors.gold : YiColors.goldDark),
        const Text(' 变 ', style: TextStyle(color: YiColors.cinnabar, fontSize: 11)),
        Container(width: 26, height: 3, color: c.fromYang ? YiColors.goldDark : YiColors.gold),
        Text(c.to, style: const TextStyle(color: YiColors.cinnabar, fontSize: 12)),
      ]),
    );
  }

  Widget _relationRow(TransformResult r) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0x1AC9A876),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x55C9A876)),
      ),
      child: Row(children: [
        Text('体 ${r.tiName}(${r.tiWuxing})', style: const TextStyle(color: YiColors.textPrimary, fontSize: 12)),
        const SizedBox(width: 14),
        Text(r.relation, style: const TextStyle(color: YiColors.gold, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(width: 14),
        Text('用 ${r.yongName}(${r.yongWuxing})', style: const TextStyle(color: YiColors.textSecondary, fontSize: 12)),
        const Spacer(),
        Text(r.verdict, style: TextStyle(
          color: _verdictColor(r.verdict), fontSize: 15, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Color _verdictColor(String v) {
    if (v == '凶') return YiColors.cinnabar;
    if (v == '吉' || v == '大吉') return YiColors.pine;
    if (v == '小吉') return const Color(0xFFC9A876);
    return YiColors.textTertiary;
  }

  // ---------- 个性化建议 ----------
  Widget _adviceCard(TransformState s) {
    final r = s.result;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('从 ${r.ben.name} 至 ${r.changed.name} 之 推 演', style: const TextStyle(
            fontSize: 12, letterSpacing: 2, color: YiColors.cinnabar)),
        const SizedBox(height: 8),
        Text(r.verdictText, style: const TextStyle(color: YiColors.textSecondary, fontSize: 13, height: 1.7)),
      ]),
    );
  }

  // ---------- 选卦 ----------
  Widget _hexPicker(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('换 一 卦 推 演', style: TextStyle(color: YiColors.textTertiary, fontSize: 12, letterSpacing: 2)),
      const SizedBox(height: 10),
      SizedBox(
        height: 120,
        child: GridView.count(
          crossAxisCount: 8,
          childAspectRatio: 0.9,
          scrollDirection: Axis.vertical,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            for (var no = 1; no <= 64; no++)
              _hexPickerCell(no),
          ],
        ),
      ),
    ]);
  }

  Widget _hexPickerCell(int no) {
    final hex = widget.vm.hexByNo(no);
    final active = widget.vm.state.benNo == no;
    return InkWell(
      onTap: () => widget.vm.selectHex(no),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: active ? const Color(0x33D04D3E) : const Color(0x0AFFFFFF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: active ? const Color(0x88D04D3E) : const Color(0x1AFFFFFF)),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(hex.name, style: TextStyle(fontSize: 15,
              color: active ? YiColors.cinnabar : YiColors.textSecondary)),
          Text('${hex.no}', style: const TextStyle(fontSize: 9, color: YiColors.textMuted)),
        ]),
      ),
    );
  }

  BoxDecoration _cardDeco() {
    return BoxDecoration(
      color: YiColors.inkCard,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: YiColors.stroke),
    );
  }
}

/// 爻象竖排 (上爻在上, 初爻在下); 阳爻实线 阴爻两短段
class _YaoStack extends StatelessWidget {
  final Hex hex;
  final List<int> moving;
  final void Function(int i)? onTap; // 点击爻 → 切换动爻 (仅本卦)

  const _YaoStack({required this.hex, required this.moving, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 5; i >= 0; i--) // 上爻 → 初爻
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.5),
            child: InkWell(
              onTap: onTap == null ? null : () => onTap!(i),
              borderRadius: BorderRadius.circular(2),
              child: _yaoLine(hex.yangs[i], moving.contains(i), hex.yaoName(i)),
            ),
          ),
      ],
    );
  }

  Widget _yaoLine(bool yang, bool isMoving, String name) {
    final color = isMoving ? YiColors.cinnabar : YiColors.gold;
    Widget line() => Container(
      width: yang ? 44 : 20,
      height: 4,
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
    );
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      SizedBox(width: 52, child: Center(
        child: isMoving
            ? Text(name, style: const TextStyle(fontSize: 9, color: YiColors.cinnabar))
            : const SizedBox.shrink(),
      )),
      if (yang)
        line()
      else
        Row(children: [
          Container(width: 20, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 4),
          Container(width: 20, height: 4, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        ]),
    ]);
  }
}
