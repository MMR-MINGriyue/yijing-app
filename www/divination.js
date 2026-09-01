/* ============================================================
 * divination.js — 更多占法: 八字 / 小六壬 / 梅花易数
 * 依赖: index.html 中的 YijingCalendar (干支历) 与 data.js 的 YijingEngine (64卦/体用)
 * 挂载: window.YijingDivination = { LunarCalendar, BaZi, XiaoLiuRen, MeiHua }
 * ============================================================ */
(function () {
  'use strict';

  var GAN = ['甲','乙','丙','丁','戊','己','庚','辛','壬','癸'];
  var ZHI = ['子','丑','寅','卯','辰','巳','午','未','申','酉','戌','亥'];
  var WUXING = { '甲':'木','乙':'木','丙':'火','丁':'火','戊':'土','己':'土','庚':'金','辛':'金','壬':'水','癸':'水' };
  var ZHI_WUXING = { '子':'水','丑':'土','寅':'木','卯':'木','辰':'土','巳':'火','午':'火','未':'土','申':'金','酉':'金','戌':'土','亥':'水' };

  /* ============ 农历 (1900-2100) ============ */
  var LunarCalendar = (function () {
    /* 经典农历数据表: 每年 16-bit? — 此处用标准 1900-2100 紧凑表
       高4位闰月月份(0=无闰), 低12位大小月(1=30天,0=29天), 低位起=正月
       最后一位 1901 附加标志位表沿用业界通用 lunarInfo 而非高4位方案 */
    var DATA = [
      0x04bd8,0x04ae0,0x0a570,0x054d5,0x0d260,0x0d950,0x16554,0x056a0,0x09ad0,0x055d2,
      0x04ae0,0x0a5b6,0x0a4d0,0x0d250,0x1d255,0x0b540,0x0d6a0,0x0ada2,0x095b0,0x14977,
      0x04970,0x0a4b0,0x0b4b5,0x06a50,0x06d40,0x1ab54,0x02b60,0x09570,0x052f2,0x04970,
      0x06566,0x0d4a0,0x0ea50,0x06e95,0x05ad0,0x02b60,0x186e3,0x092e0,0x1c8d7,0x0c950,
      0x0d4a0,0x1d8a6,0x0b550,0x056a0,0x1a5b4,0x025d0,0x092d0,0x0d2b2,0x0a950,0x0b557,
      0x06ca0,0x0b550,0x15355,0x04da0,0x0a5b0,0x14573,0x052b0,0x0a9a8,0x0e950,0x06aa0,
      0x0aea6,0x0ab50,0x04b60,0x0aae4,0x0a570,0x05260,0x0f263,0x0d950,0x05b57,0x056a0,
      0x096d0,0x04dd5,0x04ad0,0x0a4d0,0x0d4d4,0x0d250,0x0d558,0x0b540,0x0b6a0,0x195a6,
      0x095b0,0x049b0,0x0a974,0x0a4b0,0x0b27a,0x06a50,0x06d40,0x0af46,0x0ab60,0x09570,
      0x04af5,0x04970,0x064b0,0x074a3,0x0ea50,0x06b58,0x05ac0,0x0ab60,0x096d5,0x092e0,
      0x0c960,0x0d954,0x0d4a0,0x0da50,0x07552,0x056a0,0x0abb7,0x025d0,0x092d0,0x0cab5,
      0x0a950,0x0b4a0,0x0baa4,0x0ad50,0x055d9,0x04ba0,0x0a5b0,0x15176,0x052b0,0x0a930,
      0x07954,0x06aa0,0x0ad50,0x05b52,0x04b60,0x0a6e6,0x0a4e0,0x0d260,0x0ea65,0x0d530,
      0x05aa0,0x076a3,0x096d0,0x04afb,0x04ad0,0x0a4d0,0x1d0b6,0x0d250,0x0d520,0x0dd45,
      0x0b5a0,0x056d0,0x055b2,0x049b0,0x0a577,0x0a4b0,0x0aa50,0x1b255,0x06d20,0x0ada0,
      0x14b63,0x09370,0x049f8,0x04970,0x064b0,0x168a6,0x0ea50,0x06b20,0x1a6c4,0x0aae0,
      0x0a2e0,0x0d2e3,0x0c960,0x0d557,0x0d4a0,0x0da50,0x05d55,0x056a0,0x0a6d0,0x055d4,
      0x052d0,0x0a9b8,0x0a950,0x0b4a0,0x0b6a6,0x0ad50,0x055a0,0x0aba4,0x0a5b0,0x052b0,
      0x0b273,0x06930,0x07337,0x06aa0,0x0ad50,0x14b55,0x04b60,0x0a570,0x054e4,0x0d160,
      0x0e968,0x0d520,0x0daa0,0x16aa6,0x056d0,0x04ae0,0x0a9d4,0x0a2d0,0x0d150,0x0f252,
      0x0d520
    ];
    var BASE_YEAR = 1900, BASE_MONTH = 1, BASE_DAY = 31; /* 1900-01-31 = 农历1900正月初一 */
    function yearDays(y) { /* 该农历年总天数 */
      var sum = 348;
      for (var i = 0x8000; i > 0x8; i >>= 1) sum += (DATA[y - 1900] & i) ? 1 : 0;
      return sum + leapDays(y);
    }
    function leapMonth(y) { return DATA[y - 1900] & 0xf; }
    function leapDays(y) { return leapMonth(y) ? ((DATA[y - 1900] & 0x10000) ? 30 : 29) : 0; }
    function monthDays(y, m) { return (DATA[y - 1900] & (0x10000 >> m)) ? 30 : 29; }

    function toJDN(y, m, d) {
      var a = Math.floor((14 - m) / 12), yy = y + 4800 - a, mm = m + 12 * a - 3;
      return d + Math.floor((153 * mm + 2) / 5) + 365 * yy + Math.floor(yy / 4) - Math.floor(yy / 100) + Math.floor(yy / 400) - 32045;
    }

    var MONTH_CN = ['正','二','三','四','五','六','七','八','九','十','冬','腊'];
    /** 公历 Date → { year, month(1-12), day, isLeap, monthLabel, yearGanZhi, animal } */
    function solarToLunar(date) {
      if (!date || isNaN(date.getTime())) return null;
      var offset = Math.floor(toJDN(date.getFullYear(), date.getMonth() + 1, date.getDate()) - toJDN(BASE_YEAR, BASE_MONTH, BASE_DAY));
      if (offset < 0) return null;
      /* 定位农历年 */
      var y = 1900;
      while (y <= 2100) {
        var yd = yearDays(y);
        if (offset < yd) break;
        offset -= yd; y++;
      }
      if (y > 2100) return null;
      /* 显式月表: 闰月排在其基础月之后 */
      var leap = leapMonth(y);
      var months = [];
      for (var m = 1; m <= 12; m++) {
        months.push({ m: m, isLeap: false, days: monthDays(y, m) });
        if (leap === m) months.push({ m: m, isLeap: true, days: leapDays(y) });
      }
      var cur = null;
      for (var i = 0; i < months.length; i++) {
        if (offset < months[i].days) { cur = months[i]; break; }
        offset -= months[i].days;
      }
      if (!cur) return null;
      var gzIdx = ((y - 1984) % 60 + 60) % 60;
      return {
        year: y, month: cur.m, day: offset + 1, isLeap: cur.isLeap,
        monthLabel: (cur.isLeap ? '闰' : '') + MONTH_CN[cur.m - 1] + '月',
        yearGanZhi: GAN[gzIdx % 10] + ZHI[gzIdx % 12],
        animal: ZHI[((y - 1900) % 12 + 12) % 12]
      };
    }

    /** 公历 Date → 时辰序号 (0=子时 23-1点, 1=丑 1-3 …) */
    function shichenIndex(date) {
      var h = date.getHours();
      return Math.floor(((h + 1) % 24) / 2);
    }

    return { solarToLunar: solarToLunar, shichenIndex: shichenIndex, leapMonth: leapMonth, monthDays: monthDays, yearDays: yearDays };
  })();

  /* ============ 八字 (四柱 + 五行 + 十神) ============ */
  var BaZi = (function () {
    /* 地支藏干 (本气/中气/余气) */
    var HIDDEN = {
      子: ['癸'], 丑: ['己','癸','辛'], 寅: ['甲','丙','戊'], 卯: ['乙'],
      辰: ['戊','乙','癸'], 巳: ['丙','庚','戊'], 午: ['丁','己'], 未: ['己','丁','乙'],
      申: ['庚','壬','戊'], 酉: ['辛'], 戌: ['戊','辛','丁'], 亥: ['壬','甲']
    };
    /* 十神: 以日主天干为基准, 按五行生克 + 同异定十神 */
    var SHENG = { 木:'火', 火:'土', 土:'金', 金:'水', 水:'木' };    /* 我生 */
    var KE    = { 木:'土', 土:'水', 水:'火', 火:'金', 金:'木' };    /* 我克 */
    function tenGod(dayGan, otherGan) {
      if (dayGan === otherGan) return '比肩';
      var me = WUXING[dayGan], other = WUXING[otherGan];
      var sameYinYang = (GAN.indexOf(dayGan) % 2) === (GAN.indexOf(otherGan) % 2);
      if (SHENG[me] === other) return sameYinYang ? '食神' : '伤官';
      if (other === me) return sameYinYang ? '比肩' : '劫财';
      if (KE[me] === other) return sameYinYang ? '偏财' : '正财';
      if (KE[other] === me) return sameYinYang ? '七杀' : '正官';
      if (SHENG[other] === me) return sameYinYang ? '偏印' : '正印';
      return '?';
    }
    /* 时柱: 五鼠遁 — 甲己日甲子时起, 乙庚丙作初, 丙辛戊子起, 丁壬庚子行, 戊癸壬子头 */
    var HOUR_GAN_START = [0, 2, 4, 6, 8]; /* 日干 idx%5 → 子时天干 idx */
    function hourPillar(dayGan, shichenIdx) {
      var dIdx = GAN.indexOf(dayGan);
      var start = HOUR_GAN_START[dIdx % 5];
      var ganIdx = (start + shichenIdx) % 10;
      return GAN[ganIdx] + ZHI[shichenIdx % 12];
    }

    /** 计算四柱八字
     * @param date  公历 Date (含出生时间; 时辰 23 点属次日子时, 简化按当前日排)
     * @return { pillars:[{gan,zhi,hidden:[{gan,god}]}]×4, wuxing统计, dayGan, dayGod, strength } */
    function compute(date) {
      if (!date || isNaN(date.getTime())) return null;
      if (typeof YijingCalendar === 'undefined') return null;
      var yGZ = YijingCalendar.ganzhiYear(date);
      var mGZ = YijingCalendar.ganzhiMonth(date);
      var dGZ = YijingCalendar.ganzhiDay(date);
      var scIdx = LunarCalendar.shichenIndex(date);
      var hGZ = hourPillar(dGZ[0], scIdx);

      var pillars = [yGZ, mGZ, dGZ, hGZ].map(function (gz, i) {
        var gan = gz[0], zhi = gz[1];
        var hidden = HIDDEN[zhi].map(function (hg, k) {
          return { gan: hg, god: tenGod(dGZ[0], hg), weight: k === 0 ? '本气' : (k === 1 ? '中气' : '余气') };
        });
        return { gan: gan, zhi: zhi, gz: gz, pos: ['年','月','日','时'][i], hidden: hidden,
                 ganGod: i === 2 ? '日主' : tenGod(dGZ[0], gan) };
      });

      /* 五行统计: 4 天干 + 4 地支本气 (不含藏干加权, 简明版) */
      var wx = { 木:0, 火:0, 土:0, 金:0, 水:0 };
      pillars.forEach(function (p) { wx[WUXING[p.gan]]++; wx[ZHI_WUXING[p.zhi]]++; });
      var total = 8;
      var dayEl = WUXING[dGZ[0]];
      /* 日主强弱: 同党(生我+同我) vs 异党 */
      var tong = wx[dayEl] + (wx[SHENG_IN[dayEl]] || 0);
      var strength = tong >= 4 ? '偏强' : (tong <= 2 ? '偏弱' : '中和');

      return {
        pillars: pillars, wuxing: wx, wuxingTotal: total,
        dayGan: dGZ[0], dayElement: dayEl, dayGod: pillars[2].ganGod,
        strength: strength, shichen: ZHI[scIdx] + '时',
        lunar: LunarCalendar.solarToLunar(date)
      };
    }
    var SHENG_IN = { 木:'水', 火:'木', 土:'火', 金:'土', 水:'金' }; /* 生我者 */
    return { compute: compute, tenGod: tenGod, hourPillar: hourPillar };
  })();

  /* ============ 大运流年 (八字) ============ */
  var DaYun = (function () {
    /* 地支六冲 */
    var CHONG = { '子':'午','午':'子','丑':'未','未':'丑','寅':'申','申':'寅','卯':'酉','酉':'卯','辰':'戌','戌':'辰','巳':'亥','亥':'巳' };
    /* 地支六合 */
    var HE = { '子':'丑','丑':'子','寅':'亥','亥':'寅','卯':'戌','戌':'卯','辰':'酉','酉':'辰','巳':'申','申':'巳','午':'未','未':'午' };
    /* 地支相刑 (简化三刑表, 不含自刑) */
    var XING = {
      '寅':['巳','申'], '巳':['申','寅'], '申':['寅','巳'],
      '丑':['戌','未'], '戌':['未','丑'], '未':['丑','戌'],
      '子':['卯'], '卯':['子']
    };
    /* 天干五合 */
    var GAN_HE = { '甲':'己','己':'甲','乙':'庚','庚':'乙','丙':'辛','辛':'丙','丁':'壬','壬':'丁','戊':'癸','癸':'戊' };
    var SHENG = { 木:'火', 火:'土', 土:'金', 金:'水', 水:'木' }; /* 我生 */
    var KE = { 木:'土', 土:'水', 水:'火', 火:'金', 金:'木' };   /* 我克 */
    /* 宫位语义: 0年柱 1月柱 2日柱 3时柱, -1 = 大运 */
    var PALACE = ['年柱·根基', '月柱·父母事业', '日柱·自身婚姻', '时柱·子女'];

    /* 十神主事句 (模板, 无自由文本) */
    var GOD_MAIN = {
      '比肩': '比肩主事，同侪助力与竞争并见，宜自立不宜依赖',
      '劫财': '劫财当值，破财分福之忧，忌合伙借贷',
      '食神': '食神主事，才艺生发，口福安逸，顺遂之年',
      '伤官': '伤官吐秀，才华显露，慎言辞招忌',
      '偏财': '偏财主事，意外之财可期，忌贪多',
      '正财': '正财主事，勤勉得财，婚姻家庭之象',
      '七杀': '七杀攻身，压力与机遇并存，宜静制不宜躁进',
      '正官': '正官主事，名分职守，功名可期',
      '偏印': '偏印主事，领悟独到，防孤僻多虑',
      '正印': '正印主事，学业文书有喜，贵人扶助'
    };
    var EVENT_TPL = {
      chong: '冲动{p}，主变动',
      he: '合入{p}，主牵绊亦有成',
      xing: '刑扰{p}，主是非烦扰'
    };

    function isYangGan(g) { return GAN.indexOf(g) % 2 === 0; }

    /** 起运: 顺行取生 → 下一节 的间隔, 逆行取生 → 上一节; 3日折1岁, 精确到月 */
    function qiYun(birthTs, fwd) {
      if (typeof PreciseTerms === 'undefined' || !PreciseTerms.around) return null;
      var a = PreciseTerms.around(birthTs);
      if (!a) return null;
      var gapMin = Math.round((fwd ? a.next.ts - birthTs : birthTs - a.prev.ts) / 60000);
      var totalMonths = Math.round(gapMin / (3 * 24 * 60) * 12);
      return {
        years: Math.floor(totalMonths / 12),
        months: totalMonths % 12,
        /* 起运时刻 = 出生 + 折算后的年月 (3日折1岁的换算结果, 非实际间隔) */
        startTs: addMonths(birthTs, totalMonths),
        termName: fwd ? a.next.name : a.prev.name,
        nearEdge: Math.min(a.next.ts - birthTs, birthTs - a.prev.ts) < 24 * 3600000
      };
    }

    function isLeap(y) { return (y % 4 === 0 && y % 100 !== 0) || y % 400 === 0; }
    /* 公历月加法 (日期钳到目标月末) */
    function addMonths(ts, n) {
      var d = new Date(ts);
      var y = d.getFullYear(), mo = d.getMonth() + n;
      y += Math.floor(mo / 12); mo = ((mo % 12) + 12) % 12;
      var last = new Date(y, mo + 1, 0).getDate();
      var da = Math.min(d.getDate(), last);
      return new Date(y, mo, da, d.getHours(), d.getMinutes()).getTime();
    }
    /* 公历年加法 (处理 2/29 → 3/1) */
    function addYears(ts, n) {
      var d = new Date(ts);
      var y = d.getFullYear() + n, mo = d.getMonth(), da = d.getDate();
      if (mo === 1 && da === 29 && !isLeap(y)) { mo = 2; da = 1; }
      return new Date(y, mo, da, d.getHours(), d.getMinutes()).getTime();
    }
    /* 时刻 ts 所属的立春年 (立春前属上一年) */
    function liChunYear(ts) {
      var y = new Date(ts + 8 * 3600000).getUTCFullYear();
      if (typeof PreciseTerms === 'undefined' || !PreciseTerms.jieList) return y;
      var list = PreciseTerms.jieList(y);
      if (list && ts < list[1].ts) return y - 1;
      return y;
    }

    /** 单个流年分析: 全量生克 (十神主事 + 冲合刑事件 + 岁运天干关系) */
    function analyzeYear(bazi, gzY, stepGZ) {
      var god = BaZi.tenGod(bazi.dayGan, gzY[0]);
      var zhiY = gzY[1];
      var events = [];
      var targets = bazi.pillars.map(function (p, i) { return { zhi: p.zhi, palace: i }; });
      targets.push({ zhi: stepGZ[1], palace: -1 });
      targets.forEach(function (t) {
        var type = null;
        if (CHONG[zhiY] === t.zhi) type = 'chong';
        else if (HE[zhiY] === t.zhi) type = 'he';
        else if ((XING[zhiY] || []).indexOf(t.zhi) >= 0) type = 'xing';
        if (type && !events.some(function (e) { return e.type === type && e.palace === t.palace; })) {
          events.push({ type: type, palace: t.palace, zhi: t.zhi });
        }
      });
      var eventText = events.map(function (e) {
        return EVENT_TPL[e.type].replace('{p}', e.palace === -1 ? '大运' : PALACE[e.palace]);
      }).join('；');
      /* 岁运天干关系 */
      var me = WUXING[gzY[0]], dy = WUXING[stepGZ[0]];
      var ganRel;
      if (GAN_HE[gzY[0]] === stepGZ[0]) ganRel = '岁运天干相合，情事牵绊';
      else if (SHENG[me] === dy) ganRel = '岁生运，顺势';
      else if (SHENG[dy] === me) ganRel = '运生岁，得助';
      else if (KE[me] === dy) ganRel = '岁克运，制衡';
      else if (KE[dy] === me) ganRel = '运克岁，受阻';
      else ganRel = '岁运比和';
      var text = (GOD_MAIN[god] || (god + '主事')) + '。' + (eventText ? eventText + '。' : '') + ganRel + '。';
      return { god: god, events: events, ganRel: ganRel, text: text };
    }

    /** 大运流年总分析
     * @param date      出生日期 (Date, 含时间)
     * @param gender    'male' | 'female'
     * @param opts      { hourUnknown: bool }
     * @return { bazi, forward, qiYun, steps[] } */
    function analyze(date, gender, opts) {
      var hourUnknown = !!(opts && opts.hourUnknown);
      var bazi = BaZi.compute(date);
      if (!bazi) return null;
      /* 阳男顺 / 阴男逆 / 阳女逆 / 阴女顺 */
      var fwd = (gender !== 'female') === isYangGan(bazi.pillars[0].gan);
      var ts = date.getTime();
      var qy = qiYun(ts, fwd);
      if (!qy) return { bazi: bazi, forward: fwd, qiYun: null, steps: [], hourUnknown: hourUnknown };

      var mGZ = bazi.pillars[1].gz;
      var mg = GAN.indexOf(mGZ[0]), mz = ZHI.indexOf(mGZ[1]);
      var dir = fwd ? 1 : -1;
      var nowTs = Date.now();
      var curLYear = liChunYear(nowTs);
      var steps = [];
      for (var i = 0; i < 8; i++) {
        var gz = GAN[(mg + dir * (i + 1) + 100) % 10] + ZHI[(mz + dir * (i + 1) + 120) % 12];
        var sTs = i === 0 ? qy.startTs : addYears(steps[i - 1].startTs, 10);
        var eTs = addYears(sTs, 10);
        var y0 = liChunYear(sTs);
        var liuNian = [];
        for (var k = 0; k < 10; k++) {
          var yy = y0 + k;
          if (yy > 2100) break; /* 节气表上限 */
          var gzY = (typeof YijingCalendar !== 'undefined') ? YijingCalendar.ganzhiYear(new Date(yy, 6, 1)) : null;
          if (!gzY) break;
          var ev = analyzeYear(bazi, gzY, gz);
          ev.year = yy; ev.gz = gzY; ev.current = (yy === curLYear);
          liuNian.push(ev);
        }
        steps.push({
          gz: gz, ganGod: BaZi.tenGod(bazi.dayGan, gz[0]),
          startTs: sTs, endTs: eTs,
          startYear: new Date(sTs).getFullYear(),
          endYear: new Date(eTs - 86400000).getFullYear(),
          startAge: qy.years + 10 * i,
          current: nowTs >= sTs && nowTs < eTs,
          past: nowTs >= eTs,
          liuNian: liuNian
        });
      }
      return { bazi: bazi, forward: fwd, qiYun: qy, steps: steps, hourUnknown: hourUnknown };
    }

    return {
      analyze: analyze, analyzeYear: analyzeYear, qiYun: qiYun,
      CHONG: CHONG, HE: HE, XING: XING, PALACE: PALACE
    };
  })();

  /* ============ 小六壬 (六宫) ============ */
  var XiaoLiuRen = (function () {
    /* 固定次序: 大安→留连→速喜→赤口→小吉→空亡, 循环 */
    var PALACES = [
      { name: '大安',   luck: '吉',   dir: '东南', color: 'wood',  text: '大安事事昌，求谋在东方，失物去不远，宅舍保安康' },
      { name: '留连',   luck: '凶',   dir: '南',   color: 'water', text: '留连事难成，求谋日未明，官事凡宜缓，去者未回程' },
      { name: '速喜',   luck: '吉',   dir: '南',   color: 'fire',  text: '速喜喜来临，求财向南方，失物申未午，逢人路上寻' },
      { name: '赤口',   luck: '凶',   dir: '西',   color: 'metal', text: '赤口主口舌，官非切要防，失物急去寻，行人有惊慌' },
      { name: '小吉',   luck: '吉',   dir: '东北', color: 'wood',  text: '小吉最吉昌，路上好商量，阴人来报喜，失物在坤方' },
      { name: '空亡',   luck: '凶',   dir: '北',   color: 'earth', text: '空亡事不祥，阴人多乖张，求财无利益，行人有灾殃' }
    ];
    /** 以农历 月+日+时 三数报宫: (月+日+时-1) 从大安起顺数 — 经典口诀起法
     *  实际流行起法: 月落宫→从月宫起数日→从日宫起数时。此处采用流传最广的三数连加法:
     *  落宫 = ((月-1)+(日-1)+(时-1)) % 6 */
    function divine(date) {
      var lunar = LunarCalendar.solarToLunar(date);
      if (!lunar) return null;
      var sc = LunarCalendar.shichenIndex(date);
      /* 经典路径法: 从大安(0)起数月 → 月宫; 从月宫起数日 → 日宫; 从日宫起数时 → 时宫 */
      var monthPalace = (lunar.month - 1) % 6;
      var dayPalace = (monthPalace + lunar.day - 1) % 6;
      var hourPalace = (dayPalace + sc) % 6;
      return {
        lunar: lunar, shichenIdx: sc, shichen: ZHI[sc] + '时',
        monthPalace: PALACES[monthPalace], dayPalace: PALACES[dayPalace], hourPalace: PALACES[hourPalace],
        monthPalaceIdx: monthPalace, dayPalaceIdx: dayPalace, hourPalaceIdx: hourPalace,
        path: [monthPalace, dayPalace, hourPalace],
        summary: '农历' + lunar.monthLabel + lunar.day + '日 ' + ZHI[sc] + '时，落「' + PALACES[hourPalace].name + '」宫'
      };
    }
    return { divine: divine, PALACES: PALACES };
  })();

  /* ============ 梅花易数 ============ */
  var MeiHua = (function () {
    /* 先天八卦数: 乾1兑2离3震4巽5坎6艮7坤8 */
    var XIAN_TIAN = { '乾':1, '兑':2, '离':3, '震':4, '巽':5, '坎':6, '艮':7, '坤':8 };
    var NUM_TO_TRIGRAM = { 1:'乾', 2:'兑', 3:'离', 4:'震', 5:'巽', 6:'坎', 7:'艮', 8:'坤' };
    /* 八卦 → 三爻 (自下而上, 1=阳 0=阴) */
    var TRIGRAM_LINES = {
      乾: [1,1,1], 兑: [0,1,1], 离: [1,0,1], 震: [1,0,0],
      巽: [0,1,1], 坎: [0,1,0], 艮: [0,0,1], 坤: [0,0,0]
    };
    function trigramByNum(n) { return NUM_TO_TRIGRAM[((n - 1) % 8) + 1]; }

    /** 由上下卦+动爻组装六爻 lines (自下而上, 与 YijingEngine 一致: 'yang'/'yin') */
    function buildLines(lowerTri, upperTri, movingIdx) {
      var lines = TRIGRAM_LINES[lowerTri].concat(TRIGRAM_LINES[upperTri]).map(function (b) { return b ? 'yang' : 'yin'; });
      if (lines[movingIdx] === 'yang') lines[movingIdx] = 'moving'; else lines[movingIdx] = 'movingYin';
      return lines;
    }
    /* lines 数组 → 卦号: 复用 YijingEngine.hexByLines 若可用, 否则本地查表 */
    function hexNoFromLines(lines) {
      if (typeof YijingEngine !== 'undefined' && YijingEngine.hexByLines) {
        var norm = lines.map(function (t) { return (t === 'yin' || t === 'movingYin') ? 'yin' : 'yang'; });
        var hex = YijingEngine.hexByLines(norm);
        if (hex) return hex.no;
      }
      return null;
    }

    /** 时间起卦: 农历年支序+月+日 → 上卦? 经典: (支+月+日)%8 上卦, 加时 → 下卦, 合数%6 动爻
     * 通行口诀: 年月日为上卦, 年月日加时为下卦 */
    function byTime(date) {
      var lunar = LunarCalendar.solarToLunar(date);
      if (!lunar) return null;
      var yearZhiIdx = ((lunar.year - 1900) % 12 + 12) % 12; /* 1900=子 */
      var sc = LunarCalendar.shichenIndex(date);
      var m = lunar.month, d = lunar.day, h = sc + 1;
      var upperN = (yearZhiIdx + 1 + m + d) % 8; if (upperN === 0) upperN = 8;
      var lowerN = (yearZhiIdx + 1 + m + d + h) % 8; if (lowerN === 0) lowerN = 8;
      var moving = (yearZhiIdx + 1 + m + d + h) % 6; if (moving === 0) moving = 6;
      return assemble(trigramByNum(upperN), trigramByNum(lowerN), moving - 1, '时间起卦',
        '农历' + lunar.monthLabel + lunar.day + '日 ' + ZHI[sc] + '时', date);
    }
    /** 数字起卦: 两数分上下卦 (第一数=上? 通行: 前数取上卦, 后数取下卦), 合数%6 动爻 */
    function byNumbers(a, b) {
      a = Math.abs(Math.floor(a) || 1); b = Math.abs(Math.floor(b) || 1);
      var upperN = a % 8; if (upperN === 0) upperN = 8;
      var lowerN = b % 8; if (lowerN === 0) lowerN = 8;
      var moving = (a + b) % 6; if (moving === 0) moving = 6;
      return assemble(trigramByNum(upperN), trigramByNum(lowerN), moving - 1, '数字起卦',
        '以 ' + a + '、' + b + ' 两数取象', new Date());
    }
    /** 掷骰起卦: 两枚 1-8 随机 */
    function byDice(rand) {
      var rnd = rand || Math.random;
      var a = 1 + Math.floor(rnd() * 8), b = 1 + Math.floor(rnd() * 8);
      var moving = 1 + Math.floor(rnd() * 6);
      return assemble(trigramByNum(a), trigramByNum(b), moving - 1, '掷骰起卦',
        '骰得 ' + a + '、' + b + ', 动 ' + moving + ' 爻', new Date());
    }
    function assemble(upper, lower, movingIdx, method, source, date) {
      var lines = buildLines(lower, upper, movingIdx);
      var no = hexNoFromLines(lines);
      var r = {
        upper: upper, lower: lower, movingIdx: movingIdx, method: method, source: source,
        lines: lines, hexNo: no, date: date,
        upperNum: XIAN_TIAN[upper], lowerNum: XIAN_TIAN[lower]
      };
      /* 复用 YijingEngine 体用推演 (若可用) */
      if (no !== null && typeof YijingEngine !== 'undefined' && YijingEngine.transform) {
        var moving = [movingIdx];
        var tf = YijingEngine.transform(no, moving);
        r.transform = tf;
      }
      return r;
    }
    return { byTime: byTime, byNumbers: byNumbers, byDice: byDice, buildLines: buildLines, trigramByNum: trigramByNum, XIAN_TIAN: XIAN_TIAN };
  })();

  window.YijingDivination = { LunarCalendar: LunarCalendar, BaZi: BaZi, DaYun: DaYun, XiaoLiuRen: XiaoLiuRen, MeiHua: MeiHua };
})();
