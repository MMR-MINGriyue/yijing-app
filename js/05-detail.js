/* ============================================================
 * yijing-app · js/05-detail.js (iter29 模块化拆分)
 * 原 index.html 内联 script 按架构层切分 (保持 IIFE 顺序不变)
 * 依赖: data.js / terms.js / divination.js 先加载
 * ============================================================ */

  (function bindDetailTabs() {
    const tabs = document.querySelectorAll('#detailTabs .detail-tab');
    const panes = document.querySelectorAll('#tabPanes .tab-pane');
    if (!tabs.length) return;
    const STORAGE_KEY = 'yijing.tab.lastPane';
    const container = document.getElementById('tabPanes');
    const indTrack = document.getElementById('indTrack');
    const indThumb = document.getElementById('indThumb');
    const indArrowLeft = document.getElementById('indArrowLeft');
    const indArrowRight = document.getElementById('indArrowRight');
    const TAB_ORDER = ['guaci', 'yaoci', 'xiangzhuan'];

    function getCurrentIdx() {
      const cur = sessionStorage.getItem(STORAGE_KEY) || 'guaci';
      return TAB_ORDER.indexOf(cur);
    }

    /* ===== P9-2: Tab 滑动指示器更新 ===== */
    function updateIndicator(idx) {
      if (!indThumb) return;
      const n = TAB_ORDER.length;
      const pct = (100 / n) * idx;
      indThumb.style.transform = 'translateX(' + pct + '%)';
      if (indArrowLeft) {
        if (idx <= 0) indArrowLeft.classList.add('disabled');
        else indArrowLeft.classList.remove('disabled');
      }
      if (indArrowRight) {
        if (idx >= n - 1) indArrowRight.classList.add('disabled');
        else indArrowRight.classList.remove('disabled');
      }
    }
    function getCurrentPaneName() {
      for (let i = 0; i < tabs.length; i++) if (tabs[i].classList.contains('active')) return tabs[i].dataset.pane;
      return TAB_ORDER[0];
    }

    function activate(paneName, record) {
      const tab = document.querySelector('#detailTabs .detail-tab[data-pane="' + paneName + '"]');
      if (!tab || tab.classList.contains('active')) return;
      tabs.forEach(t => t.classList.remove('active'));
      tab.classList.add('active');
      panes.forEach(p => {
        if (p.dataset.pane === paneName) {
          p.classList.remove('leaving');
          p.classList.add('active');
          p.style.animation = 'none';
          p.offsetHeight;
          p.style.animation = '';
        } else {
          p.classList.add('leaving');
          setTimeout(() => p.classList.remove('active', 'leaving'), 280);
        }
      });
      const idx = TAB_ORDER.indexOf(paneName);
      if (idx >= 0) updateIndicator(idx);
      if (record) {
        try { sessionStorage.setItem(STORAGE_KEY, paneName); } catch (e) {}
      }
    }

    function activateByOffset(dir) {
      const cur = TAB_ORDER.indexOf(getCurrentPaneName());
      let next = cur + dir;
      if (next < 0) next = 0;
      if (next >= TAB_ORDER.length) next = TAB_ORDER.length - 1;
      if (next !== cur) activate(TAB_ORDER[next], true);
    }

    tabs.forEach(tab => {
      tab.addEventListener('click', function() { activate(this.dataset.pane, true); });
    });

    /* P9-2: 箭头点击 */
    if (indArrowLeft) indArrowLeft.addEventListener('click', () => activateByOffset(-1));
    if (indArrowRight) indArrowRight.addEventListener('click', () => activateByOffset(1));

    /* P9-2: 指示器拖动 */
    if (indTrack && indThumb) {
      let isDragging = false;
      let startX = 0;
      function getX(e) { return e.touches ? e.touches[0].clientX : e.clientX; }
      function onDown(e) {
        isDragging = true;
        startX = getX(e);
        indTrack.classList.add('dragging');
        indThumb.classList.add('dragging');
      }
      function onMove(e) {
        if (!isDragging) return;
        const rect = indTrack.getBoundingClientRect();
        const dx = getX(e) - startX;
        const cur = TAB_ORDER.indexOf(getCurrentPaneName());
        const n = TAB_ORDER.length;
        const stepW = rect.width / n;
        const curPct = (100 / n) * cur;
        const dragPct = (dx / stepW) * (100 / n);
        const newPct = Math.max(0, Math.min(100 - 100 / n, curPct + dragPct));
        indThumb.style.transform = 'translateX(' + newPct + '%)';
      }
      function onUp(e) {
        if (!isDragging) return;
        isDragging = false;
        indTrack.classList.remove('dragging');
        indThumb.classList.remove('dragging');
        const rect = indTrack.getBoundingClientRect();
        const dx = getX(e) - startX;
        const cur = TAB_ORDER.indexOf(getCurrentPaneName());
        const n = TAB_ORDER.length;
        const stepW = rect.width / n;
        const dragSteps = dx / stepW;
        if (dragSteps < -0.4) activateByOffset(1);
        else if (dragSteps > 0.4) activateByOffset(-1);
        else updateIndicator(cur);
      }
      indTrack.addEventListener('mousedown', onDown);
      document.addEventListener('mousemove', onMove);
      document.addEventListener('mouseup', onUp);
      indTrack.addEventListener('touchstart', onDown, { passive: true });
      indTrack.addEventListener('touchmove', onMove, { passive: true });
      indTrack.addEventListener('touchend', onUp);
    }

    let saved = null;
    try { saved = sessionStorage.getItem(STORAGE_KEY); } catch (e) {}
    if (saved && saved !== 'guaci') {
      setTimeout(() => activate(saved, false), 50);
    } else {
      setTimeout(() => updateIndicator(0), 50);
    }

    document.addEventListener('keydown', function(e) {
      if (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA') return;
      if (e.key === '1') activate('guaci', true);
      else if (e.key === '2') activate('yaoci', true);
      else if (e.key === '3') activate('xiangzhuan', true);
      else if (e.key === 'ArrowLeft') activateByOffset(-1);
      else if (e.key === 'ArrowRight') activateByOffset(1);
    });

    if (container) {
      let isDragging = false;
      let startX = 0;
      let dragDelta = 0;
      let startTime = 0;
      function getX(e) { return e.touches ? e.touches[0].clientX : e.clientX; }
      container.addEventListener('mousedown', (e) => {
        if (e.target.closest('.text-card') || e.target.closest('.yao-row') || e.target.closest('.yao-toggle') || e.target.closest('.yao-modal')) return;
        isDragging = true; startX = getX(e); dragDelta = 0; startTime = Date.now();
        container.style.transition = 'opacity 0.2s';
        container.style.opacity = '0.85';
      });
      document.addEventListener('mousemove', (e) => {
        if (!isDragging) return;
        dragDelta = getX(e) - startX;
      });
      document.addEventListener('mouseup', (e) => {
        if (!isDragging) return;
        isDragging = false;
        container.style.opacity = '1';
        const w = container.offsetWidth;
        const elapsed = Date.now() - startTime;
        const velocity = Math.abs(dragDelta) / elapsed;
        const threshold = w * 0.15;
        if (dragDelta < -threshold || (dragDelta < -30 && velocity > 0.3)) {
          activateByOffset(1);
        } else if (dragDelta > threshold || (dragDelta > 30 && velocity > 0.3)) {
          activateByOffset(-1);
        }
      });
      container.addEventListener('touchstart', (e) => {
        if (e.target.closest('.text-card') || e.target.closest('.yao-row') || e.target.closest('.yao-toggle')) return;
        isDragging = true; startX = getX(e); dragDelta = 0; startTime = Date.now();
        container.style.transition = 'opacity 0.2s';
        container.style.opacity = '0.85';
      }, { passive: true });
      container.addEventListener('touchmove', (e) => { if (isDragging) dragDelta = getX(e) - startX; }, { passive: true });
      container.addEventListener('touchend', () => {
        if (!isDragging) return;
        isDragging = false;
        container.style.opacity = '1';
        const w = container.offsetWidth;
        const elapsed = Date.now() - startTime;
        const velocity = Math.abs(dragDelta) / elapsed;
        const threshold = w * 0.15;
        if (dragDelta < -threshold || (dragDelta < -30 && velocity > 0.3)) activateByOffset(1);
        else if (dragDelta > threshold || (dragDelta > 30 && velocity > 0.3)) activateByOffset(-1);
      });
    }

    window.YijingUI = window.YijingUI || {};
    window.YijingUI.switchTab = activate;
    window.YijingUI.updateTabIndicator = function() { updateIndicator(TAB_ORDER.indexOf(getCurrentPaneName())); };
  })();

  /* ============ 04 屏动态渲染 (任意卦的卦辞/爻辞/象传) ============ */
  (function bindDetailRenderer() {
    if (typeof YIJING_DATA === 'undefined') return;
    const LIB = YIJING_DATA.HEX_LIBRARY;
    let currentCtx = null;
    const phone = document.getElementById('phoneDetail');
    const mini = document.getElementById('detailHexMini');
    const nameEl = document.getElementById('detailHexName');
    const subEl = document.getElementById('detailHexSub');
    const juEl = document.getElementById('detailHexJu');
    const advice = document.getElementById('detailAdvice');
    const yaoList = document.getElementById('detailYaoList');
    if (!mini || !nameEl || !subEl || !juEl || !advice || !yaoList) return;

    const CN_NUM = ['零','一','二','三','四','五','六','七','八','九'];
    function cnum(n) {
      if (n <= 10) return CN_NUM[n];
      if (n < 20) return '十' + (n % 10 ? CN_NUM[n % 10] : '');
      if (n % 10 === 0) return CN_NUM[Math.floor(n / 10)] + '十';
      return CN_NUM[Math.floor(n / 10)] + '十' + CN_NUM[n % 10];
    }
    function lineHtml(t) {
      if (t === 'yin' || t === 'movingYin') {
        const bg = (t === 'movingYin')
          ? 'linear-gradient(90deg, var(--cinnabar) 0 38%, transparent 38% 62%, var(--cinnabar) 62% 100%)'
          : 'linear-gradient(90deg, var(--gold-line) 0 38%, transparent 38% 62%, var(--gold-line) 62% 100%)';
        return '<div class="hex-line" style="background:' + bg + ';"></div>';
      }
      return '<div class="hex-line"' + (t === 'moving' ? ' style="background:var(--cinnabar);"' : '') + '></div>';
    }
    function spaced(s) { return String(s).split('').join(' '); }
    function isMoving(t) { return t === 'moving' || t === 'movingYin'; }

    /* ctx: { question, moving:[idx], method, summary } — 起卦流程传入, 可缺省 */
    function renderDetail(hex, ctx) {
      if (!hex) return;
      const C = ctx || {};
      const mv = C.moving || [];
      /* 显示用爻位: 有动爻时按动爻覆盖, 否则用卦自身的 lines 标记 */
      const lines = mv.length
        ? hex.lines.map((t, i) => {
            if (mv.indexOf(i) < 0) return t === 'moving' || t === 'movingYin' ? (t === 'moving' ? 'yang' : 'yin') : t;
            return (t === 'yin') ? 'movingYin' : 'moving';
          })
        : hex.lines.slice();
      const parts = (hex.desc || '').split(' · ');
      const virtue = parts[1] || '';
      const title = parts[0] || '';

      /* hero 区 */
      mini.innerHTML = HEX_DRAW_ORDER.map(i => lineHtml(lines[i])).join('');
      nameEl.textContent = hex.name + ' 卦';
      subEl.textContent = '第 ' + cnum(hex.no) + ' 卦 · ' + title;
      juEl.textContent = '"' + (hex.guaci || '') + '"';

      /* 三个 Tab pane */
      const panes = document.querySelectorAll('#tabPanes .tab-pane');
      const paneOf = p => Array.prototype.find.call(panes, el => el.dataset.pane === p);
      const pGuaci = paneOf('guaci');
      const pYao = paneOf('yaoci');
      const pXiang = paneOf('xiangzhuan');
      if (pGuaci) {
        pGuaci.innerHTML =
          '<div class="text-card">' +
            '<div class="label muted">本 卦 卦 辞</div>' +
            '<div class="quote">' + escapeHtml(hex.guaci || '') + '</div>' +
            '<div class="body">' + escapeHtml(hex.intro || '') + '</div>' +
          '</div>';
      }
      if (pYao) {
        pYao.innerHTML = hex.yao.map((y, i) => {
          const moving = isMoving(lines[i]);
          return '<div class="text-card">' +
            '<div class="label ' + (moving ? 'cinnabar' : 'muted') + '">' + escapeHtml(spaced(y.n)) + (moving ? ' · 动' : '') + '</div>' +
            '<div class="quote">' + escapeHtml(y.q) + '</div>' +
            '<div class="body">' + escapeHtml(y.d) + '</div>' +
          '</div>';
        }).join('');
      }
      if (pXiang) {
        pXiang.innerHTML =
          '<div class="text-card">' +
            '<div class="label muted">大 象</div>' +
            '<div class="quote">' + escapeHtml(hex.daxiang || '') + '</div>' +
            '<div class="body">上卦' + escapeHtml(hex.trigramUName) + '、下卦' + escapeHtml(hex.trigramDName) + '，象取「' + escapeHtml(virtue) + '」。</div>' +
          '</div>' +
          '<div class="text-card">' +
            '<div class="label muted">卦 德</div>' +
            '<div class="quote">' + escapeHtml(virtue) + '</div>' +
            '<div class="body">得「' + escapeHtml(hex.name) + '卦」，宜体「' + escapeHtml(virtue) + '」之义，守正而行，则吉无不利。</div>' +
          '</div>';
      }

      /* 个性化建议卡 */
      advice.innerHTML =
        '<div class="label cinnabar">个 性 化 建 议</div>' +
        '<div class="question">' + escapeHtml(C.question ? ('关于：' + C.question) : ('综 述 · ' + virtue)) + '</div>' +
        '<div class="body bright">' + escapeHtml(C.summary || hex.intro || '') + '</div>';

      /* 六爻解读列表 (保留展开/折叠开关节点, 仅替换行) */
      const rowsHtml = hex.yao.map((y, i) => {
        const t = lines[i] || 'yang';
        const moving = isMoving(t);
        const collapse = i > 0 ? ' collapsed' : '';
        return '<div class="yao-row' + (moving ? ' moving' : '') + collapse + '">' +
          '<div class="yao-badge' + (moving ? ' moving' : '') + '">' + escapeHtml(y.n[0]) + '</div>' +
          '<div class="yao-info">' +
            (moving ? '<div class="yao-tag">● 动</div>' : '') +
            '<div class="yao-name">' + escapeHtml(y.n) + '</div>' +
            '<div class="yao-desc">' + escapeHtml(y.q) + (y.d ? ' ' + escapeHtml(y.d) : '') + '</div>' +
          '</div>' +
        '</div>';
      }).join('');
      yaoList.querySelectorAll('.yao-row').forEach(r => r.remove());
      const toggle = yaoList.querySelector('.yao-toggle');
      if (toggle) toggle.insertAdjacentHTML('beforebegin', rowsHtml);
      else yaoList.insertAdjacentHTML('beforeend', rowsHtml);

      /* Tab 复位到卦辞 */
      if (window.YijingUI && typeof window.YijingUI.switchTab === 'function') {
        window.YijingUI.switchTab('guaci', false);
      }
    }

    window.YijingUI = window.YijingUI || {};
    window.YijingUI.openDetail = function(hexNo, ctx) {
      const hex = LIB.find(h => h.no === hexNo);
      if (!hex) return;
      window.YijingUI._detailHexNo = hexNo;
      window.YijingUI._detailMoving = (ctx && ctx.moving) || [];
      currentCtx = ctx || null;
      renderDetail(hex, ctx);
      try {
        document.dispatchEvent(new CustomEvent('yijing:detailchange', { detail: { hexNo: hexNo } }));
      } catch (e) {}
      if (phone) {
        phone.classList.remove('flash');
        void phone.offsetWidth;
        phone.classList.add('flash');
        setTimeout(() => phone.classList.remove('flash'), 1200);
      }
    };
    window.YijingUI.renderDetailHex = renderDetail;

    /* URL 调试参数: ?hex=31 → 直接打开第 31 卦解析 */
    try {
      const p = new URLSearchParams(location.search);
      const q = parseInt(p.get('hex'), 10);
      if (q >= 1 && q <= 64) renderDetail(LIB.find(h => h.no === q));
    } catch (e) {}
    if (!window.location.search.includes('hex=')) renderDetail(LIB[0]);
  })();

  /* ============ 05 屏爻辞详情 Modal ============
     事件委托绑定（render() 重渲染不失效）+ 按 _transformState 读取真实卦爻数据 */
  (function bindYaoModal() {
    const modal = document.getElementById('yaoModal');
    if (!modal) return;
    const closeBtn = document.getElementById('yaoModalClose');
    const roleEl = document.getElementById('yaoModalRole');
    const nameEl = document.getElementById('yaoModalName');
    const badgeEl = document.getElementById('yaoModalBadge');
    const glyphEl = document.getElementById('yaoModalGlyph');
    const posEl = document.getElementById('yaoModalPos');
    const quoteEl = document.getElementById('yaoModalQuote');
    const bodyEl = document.getElementById('yaoModalBody');
    const copyBtn = document.getElementById('yaoModalCopy');
    const shareBtn = document.getElementById('yaoModalShare');

    /* 当前弹窗内容快照（复制 / 分享用） */
    let snap = null;
    const CN_POS = ['一', '二', '三', '四', '五', '六'];

    function toast(msg) {
      const t = document.getElementById('hexToast');
      if (!t) return;
      t.textContent = msg;
      t.classList.add('show');
      clearTimeout(t._timer);
      t._timer = setTimeout(() => t.classList.remove('show'), 1800);
    }

    function yaoData(hexNo, idx) {
      const hex = (typeof YIJING_DATA !== 'undefined' && YIJING_DATA.HEX_LIBRARY)
        ? YIJING_DATA.HEX_LIBRARY[hexNo - 1] : null;
      const y = hex && hex.yao && hex.yao[idx];
      return y || { n: '第 ' + CN_POS[idx] + ' 爻', q: '（爻辞暂未收录）', d: '本爻辞解释暂未录入。' };
    }

    /* kind: 'ben' 本卦 | 'chg' 变卦；yaoIdx 为爻数组下标 0=初 … 5=上 */
    function open(kind, yaoIdx) {
      const st = window.YijingUI && window.YijingUI._transformState;
      if (!st || typeof YijingEngine === 'undefined') return;
      const r = YijingEngine.transform(st.no, st.moving);
      const isBen = (kind === 'ben');
      const hex = isBen ? r.ben : r.changed;
      const y = yaoData(hex.no, yaoIdx);
      const isMoving = isBen
        ? st.moving.indexOf(yaoIdx) >= 0
        : r.yaoChanges.some(c => c.idx === yaoIdx);
      const isYang = hex.lines ? hex.lines[yaoIdx] === 'yang' : y.n.indexOf('九') === 0 || y.n.indexOf('初') === 0;

      snap = {
        title: hex.name + '卦 · ' + y.n,
        text: '「' + y.q + '」',
        body: y.d || ''
      };
      roleEl.textContent = (isBen ? '本 卦 · ' : '变 卦 · ') + hex.name;
      nameEl.textContent = y.n;
      posEl.textContent = '第 ' + CN_POS[yaoIdx] + ' 爻 · ' + (isYang ? '阳' : '阴');
      glyphEl.textContent = isYang ? '⚊' : '⚋';
      glyphEl.className = 'glyph ' + (isMoving ? 'cinnabar' : 'gold');
      if (isMoving) {
        badgeEl.textContent = isBen ? '动 爻' : '受 动 爻';
        badgeEl.classList.add('show');
      } else {
        badgeEl.classList.remove('show');
      }
      quoteEl.textContent = '「' + y.q + '」';
      bodyEl.textContent = y.d || '';
      modal.classList.add('show');
    }
    function close() { modal.classList.remove('show'); }
    function isOpen() { return modal.classList.contains('show'); }

    /* 关闭：按钮 / 遮罩 / Esc */
    closeBtn.addEventListener('click', close);
    closeBtn.addEventListener('keydown', function (e) {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); close(); }
    });
    modal.addEventListener('click', function (e) {
      if (e.target === modal) close();
    });
    document.addEventListener('keydown', function (e) {
      if (e.key === 'Escape' && isOpen()) close();
    });

    /* 事件委托：绑在持久祖先 transformSlider 上，render() 重建行后依然有效。
       本卦视图的 .line[data-yao] 点击已被 render() stopPropagation 用于切换动爻，
       不会触发此处；点击行的其余区域 / 变卦视图行则打开爻辞详情。 */
    const slider = document.getElementById('transformSlider');
    if (slider) {
      slider.addEventListener('click', function (e) {
        const row = e.target.closest('.stack .row');
        if (!row || modal.contains(row)) return;
        const stack = row.closest('.stack');
        const view = row.closest('[data-view]');
        if (!stack || !view) return;
        const rows = [].slice.call(stack.querySelectorAll('.row'));
        const k = rows.indexOf(row);
        if (k < 0) return;
        open(view.dataset.view === '0' ? 'ben' : 'chg', HEX_DRAW_ORDER[k]);
      });
    }

    /* 复制 / 分享 */
    function buildText() {
      if (!snap) return '';
      return snap.title + '\n' + snap.text + '\n' + snap.body + '\n—— 易道 · 卦象解读';
    }
    function doCopy() {
      if (!snap) return;
      const text = buildText();
      const done = () => toast('爻辞已复制');
      const fallback = () => {
        const ta = document.createElement('textarea');
        ta.value = text;
        ta.style.position = 'fixed';
        ta.style.opacity = '0';
        document.body.appendChild(ta);
        ta.select();
        try { document.execCommand('copy'); done(); } catch (err) { toast('复制失败'); }
        document.body.removeChild(ta);
      };
      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(done).catch(fallback);
      } else {
        fallback();
      }
    }
    function doShare() {
      if (!snap) return;
      if (navigator.share) {
        navigator.share({ title: '易道 · ' + snap.title, text: buildText() }).catch(function () {});
      } else {
        doCopy();
        toast('已复制，可粘贴分享');
      }
    }
    if (copyBtn) copyBtn.addEventListener('click', doCopy);
    if (shareBtn) shareBtn.addEventListener('click', doShare);
  })();

  /* ============ 响应式布局三态 ============
     app  : ≤900px  —— 全屏单屏 App，6 屏横向 scroll-snap 轮播
     grid : 901–1599px —— 390px 原尺寸换行网格 + 纵向滚动（保证可读）
     fit  : ≥1600px —— 2940×1300 设计画廊等比缩放全览
     断点与 CSS 的 @media 严格一致；URL ?view= 可强制覆盖。 */
  const YijingLayout = (function () {
    const APP_Q = '(max-width: 900px)';
    const GRID_Q = '(min-width: 901px) and (max-width: 1599px)';
    const mqApp = window.matchMedia ? window.matchMedia(APP_Q) : null;
    const mqGrid = window.matchMedia ? window.matchMedia(GRID_Q) : null;

    function mode() {
      const v = new URLSearchParams(location.search).get('view');
      if (v === 'app') return 'app';
      if (v === 'grid') return 'grid';
      if (v === 'fit' || v === 'canvas' || v === 'gallery') return 'fit';
      if (mqApp && mqApp.matches) return 'app';
      if (mqGrid && mqGrid.matches) return 'grid';
      return 'fit';
    }
    return {
      mode: mode,
      isApp: function () { return mode() === 'app'; },
      mqApp: mqApp,
      mqGrid: mqGrid,
      APP_Q: APP_Q,
      GRID_Q: GRID_Q
    };
  })();
  window.YijingLayout = YijingLayout;
  /* 兼容旧引用 */
  const YijingAppMode = { is: YijingLayout.isApp, mq: YijingLayout.mqApp, QUERY: YijingLayout.APP_Q };
  window.YijingAppMode = YijingAppMode;

  /* ============ 统一屏框结构 ============
     把 .phone-label 移出手机屏，落在屏框下方。
     修复：标签原为 absolute + margin-top:40px，静态位置落在屏内第 40px 处，
     与状态栏下方内容重叠（文字压文字）。 */
