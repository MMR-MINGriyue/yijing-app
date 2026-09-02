// 引擎 + 屏4数据 + 屏6数据 逻辑验证 (纯 Dart, 无 flutter 依赖)
// 运行: flutter/bin/dart run tool/verify_engine.dart
// 说明: ViewModel 测试见 test/ (需 flutter test)
// ignore_for_file: avoid_print
import 'package:yijing_transform/data/hex_repository.dart';
import 'package:yijing_transform/data/history_repository.dart';

int pass = 0, fail = 0;
void check(String name, bool ok, [String? detail]) {
  if (ok) {
    pass++;
    print('PASS $name');
  } else {
    fail++;
    print('FAIL $name ${detail ?? ''}');
  }
}

void main() {
  final repo = HexRepository.instance..init();

  // ---- 数据完整性 (新完整数据格式) ----
  check('64 卦加载', repo.hexByNo(64).name == '未济', repo.hexByNo(64).name);
  check('乾全阳', repo.hexByNo(1).yangs.every((y) => y));
  check('坤全阴', repo.hexByNo(2).yangs.every((y) => !y));

  // ---- 屏4 数据 (卦辞/爻辞/象传) ----
  final qian = repo.hexByNo(1);
  check('乾卦辞含元亨利贞', qian.guaci.contains('元'), qian.guaci);
  check('乾大象 = 天行健', qian.daxiang.contains('天行健'), qian.daxiang);
  check('乾 intro 非空', qian.intro.isNotEmpty);
  check('乾 6 爻辞', qian.yao.length == 6, qian.yao.length.toString());
  check('初九爻名/爻辞', qian.yao[0].n == '初九' && qian.yao[0].q.contains('潜龙'),
      '${qian.yao[0].n} ${qian.yao[0].q}');
  check('上九爻辞', qian.yao[5].q.contains('亢龙'), qian.yao[5].q);
  check('desc 拆分 title/virtue', qian.title == '乾为天' && qian.virtue == '刚健中正',
      '${qian.title}|${qian.virtue}');
  check('上卦/下卦自然名', qian.triUN == '天' && qian.triDN == '天');
  check('64 卦都有 6 爻辞', (() {
    for (var i = 1; i <= 64; i++) {
      if (repo.hexByNo(i).yao.length != 6) return false;
    }
    return true;
  })());
  check('64 卦卦辞全非空', (() {
    for (var i = 1; i <= 64; i++) {
      if (repo.hexByNo(i).guaci.isEmpty) return false;
    }
    return true;
  })());
  check('64 卦象传全非空', (() {
    for (var i = 1; i <= 64; i++) {
      if (repo.hexByNo(i).daxiang.isEmpty) return false;
    }
    return true;
  })());

  // ---- 屏5 引擎 (回归) ----
  final r1 = repo.transform(1, [2]);
  check('乾九三动 → 变履', r1.changed.name == '履',
      '${r1.changed.name}/${r1.changed.no}');
  check('互卦乾', r1.hu.name == '乾', r1.hu.name);
  final r2 = repo.transform(2, [0]);
  check('坤初六动 → 变复', r2.changed.name == '复', r2.changed.name);
  final r3 = repo.transform(11, [5]);
  check('泰上爻动 → 用生体大吉',
      r3.relation == '用生体' && r3.verdict == '大吉',
      '${r3.tiName}(${r3.tiWuxing}) ${r3.relation} ${r3.verdict}');
  final r4 = repo.transform(1, []);
  check('乾无动 → 比和吉',
      r4.relation == '比和' && r4.verdict == '吉', '${r4.relation}/${r4.verdict}');
  final r5 = repo.transform(3, [0, 4]);
  check('动爻排序', r5.moving.join(',') == '0,4', r5.moving.join(','));

  // ---- 屏6 历史数据 (repository 层) ----
  final histRepo = HistoryRepository.instance;
  final list = histRepo.load();
  check('历史 mock 数据 ≥ 8 条', list.length >= 8, list.length.toString());
  check('月份范围覆盖上月', histRepo.monthRange().minM <= DateTime.now().month - 1,
      '${histRepo.monthRange().minY}-${histRepo.monthRange().minM}');
  check('本月记录非空', histRepo.ofMonth(DateTime.now().year, DateTime.now().month).isNotEmpty);
  check('含非卦类占法 (type=bazi/xlr)', list.any((r) => r.type == 'bazi') && list.any((r) => r.type == 'xlr'));
  check('含卦象 lines (iching)', list.where((r) => r.type == 'iching').every((r) => r.lines != null && r.lines!.length == 6));
  check('方向覆盖事业/感情/财运', ['事业', '感情', '财运'].every((d) => list.any((r) => r.direction == d)));

  print('\n结果: $pass 通过, $fail 失败');
  if (fail > 0) { throw StateError('$fail 项失败'); }
}
