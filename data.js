/* ===================================================================
 * 易道 · 卦象解读 — 数据层
 * -------------------------------------------------------------------
 * 设计原则: 数据与渲染分离, 未来接入真实 API 时只需替换 YIJING_DATA
 * 或在 YijingAPI 命名空间下扩展 fetch 方法.
 *
 * 字段约定:
 *   no          - 卦序 (1-64)
 *   name        - 中文卦名 (单字)
 *   en          - 拼音
 *   desc        - 卦象描述 (上卦 + 下卦 + 卦德)
 *   lines[6]    - 六爻, 从初爻到上爻, 枚举: 'yang' | 'yin' | 'moving'
 *   trigramU    - 上卦卦象符号 (☰☱☲☳☴☵☶☷)
 *   trigramD    - 下卦卦象符号
 *   trigramUName- 上卦名 (天/泽/火/雷/风/水/山/地)
 *   trigramDName- 下卦名
 * ================================================================= */

const YIJING_DATA = {
  /* 64 卦完整数据库 (本设计稿示例前 16 卦, 后续可补全) */
  HEX_LIBRARY: [
    { no:1,  name:'乾', en:'Qian', desc:'乾为天 · 刚健中正', trigramU:'☰', trigramD:'☰', trigramUName:'天', trigramDName:'天', lines:['yang','yang','yang','yang','yang','yang'],
      yao:[
        {n:'初九', q:'潜龙勿用。', d:'时机未至，宜潜藏待时，不可妄动。'},
        {n:'九二', q:'见龙在田，利见大人。', d:'德才初显，宜主动求教于贤达之君子。'},
        {n:'九三', q:'君子终日乾乾，夕惕若厉，无咎。', d:'处下卦之终，宜日勤夜惕，方可免过。'},
        {n:'九四', q:'或跃在渊，无咎。', d:'进退之间，可跃可止，进退有度则无过。'},
        {n:'九五', q:'飞龙在天，利见大人。', d:'阳刚中正，居尊位而得时，大业成就。'},
        {n:'上九', q:'亢龙有悔。', d:'阳极必衰，盛极而衰，知进而不知退则悔。'}
      ] },
    { no:2,  name:'坤', en:'Kun', desc:'坤为地 · 柔顺包容', trigramU:'☷', trigramD:'☷', trigramUName:'地', trigramDName:'地', lines:['yin','yin','yin','yin','yin','yin'],
      yao:[
        {n:'初六', q:'履霜，坚冰至。', d:'见微知著，顺势而为，防微杜渐。'},
        {n:'六二', q:'直方大，不习无不利。', d:'柔顺中正，顺应大道，自然而成。'},
        {n:'六三', q:'含章可贞，或从王事，无成有终。', d:'含藏才华，静守以待时。'},
        {n:'六四', q:'括囊，无咎无誉。', d:'谨言慎行，缄默自守。'},
        {n:'六五', q:'黄裳元吉。', d:'柔居尊位，以中和之德获大吉。'},
        {n:'上六', q:'龙战于野，其血玄黄。', d:'阴极必争，宜收敛退避。'}
      ] },
    { no:3,  name:'屯', en:'Zhun', desc:'水雷屯 · 起始艰难', trigramU:'☵', trigramD:'☳', trigramUName:'水', trigramDName:'雷', lines:['yang','yin','yin','yang','yin','yin'],
      yao:[
        {n:'初九', q:'磐桓，利居贞，利建侯。', d:'起步维艰，宜守正待时。'},
        {n:'六二', q:'屯如邅如，乘马班如。', d:'进退两难，宜静守勿躁。'},
        {n:'六三', q:'即鹿无虞，惟入于林中。', d:'追逐无主，徒劳无功。'},
        {n:'六四', q:'乘马班如，求婚媾，往吉。', d:'结伴而行，求贤相助。'},
        {n:'九五', q:'屯其膏，小贞吉，大贞凶。', d:'蓄养恩泽，小事可成，大事需慎。'},
        {n:'上六', q:'乘马班如，泣血涟如。', d:'艰难至极，宜坚守以待变。'}
      ] },
    { no:4,  name:'蒙', en:'Meng', desc:'山水蒙 · 启蒙奋发', trigramU:'☶', trigramD:'☵', trigramUName:'山', trigramDName:'水', lines:['yin','yin','yang','yin','yin','yang'],
      yao:[
        {n:'初六', q:'发蒙，利用刑人。', d:'启发蒙昧，宜立规训。'},
        {n:'九二', q:'包蒙吉，纳妇吉，子克家。', d:'包容教化，广纳贤才。'},
        {n:'六三', q:'勿用取女，见金夫。', d:'不可贪图，坚守正道。'},
        {n:'六四', q:'困蒙，吝。', d:'困于蒙昧，需主动求教。'},
        {n:'六五', q:'童蒙，吉。', d:'虚心受教，吉。'},
        {n:'上九', q:'击蒙，不利为寇，利御寇。', d:'启人蒙昧，宜严宽相济。'}
      ] },
    { no:5,  name:'需', en:'Xu', desc:'水天需 · 等待时机', trigramU:'☵', trigramD:'☰', trigramUName:'水', trigramDName:'天', lines:['yang','yin','yang','yang','yang','yang'],
      yao:[
        {n:'初九', q:'需于郊，利用恒，无咎。', d:'远离险境，宜守常不变。'},
        {n:'九二', q:'需于沙，小有言，终吉。', d:'小有口舌之争，终能化解。'},
        {n:'九三', q:'需于泥，致寇至。', d:'近险而招致敌寇。'},
        {n:'六四', q:'需于血，出自穴。', d:'处险之中，需奋力脱离。'},
        {n:'九五', q:'需于酒食，贞吉。', d:'以酒食养人，居正得吉。'},
        {n:'上六', q:'入于穴，有不速之客三人来。', d:'不请自来，敬之终吉。'}
      ] },
    { no:6,  name:'讼', en:'Song', desc:'天水讼 · 慎争止讼', trigramU:'☰', trigramD:'☵', trigramUName:'天', trigramDName:'水', lines:['yang','yang','yang','yin','yang','yang'],
      yao:[
        {n:'初六', q:'不永所事，小有言，终吉。', d:'不宜久争，小有口舌终吉。'},
        {n:'九二', q:'不克讼，归而逋。', d:'争讼不胜，宜退避。'},
        {n:'六三', q:'食旧德，贞厉，终吉。', d:'守旧德，虽危终吉。'},
        {n:'九四', q:'不克讼，复即命渝。', d:'争讼不顺，宜改变初衷。'},
        {n:'九五', q:'讼，元吉。', d:'以中正决讼，大吉。'},
        {n:'上九', q:'或锡之鞶带，终朝三褫之。', d:'虽得荣宠，终被剥夺。'}
      ] },
    { no:7,  name:'师', en:'Shi', desc:'地水师 · 军旅众人', trigramU:'☷', trigramD:'☵', trigramUName:'地', trigramDName:'水', lines:['yin','yang','yang','yin','yang','yang'],
      yao:[
        {n:'初六', q:'师出以律，否臧凶。', d:'军纪不严，必致凶险。'},
        {n:'九二', q:'在师中，吉无咎。', d:'主帅刚中，能得众人之心。'},
        {n:'六三', q:'师或舆尸，凶。', d:'用人不当，必致大败。'},
        {n:'六四', q:'师左次，无咎。', d:'退守有序，亦为上策。'},
        {n:'六五', q:'田有禽，利执言。', d:'猎获有利，宜建言献策。'},
        {n:'上六', q:'大君有命，开国承家。', d:'功成受命，慎用封赏。'}
      ] },
    { no:8,  name:'比', en:'Bi', desc:'水地比 · 亲辅比邻', trigramU:'☵', trigramD:'☷', trigramUName:'水', trigramDName:'地', lines:['yang','yang','yang','yin','yin','yin'],
      yao:[
        {n:'初六', q:'有孚比之，无咎。', d:'诚信结交，无过。'},
        {n:'六二', q:'比之自内，贞吉。', d:'自内而比，亲近有道。'},
        {n:'六三', q:'比之匪人。', d:'所比非人，凶。'},
        {n:'六四', q:'外比之，贞吉。', d:'向外结交贤者，吉。'},
        {n:'九五', q:'显比，王用三驱。', d:'光明正大地亲比。'},
        {n:'上六', q:'比之无首，凶。', d:'结比无首领，必凶。'}
      ] },
    { no:9,  name:'小畜', en:'Xiao Xu', desc:'风天小畜 · 以柔制刚', trigramU:'☴', trigramD:'☰', trigramUName:'风', trigramDName:'天', lines:['yang','yang','yang','yang','yin','yang'],
      yao:[
        {n:'初九', q:'复自道，何其咎，吉。', d:'回归正途，何过之有。'},
        {n:'九二', q:'牵复，吉。', d:'被牵引而复归正道。'},
        {n:'九三', q:'舆说辐，夫妻反目。', d:'与人不和，关系破裂。'},
        {n:'六四', q:'有孚，血去惕出，无咎。', d:'以诚信化解险难。'},
        {n:'九五', q:'有孚挛如，富以其邻。', d:'诚信相连，与邻共富。'},
        {n:'上九', q:'既雨既处，尚德载。', d:'阴阳和合，积德为上。'}
      ] },
    { no:10, name:'履', en:'Lu', desc:'天泽履 · 如履薄冰', trigramU:'☰', trigramD:'☱', trigramUName:'天', trigramDName:'泽', lines:['yang','yin','yang','yang','yang','yang'],
      yao:[
        {n:'初九', q:'素履，往无咎。', d:'朴素行事，无过。'},
        {n:'九二', q:'履道坦坦，幽人贞吉。', d:'大道平坦，隐者守正则吉。'},
        {n:'六三', q:'眇能视，跛能履，履虎尾。', d:'才不足而强行，必凶。'},
        {n:'九四', q:'履虎尾，愬愬终吉。', d:'履险而惧，终能获吉。'},
        {n:'九五', q:'夬履，贞厉。', d:'刚决果敢，守正防危。'},
        {n:'上九', q:'视履考祥，其旋元吉。', d:'回顾所行，圆满大吉。'}
      ] },
    { no:11, name:'泰', en:'Tai', desc:'地天泰 · 阴阳交泰', trigramU:'☷', trigramD:'☰', trigramUName:'地', trigramDName:'天', lines:['yang','yang','yang','yin','yin','yin'],
      yao:[
        {n:'初九', q:'拔茅茹，以其汇，征吉。', d:'同根连类，共同进取。'},
        {n:'九二', q:'包荒，用冯河，不遐遗。', d:'包容大度，远虑不弃。'},
        {n:'九三', q:'无平不陂，无往不复。', d:'平陂往复，慎终如始。'},
        {n:'六四', q:'翩翩，不富以其邻。', d:'阳气上达，与邻共进。'},
        {n:'六五', q:'帝乙归妹，以祉元吉。', d:'以柔居尊，大吉。'},
        {n:'上六', q:'城复于隍，勿用师。', d:'泰极而否，宜静守。'}
      ] },
    { no:12, name:'否', en:'Pi', desc:'天地否 · 闭塞不通', trigramU:'☰', trigramD:'☷', trigramUName:'天', trigramDName:'地', lines:['yin','yin','yin','yang','yang','yang'],
      yao:[
        {n:'初六', q:'拔茅茹，以其汇，贞吉。', d:'小人连类，守正待变。'},
        {n:'六二', q:'包承，小人吉，大人否。', d:'包容承顺，小人吉大人否。'},
        {n:'六三', q:'包羞。', d:'含耻忍辱，终将蒙羞。'},
        {n:'九四', q:'有命无咎，畴离祉。', d:'天命所系，可获福泽。'},
        {n:'九五', q:'休否，大人吉。', d:'休止闭塞，大人获吉。'},
        {n:'上九', q:'倾否，先否后喜。', d:'倾覆否塞，先忧后喜。'}
      ] },
    { no:13, name:'同人', en:'Tong Ren', desc:'天火同人 · 和同于人', trigramU:'☰', trigramD:'☲', trigramUName:'天', trigramDName:'火', lines:['yang','yang','yin','yang','yang','yang'],
      yao:[
        {n:'初九', q:'同人于门，无咎。', d:'与人和同于门外，无过。'},
        {n:'六二', q:'同人于宗，吝。', d:'仅同于宗族，狭隘。'},
        {n:'九三', q:'伏戎于莽，升其高陵。', d:'心怀异志，难成大同。'},
        {n:'九四', q:'乘其墉，弗克攻，吉。', d:'欲攻未攻，能自我克制。'},
        {n:'九五', q:'同人，先号咷而后笑。', d:'先忧后喜，能和同于人。'},
        {n:'上九', q:'同人于郊，无悔。', d:'远同人于郊野，心怀广阔。'}
      ] },
    { no:14, name:'大有', en:'Da You', desc:'火天大有 · 光明盛大', trigramU:'☲', trigramD:'☰', trigramUName:'火', trigramDName:'天', lines:['yang','yang','yang','yang','yang','yin'],
      yao:[
        {n:'初九', q:'无交害，匪咎，艰则无咎。', d:'不涉害处，艰守无过。'},
        {n:'九二', q:'大车以载，有攸往。', d:'任重致远，前景光明。'},
        {n:'九三', q:'公用亨于天子，小人弗克。', d:'宜奉天子，非小人之福。'},
        {n:'九四', q:'匪其彭，无咎。', d:'不恃其盛，无过。'},
        {n:'六五', q:'厥孚交如，威如，吉。', d:'以诚信相交，威严自显。'},
        {n:'上九', q:'自天佑之，吉无不利。', d:'天命所佑，大吉。'}
      ] },
    { no:15, name:'谦', en:'Qian', desc:'地山谦 · 谦下不盈', trigramU:'☷', trigramD:'☶', trigramUName:'地', trigramDName:'地', lines:['yin','yin','yang','yin','yin','yang'],
      yao:[
        {n:'初六', q:'谦谦君子，用涉大川，吉。', d:'谦而又谦，可涉险难。'},
        {n:'六二', q:'鸣谦，贞吉。', d:'谦德闻名，守正则吉。'},
        {n:'九三', q:'劳谦，君子有终，吉。', d:'勤劳而谦，必有善终。'},
        {n:'六四', q:'无不利，撝谦。', d:'无所不利，发挥谦德。'},
        {n:'六五', q:'不富以其邻，利用侵伐。', d:'不独富，谦让利众。'},
        {n:'上六', q:'鸣谦，利用行师。', d:'谦德远闻，可用于军旅。'}
      ] },
    { no:16, name:'豫', en:'Yu', desc:'雷地豫 · 顺时豫乐', trigramU:'☳', trigramD:'☷', trigramUName:'雷', trigramDName:'地', lines:['yang','yin','yin','yin','yin','yang'],
      yao:[
        {n:'初六', q:'鸣豫，凶。', d:'逸豫之名，必致凶险。'},
        {n:'六二', q:'介于石，不终日，贞吉。', d:'守正不移，明察事理。'},
        {n:'六三', q:'盱豫，悔。', d:'阿谀奉承，必有悔恨。'},
        {n:'九四', q:'由豫，大有得。', d:'由豫而动，大有所得。'},
        {n:'六五', q:'贞疾，恒不死。', d:'居尊忧危，守正可免死。'},
        {n:'上六', q:'冥豫成，有渝无咎。', d:'沉迷豫乐，能改则无过。'}
      ] }
  ],

  /* 起卦方式 */
  METHODS: [
    { id:'numeric', name:'数 字 起 卦', icon:'数', desc:'心中默念数字，生成卦象', featured:true,  accent:'cinnabar' },
    { id:'yarrow',  name:'蓍 草 演 卦', icon:'⛌', desc:'依古法，五十茎蓍草取卦', featured:false, accent:'pine'     },
    { id:'coin',    name:'铜 钱 起 卦', icon:'币', desc:'三枚铜钱，共六次成卦', featured:false, accent:'gold'     }
  ],

  /* 起卦方向 */
  DIRECTIONS: [
    { id:'career', name:'事业', color:'cinnabar' },
    { id:'love',   name:'感情', color:'pine'     },
    { id:'health', name:'健康', color:'cinnabar' },
    { id:'wealth', name:'财运', color:'gold'     },
    { id:'study',  name:'学业', color:'cinnabar' }
  ],

  /* 历史记录 - 包含 month 字段用于月份分组 */
  HISTORY: [
    { date:'今日 09:32',   month:'2026-06', day:17, hexNo:1,  name:'乾卦', question:'问：近期事业运筹方向', direction:'事业', directionColor:'cinnabar', highlight:true,  lines:['yang','yang','moving','yang','yang','yang'] },
    { date:'昨日 21:32',   month:'2026-06', day:16, hexNo:5,  name:'需卦', question:'问：近期事业运筹方向', direction:'事业', directionColor:'cinnabar', highlight:false, lines:['yang','yang','yang','yang','moving','yang'] },
    { date:'本周一 19:08', month:'2026-06', day:15, hexNo:31, name:'咸卦', question:'问：与TA关系走向',     direction:'感情', directionColor:'pine',     highlight:false, lines:['yin','yin','yin','yin','yin','yin'] },
    { date:'上周日 14:22', month:'2026-06', day:14, hexNo:5,  name:'需卦', question:'问：近期财运转机',     direction:'财运', directionColor:'gold',     highlight:false, lines:['yang','yang','yang','moving','moving','yang'] },
    { date:'06/05 09:18',  month:'2026-06', day:5,  hexNo:14, name:'大有卦', question:'问：项目推进节奏',   direction:'事业', directionColor:'cinnabar', highlight:false, lines:['yang','yang','yang','yang','yang','yin'] },
    { date:'06/03 22:45',  month:'2026-06', day:3,  hexNo:16, name:'豫卦', question:'问：与同事关系',       direction:'事业', directionColor:'cinnabar', highlight:false, lines:['yang','yin','yin','yin','yin','yang'] },
    { date:'06/01 11:30',  month:'2026-06', day:1,  hexNo:9,  name:'小畜卦', question:'问：近期财运',       direction:'财运', directionColor:'gold',     highlight:false, lines:['yang','yang','yang','yang','yin','yang'] },
    { date:'05/28 18:22',  month:'2026-05', day:28, hexNo:11, name:'泰卦', question:'问：身体状态',         direction:'健康', directionColor:'cinnabar', highlight:false, lines:['yang','yang','yang','yin','yin','yin'] },
    { date:'05/24 14:08',  month:'2026-05', day:24, hexNo:12, name:'否卦', question:'问：合作走向',         direction:'事业', directionColor:'cinnabar', highlight:false, lines:['yin','yin','yin','yang','yang','yang'] },
    { date:'05/20 20:15',  month:'2026-05', day:20, hexNo:6,  name:'讼卦', question:'问：与家人的冲突',     direction:'感情', directionColor:'pine',     highlight:false, lines:['yang','yang','yang','yin','yang','yang'] },
    { date:'05/15 09:42',  month:'2026-05', day:15, hexNo:44, name:'姤卦', question:'问：求职方向',         direction:'事业', directionColor:'cinnabar', highlight:false, lines:['yang','yin','yang','yang','yang','yang'] },
    { date:'05/08 16:30',  month:'2026-05', day:8,  hexNo:1,  name:'乾卦', question:'问：本月运势',         direction:'事业', directionColor:'cinnabar', highlight:false, lines:['yang','yang','yang','yang','yang','moving'] }
  ],

  /* 今日一卦 hero 数据 */
  TODAY: {
    hexNo: 1, name: '乾 卦', en: 'Qian · The Creative',
    attr: '乾为天 · 刚健中正', quote: '天行健，君子以自强不息。',
    desc: '今日大运亨通，宜积极进取，主动把握机遇；但需戒骄戒躁，稳健前行，方可成就大业。',
    greeting: '辰安，慕白', date: '丙午年 甲午月 戊申日',
    lines: ['yang','yang','moving','yang','yang','yang']
  }
};

/* ===================================================================
 * 模拟 API 适配层 — 真实接入时把 stub 替换为 fetch 调用即可
 * -------------------------------------------------------------------
 * 用法:
 *   YijingAPI.getHexLibrary().then(data => render(data));
 *   YijingAPI.getHistory().then(data => render(data));
 * ================================================================= */
const YijingAPI = {
  baseURL: '/api/v1',

  async getHexLibrary() {
    if (window.__USE_REAL_API__) {
      const r = await fetch(this.baseURL + '/hexagrams');
      return await r.json();
    }
    return new Promise(resolve => setTimeout(() => resolve(YIJING_DATA.HEX_LIBRARY), 200));
  },

  async getMethods() {
    if (window.__USE_REAL_API__) {
      const r = await fetch(this.baseURL + '/methods');
      return await r.json();
    }
    return Promise.resolve(YIJING_DATA.METHODS);
  },

  async getDirections() {
    return Promise.resolve(YIJING_DATA.DIRECTIONS);
  },

  async getHistory() {
    if (window.__USE_REAL_API__) {
      const r = await fetch(this.baseURL + '/history');
      return await r.json();
    }
    return Promise.resolve(YIJING_DATA.HISTORY);
  },

  async getTodayHex() {
    return Promise.resolve(YIJING_DATA.TODAY);
  }
};
