// 引擎逻辑验证 (纯 Dart, 无需 flutter tester)
// 运行: flutter/bin/dart run tool/verify_engine.dart
import 'package:yijing_transform/data/hex_repository.dart';

int pass = 0, fail = 0;
void check(String name, bool ok, [String? detail]) {
  if (ok) { pass++; print('PASS $name'); }
  else { fail++; print('FAIL $name ${detail ?? ''}'); }
}

void main() {
  final repo = HexRepository.instance..init();

  // 数据完整性
  check('64 卦加载', repo.hexByNo(64).name == '未济', repo.hexByNo(64).name);
  check('乾全阳', repo.hexByNo(1).yangs.every((y) => y));
  check('坤全阴', repo.hexByNo(2).yangs.every((y) => !y));

  // 乾九三动 → 履 (与易道默认一致)
  final r1 = repo.transform(1, [2]);
  check('乾九三动 → 变履', r1.changed.name == '履', r1.changed.name + '/' + r1.changed.no.toString());
  check('互卦乾', r1.hu.name == '乾', r1.hu.name);

  // 坤初六动 → 复
  final r2 = repo.transform(2, [0]);
  check('坤初六动 → 变复', r2.changed.name == '复', r2.changed.name);

  // 泰卦上爻动: 上坤(土)为用, 下乾(金)为体 → 用生体大吉
  // 泰 = 地天泰 no.11 (triU=☷坤, triD=☰乾); 否 = 天地否 no.12 (反)
  final r3 = repo.transform(11, [5]);
  check('泰上爻动 → 用坤土生体乾金 → 用生体大吉',
      r3.ben.name == '泰' && r3.yongWuxing == '土' && r3.tiWuxing == '金'
          && r3.relation == '用生体' && r3.verdict == '大吉',
      '${r3.tiName}(${r3.tiWuxing}) ${r3.relation} ${r3.verdict}');

  // 比和
  final r4 = repo.transform(1, []);
  check('乾无动 → 比和吉', r4.relation == '比和' && r4.verdict == '吉',
      '${r4.relation}/${r4.verdict}');

  // 多动爻
  final r5 = repo.transform(3, [0, 4]); // 屯卦 初九+九五动
  check('屯初九五动 → 变卦非屯', r5.changed.name != '屯', r5.changed.name);
  check('动爻排序', r5.moving.join(',') == '0,4', r5.moving.join(','));

  print('\n结果: $pass 通过, $fail 失败');
  if (fail > 0) { throw StateError('$fail 项失败'); }
}
