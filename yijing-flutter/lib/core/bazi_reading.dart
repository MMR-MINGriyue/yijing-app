/// 八字解读 (iter47) — 日主心性 / 五行喜用 / 十神倾向 / 神煞释义
/// 传统命理通识撰写, 供参考启发, 不作宿命论断.
library;

import 'bazi.dart';

/// 解读卡
class BaziReading {
  final String title;
  final String body;
  const BaziReading({required this.title, required this.body});
}

// ---------- 日主心性 (十天干) ----------

const Map<String, String> kDayMasterTraits = {
  '甲': '甲木参天，正直向上。为人有担当、重原则，如栋梁之材，愿为他人遮风挡雨。'
      '宜立长志、行正道；忌固执不知回旋，木过刚则易折。',
  '乙': '乙木藤萝，柔韧善攀。心思细腻、能屈能伸，善借势而为，人缘颇佳。'
      '宜以柔克刚、择良木而栖；忌优柔寡断、依附失度。',
  '丙': '丙火太阳，光明磊落。热情外放、乐于照人，天生有感染力与舞台感。'
      '宜发挥热忱、普照四方；忌急躁张扬，火过旺则灼人灼己。',
  '丁': '丁火灯烛，温润幽明。心细而有灵性，善在细微处温暖他人，重情重义。'
      '宜守静持恒、以柔济事；忌多思多虑，灯火易为风扰。',
  '戊': '戊土高山，厚重沉稳。守信持重、包容大度，是可倚靠的中流砥柱。'
      '宜厚德载物、稳中求进；忌因循守旧，山不动则难通变。',
  '己': '己土田园，温厚滋养。随和务实、善于成全，默默孕育万物而不争。'
      '宜深耕细作、培育根基；忌耳软心活，田不耕则荒。',
  '庚': '庚金顽铁，刚毅果决。重义气、讲执行，遇事敢作敢当，百炼成锋。'
      '宜砥砺成器、以义服人；忌锋芒太露，金过利则伤人。',
  '辛': '辛金珠玉，精致清贵。审美出众、心气高洁，于细节处见真章。'
      '宜精雕细琢、术业专攻；忌恃才傲物，玉不经琢难成器。',
  '壬': '壬水江河，奔流不息。智慧圆融、格局开阔，善统筹而志在四方。'
      '宜顺势而行、汇流成海；忌泛滥无制，水无堤则漫溢。',
  '癸': '癸水雨露，静默润物。聪慧内敛、直觉敏锐，于无声处滋养众生。'
      '宜潜心积累、滴水穿石；忌阴郁多疑，露不聚则易散。',
};

// ---------- 神煞释义 ----------

const Map<String, String> kShenShaMeaning = {
  '天乙贵人': '命中最尊之吉星，主贵人扶助、逢凶化吉。遇难常得他人援手，宜广结善缘。',
  '文昌': '主聪慧文采、学业考试。利读书著作、策划谋略，宜勤学以承其吉。',
  '驿马': '主动象，主奔波远行、变迁升迁。利于外出发展、异地求财，静守反而不宜。',
  '桃花': '主异性缘与人际魅力。善用之则人缘助运，须防情感纠葛、心猿意马。',
  '华盖': '主孤高清雅、艺文宗教之缘。宜钻研专技、潜心创作，独处是其养分。',
};

/// 命中神煞 → 逐条释义
List<BaziReading> shenShaReadings(List<String> shenSha) {
  return [
    for (final s in shenSha)
      if (kShenShaMeaning.containsKey(s))
        BaziReading(title: '神煞 · $s', body: kShenShaMeaning[s]!),
  ];
}

// ---------- 五行喜用 ----------

const Map<String, List<String>> kShengKeFor = {
  // 该五行偏强时的喜用方向 (克我 / 我克 / 泄我)
  '木': ['金', '土', '火'], '火': ['水', '金', '土'], '土': ['木', '水', '金'],
  '金': ['火', '木', '水'], '水': ['土', '火', '木'],
};

const Map<String, List<String>> kShengInFor = {
  // 该五行偏弱时的喜用方向 (生我 / 同我)
  '木': ['水', '木'], '火': ['木', '火'], '土': ['火', '土'],
  '金': ['土', '金'], '水': ['金', '水'],
};

const Map<String, String> kElementLifeHint = {
  '木': '东方、青色绿意、草木园艺与生发之业',
  '火': '南方、赤色暖阳、电子能源与文教传播',
  '土': '中央、黄色厚土、地产基建与仓储实业',
  '金': '西方、白色金属、金融机械与精密制造',
  '水': '北方、玄色流水、贸易流通与智慧咨询',
};

/// 喜用建议: 依日主强弱取调候方向
BaziReading wuxingAdvice(BaZiChart c) {
  final el = c.dayElement;
  final weak = c.strength == '偏弱';
  final favor = (weak ? kShengInFor[el] : kShengKeFor[el]) ?? const ['?'];
  final avoid = (weak ? kShengKeFor[el] : kShengInFor[el]) ?? const ['?'];
  final favors = favor.join('、');
  final avoids = avoid.join('、');
  final hints = favor
      .where(kElementLifeHint.containsKey)
      .map((e) => '$e：${kElementLifeHint[e]}')
      .join('；');
  return BaziReading(
    title: '五行喜用 · 日主${c.dayGan}$el${c.strength}',
    body: '日主$el${weak ? '偏弱，宜生扶' : '偏强，宜疏导'}，喜$favors 之气，忌$avoids。\n'
        '取用方向：$hints。',
  );
}

// ---------- 十神倾向 ----------

const Map<String, String> kTenGodTrait = {
  '比肩': '自立自强、重朋友义气，宜合伙同侪共事，忌固执争强。',
  '劫财': '敢闯敢拼、行动力强，宜开拓进取，忌冲动破财、轻信他人。',
  '食神': '温厚有才艺、口福人缘俱佳，宜技艺创作与经营，忌耽于安逸。',
  '伤官': '聪颖外露、才华横溢，宜创意表达与技术革新，忌恃才傲物、口舌招尤。',
  '偏财': '慷慨豪爽、财路活络，宜开拓商机、把握时势，忌挥霍无度。',
  '正财': '务实勤俭、聚财有道，宜稳业积累、精打细算，忌过俭失机。',
  '七杀': '果敢决断、抗压强悍，宜竞争性事业与担纲重任，忌急躁树敌。',
  '正官': '自律守正、堪当制度之才，宜公职管理、名正言顺行事，忌过于保守。',
  '偏印': '思维独到、善悟玄理，宜研究专技与冷门领域，忌孤僻多虑。',
  '正印': '好学仁厚、易得长辈庇荫，宜学术文教、厚积薄发，忌依赖懒散。',
};

/// 十神倾向: 命局天干 + 藏干本气计数最多者为主倾向
List<BaziReading> tenGodReadings(BaZiChart c) {
  final stats = tenGodStats(c);
  if (stats.isEmpty) return const [];
  final sorted = stats.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final reads = <BaziReading>[];
  final top = sorted.first;
  if (kTenGodTrait.containsKey(top.key)) {
    reads.add(BaziReading(
      title: '格局倾向 · ${top.key}为显（${top.value}见）',
      body: kTenGodTrait[top.key]!,
    ));
  }
  final missing = kTenGodTrait.keys.where((k) => !stats.containsKey(k)).toList();
  if (missing.isNotEmpty) {
    reads.add(BaziReading(
      title: '命局所缺 · ${missing.join('、')}',
      body: '命局十神未见者，相关际遇宜后天主动经营补足：${missing.map((m) => kTenGodTrait[m]!.split('，').first).join('；')}。',
    ));
  }
  return reads;
}

// ---------- 组装 ----------

/// 全部解读卡 (日主心性 + 喜用 + 十神倾向 + 神煞释义)
List<BaziReading> baziReadings(BaZiChart c) {
  return [
    if (kDayMasterTraits.containsKey(c.dayGan))
      BaziReading(title: '日主心性 · ${c.dayGan}${c.dayElement}', body: kDayMasterTraits[c.dayGan]!),
    wuxingAdvice(c),
    ...tenGodReadings(c),
    ...shenShaReadings(shenShaOf(c)),
  ];
}
