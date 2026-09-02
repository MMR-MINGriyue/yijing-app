// 引擎逻辑验证 (纯 Dart, 无需 flutter tester)
// 运行: flutter/bin/dart run tool/verify_engine.dart
// ignore_for_file: avoid_print
import 'package:yijing_transform/data/hex_repository.dart';

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
  // ignore: avoid_print
  print('Hex library engine verification (iter30)');
  final repo = HexRepository.instance..init();

  check('64 卦加载', repo.hexByNo(64).name == '未济', repo.hexByNo(64).name);
  check('乾全阳', repo.hexByNo(1).yangs.every((y) => y));
  check('坤全阴', repo.hexByNo(2).yangs.every((y) => !y));

  final r1 = repo.transform(1, [2]);
  check('乾九三动 → 变履', r1.changed.name == '履',
      '${r1.changed.name}/${r1.changed.no}');
  check('互卦乾', r1.hu.name == '乾', r1.hu.name);

  final r2 = repo.transform(2, [0]);
  check('坤初六动 → 变复', r2.changed.name == '复', r2.changed.name);

  // 泰 = 地天泰 no.11: triU=☷坤, triD=☰乾. 上爻动 → 用=上坤(土), 体=下乾(金) → 用生体大吉
  final r3 = repo.transform(11, [5]);
  check('泰上爻动 → 用坤土生体乾金 → 用生体大吉',
      r3.ben.name == '泰' &&
          r3.yongWuxing == '土' &&
          r3.tiWuxing == '金' &&
          r3.relation == '用生体' &&
          r3.verdict == '大吉',
      '${r3.tiName}(${r3.tiWuxing}) ${r3.relation} ${r3.verdict}');

  final r4 = repo.transform(1, []);
  check('乾无动 → 比和吉',
      r4.relation == '比和' && r4.verdict == '吉',
      '${r4.relation}/${r4.verdict}');

  final r5 = repo.transform(3, [0, 4]);
  check('屯初九五动 → 变卦非屯', r5.changed.name != '屯', r5.changed.name);
  check('动爻排序', r5.moving.join(',') == '0,4', r5.moving.join(','));

  // ignore: avoid_print
  print('\n结果: $pass 通过, $fail 失败');
  if (fail > 0) { throw StateError('$fail 项失败'); }
}
