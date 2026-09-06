# -*- coding: utf-8 -*-
# iter36: detail_screen 分享卡 + 爻辞弹窗; detail_viewmodel question 字段
import io

# ---------- detail_viewmodel.dart ----------
p = 'lib/viewmodel/detail_viewmodel.dart'
s = io.open(p, encoding='utf-8').read()
s = s.replace("""  late Hex _hex;
  DetailTab _tab = DetailTab.guaci;

  DetailViewModel({HexRepository? repo, FavoritesRepository? favs, int hexNo = 1})
      : _repo = repo ?? HexRepository.instance,
        _favs = favs ?? FavoritesRepository.instance {
    _hex = _repo.hexByNo(hexNo);
  }

  Hex get hex => _hex;
  DetailTab get tab => _tab;""",
"""  late Hex _hex;
  DetailTab _tab = DetailTab.guaci;
  String _question = ''; // 所问之事 (分享卡用)

  DetailViewModel({HexRepository? repo, FavoritesRepository? favs, int hexNo = 1, String question = ''})
      : _repo = repo ?? HexRepository.instance,
        _favs = favs ?? FavoritesRepository.instance {
    _hex = _repo.hexByNo(hexNo);
    _question = question;
  }

  Hex get hex => _hex;
  DetailTab get tab => _tab;
  String get question => _question;""")
io.open(p, 'w', encoding='utf-8', newline='').write(s)

# ---------- detail_screen.dart ----------
p = 'lib/view/detail_screen.dart'
s = io.open(p, encoding='utf-8').read()

s = s.replace("""import 'package:flutter/material.dart';

import '../model/hex.dart';""",
"""import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../model/hex.dart';
import 'widgets/share_card.dart';""")

s = s.replace("""class DetailScreen extends StatefulWidget {
  final DetailViewModel vm;
  final void Function(Hex hex)? onOpenTransform;

  const DetailScreen({super.key, required this.vm, this.onOpenTransform});""",
"""class DetailScreen extends StatefulWidget {
  final DetailViewModel vm;
  final void Function(Hex hex)? onOpenTransform;
  final Future<void> Function(Hex hex, List<int> moving, String question)? onShare;

  const DetailScreen({super.key, required this.vm, this.onOpenTransform, this.onShare});""")

s = s.replace("""        actions: [
          IconButton(
            icon: Icon(widget.vm.isFav(h.no) ? Icons.star : Icons.star_border,
                color: widget.vm.isFav(h.no) ? YiColors.cinnabar : YiColors.textTertiary),
            onPressed: () => widget.vm.toggleFav(h.no),
            tooltip: '收藏此卦',
          ),
        ],""",
"""        actions: [
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
        ],""")

s = s.replace("""          if (widget.onOpenTransform != null) _openTransformBtn(h),
          const SizedBox(height: 16),
          _yaoList(h),""",
"""          if (widget.onOpenTransform != null) _openTransformBtn(h),
          const SizedBox(height: 12),
          _shareBtn(h),
          const SizedBox(height: 16),
          _yaoList(h),""")

s = s.replace("""  Widget _openTransformBtn(Hex h) {""",
"""  // ---------- 分享卡 (PWA YijingShare 同款布局) ----------
  void _share() {
    final mv = widget.vm.state?.result?.moving ?? const <int>[];
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

  Widget _openTransformBtn(Hex h) {""")

# 爻行加点击 (InkWell 包装)
old_yao = """      for (var i = 0; i < 6; i++)
        Padding(
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
    ]);
  }"""
assert old_yao in s, 'yao rows not found'
new_yao = """      for (var i = 0; i < 6; i++)
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
  }"""
s = s.replace(old_yao, new_yao)

# 文件末尾追加默认分享实现
s += """

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
"""

io.open(p, 'w', encoding='utf-8', newline='').write(s)
print('detail patched')
