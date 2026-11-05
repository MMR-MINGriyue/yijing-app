/// 先天八卦表 (iter57) — 梅花易数先天数序: 乾兑离震巽坎艮坤.
/// bits 为三爻自下而上 ('1'=阳 '0'=阴), 供转盘绘制卦符.
library;

const List<({String name, String nature, String bits})> kBaguaXiantian = [
  (name: '乾', nature: '天', bits: '111'),
  (name: '兑', nature: '泽', bits: '110'),
  (name: '离', nature: '火', bits: '101'),
  (name: '震', nature: '雷', bits: '100'),
  (name: '巽', nature: '风', bits: '011'),
  (name: '坎', nature: '水', bits: '010'),
  (name: '艮', nature: '山', bits: '001'),
  (name: '坤', nature: '地', bits: '000'),
];

/// 自然名 → 先天八卦序号 (0..7); 未命中回退 0 (乾)
int baguaIndexOf(String nature) {
  final i = kBaguaXiantian.indexWhere((e) => e.nature == nature);
  return i < 0 ? 0 : i;
}
