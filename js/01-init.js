/* ============================================================
 * yijing-app · js/01-init.js (iter29 模块化拆分)
 * 原 index.html 内联 script 按架构层切分 (保持 IIFE 顺序不变)
 * 依赖: data.js / terms.js / divination.js 先加载
 * ============================================================ */

  (function bindRecentList() {
    const box = document.getElementById('recentList');
    if (!box) return;
    /* iter23: 屏1首屏 auto-scroll 让最近占卜卡完整可见 (hero 已 flex-shrink:0 + 紧凑化)
       iter25: 横屏(landscape)下跳过 — 横屏网格模式首屏应停留 hero */
    function adjustHomeScroll() {
      if (window.matchMedia && window.matchMedia('(orientation: landscape)').matches) return;
      const rec = document.getElementById('recentList');
      const c = rec && rec.closest('.content.scroll'); /* 从 recentList 反查所属屏1 content */
      const tab = document.querySelector('.tabbar');
      if (!c || !rec || !tab || rec.children.length === 0) return;
      c.scrollTop = 0; /* 基准: 在 scrollTop=0 时测量 rec/tab 的视口坐标 */
      const recBottom = rec.getBoundingClientRect().bottom;
      const tabTop = tab.getBoundingClientRect().top;
      /* 让 rec.bottom 落在 tabTop - 12 (留 12px 视觉缓冲) */
      const targetScrollTop = recBottom - tabTop + 12;
      const maxScroll = c.scrollHeight - c.clientHeight;
      if (targetScrollTop > 0) c.scrollTop = Math.min(targetScrollTop, maxScroll);
    }
    window.YijingUI = window.YijingUI || {};
    window.YijingUI.adjustHomeScroll = adjustHomeScroll;
    function renderRecent() {
      const list = (typeof window.YijingHistory !== 'undefined')
        ? window.YijingHistory.all()
        : ((typeof YIJING_DATA !== 'undefined') ? YIJING_DATA.HISTORY : []);
      /* 容错: 跳过缺关键字段的畸形记录; 仅显示可跳转解析的记录 (八字/小六壬无 hexNo) */
      const items = list.filter(h => h && h.name && h.question && h.hexNo).slice(0, 2);
      box.innerHTML = '';
      items.forEach(h => {
        const rec = (h && typeof h.lines === 'object' && h.lines) ? h.lines : {};
        const linesHtml = HEX_DRAW_ORDER.map(i => {
          const t = rec[i];
          if (t === 'yin') return '<div class="recent-line yin"></div>';
          if (t === 'movingYin') return '<div class="recent-line yin moving"></div>';
          return '<div class="recent-line' + (t === 'moving' ? ' moving' : '') + '"></div>';
        }).join('');
        const card = document.createElement('div');
        card.className = 'recent-card';
        card.style.cursor = 'pointer';
        card.setAttribute('role', 'button');
        card.setAttribute('tabindex', '0');
        card.setAttribute('aria-label', '查看' + h.name + '解析');
        card.innerHTML =
          '<div class="recent-hex">' + linesHtml + '</div>' +
          '<div class="recent-info">' +
            '<div class="recent-head">' +
              '<div class="recent-name">' + escapeHtml(h.name) + '</div>' +
              '<div class="recent-time">' + escapeHtml(fmtRecordTime(h)) + '</div>' +
            '</div>' +
            '<div class="recent-q">' + escapeHtml(h.question) + '</div>' +
          '</div>';
        card.addEventListener('click', () => {
          if (h.hexNo && window.YijingUI && typeof window.YijingUI.openDetail === 'function') {
            window.YijingUI.openDetail(h.hexNo);
            if (window.YijingUI.gotoScreen) window.YijingUI.gotoScreen(3);
          }
        });
        card.addEventListener('keydown', e => {
          if (e.key === 'Enter' || e.key === ' ') {
            e.preventDefault();
            if (h.hexNo && window.YijingUI && typeof window.YijingUI.openDetail === 'function') {
              window.YijingUI.openDetail(h.hexNo);
              if (window.YijingUI.gotoScreen) window.YijingUI.gotoScreen(3);
            }
          }
        });
        box.appendChild(card);
      });
      /* 屏1入场 stagger 完成后 (hero 0.14s + quick-row 0.26s + recent-section 0.38s + 0.7s anim) 触发 auto-scroll */
      setTimeout(adjustHomeScroll, 1100);
    }
    window.YijingUI.refreshRecent = renderRecent;
    renderRecent();
  })();

  /* 由起卦结果构造一条历史记录 */
  function buildHistoryRecord(hex, castRes, question, direction, methodName) {
    const now = new Date();
    const lines = castRes.lines.map(function (t, i) {
      const mv = castRes.moving.indexOf(i) >= 0;
      if (!mv) return t;
      return t === 'yin' ? 'movingYin' : 'moving';
    });
    const HH = String(now.getHours()).padStart(2, '0');
    const MM = String(now.getMinutes()).padStart(2, '0');
    return {
      date: '今日 ' + HH + ':' + MM,
      ts: now.getTime(),
      month: now.getFullYear() + '-' + String(now.getMonth() + 1).padStart(2, '0'),
      day: now.getDate(),
      hexNo: hex.no,
      name: hex.name + '卦',
      question: question ? ('问：' + question) : '问：心中所念之事',
      direction: direction || '综合',
      directionColor: (function () {
        const map = { '事业': 'cinnabar', '感情': 'pine', '健康': 'cinnabar', '财运': 'gold', '学业': 'cinnabar' };
        return map[direction] || 'gold';
      })(),
      highlight: true,
      lines: lines,
      moving: castRes.moving.slice(),
      method: methodName || ''
    };
  }
  window.buildHistoryRecord = buildHistoryRecord;

  /* 记录时间显示: 有 ts 用真实时间 (今日/日期 + 时分), 旧数据回退 date 字段 */
  function fmtRecordTime(h) {
    if (!h.ts) return h.date || '';
    const d = new Date(h.ts);
    const now = new Date();
    const sameDay = d.getFullYear() === now.getFullYear() &&
      d.getMonth() === now.getMonth() && d.getDate() === now.getDate();
    const hm = String(d.getHours()).padStart(2, '0') + ':' + String(d.getMinutes()).padStart(2, '0');
    return (sameDay ? '今日' : ((d.getMonth() + 1) + '月' + d.getDate() + '日')) + ' ' + hm;
  }

  /* 数据不足 64 卦时才显示「后续卦待补全」提示 */
  function appendMoreHint(grid, loadedCount) {
    if (!grid || loadedCount >= 64) return;
    const more = document.createElement('div');
    more.className = 'hex-more';
    more.textContent = '第 ' + (loadedCount + 1) + ' - 64 卦 · 滑动查看更多 ↓';
    grid.appendChild(more);
  }

  /* ============ 注入 03 屏 8×2 网格 (异步加载, 兼容 data.js 缺失) ============ */
  (function renderHexGrid(data) {
    const D = data || (typeof YIJING_DATA !== 'undefined' ? YIJING_DATA.HEX_LIBRARY : []);
    const grid = document.getElementById('hex-grid-rows');
    if (!grid) return;
    for (let i = 0; i < D.length; i += 2) {
      const a = D[i], b = D[i+1];
      const row = document.createElement('div');
      row.className = 'hex-row';
      row.dataset.scope = (a.no <= 30) ? 'upper' : 'lower';
      const aCard = renderHexCard(a, i === 0);
      const bCard = b ? renderHexCard(b, false) : '';
      row.innerHTML = aCard + bCard;
      grid.appendChild(row);
    }
    if (D.length < 64) {
      const more = document.createElement('div');
      more.className = 'hex-more';
      more.textContent = '第 ' + (D.length + 1) + ' - 64 卦 · 滑动查看更多 ↓';
      grid.appendChild(more);
    }
    if (typeof window.bindHexFilters === 'function') window.bindHexFilters();

    /* 点击卦卡 → 打开 04 屏对应卦的解析并跳转 */
    grid.addEventListener('click', (e) => {
      const cardEl = e.target.closest('.hex-card');
      if (!cardEl) return;
      const no = parseInt(cardEl.dataset.no, 10);
      if (no && window.YijingUI && typeof window.YijingUI.openDetail === 'function') {
        window.YijingUI.openDetail(no);
        if (window.YijingUI.gotoScreen) window.YijingUI.gotoScreen(3);
      }
    });
  })();

  /* ============ 注入 02 屏 3 个起卦方式 ============ */
  (function renderMethods(data) {
    const D = data || (typeof YIJING_DATA !== 'undefined' ? YIJING_DATA.METHODS : []);
    const list = document.getElementById('method-list');
    if (!list) return;
    D.forEach(m => {
      const card = document.createElement('div');
      card.className = 'method-card' + (m.featured ? ' featured' : '');
      card.dataset.method = m.id;
      card.innerHTML =
        '<div class="method-icon ' + m.accent + '">' + escapeHtml(m.icon) + '</div>' +
        '<div class="method-info">' +
          '<div class="method-name dark">' + escapeHtml(m.name) + '</div>' +
          '<div class="method-desc">' + escapeHtml(m.desc) + '</div>' +
        '</div>' +
        (m.featured ? '<div class="badge">推 荐</div>' : '<div class="arrow">→</div>');
      list.appendChild(card);
    });
  })();

  /* ============ 注入 02 屏 5 个方向标签 (点击切换 + 记忆上次选择) ============ */
  (function renderTags(data) {
    const D = data || (typeof YIJING_DATA !== 'undefined' ? YIJING_DATA.DIRECTIONS : []);
    const row = document.getElementById('tag-row');
    if (!row) return;
    /* 上次选择恢复 (找不到则回退第 1 项) */
    let last = null;
    try { last = localStorage.getItem('yijing.lastDirection'); } catch (e) {}
    const hasLast = D.some(d => d.name === last);
    D.forEach((d, i) => {
      const t = document.createElement('div');
      const isDefault = !hasLast && i === 0;
      t.className = 'tag' + (isDefault || d.name === last ? ' active' : '');
      t.textContent = d.name;
      t.setAttribute('role', 'radio');
      t.setAttribute('aria-checked', t.className.indexOf('active') >= 0 ? 'true' : 'false');
      row.appendChild(t);
    });
    row.setAttribute('role', 'radiogroup');
    /* 保证仅一项 active */
    const setActive = function (target) {
      row.querySelectorAll('.tag').forEach(function (t) {
        const on = t === target;
        t.classList.toggle('active', on);
        t.setAttribute('aria-checked', on ? 'true' : 'false');
      });
      try { localStorage.setItem('yijing.lastDirection', target.textContent); } catch (e) {}
    };
    row.addEventListener('click', function (e) {
      const t = e.target.closest('.tag');
      if (t && !t.classList.contains('active')) setActive(t);
    });
    row.addEventListener('keydown', function (e) {
      if (e.key !== 'Enter' && e.key !== ' ') return;
      const t = e.target.closest && e.target.closest('.tag');
      if (t) { e.preventDefault(); setActive(t); }
    });
  })();

  /* ============ 注入 06 屏历史分组 ============ */
  (function renderHistory(data) {
    const D = data || (typeof YIJING_DATA !== 'undefined' ? YIJING_DATA.HISTORY : []);
    const today = document.getElementById('hist-today');
    const week  = document.getElementById('hist-week');
    if (!today || !week) return;
    D.forEach((h, i) => {
      const card = document.createElement('div');
      card.className = 'hist-card' + (h.highlight ? ' highlight' : '');
      const rec = (h && typeof h.lines === 'object' && h.lines) ? h.lines : {};
      const linesHtml = HEX_DRAW_ORDER.map(i => {
        const t = rec[i];
        if (t === 'yin') {
          return '<div class="hist-line" style="width:14px;"></div>';
        }
        return '<div class="hist-line' + (t==='moving'?' moving':'') + '"></div>';
      }).join('');
      card.innerHTML =
        '<div class="hist-hex">' + linesHtml + '</div>' +
        '<div class="hist-info">' +
          '<div class="hist-head">' +
            '<div style="display:flex;align-items:center;gap:8px;">' +
              '<div class="hist-name">' + escapeHtml(h.name) + '</div>' +
              '<div class="tag-mini ' + h.directionColor + '">' + escapeHtml(h.direction) + '</div>' +
            '</div>' +
            '<div class="hist-time">' + escapeHtml(fmtRecordTime(h)) + '</div>' +
          '</div>' +
          '<div class="hist-q">' + escapeHtml(h.question) + '</div>' +
        '</div>';
      if (i === 0) today.appendChild(card); else week.appendChild(card);
    });
  })();

  /* ============ 01 屏 时辰 → 卦象 (时间卦 + 换一卦) ============ */
