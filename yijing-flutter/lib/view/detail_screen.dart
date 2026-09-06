import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../model/hex.dart';
import 'widgets/share_card.dart';
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
      backgroundColor: YiColors.ink,
      appBar: AppBar(
        backgroundColor: YiColors.ink,
        foregroundColor: YiColors.gold,
        title: const Text('卦 辞 解 析', style: TextStyle(letterSpacing: 6, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, size: 19),
            onPressed: _share,
            tooltip: '生成分享卡',
          ),
          IconButton(
            icon: Icon(widget.vm.isFav(h.no) ? Icons.star : Icons.star_border,
                color: widget.vm.isFav(h.no) ? YiColors.cinnabar : YiColors.textTertiary),
            onPressed: () => widget.vm.toggleFav(h.no),
            tooltip: '收藏此卦',
          ),
        ],
      ),
      body: ListView(
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
    );
  }

  // ---------- hero: 卦象 + 卦名 + 引文 ----------
  Widget _hero(Hex h) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YiColors.inkCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: YiColors.stroke),
      ),
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

  Widget _miniYaoStack(Hex h) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      for (var i = 5; i >= 0; i--)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Container(width: h.yangs[i] ? 44 : 20, height: 4,
              decoration: BoxDecoration(color: YiColors.gold, borderRadius: BorderRadius.circular(2))),
        ),
    ]);
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
      decoration: BoxDecoration(
        color: YiColors.inkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: YiColors.strokeSoft),
      ),
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

  // ---------- 个性化建议 ----------
  Widget _advice(Hex h) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0x1AD04D3E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x55D04D3E)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('个 性 化 建 议', style: const TextStyle(
            fontSize: 11, letterSpacing: 3, color: YiColors.cinnabar)),
        const SizedBox(height: 8),
        Text('综 述 · ${h.virtue}', style: const TextStyle(
            fontSize: 11, color: YiColors.textTertiary)),
        const SizedBox(height: 6),
        Text(h.intro, style: const TextStyle(
            fontSize: 13, height: 1.7, color: YiColors.textSecondary)),
      ]),
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

  // ---------- 爻辞弹窗 (点击爻行, PWA 屏4 行为) ----------
  void _showYaoSheet(Hex h, int i) {
    final yao = h.yao[i];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: YiColors.inkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('${yao.n} · ${h.name}卦',
                    style: const TextStyle(
                        fontSize: 16, letterSpacing: 2, color: YiColors.gold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: YiColors.textTertiary),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(
                        text: '${yao.n} · ${h.name}卦\n${yao.q}\n${yao.d}'));
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                        content:
                            Text('爻辞已复制', style: TextStyle(color: YiColors.textPrimary)),
                        backgroundColor: Color(0xFF231A11),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ));
                    }
                  },
                  tooltip: '复制爻辞',
                ),
              ]),
              const SizedBox(height: 8),
              Text(yao.q,
                  style: const TextStyle(
                      fontSize: 15, height: 1.7, color: YiColors.textPrimary)),
              const SizedBox(height: 8),
              Text(yao.d,
                  style: const TextStyle(
                      fontSize: 13, height: 1.7, color: YiColors.textSecondary)),
            ]),
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

  // ---------- 六爻解读 ----------
  Widget _yaoList(Hex h) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: const [
        Expanded(child: Divider(color: YiColors.strokeSoft)),
        Padding(padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('六 爻 解 读', style: TextStyle(fontSize: 11, letterSpacing: 3, color: YiColors.textTertiary))),
        Expanded(child: Divider(color: YiColors.strokeSoft)),
      ]),
      const SizedBox(height: 6),
      for (var i = 0; i < 6; i++)
        InkWell(
          onTap: () => _showYaoSheet(h, i),
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
    ]);
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
