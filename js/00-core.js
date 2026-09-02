/* ============================================================
 * yijing-app · js/00-core.js (iter29 模块化拆分)
 * 原 index.html 内联 script 按架构层切分 (保持 IIFE 顺序不变)
 * 依赖: data.js / terms.js / divination.js 先加载
 * ============================================================ */

  /* ============ 工具函数 ============ */
  function escapeHtml(s) { return String(s).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c])); }
  /* 六爻显示顺序: 上爻 → 初爻 (lines 数组为初→上, 需反转后自上而下绘制)
     iter29: 模块化拆分后跨文件共享, 必须挂 window (const 不跨 script 可见) */
  window.HEX_DRAW_ORDER = [5, 4, 3, 2, 1, 0];
  /* ============ 干支历法 (干支纪日连续可靠, 纪年以立春为界) ============ */
  const YijingCalendar = (function () {
    const GAN = ['甲','乙','丙','丁','戊','己','庚','辛','壬','癸'];
    const ZHI = ['子','丑','寅','卯','辰','巳','午','未','申','酉','戌','亥'];
    /* 格里历 → 儒略日数 (JDN) */
    function jdn(y, m, d) {
      const a = Math.floor((14 - m) / 12);
      const yy = y + 4800 - a;
      const mm = m + 12 * a - 3;
      return d + Math.floor((153 * mm + 2) / 5) + 365 * yy +
             Math.floor(yy / 4) - Math.floor(yy / 100) + Math.floor(yy / 400) - 32045;
    }
    /* 干支纪日: 60 日一循环, 锚点 JD 2458511 = 甲子日 (0 基) */
    function ganzhiDay(date) {
      const idx = ((jdn(date.getFullYear(), date.getMonth() + 1, date.getDate()) - 11) % 60 + 60) % 60;
      return GAN[idx % 10] + ZHI[idx % 12];
    }
    /* 干支纪年: 以立春(~2月4日)为界, 1984 = 甲子 */
    function ganzhiYear(date) {
      let y = date.getFullYear();
      const m = date.getMonth() + 1, d = date.getDate();
      if (m < 2 || (m === 2 && d < 4)) y -= 1;
      const idx = ((y - 1984) % 60 + 60) % 60;
      return GAN[idx % 10] + ZHI[idx % 12];
    }
    /* 月干支: 以立春为正月(寅月)起点, 每月以节气为界 (立春/惊蛰/…/小寒)
       节气日每年漂移 < 1 天, 2024-2030 用同表精度 ±1 天, 足够 UI 展示 */
    const TERMS = [
      /* [月, 日, 月序] 按公历年内时间排序; 月序 0=寅 … 10=子, 11=丑 */
      [1, 6, 11],   /* 小寒 → 丑月 */
      [2, 4, 0],    /* 立春 → 寅月 */
      [3, 5, 1],    /* 惊蛰 → 卯月 */
      [4, 4, 2],    /* 清明 → 辰月 */
      [5, 5, 3],    /* 立夏 → 巳月 */
      [6, 5, 4],    /* 芒种 → 午月 */
      [7, 6, 5],    /* 小暑 → 未月 */
      [8, 7, 6],    /* 立秋 → 申月 */
      [9, 7, 7],    /* 白露 → 酉月 */
      [10, 8, 8],   /* 寒露 → 戌月 */
      [11, 7, 9],   /* 立冬 → 亥月 */
      [12, 7, 10]   /* 大雪 → 子月 */
    ];
    function monthGanzhiIndex(date) {
      const y = date.getFullYear(), m = date.getMonth() + 1, d = date.getDate();
      const curJDN = jdn(y, m, d);
      let mi = 10; /* 1 月 1-5 日: 上一年大雪起的子月 */
      TERMS.forEach(function (t) {
        if (curJDN >= jdn(y, t[0], t[1])) mi = t[2];
      });
      return mi;
    }
    /* 月干支: 年上起月法 — 甲己之年丙作首 (正月建寅)
       优先用 terms.js 分钟级节气表 (修掉节气交界日 ±1 天月柱可能错的边界问题),
       表不可用时回退日期级旧表 */
    function ganzhiMonth(date) {
      /* 精确路径: 12 节索引 0=小寒..11=大雪 → 月支索引 小寒→丑(11), 立春→寅(0) */
      if (typeof PreciseTerms !== 'undefined' && PreciseTerms.jieList) {
        const ts = date.getTime();
        const y0 = date.getFullYear();
        const listY = PreciseTerms.jieList(y0);
        const listPrev = PreciseTerms.jieList(y0 - 1);
        if (listY && listPrev) {
          const idx = (function () {
            for (let i = 11; i >= 0; i--) { if (ts >= listY[i].ts) return i; }
            return 11; /* 早于当年小寒 → 上一年大雪起的子月 */
          })();
          const mi = (idx + 11) % 12;
          /* 干支年以立春为界: 立春前属上一年 */
          let y = y0;
          if (ts < listY[1].ts) y -= 1;
          const yearGanIdx = (((y - 1984) % 60 + 60) % 60) % 10;
          const monthGanStart = [2, 4, 6, 8, 0][yearGanIdx % 5];
          const ganIdx = (monthGanStart + mi) % 10;
          const zhiIdx = (2 + mi) % 12; /* 寅=2 */
          return GAN[ganIdx] + ZHI[zhiIdx];
        }
      }
      /* 回退: 日期级旧表 */
      let y = date.getFullYear();
      const m = date.getMonth() + 1, d = date.getDate();
      if (m < 2 || (m === 2 && d < 4)) y -= 1;
      const yearGanIdx = (((y - 1984) % 60 + 60) % 60) % 10;
      /* 正月天干: 甲/己年=丙(2), 乙/庚年=戊(4), 丙/辛年=庚(6), 丁/壬年=壬(8), 戊/癸年=甲(0) */
      const monthGanStart = [2, 4, 6, 8, 0][yearGanIdx % 5];
      const mi = monthGanzhiIndex(date);
      const ganIdx = (monthGanStart + mi) % 10;
      const zhiIdx = (2 + mi) % 12; /* 寅=2 */
      return GAN[ganIdx] + ZHI[zhiIdx];
    }
    function gregorian(date) {
      return (date.getMonth() + 1) + '月' + date.getDate() + '日';
    }
    return { jdn: jdn, ganzhiDay: ganzhiDay, ganzhiYear: ganzhiYear, ganzhiMonth: ganzhiMonth, gregorian: gregorian };
  })();
  window.YijingCalendar = YijingCalendar;

  /* ============ 状态栏实时时钟 (6 屏同步, 30s 刷新) ============ */
  (function bindStatusBarClock() {
    const els = [].slice.call(document.querySelectorAll('.status-time'));
    if (!els.length) return;
    function tick() {
      const n = new Date();
      const t = n.getHours() + ':' + String(n.getMinutes()).padStart(2, '0');
      els.forEach(el => { el.textContent = t; });
    }
    tick();
    setInterval(tick, 30000);
  })();
  function renderHexCard(hex, featured) {
    const linesHtml = HEX_DRAW_ORDER.map(i => {
      const t = hex.lines[i];
      if (t === 'yin' || t === 'movingYin') {
        const c = (t === 'movingYin') ? 'background:var(--cinnabar);' : '';
        return '<div class="row"><div class="hex-line" style="width:16px;height:3px;' + c + '"></div>' +
          '<div class="hex-line" style="width:4px;height:3px;background:transparent;"></div>' +
          '<div class="hex-line" style="width:16px;height:3px;' + c + '"></div></div>';
      }
      return '<div class="row"><div class="hex-line" style="width:36px;height:3px;' + (t==='moving'?'background:var(--cinnabar);':'') + '"></div></div>';
    }).join('');
    return '<div class="hex-card' + (featured?' featured':'') + '" data-no="' + hex.no + '">' +
      '<div class="hex-icon">' + linesHtml + '</div>' +
      '<div class="hex-name">' + escapeHtml(hex.name) + '</div>' +
      '<div class="hex-no">第 ' + hex.no + ' 卦</div>' +
    '</div>';
  }

  /* ============ 起卦历史存储 (localStorage + 内置示例数据) ============ */
  const YijingHistory = (function () {
    const KEY = 'yijing.history.v1';
    function load() {
      try { const v = JSON.parse(localStorage.getItem(KEY) || '[]'); return Array.isArray(v) ? v : []; }
      catch (e) { return []; }
    }
    function save(list) { try { localStorage.setItem(KEY, JSON.stringify(list)); } catch (e) {} }
    /** 新增一条记录 (置于最前), 返回该记录 */
    function add(rec) { const l = load(); l.unshift(rec); save(l); return rec; }
    /** 真实记录 + 内置示例数据 (真实记录在前, 视为更新) */
    function all() {
      const base = (typeof YIJING_DATA !== 'undefined' && YIJING_DATA.HISTORY) ? YIJING_DATA.HISTORY : [];
      return load().concat(base);
    }
    function clear() { save([]); }
    function count() { return load().length; }
    /** 按 all() 的下标删除: 前半段命中 localStorage, 后半段命中内置示例数据 */
    function removeAt(idx) {
      const mine = load();
      if (idx < mine.length) { mine.splice(idx, 1); save(mine); return true; }
      const base = (typeof YIJING_DATA !== 'undefined' && YIJING_DATA.HISTORY) ? YIJING_DATA.HISTORY : [];
      const j = idx - mine.length;
      if (j >= 0 && j < base.length) { base.splice(j, 1); return true; }
      return false;
    }
    function removeMany(indicesDesc) {
      indicesDesc.forEach(i => removeAt(i));
    }
    return { KEY: KEY, load: load, save: save, add: add, all: all, clear: clear, count: count,
             removeAt: removeAt, removeMany: removeMany };
  })();
  window.YijingHistory = YijingHistory;

  /* ============ 01 屏 最近占卜 (真实记录前 2 条, 点击直达 04 屏解析) ============ */
