/* ============================================================
 * yijing-app · js/02-home-cast.js (iter29 模块化拆分)
 * 原 index.html 内联 script 按架构层切分 (保持 IIFE 顺序不变)
 * 依赖: data.js / terms.js / divination.js 先加载
 * ============================================================ */

  (function bindHourHero() {
    const card = document.getElementById('heroCard');
    if (!card) return;
    const tag = document.getElementById('heroTag');
    const triU = document.getElementById('heroTriU');
    const triD = document.getElementById('heroTriD');
    const stack = document.getElementById('heroStack');
    const meta = document.getElementById('heroMeta');
    const idx = document.getElementById('heroIdx');
    const name = document.getElementById('heroName');
    const en = document.getElementById('heroEn');
    const attr = document.getElementById('heroAttr');
    const quote = document.getElementById('heroQuote');
    const desc = document.getElementById('heroDesc');
    const refresh = document.getElementById('heroRefresh');
    const refreshBtn = document.getElementById('heroRefresh');
    const TRIGRAMS = {
      '☰': '天', '☱': '泽', '☲': '火', '☳': '雷',
      '☴': '风', '☵': '水', '☶': '山', '☷': '地'
    };
    const HOUR_HEX = [0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23];
    const DEFAULT_QUOTES = {
      0:  { q: '元，亨，利，贞。', d: '今日大运亨通，宜积极进取，主动把握机遇；但需戒骄戒躁，稳健前行，方可成就大业。' },
      1:  { q: '元，亨，利牝马之贞。', d: '今日宜顺随大势，柔中带刚；以退为进，反得长久。' },
      2:  { q: '元，亨，利，贞。勿用，有攸往。', d: '万事初创，时机未熟。宜守不宜动，蓄势待发。' },
      3:  { q: '亨。匪我求童蒙，童蒙求我。', d: '宜主动求教或启发他人，谦逊受益，刚愎必败。' },
      4:  { q: '有孚，光亨，贞吉，利涉大川。', d: '宜耐心等待，心怀诚信。时机将至，谋定后动。' },
      5:  { q: '有孚，窒惕，中吉，终凶。', d: '慎争止讼，不与人争则吉；强争必凶。' }
    };
    const TRAITS = {
      qian: '乾为天 · 刚健中正', dui: '兑为泽 · 悦言和悦', li: '离为火 · 光明依附',
      zhen: '震为雷 · 奋起警醒', xun: '巽为风 · 顺入谦下', kan: '坎为水 · 险中求通',
      gen: '艮为山 · 止静守成', kun: '坤为地 · 柔顺包容'
    };
    const POS_NAMES = ['初', '二', '三', '四', '五', '上'];
    const TRIGRAM_TO_HEX_NO = {
      qian_qian: 1, kun_kun: 2, zhen_kun: 3, gen_kan: 4, kan_qian: 5, qian_kan: 6,
      kun_kan: 7, kan_kun: 8, xun_qian: 9, dui_qian: 10, kun_qian: 11, qian_kun: 12,
      li_qian: 13, qian_li: 14, gen_kun: 15, zhen_kun: 16
    };

    function hexNoFromHour(h) {
      const base = h % 16;
      return HOUR_HEX[base] !== undefined ? HOUR_HEX[base] : 0;
    }

    function lineType(t, idx, hexNo) {
      if (typeof YIJING_DATA === 'undefined') return t;
      const hex = YIJING_DATA.HEX_LIBRARY[hexNo - 1];
      if (!hex) return t;
      return hex.lines[idx] || t;
    }

    function getByHour() {
      const h = new Date().getHours();
      const idx2 = h % 16;
      const hex = (typeof YIJING_DATA !== 'undefined') ? YIJING_DATA.HEX_LIBRARY[idx2] : null;
      if (!hex) return { no: 1, name: '乾', en: 'Qian', desc: '乾为天 · 刚健中正', lines: ['yang','yang','yang','yang','yang','yang'] };
      return hex;
    }

    function getByRefresh() {
      const last = parseInt(sessionStorage.getItem('yijing.hero.refreshCount') || '0', 10);
      const newCount = last + 1;
      sessionStorage.setItem('yijing.hero.refreshCount', String(newCount));
      const list = (typeof YIJING_DATA !== 'undefined') ? YIJING_DATA.HEX_LIBRARY : [];
      if (list.length === 0) return { no: 1, name: '乾', en: 'Qian', desc: '乾为天 · 刚健中正', lines: ['yang','yang','yang','yang','yang','yang'] };
      const idx = newCount % list.length;
      return list[idx];
    }

    function render(hex, mode) {
      const triUGlyph = (hex.trigramU || '☰');
      const triDGlyph = (hex.trigramD || '☰');
      const triUName = TRIGRAMS[triUGlyph] || '天';
      const triDName = TRIGRAMS[triDGlyph] || '天';
      triU.textContent = triUGlyph + ' 上 · ' + triUName;
      triD.textContent = triDGlyph + ' 下 · ' + triDName;

      stack.innerHTML = '';
      for (let i = 5; i >= 0; i--) {
        const t = hex.lines[i] || 'yang';
        const wrap = document.createElement('div');
        wrap.className = 'hex-line';
        if (t === 'yang') wrap.classList.add('yang');
        else if (t === 'yin') wrap.classList.add('yin');
        else if (t === 'moving') wrap.classList.add('yang', 'moving');

        if (t === 'moving') {
          const tag2 = document.createElement('div');
          tag2.className = 'line-tag moving';
          tag2.textContent = '动';
          wrap.appendChild(tag2);
        }
        if (t === 'yin') {
          const left = document.createElement('div'); left.className = 'line-half';
          const gap = document.createElement('div'); gap.className = 'line-gap';
          const right = document.createElement('div'); right.className = 'line-half';
          wrap.appendChild(left); wrap.appendChild(gap); wrap.appendChild(right);
        }
        const num = document.createElement('div');
        num.className = 'line-num';
        num.textContent = POS_NAMES[i];
        wrap.appendChild(num);
        stack.appendChild(wrap);
      }

      const yangCount = hex.lines.filter(x => x === 'yang' || x === 'moving').length;
      const movingCount = hex.lines.filter(x => x === 'moving').length;
      meta.innerHTML =
        '<div class="hex-meta-item"><span class="dot yin-yang"></span>' +
        (yangCount === 6 ? '纯阳' : yangCount === 0 ? '纯阴' : '阳 ' + yangCount + ' / 阴 ' + (6 - yangCount)) +
        '</div>' +
        '<div class="hex-meta-item"><span class="dot moving"></span>' +
        (movingCount === 0 ? '无动爻' : movingCount + ' 动爻') +
        '</div>';

      idx.textContent = '第 ' + (hex.no < 10 ? ' ' : '') + hex.no + ' 卦';
      name.textContent = hex.name + ' 卦';
      en.textContent = hex.en + ' · ' + (hex.name === '乾' ? 'The Creative' : hex.name === '坤' ? 'The Receptive' : 'Hexagram');
      attr.textContent = hex.desc || '—';

      const dq = hex.guaci
        ? { q: hex.guaci, d: hex.intro || hex.desc || '—' }
        : (DEFAULT_QUOTES[hex.no] || DEFAULT_QUOTES[0]);
      quote.style.opacity = '0';
      desc.style.opacity = '0';
      setTimeout(() => {
        quote.textContent = '「' + dq.q + '」';
        desc.textContent = dq.d;
        quote.style.opacity = '1';
        desc.style.opacity = '1';
      }, mode === 'refresh' ? 200 : 350);
    }

    function shimmer() {
      const sh = document.createElement('div');
      sh.className = 'hero-shimmer';
      card.appendChild(sh);
      setTimeout(() => sh.remove(), 700);
    }
    const veil = document.getElementById('lottieVeil');
    const particles = document.getElementById('lottieParticles');
    function buildParticles() {
      if (!particles) return;
      particles.innerHTML = '';
      const N = 14;
      for (let i = 0; i < N; i++) {
        const d = document.createElement('div');
        d.className = 'dot-p';
        const angle = (i / N) * Math.PI * 2;
        const dist = 70 + Math.random() * 30;
        d.style.left = 'calc(50% - 2px)';
        d.style.top = 'calc(50% - 2px)';
        d.style.setProperty('--dx', Math.cos(angle) * dist + 'px');
        d.style.setProperty('--dy', Math.sin(angle) * dist + 'px');
        d.style.animationDelay = (i * 30) + 'ms';
        particles.appendChild(d);
      }
    }
    function lottieRefresh(done) {
      if (!veil) { done(); return; }
      buildParticles();
      particles.classList.remove('active');
      veil.classList.add('active');
      card.classList.add('refreshing');
      void veil.offsetWidth;
      particles.classList.add('active');
      setTimeout(() => {
        done();
        setTimeout(() => {
          veil.classList.remove('active');
          card.classList.remove('refreshing');
          particles.classList.remove('active');
        }, 200);
      }, 700);
    }

    const initial = getByHour();
    render(initial, 'init');

    if (refreshBtn) {
      refreshBtn.addEventListener('click', () => {
        if (refreshBtn.classList.contains('spinning')) return;
        refreshBtn.classList.add('spinning');
        lottieRefresh(() => {
          const next = getByRefresh();
          render(next, 'refresh');
          setTimeout(() => refreshBtn.classList.remove('spinning'), 400);
        });
      });
    }

    setTimeout(() => {
      const cur = getByHour();
      if (cur.no !== initial.no) render(cur, 'hour');
    }, 30000);

    window.YijingUI = window.YijingUI || {};
    window.YijingUI.refreshHero = () => { if (refreshBtn) refreshBtn.click(); };
    window.YijingUI.heroByHour = () => { render(getByHour(), 'hour'); };

    const heroCardEl = document.getElementById('heroCard');
    const handle = document.getElementById('heroExpandHandle');
    const fs = document.getElementById('heroFullscreen');
    const fsClose = document.getElementById('heroFsClose');
    const fsTrigram = document.getElementById('fsTrigram');
    const fsHex = document.getElementById('fsHex');
    const fsName = document.getElementById('fsName');
    const fsEn = document.getElementById('fsEn');
    const fsAttr = document.getElementById('fsAttr');
    const fsQuote = document.getElementById('fsQuote');
    const fsBody = document.getElementById('fsBody');
    const DEFAULT_FS = {
      0:  { body: '乾卦象征天，纯阳之卦，代表刚健中正、万物创始之象。乾之德，在于自强不息、至诚无息。' },
      1:  { body: '坤卦象征地，纯阴之卦，代表柔顺包容、万物承载之德。坤之德，在于厚德载物、至静而宁。' },
      2:  { body: '屯卦象征起始艰难，万物初生之时，险中求进，宜守正待时。' },
      3:  { body: '蒙卦象征启蒙奋发，承蒙教化之象。宜主动求教，启发蒙昧。' }
    };
    function openFullscreen() {
      if (!fs) return;
      const triUGlyph = initial.trigramU || '☰';
      const triDGlyph = initial.trigramD || '☰';
      const triUName = (TRIGRAMS[triUGlyph]) || '天';
      const triDName = (TRIGRAMS[triDGlyph]) || '天';
      fsTrigram.textContent = triUGlyph + ' 上·' + triUName + '  ' + triDGlyph + ' 下·' + triDName;
      fsHex.innerHTML = '';
      for (let i = 5; i >= 0; i--) {
        const t = initial.lines[i] || 'yang';
        const div = document.createElement('div');
        if (t === 'yin') {
          div.className = 'line yin';
        } else {
          div.className = 'line' + (t === 'moving' ? ' moving' : '');
        }
        fsHex.appendChild(div);
      }
      fsName.textContent = initial.name + ' 卦';
      fsEn.textContent = initial.en + ' · ' + (initial.name === '乾' ? 'The Creative' : 'Hexagram');
      fsAttr.textContent = initial.desc || '';
      fsQuote.textContent = '「' + (quote.textContent || '元，亨，利，贞。') + '」';
      fsBody.textContent = initial.intro || (DEFAULT_FS[initial.no] || DEFAULT_FS[0]).body;
      // P9-1: 渲染六爻交互
      renderFsYaoList();
      fs.classList.add('show');
    }

    /* ===== P9-1: hero 全屏内嵌六爻交互 ===== */
    const fsYaoList = document.getElementById('fsYaoList');
    const fsYaoSummaryText = document.getElementById('fsYaoSummaryText');
    /* 爻名依古法: 初九 / 九二 / 九三 … 上九 (复用推演引擎) */
    function getYaoName(line, posIdx) {
      const isYang = !(line === 'yin' || line === 'movingYin');
      if (typeof YijingEngine !== 'undefined') return YijingEngine.yaoName(posIdx, isYang);
      const POS = ['初', '二', '三', '四', '五', '上'];
      const nine = isYang ? '九' : '六';
      return (posIdx === 0 || posIdx === 5) ? POS[posIdx] + nine : nine + POS[posIdx];
    }
    function getYaoQuote(hexNo, posIdx, line) {
      const list = (typeof YIJING_DATA !== 'undefined') ? YIJING_DATA.HEX_LIBRARY : [];
      const hex = list[hexNo - 1];
      if (hex && hex.yao && hex.yao[posIdx]) return hex.yao[posIdx];
      return {
        n: getYaoName(line, posIdx),
        q: '（爻辞暂未补全）',
        d: '本爻辞解释暂未录入。'
      };
    }
    function renderFsYaoList() {
      if (!fsYaoList) return;
      fsYaoList.innerHTML = '';
      const hexNo = initial.no || 1;
      const lines = initial.lines || ['yang','yang','yang','yang','yang','yang'];
      let movingCount = 0;
      for (let i = 5; i >= 0; i--) {
        const t = lines[i] || 'yang';
        const isMoving = (t === 'moving');
        if (isMoving) movingCount++;
        const yaoData = getYaoQuote(hexNo, i, t);
        const row = document.createElement('div');
        row.className = 'fs-yao-row' + (isMoving ? ' moving' : '');
        row.dataset.yaoIdx = i;
        row.innerHTML =
          '<div class="fs-yao-badge">' + (i === 0 ? '初' : (i === 5 ? '上' : (i + 1))) + '</div>' +
          '<div class="fs-yao-info">' +
            '<div class="fs-yao-name">' + escapeHtml(yaoData.n) +
              (isMoving ? '<span class="fs-yao-tag">● 动</span>' : '') +
            '</div>' +
            '<div class="fs-yao-quote">' + escapeHtml(yaoData.q) + '</div>' +
          '</div>' +
          '<div class="fs-yao-arrow">›</div>' +
          '<div class="fs-yao-tooltip">' +
            '<div class="t-quote">「' + escapeHtml(yaoData.q) + '」</div>' +
            '<div class="t-body">' + escapeHtml(yaoData.d) + '</div>' +
          '</div>';
        fsYaoList.appendChild(row);
      }
      if (fsYaoSummaryText) {
        if (movingCount > 0) {
          fsYaoSummaryText.textContent = '本 卦 共 ' + movingCount + ' 个 动 爻  ·  点 击 查 看 爻 辞';
        } else {
          fsYaoSummaryText.textContent = '点 击 任 意 爻 查 看 爻 辞';
        }
      }
    }
    if (fsYaoList) {
      fsYaoList.addEventListener('click', (e) => {
        const row = e.target.closest('.fs-yao-row');
        if (!row) return;
        const wasExpanded = row.classList.contains('expanded');
        // 关闭其他所有展开项
        fsYaoList.querySelectorAll('.fs-yao-row.expanded').forEach(r => r.classList.remove('expanded'));
        if (!wasExpanded) row.classList.add('expanded');
      });
    }
    function closeFullscreen() { if (fs) fs.classList.remove('show'); }
    if (heroCardEl) heroCardEl.addEventListener('click', (e) => {
      if (e.target.closest('.hero-refresh')) return;
      if (e.target.closest('.hero-expand-handle')) { e.stopPropagation(); openFullscreen(); return; }
      openFullscreen();
    });
    if (handle) handle.addEventListener('click', (e) => { e.stopPropagation(); openFullscreen(); });
    if (fsClose) fsClose.addEventListener('click', (e) => { e.stopPropagation(); closeFullscreen(); });
    if (fsClose) fsClose.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); e.stopPropagation(); closeFullscreen(); }
    });
    /* Esc 关闭全屏；打开时把焦点移到关闭按钮，关闭后归还 */
    if (fs) {
      document.addEventListener('keydown', (e) => {
        if (e.key !== 'Escape' || !fs.classList.contains('show')) return;
        closeFullscreen();
      });
      const fsObserver = new MutationObserver(() => {
        if (fs.classList.contains('show')) {
          if (fsClose) { try { fsClose.focus(); } catch (err) {} }
        } else if (heroCardEl && document.activeElement === fsClose) {
          try { heroCardEl.focus(); } catch (err) {}
        }
      });
      fsObserver.observe(fs, { attributes: true, attributeFilter: ['class'] });
    }
    if (fs) fs.addEventListener('click', (e) => { if (e.target === fs) closeFullscreen(); });
    window.YijingUI.openHeroFullscreen = openFullscreen;
    window.YijingUI.closeHeroFullscreen = closeFullscreen;
  })();

  /* ============ 01 屏 时辰问候 ============ */
  (function bindHourGreeting() {
    window.YijingUI = window.YijingUI || {};
    const hello = document.getElementById('greetHello');
    const date = document.getElementById('greetDate');
    const tip = document.getElementById('greetHourTip');
    if (!hello || !tip) return;
    const HOURS = [
      { h: 23, n: '子', s: '夜 半', g: '子夜安', desc: '夜深人静，万物归藏' },
      { h: 1,  n: '丑', s: '鸡 鸣', g: '丑时安', desc: '夜色将尽，鸡鸣待旦' },
      { h: 3,  n: '寅', s: '平 旦', g: '寅时安', desc: '黎明破晓，万物苏醒' },
      { h: 5,  n: '卯', s: '日 出', g: '卯时安', desc: '日出东方，朝气初升' },
      { h: 7,  n: '辰', s: '食 时', g: '辰安', desc: '朝食之时，万物舒展' },
      { h: 9,  n: '巳', s: '隅 中', g: '巳时安', desc: '日近中天，阳气正盛' },
      { h: 11, n: '午', s: '日 中', g: '午安', desc: '日正当中，阴气初生' },
      { h: 13, n: '未', s: '日 昳', g: '未时安', desc: '日过中天，渐西斜' },
      { h: 15, n: '申', s: '哺 时', g: '申时安', desc: '夕阳将下，归鸟入林' },
      { h: 17, n: '酉', s: '日 入', g: '酉时安', desc: '日落西山，万物归息' },
      { h: 19, n: '戌', s: '黄 昏', g: '戌时安', desc: '暮色四合，天地昏黄' },
      { h: 21, n: '亥', s: '人 定', g: '亥时安', desc: '人定归寝，万籁俱寂' }
    ];
    function getCurrent() {
      const h = new Date().getHours();
      const idx = Math.floor((h + 1) / 2) % 12;
      return HOURS[idx];
    }
    function render() {
      const cur = getCurrent();
      hello.style.opacity = '0';
      tip.style.opacity = '0';
      setTimeout(() => {
        hello.textContent = cur.g + '，慕白';
        /* 真实干支日期: 丙午年 丙申月 丁丑日 · 8月31日 (时辰描述挪至 title) */
        if (date && window.YijingCalendar) {
          const now = new Date();
          date.textContent = YijingCalendar.ganzhiYear(now) + '年 ' +
            YijingCalendar.ganzhiMonth(now) + '月 ' +
            YijingCalendar.ganzhiDay(now) + '日 · ' + YijingCalendar.gregorian(now);
          date.title = cur.desc;
        } else if (date) {
          date.textContent = cur.desc;
        }
        tip.innerHTML = '<span class="pip"></span>' + cur.n + ' · ' + cur.s;
        hello.style.opacity = '1';
        tip.style.opacity = '1';
      }, 200);
    }
    render();
    setInterval(render, 30000);
    if (window.YijingUI) window.YijingUI.forceHour = render;
  })();

  /* ============ 03 屏 搜索 + 过滤 ============ */
  (function bindHexFilters() {
    window.bindHexFilters = function() {
      const toggle = document.getElementById('hexSearchToggle');
      const bar = document.getElementById('hexSearchBar');
      const input = document.getElementById('hexSearchInput');
      const clear = document.getElementById('hexSearchClear');
      const filters = document.querySelectorAll('.filter-row .filter');
      const meta = document.getElementById('hexFilterMeta');
      const rows = document.querySelectorAll('#hex-grid-rows .hex-row');
      const cards = document.querySelectorAll('#hex-grid-rows .hex-card');
      if (!toggle || !bar) return;

      let activeFilter = 'all';
      let searchTerm = '';
      let activePalace = '';      /* '' = 八宫全部 */

      /* 收藏: 复用 yijing.favHexes */
      function favList() {
        try { return JSON.parse(localStorage.getItem('yijing.favHexes') || '[]'); } catch (e) { return []; }
      }
      /* 宫成员集合: { 卦序: true } */
      function palaceSet(name) {
        const set = {};
        if (name && typeof YijingEngine !== 'undefined' && YijingEngine.palaceMembers) {
          YijingEngine.palaceMembers(name).forEach(n => { set[n] = true; });
        }
        return set;
      }

      function apply() {
        const favs = favList();
        const pset = (activeFilter === 'palace' && activePalace) ? palaceSet(activePalace) : null;
        let visible = 0;
        rows.forEach((row, ri) => {
          const rowCards = row.querySelectorAll('.hex-card');
          let rowHasVisible = false;
          rowCards.forEach((card, ci) => {
            const hexIdx = ri * 2 + ci;
            const hex = (typeof YIJING_DATA !== 'undefined') ? YIJING_DATA.HEX_LIBRARY[hexIdx] : null;
            let match = true;
            if (activeFilter === 'upper') match = (hexIdx < 30);
            else if (activeFilter === 'lower') match = (hexIdx >= 30);
            else if (activeFilter === 'fav') match = favs.indexOf(hexIdx + 1) >= 0;
            else if (pset) match = !!pset[hexIdx + 1];
            if (searchTerm) {
              const hay = (card.textContent + ' ' + (hex ? (hex.no + ' ' + hex.name + ' ' + hex.en + ' ' + hex.desc) : '')).toLowerCase();
              match = match && hay.indexOf(searchTerm) >= 0;
            }
            if (match) { card.classList.remove('hidden'); rowHasVisible = true; visible++; }
            else { card.classList.add('hidden'); }
          });
          if (rowHasVisible) row.classList.remove('hidden');
          else row.classList.add('hidden');
        });
        /* 宫筛选时标注每卦的世位 */
        if (activeFilter === 'palace') {
          cards.forEach((card, i) => {
            let tip = card.querySelector('.palace-tip');
            const info = (typeof YijingEngine !== 'undefined' && YijingEngine.palaceOf) ? YijingEngine.palaceOf(i + 1) : null;
            if (!info) return;
            if (!tip) {
              tip = document.createElement('div');
              tip.className = 'palace-tip';
              card.appendChild(tip);
            }
            tip.textContent = info.palace + ' · ' + info.stage;
            tip.style.display = '';
          });
        } else {
          cards.forEach(c => { const t = c.querySelector('.palace-tip'); if (t) t.style.display = 'none'; });
        }
        const label = (activeFilter === 'palace' && activePalace) ? activePalace + ' · ' : '';
        if (meta) meta.textContent = label + '共 ' + visible + ' 卦' + (searchTerm ? ' · "' + searchTerm + '"' : '');
        const grid = document.getElementById('hex-grid-rows');
        if (grid) {
          const more = grid.querySelector('.hex-more');
          if (more) more.style.display = (searchTerm || activeFilter !== 'all') ? 'none' : 'block';
        }
      }

      toggle.addEventListener('click', () => {
        const showing = bar.style.display !== 'none';
        bar.style.display = showing ? 'none' : 'flex';
        if (!showing) setTimeout(() => input.focus(), 200);
        else input.value = '';
        searchTerm = '';
        apply();
      });
      input.addEventListener('input', () => {
        searchTerm = input.value.trim().toLowerCase();
        apply();
      });
      clear.addEventListener('click', () => {
        input.value = '';
        searchTerm = '';
        apply();
        input.focus();
      });
      /* 八宫二级选择 chip */
      const palaceRow = document.getElementById('palaceRow');
      function paintPalaceChips() {
        if (!palaceRow) return;
        [].slice.call(palaceRow.children).forEach(c =>
          c.classList.toggle('active', c.dataset.palace === activePalace));
      }
      if (palaceRow && typeof YijingEngine !== 'undefined' && YijingEngine.PALACE_NAMES) {
        palaceRow.innerHTML = '';
        const mk = (label, name) => {
          const el = document.createElement('div');
          el.className = 'palace-chip';
          el.dataset.palace = name;
          el.textContent = label;
          el.setAttribute('role', 'button');
          el.tabIndex = 0;
          const act = () => { activePalace = name; paintPalaceChips(); apply(); };
          el.addEventListener('click', act);
          el.addEventListener('keydown', (e) => {
            if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); act(); }
          });
          palaceRow.appendChild(el);
        };
        mk('全 部', '');
        YijingEngine.PALACE_NAMES.forEach(p => mk(p.replace('宫', ''), p));
        paintPalaceChips();
      }

      filters.forEach(f => {
        f.addEventListener('click', () => {
          filters.forEach(x => x.classList.remove('active'));
          f.classList.add('active');
          activeFilter = f.dataset.filter;
          if (palaceRow) palaceRow.hidden = (activeFilter !== 'palace');
          paintPalaceChips();
          apply();
        });
      });
      /* 收藏在其他屏变化时同步刷新列表 */
      document.addEventListener('yijing:favchange', apply);
      apply();
    };
    if (document.getElementById('hex-grid-rows') && document.getElementById('hex-grid-rows').children.length > 0) {
      window.bindHexFilters();
    }
  })();

  /* ============ 05 屏 滑动切换 + 爻变 ============ */
