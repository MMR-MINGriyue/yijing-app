import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../model/hex.dart';
import '../data/hex_advice.dart';
import 'widgets/hex_glyph.dart';
import 'widgets/share_card.dart';
import 'widgets/yao_sheet.dart';
import '../theme/ink_wash.dart';
import '../theme/yi_transitions.dart';
import '../theme/yijing_theme.dart';
import '../viewmodel/detail_viewmodel.dart';

/// 屏 4 卦辞解析 — View 层 (纯 UI)
class DetailScreen extends StatefulWidget {
  final DetailViewModel vm;
  final void Function(Hex hex)? onOpenTransform;
  final Future<void> Function(Hex hex, List<int> moving, String question)? onShare;

  const DetailScreen({super.key, required this.vm, this.onOpenTransform, this.onShare});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _yaoExpanded = false; // 六爻展开/折叠 (PWA对齐: 默认仅显示初/二爻)

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
    final h = widget.vm.hex;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: YiColors.gold,
        title: const Text('卦 辞 解 析', style: TextStyle(letterSpacing: 6, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, size: 19),
            onPressed: _share,
            tooltip: '生成分享卡',
          ),
          _FavStar(
            fav: widget.vm.isFav(h.no),
            onTap: () => widget.vm.toggleFav(h.no),
          ),
        ],
      ),
      body: YiInkWash(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: _onHorizontalDragEnd,
          child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          _hero(h),
          const SizedBox(height: 14),
          _tabs(),
          const SizedBox(height: 14),
          ..._tabContent(h),
          const SizedBox(height: 14),
          _advice(h),
          const SizedBox(height: 16),
          if (widget.onOpenTransform != null) _openTransformBtn(h),
          const SizedBox(height: 12),
          _shareBtn(h),
          const SizedBox(height: 16),
          _yaoList(h),
        ],
      ),
      ),
      ),
    );
  }

  // ---------- hero: 卦象 + 卦名 + 引文 ----------
  Widget _hero(Hex h) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: yiCardDecoration(border: YiColors.stroke, radius: 20),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _miniYaoStack(h),
          const SizedBox(width: 22),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('第 ${h.no} 卦 · ${h.title}',
                style: const TextStyle(fontSize: 12, letterSpacing: 3, color: YiColors.textTertiary)),
            const SizedBox(height: 8),
            Text('${h.name} 卦', style: const TextStyle(
                fontSize: 30, fontWeight: FontWeight.w500, letterSpacing: 8, color: YiColors.textPrimary)),
            const SizedBox(height: 6),
            Text(h.en, style: const TextStyle(fontSize: 11, letterSpacing: 2, color: YiColors.gold)),
            const SizedBox(height: 6),
            Text(h.virtue, style: const TextStyle(fontSize: 13, letterSpacing: 2, color: YiColors.cinnabar)),
          ]),
        ]),
        const SizedBox(height: 12),
        Text('「${h.guaci}」', textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, height: 1.6, color: YiColors.textPrimary)),
      ]),
    );
  }

  /// 左右滑动切换卦象 (iter49): 左滑下一卦, 右滑上一卦, 1↔64 环绕
  void _onHorizontalDragEnd(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v.abs() < 450) return;
    final delta = v < 0 ? 1 : -1; // 左滑 → 下一卦
    final next = ((widget.vm.hex.no - 1 + delta) % 64 + 64) % 64 + 1;
    if (next == widget.vm.hex.no) return;
    Navigator.of(context).pushReplacement(yiFadeRoute(DetailScreen(
      vm: DetailViewModel(
        hexNo: next,
        question: widget.vm.question,
        direction: widget.vm.direction,
      ),
      onOpenTransform: widget.onOpenTransform,
      onShare: widget.onShare,
    )));
  }

  Widget _miniYaoStack(Hex h) {
    // iter45: 统一走 HexGlyph (金渐变爻身, 与全应用卦爻视觉一致)
    return HexGlyph(lines: h.yangs, width: 44, lineH: 5.5, gap: 5);
  }

  // ---------- Tab: 卦辞 / 爻辞 / 象传 ----------
  Widget _tabs() {
    const tabs = [(DetailTab.guaci, '卦辞'), (DetailTab.yaoci, '爻辞'), (DetailTab.xiangzhuan, '象传')];
    return Row(children: [
      for (final (t, label) in tabs)
        Expanded(
          child: InkWell(
            onTap: () => widget.vm.setTab(t),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 2,
                    color: widget.vm.tab == t ? YiColors.cinnabar : YiColors.strokeSoft,
                  ),
                ),
              ),
              child: Text(label, textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14, letterSpacing: 4,
                    color: widget.vm.tab == t ? YiColors.cinnabar : YiColors.textTertiary,
                  )),
            ),
          ),
        ),
    ]);
  }

  List<Widget> _tabContent(Hex h) {
    return switch (widget.vm.tab) {
      DetailTab.guaci => [_textCard('本 卦 卦 辞', h.guaci, h.intro)],
      DetailTab.yaoci => [
          for (final y in h.yao)
            _textCard(y.n, y.q, y.d),
        ],
      DetailTab.xiangzhuan => [
          _textCard('大 象', h.daxiang,
              '上卦${h.triUN}、下卦${h.triDN}，象取「${h.virtue}」。'),
          _textCard('卦 德', h.virtue,
              '得「${h.name}卦」，宜体「${h.virtue}」之义，守正而行，则吉无不利。'),
        ],
    };
  }

  Widget _textCard(String label, String quote, String body) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: yiCardDecoration(),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(
            fontSize: 11, letterSpacing: 3, color: YiColors.textTertiary)),
        const SizedBox(height: 10),
        Text(quote, style: const TextStyle(
            fontSize: 14, height: 1.6, letterSpacing: 0.5, color: YiColors.textPrimary)),
        const SizedBox(height: 8),
        Text(body, style: const TextStyle(
            fontSize: 12, height: 1.7, color: YiColors.textSecondary)),
      ]),
    );
  }

  // ---------- 方向建议 (iter42: 事业/感情/财运 三分栏, per-hex 数据源) ----------
  Widget _advice(Hex h) {
    final dir = widget.vm.adviceDir;
    final text = kHexAdvice[h.no]?[dir] ??
        '按「${h.virtue}」之义行事，守正以待时。';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1AD04D3E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x55D04D3E)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('方 向 建 议', style: const TextStyle(
            fontSize: 11, letterSpacing: 3, color: YiColors.cinnabar)),
        const SizedBox(height: 8),
        Text('综 述 · ${h.virtue}', style: const TextStyle(
            fontSize: 11, color: YiColors.textTertiary)),
        const SizedBox(height: 6),
        Text(h.intro, style: const TextStyle(
            fontSize: 13, height: 1.7, color: YiColors.textSecondary)),
        const SizedBox(height: 12),
        Row(children: [
          for (final d in kAdviceDirections) ...[
            Expanded(child: _adviceChip(d)),
            if (d != kAdviceDirections.last) const SizedBox(width: 8),
          ],
        ]),
        const SizedBox(height: 10),
        AnimatedSwitcher(
          duration: YiMotion.base,
          switchInCurve: YiMotion.easeOutExpo,
          switchOutCurve: YiMotion.easeOutExpo,
          child: Text(
            text,
            key: ValueKey('advice-${h.no}-$dir'),
            style: const TextStyle(
                fontSize: 13, height: 1.7, color: YiColors.gold),
          ),
        ),
      ]),
    );
  }

  Widget _adviceChip(String d) {
    final selected = widget.vm.adviceDir == d;
    final color = switch (d) {
      '事业' => YiColors.cinnabar,
      '感情' => YiColors.pine,
      _ => YiColors.gold,
    };
    return InkWell(
      onTap: () => widget.vm.setAdviceDir(d),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: YiMotion.base,
        curve: YiMotion.easeOutExpo,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : YiColors.inkCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : YiColors.stroke),
        ),
        alignment: Alignment.center,
        child: Text(d, style: TextStyle(
            fontSize: 12, letterSpacing: 2,
            color: selected ? color : YiColors.textSecondary)),
      ),
    );
  }

  // ---------- 分享卡 (PWA YijingShare 同款布局) ----------
  void _share() {
    final mv = widget.vm.moving;
    final action = widget.onShare ?? _shareCardDefault;
    action(widget.vm.hex, mv, widget.vm.question);
  }

  Widget _shareBtn(Hex h) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _share,
        style: OutlinedButton.styleFrom(
          foregroundColor: YiColors.gold,
          side: const BorderSide(color: YiColors.goldDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: const Icon(Icons.ios_share, size: 17),
        label: const Text('生成分享卡', style: TextStyle(letterSpacing: 4, fontSize: 13)),
      ),
    );
  }

  Widget _openTransformBtn(Hex h) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => widget.onOpenTransform!(h),
        style: OutlinedButton.styleFrom(
          foregroundColor: YiColors.gold,
          side: const BorderSide(color: YiColors.goldDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        icon: const Icon(Icons.change_history_outlined, size: 18),
        label: const Text('查看变卦推演', style: TextStyle(letterSpacing: 4, fontSize: 13)),
      ),
    );
  }

  // ---------- 六爻解读 (PWA对齐: 默认显示初/二爻, 可展开全部六爻) ----------
  Widget _yaoList(Hex h) {
    final visibleCount = _yaoExpanded ? 6 : 2;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: const [
        Expanded(child: Divider(color: YiColors.strokeSoft)),
        Padding(padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('六 爻 解 读', style: TextStyle(fontSize: 11, letterSpacing: 3, color: YiColors.textTertiary))),
        Expanded(child: Divider(color: YiColors.strokeSoft)),
      ]),
      const SizedBox(height: 6),
      AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: Column(children: [
          for (var i = 0; i < visibleCount; i++)
            InkWell(
              key: ValueKey('yao-$i'),
              onTap: () => showYaoSheet(context, h, i),
              borderRadius: BorderRadius.circular(10),
              child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 28, height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0x22C9A876),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(h.yao[i].n[0], style: const TextStyle(
                      fontSize: 13, color: YiColors.gold, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(h.yao[i].n, style: const TextStyle(fontSize: 13, color: YiColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(h.yao[i].d.isEmpty ? h.yao[i].q : '${h.yao[i].q} ${h.yao[i].d}',
                      style: const TextStyle(fontSize: 11, height: 1.6, color: YiColors.textSecondary)),
                ])),
              ]),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 8),
      _yaoToggle(),
    ]);
  }

  /// 六爻展开/折叠切换按钮 (PWA yao-toggle 同款: 虚线框 + 卦象图标 + 文字 + 箭头)
  Widget _yaoToggle() {
    return InkWell(
      onTap: () => setState(() => _yaoExpanded = !_yaoExpanded),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: YiColors.strokeSoft, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          // 卦象小图标 (5条横线)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: YiColors.gold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (var k = 0; k < 5; k++)
                Container(
                  width: 14, height: 1.5,
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    color: _yaoExpanded ? YiColors.cinnabar : YiColors.gold,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
            ]),
          ),
          const SizedBox(width: 10),
          Text(
            _yaoExpanded ? '收 起 末 四 爻' : '展 开 全 部 六 爻',
            style: TextStyle(
              fontSize: 11, letterSpacing: 2,
              color: _yaoExpanded ? YiColors.cinnabar : YiColors.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          AnimatedRotation(
            turns: _yaoExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 300),
            child: Icon(
              Icons.keyboard_arrow_down, size: 16,
              color: _yaoExpanded ? YiColors.cinnabar : YiColors.gold,
            ),
          ),
        ]),
      ),
    );
  }
}


/// 默认分享实现: 渲染分享卡 PNG → 临时文件 → 系统分享 (PWA YijingShare 同款卡面)
Future<void> _shareCardDefault(Hex hex, List<int> moving, String question) async {
  final img = await renderShareCardImage(ShareCardData(
    hex: hex,
    moving: moving,
    question: question,
    now: DateTime.now(),
  ));
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final dir = await getTemporaryDirectory();
  final stamp = DateTime.now().millisecondsSinceEpoch;
  final file = File('${dir.path}/yijing-share-${hex.no}-$stamp.png');
  await file.writeAsBytes(byteData!.buffer.asUint8List());
  await SharePlus.instance.share(ShareParams(
    files: [XFile(file.path)],
    text: '易道 · ${hex.name}卦 · ${hex.desc}',
  ));
}


/// 收藏星 — 切换时 scale 1→1.34→1 弹跳 (PWA v1.17 pop 反馈)
class _FavStar extends StatefulWidget {
  final bool fav;
  final VoidCallback onTap;

  const _FavStar({required this.fav, required this.onTap});

  @override
  State<_FavStar> createState() => _FavStarState();
}

class _FavStarState extends State<_FavStar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void didUpdateWidget(covariant _FavStar old) {
    super.didUpdateWidget(old);
    if (old.fav != widget.fav) _ctrl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, _) {
          final t = _ctrl.value;
          // 弹跳: 0→0.4 抬到 1.34, 0.4→1 回落; 峰值带 -10° 旋转
          final phase = t < 0.4 ? Curves.easeOut.transform(t / 0.4)
              : Curves.easeOutBack.transform((t - 0.4) / 0.6);
          final scale = 1.0 + 0.34 * (t == 0 ? 0.0 : (1 - phase));
          final rotate = t == 0 ? 0.0 : -0.17 * (1 - phase);
          return Transform.rotate(
            angle: rotate,
            child: Transform.scale(
              scale: scale,
              child: Icon(
                widget.fav ? Icons.star : Icons.star_border,
                size: 22,
                color: widget.fav ? YiColors.cinnabar : YiColors.textTertiary,
              ),
            ),
          );
        },
      ),
    );
  }
}
