/* ============================================================
 * yijing-app · js/04-history.js (iter29 模块化拆分)
 * 原 index.html 内联 script 按架构层切分 (保持 IIFE 顺序不变)
 * 依赖: data.js / terms.js / divination.js 先加载
 * ============================================================ */

  (function bindHistoryStates() {
    const today = document.getElementById('hist-today');
    const week = document.getElementById('hist-week');
    const monthLabel = document.getElementById('monthLabel');
    const monthStats = document.getElementById('monthStats');
    const monthPrev = document.getElementById('monthPrev');
    const monthNext = document.getElementById('monthNext');
    if (!today) return;
    /* iter28: 搜索关键字高亮 (在转义后安全地插入 <mark>) */
    function highlight(text, kw) {
      const s = String(text == null ? '' : text);
      if (!kw) return escapeHtml(s);
      const lower = s.toLowerCase();
      const kwl = kw.toLowerCase();
      const idx = lower.indexOf(kwl);
      if (idx < 0) return escapeHtml(s);
      return escapeHtml(s.slice(0, idx)) +
        '<mark class="hist-mark">' + escapeHtml(s.slice(idx, idx + kw.length)) + '</mark>' +
        escapeHtml(s.slice(idx + kw.length));
    }
    function renderOne(h, idx) {
      const card = document.createElement('div');
      card.className = 'hist-card month-card' + (h.highlight ? ' highlight' : '') + (histKeyword ? ' search-hit' : '');
      card.dataset.idx = idx;
      card.dataset.hex = h.hexNo;
      /* 容错: 导入的旧格式/缺字段记录无 lines 时按全阳爻渲染, 不抛异常
         非卦类占法 (八字/小六壬): 以占法徽标替代卦形缩略图 */
      const thumbHtml = (h.type && h.type !== 'iching' && !(typeof h.lines === 'object' && h.lines))
        ? '<div class="hist-badge ' + (h.directionColor || 'gold') + '">' + (h.direction || h.type) + '</div>'
        : (function () {
            const rec = (h && typeof h.lines === 'object' && h.lines) ? h.lines : {};
            return HEX_DRAW_ORDER.map(i => {
              const t = rec[i];
              if (t === 'yin') return '<div class="hist-line" style="width:14px;"></div>';
              if (t === 'movingYin') return '<div class="hist-line moving" style="width:14px;"></div>';
              return '<div class="hist-line' + (t==='moving'?' moving':'') + '"></div>';
            }).join('');
          })();
      card.innerHTML =
        '<div class="select-check">✓</div>' +
        '<div class="hist-hex">' + thumbHtml + '</div>' +
        '<div class="hist-info">' +
          '<div class="hist-head">' +
            '<div style="display:flex;align-items:center;gap:8px;">' +
              '<div class="hist-name">' + highlight(h.name, histKeyword) + '</div>' +
              '<div class="tag-mini ' + h.directionColor + '">' + escapeHtml(h.direction) + '</div>' +
            '</div>' +
            '<div class="hist-time">' + escapeHtml(fmtRecordTime(h)) + '</div>' +
          '</div>' +
          '<div class="hist-q">' + highlight(h.question, histKeyword) + '</div>' +
        '</div>';
      return card;
    }
    /* 真实起卦记录 (localStorage) + 内置示例数据 */
    function getHistory() {
      return (typeof window.YijingHistory !== 'undefined') ? window.YijingHistory.all()
           : ((typeof YIJING_DATA !== 'undefined') ? YIJING_DATA.HISTORY : []);
    }
    const MONTH_NAMES = ['一','二','三','四','五','六','七','八','九','十','十一','十二'];
    const ymOf = (y, m) => y * 12 + m;
    const ymSplit = n => { const m = n % 12 || 12; return [ (n - m) / 12, m ]; };
    /* 月份范围随数据动态扩展: 最早一条记录 ~ max(最新记录, 当前自然月) */
    let minYm = ymOf(2026, 5), maxYm = ymOf(2026, 6);
    let currentYear = 2026, currentMonth = 6;
    function refreshRange(keepCurrent) {
      const set = {};
      getHistory().forEach(function (h) { if (h.month) set[h.month] = true; });
      const now = new Date();
      const curYm = now.getFullYear() + '-' + String(now.getMonth() + 1).padStart(2, '0');
      const curNum = ymOf(now.getFullYear(), now.getMonth() + 1);
      const keys = Object.keys(set).sort();
      const minKey = keys.length ? keys[0] : curYm;
      const maxKey = keys.length ? keys[keys.length - 1] : curYm;
      const a = minKey.split('-'), b = maxKey.split('-');
      minYm = ymOf(+a[0], +a[1]);
      /* 上界取「最新记录月份」与「当前月」的较大者, 保证新起卦能翻到 */
      maxYm = Math.max(ymOf(+b[0], +b[1]), curNum);
      if (!keepCurrent) { currentYear = +b[0]; currentMonth = +b[1]; }
      const cur = ymOf(currentYear, currentMonth);
      if (cur < minYm) { currentYear = +a[0]; currentMonth = +a[1]; }
      if (cur > maxYm) { const t = ymSplit(maxYm); currentYear = t[0]; currentMonth = t[1]; }
    }
    refreshRange(false);
    function setNavState() {
      const cur = ymOf(currentYear, currentMonth);
      if (monthPrev) monthPrev.classList.toggle('disabled', cur <= minYm);
      if (monthNext) monthNext.classList.toggle('disabled', cur >= maxYm);
    }
    function renderCurrentMonth() {
      const cur = String(currentYear) + '-' + String(currentMonth).padStart(2, '0');
      if (monthLabel) monthLabel.textContent = currentYear + ' 年 ' + MONTH_NAMES[currentMonth - 1] + ' 月';
      const list = getHistory();
      let monthItems = list.filter(h => h.month === cur);
      // P9-3: 应用卦象筛选
      if (activeHexFilter !== null) {
        monthItems = monthItems.filter(h => h.hexNo === activeHexFilter);
      }
      // 方向筛选
      if (activeDirFilter) {
        monthItems = monthItems.filter(h => h.direction === activeDirFilter);
      }
      // 占法筛选 (type 缺省视为 iching)
      if (activeTypeFilter) {
        monthItems = monthItems.filter(h => recType(h) === activeTypeFilter);
      }
      // 关键词搜索: 卦名 / 问题 / 日期
      if (histKeyword) {
        const kw = histKeyword.toLowerCase();
        monthItems = monthItems.filter(h =>
          String(h.name || '').toLowerCase().includes(kw) ||
          String(h.question || '').toLowerCase().includes(kw) ||
          String(h.date || '').toLowerCase().includes(kw) ||
          String(h.day || '').includes(histKeyword));
      }
      if (monthItems.length === 0) {
        today.innerHTML = '<div class="group-cap">' + currentMonth + ' 月</div>';
        const emptyMsg = histKeyword
          ? '无 匹 配 记 录'
          : (activeHexFilter !== null || activeDirFilter
            ? '该 筛 选 条 件 下 本 月 无 记 录'
            : '本 月 尚 未 起 卦<br>卦象可循，方寸不乱');
        week.innerHTML = '<div class="hist-empty">' + emptyMsg + '</div>';
        if (monthStats) monthStats.textContent = '共 0 次';
        updateFilterMeta(0);
        return;
      }
      if (monthStats) monthStats.textContent = '共 ' + monthItems.length + ' 次';
      updateFilterMeta(monthItems.length);
      /* 排序: 按 ts 时间戳 (真实记录最新/最早在前), 内置样例无 ts 沉底 */
      const ordered = monthItems.slice().sort((a, b) =>
        histSortDesc ? ((b.ts || 0) - (a.ts || 0)) : ((a.ts || 0) - (b.ts || 0)));
      const lateItems = ordered.filter(h => h.day >= 17);
      const earlyItems = ordered.filter(h => h.day < 17);
      const g1 = histSortDesc ? lateItems : earlyItems;
      const g2 = histSortDesc ? earlyItems : lateItems;
      today.innerHTML = '<div class="group-cap">' + (histSortDesc ? '近 期' : '早 些') + '</div>';
      g1.forEach((h, i) => {
        const realIdx = list.indexOf(h);
        today.appendChild(renderOne(h, realIdx));
      });
      if (g2.length > 0) {
        week.innerHTML = '<div class="group-cap">' + (histSortDesc ? '同 月 早 些' : '同 月 近 期') + '</div>';
        g2.slice(0, 4).forEach(h => {
          const realIdx = list.indexOf(h);
          week.appendChild(renderOne(h, realIdx));
        });
      } else {
        week.innerHTML = '';
      }
      bindLongPress();
      if (selectMode) renderSelectToolbar();
    }
    /* ===== 排序切换 (⇅) ===== */
    let histSortDesc = true; /* true = 最新在前 */
    const histSortBtn = document.getElementById('histSortBtn');
    if (histSortBtn) {
      const applySortState = function () {
        histSortBtn.setAttribute('aria-label',
          histSortDesc ? '当前最新在前，点击改为最早在前' : '当前最早在前，点击改为最新在前');
        histSortBtn.classList.toggle('flipped', !histSortDesc);
      };
      histSortBtn.addEventListener('click', () => {
        histSortDesc = !histSortDesc;
        applySortState();
        renderCurrentMonth();
      });
      applySortState();
    }
    /* ===== 关键词搜索 ===== */
    let histKeyword = '';
    const histSearchInput = document.getElementById('histSearchInput');
    if (histSearchInput) {
      histSearchInput.addEventListener('input', () => {
        histKeyword = histSearchInput.value.trim();
        renderCurrentMonth();
      });
    }
    /* ===== 统计卡: 总次数 / 本周(近7天) / 收藏, 全部实时计算 ===== */
    function renderStats() {
      const list = getHistory();
      let favCount = 0;
      try {
        const f = JSON.parse(localStorage.getItem('yijing.favHexes') || '[]');
        if (Array.isArray(f)) favCount = f.length;
      } catch (e) {}
      const now = new Date();
      const weekStart = new Date(now.getFullYear(), now.getMonth(), now.getDate() - 6);
      let weekCount = 0;
      list.forEach(h => {
        let d = h.ts ? new Date(h.ts) : null;
        if (!d && h.month) {
          const p = String(h.month).split('-');
          d = new Date(+p[0], (+p[1]) - 1, h.day || 1);
        }
        if (d && d >= weekStart && d <= now) weekCount++;
      });
      const stTotal = document.getElementById('statTotal');
      const stWeek = document.getElementById('statWeek');
      const stFav = document.getElementById('statFav');
      const stCount = document.getElementById('histTotalCount');
      if (stTotal) stTotal.textContent = String(list.length);
      if (stWeek) stWeek.textContent = String(weekCount);
      if (stFav) stFav.textContent = String(favCount);
      if (stCount) stCount.textContent = 'Past Divinations · 共 ' + list.length + ' 次';
    }
    document.addEventListener('yijing:favchange', renderStats);
    if (monthPrev) monthPrev.addEventListener('click', () => {
      currentMonth--;
      if (currentMonth < 1) { currentMonth = 12; currentYear--; }
      setNavState();
      activeDirFilter = '';
      renderHexFilterChips();
      renderDirChips();
      renderCurrentMonth();
    });
    if (monthNext) monthNext.addEventListener('click', () => {
      currentMonth++;
      if (currentMonth > 12) { currentMonth = 1; currentYear++; }
      setNavState();
      activeDirFilter = '';
      renderHexFilterChips();
      renderDirChips();
      renderCurrentMonth();
    });
    setNavState();

    /* ===== P9-3: 按卦象筛选 ===== */
    const hexFilterRow = document.getElementById('hexFilterRow');
    const hexFilterMetaText = document.getElementById('hexFilterMetaText');
    const hexFilterClear = document.getElementById('hexFilterClear');
    let activeHexFilter = null; // null = 全部, number = hexNo
    let activeDirFilter = '';   // '' = 全部, 文本 = direction
    let activeTypeFilter = '';  // '' = 全部, iching/bazi/xlr/meihua = 占法
    const FILTER_HEXES = [1, 2, 5, 11, 12, 16, 6, 9]; // 乾/坤/需/泰/否/豫/讼/小畜
    const HEX_NAMES = {
      1:'乾', 2:'坤', 5:'需', 11:'泰', 12:'否', 16:'豫', 6:'讼', 9:'小畜'
    };
    function getHexGlyph(hexNo) {
      const list = (typeof YIJING_DATA !== 'undefined') ? YIJING_DATA.HEX_LIBRARY : [];
      const hex = list.find(h => h.no === hexNo);
      return hex ? hex.trigramU : '☰';
    }
    function getHexCount(hexNo) {
      const list = getHistory();
      const cur = String(currentYear) + '-' + String(currentMonth).padStart(2, '0');
      return list.filter(h => h.month === cur && h.hexNo === hexNo).length;
    }
    function renderHexFilterChips() {
      if (!hexFilterRow) return;
      hexFilterRow.innerHTML = '';
      // 全部
      const all = document.createElement('div');
      all.className = 'hex-filter-chip active';
      all.dataset.hex = '';
      all.innerHTML = '<span class="chip-glyph">⊕</span><span>全 部</span>';
      hexFilterRow.appendChild(all);
      FILTER_HEXES.forEach(no => {
        const chip = document.createElement('div');
        chip.className = 'hex-filter-chip';
        chip.dataset.hex = String(no);
        const count = getHexCount(no);
        chip.innerHTML =
          '<span class="chip-glyph">' + getHexGlyph(no) + '</span>' +
          '<span>' + (HEX_NAMES[no] || ('第' + no)) + '</span>' +
          '<span class="chip-count">' + count + '</span>';
        hexFilterRow.appendChild(chip);
      });
      bindHexChipClicks();
    }
    function bindHexChipClicks() {
      if (!hexFilterRow) return;
      hexFilterRow.querySelectorAll('.hex-filter-chip').forEach(chip => {
        chip.addEventListener('click', () => {
          const v = chip.dataset.hex;
          if (v === '') {
            activeHexFilter = null;
          } else {
            const n = parseInt(v, 10);
            activeHexFilter = (activeHexFilter === n) ? null : n;
          }
          // 更新 active 状态
          hexFilterRow.querySelectorAll('.hex-filter-chip').forEach(c => c.classList.remove('active'));
          if (activeHexFilter === null) {
            hexFilterRow.querySelector('.hex-filter-chip[data-hex=""]').classList.add('active');
          } else {
            const target = hexFilterRow.querySelector('.hex-filter-chip[data-hex="' + activeHexFilter + '"]');
            if (target) target.classList.add('active');
          }
          renderCurrentMonth();
        });
      });
    }
    function updateFilterMeta(count) {
      const typeLabel = activeTypeFilter ? (TYPE_CHIPS.find(t => t[0] === activeTypeFilter) || ['', ''])[1] : '';
      if (hexFilterMetaText) {
        if (activeHexFilter !== null || activeDirFilter || activeTypeFilter) {
          const parts = [];
          if (activeHexFilter !== null) {
            parts.push('「' + (HEX_NAMES[activeHexFilter] || ('第' + activeHexFilter + '卦')) + '」');
          }
          if (activeDirFilter) parts.push('「' + activeDirFilter + '」');
          if (typeLabel) parts.push('「' + typeLabel + '」');
          hexFilterMetaText.textContent = '正 在 筛 选：' + parts.join(' + ') + ' ·  ' + count + ' 条';
        } else {
          hexFilterMetaText.textContent = '按 卦 象 / 方 向 / 占 法 筛 选';
        }
      }
      if (hexFilterClear) {
        hexFilterClear.style.display = (activeHexFilter !== null || activeDirFilter || activeTypeFilter) ? 'inline' : 'none';
      }
    }
    /* ===== 方向筛选 chips (当月出现过的方向动态生成) ===== */
    const dirFilterRow = document.getElementById('dirFilterRow');
    /* ===== 占法筛选 chips: 记录 type 缺省视为 iching (兼容旧数据) ===== */
    const typeFilterRow = document.getElementById('typeFilterRow');
    const TYPE_CHIPS = [['iching','易经','☰'], ['bazi','八字','命'], ['xlr','小六壬','壬'], ['meihua','梅花','梅']];
    function recType(h) { return h.type || 'iching'; }
    function renderTypeChips() {
      if (!typeFilterRow) return;
      typeFilterRow.innerHTML = '';
      TYPE_CHIPS.forEach(function (tc) {
        const v = tc[0];
        const chip = document.createElement('div');
        chip.className = 'hex-filter-chip' + (activeTypeFilter === v ? ' active' : '');
        chip.setAttribute('role', 'button');
        chip.setAttribute('aria-label', '筛选占法 ' + tc[1]);
        chip.innerHTML = '<span class="chip-glyph">' + tc[2] + '</span><span>' + tc[1] + '</span>';
        chip.addEventListener('click', () => {
          activeTypeFilter = (activeTypeFilter === v) ? '' : v;
          renderTypeChips();
          renderCurrentMonth();
        });
        typeFilterRow.appendChild(chip);
      });
    }
    renderTypeChips();
    function renderDirChips() {
      if (!dirFilterRow) return;
      const list = getHistory();
      const cur = String(currentYear) + '-' + String(currentMonth).padStart(2, '0');
      const dirs = [];
      list.forEach(h => {
        if (h.month === cur && h.direction && dirs.indexOf(h.direction) < 0) dirs.push(h.direction);
      });
      dirFilterRow.innerHTML = '';
      if (!dirs.length && !activeDirFilter) { dirFilterRow.style.display = 'none'; return; }
      dirFilterRow.style.display = '';
      const mk = function (label, value, count) {
        const chip = document.createElement('div');
        chip.className = 'hex-filter-chip' + (activeDirFilter === value ? ' active' : '');
        chip.dataset.dir = value;
        chip.setAttribute('role', 'button');
        chip.setAttribute('aria-label', '筛选方向 ' + label);
        chip.innerHTML = '<span class="chip-glyph">◈</span><span>' + label + '</span>' +
          (count != null ? '<span class="chip-count">' + count + '</span>' : '');
        chip.addEventListener('click', () => {
          activeDirFilter = (activeDirFilter === value && value !== '') ? '' : value;
          renderDirChips();
          renderCurrentMonth();
        });
        return chip;
      };
      dirFilterRow.appendChild(mk('全方向', ''));
      dirs.forEach(d => {
        dirFilterRow.appendChild(mk(d, d, list.filter(h => h.month === cur && h.direction === d).length));
      });
    }
    /* 07 屏跳转入口: 设置方向筛选并刷新 */
    window.YijingUI = window.YijingUI || {};
    window.YijingUI.filterByDirection = function (dir) {
      activeDirFilter = dir || '';
      renderDirChips();
      renderCurrentMonth();
    };
    if (hexFilterClear) {
      hexFilterClear.addEventListener('click', () => {
        activeHexFilter = null;
        activeDirFilter = '';
        activeTypeFilter = '';
        renderHexFilterChips();
        renderDirChips();
        renderTypeChips();
        renderCurrentMonth();
      });
    }

    let selectMode = false;
    let selectedSet = new Set();
    let longPressTimer = null;
    let longPressTriggered = false;
    const LONG_PRESS_MS = 480;
    renderHexFilterChips();
    renderDirChips();
    renderCurrentMonth();
    renderStats();

    function enterSelectMode(card) {
      selectMode = true;
      selectedSet.clear();
      const idx = parseInt(card.dataset.idx, 10);
      if (!isNaN(idx)) selectedSet.add(idx);
      today.classList.add('select-mode');
      week.classList.add('select-mode');
      today.querySelectorAll('.hist-card').forEach(c => c.classList.add('selectable'));
      week.querySelectorAll('.hist-card').forEach(c => c.classList.add('selectable'));
      if (!isNaN(idx)) {
        const realCard = document.querySelector('.hist-card[data-idx="' + idx + '"]');
        if (realCard) realCard.classList.add('selected');
      }
      renderSelectToolbar();
    }
    function exitSelectMode() {
      selectMode = false;
      selectedSet.clear();
      today.classList.remove('select-mode');
      week.classList.remove('select-mode');
      today.querySelectorAll('.hist-card').forEach(c => { c.classList.remove('selectable', 'selected'); });
      week.querySelectorAll('.hist-card').forEach(c => { c.classList.remove('selectable', 'selected'); });
      const tb = document.getElementById('selectToolbar');
      if (tb) tb.remove();
    }
    function renderSelectToolbar() {
      let tb = document.getElementById('selectToolbar');
      if (!tb) {
        tb = document.createElement('div');
        tb.id = 'selectToolbar';
        tb.className = 'select-toolbar';
        const phone = today.closest('.phone');
        if (phone) {
          const content = phone.querySelector('.content');
          if (content) content.insertBefore(tb, content.firstChild);
        }
      }
      tb.innerHTML =
        '<div class="count">已 选 ' + selectedSet.size + ' 条</div>' +
        '<div class="actions">' +
          '<div class="btn cancel">取 消</div>' +
          '<div class="btn delete' + (selectedSet.size === 0 ? ' disabled' : '') + '">删 除</div>' +
        '</div>';
      tb.querySelector('.btn.cancel').onclick = exitSelectMode;
      tb.querySelector('.btn.delete').onclick = function() {
        if (selectedSet.size === 0) return;
        const toDelete = [...selectedSet].sort((a, b) => b - a);
        if (typeof window.YijingHistory !== 'undefined') window.YijingHistory.removeMany(toDelete);
        exitSelectMode();
        if (typeof refreshRange === 'function') refreshRange(true);
        setNavState();
        renderHexFilterChips();
        renderCurrentMonth();
      };
    }
    /* 长按状态: 提升到模块作用域, document 级监听只挂一次,
       避免历史列表每次重渲染都向 document 累积新监听器 (内存泄漏) */
    let pressCard = null, pressX = 0, pressY = 0;
    function onDocMove(e) {
      if (!pressCard || !longPressTimer) return;
      const t = e.touches ? e.touches[0] : e;
      if (Math.abs(t.clientX - pressX) > 8 || Math.abs(t.clientY - pressY) > 8) {
        clearTimeout(longPressTimer);
        longPressTimer = null;
        pressCard.classList.remove('pressing');
        pressCard = null;
      }
    }
    function onDocUp() {
      if (!pressCard) return;
      clearTimeout(longPressTimer);
      longPressTimer = null;
      pressCard.classList.remove('pressing');
      pressCard = null;
    }
    function bindLongPress() {
      const cards = document.querySelectorAll('.hist-card[data-idx]');
      cards.forEach(card => {
        function onDown(e) {
          if (selectMode) return;
          longPressTriggered = false;
          clearTimeout(longPressTimer);
          const t = e.touches ? e.touches[0] : e;
          pressCard = card; pressX = t.clientX; pressY = t.clientY;
          card.classList.add('pressing');
          longPressTimer = setTimeout(() => {
            longPressTriggered = true;
            card.classList.remove('pressing');
            pressCard = null;
            enterSelectMode(card);
            if (navigator.vibrate) navigator.vibrate(20);
          }, LONG_PRESS_MS);
        }
        function onClick(e) {
          if (longPressTriggered) { e.preventDefault(); e.stopPropagation(); longPressTriggered = false; return; }
          if (selectMode) {
            e.stopPropagation();
            const idx = parseInt(card.dataset.idx, 10);
            if (selectedSet.has(idx)) {
              selectedSet.delete(idx);
              card.classList.remove('selected');
            } else {
              selectedSet.add(idx);
              card.classList.add('selected');
            }
            renderSelectToolbar();
            return;
          }
          /* 普通点击 → 八字记录回屏2重排 (含大运流年); 卦类记录打开 04 屏解析 */
          const idx = parseInt(card.dataset.idx, 10);
          const rec = getHistory()[idx];
          if (rec && rec.type === 'bazi' && rec.birthTs &&
              window.YijingUI && typeof window.YijingUI.recallBazi === 'function') {
            window.YijingUI.recallBazi(rec);
            return;
          }
          const no = parseInt(card.dataset.hex, 10);
          if (no && window.YijingUI && typeof window.YijingUI.openDetail === 'function') {
            window.YijingUI.openDetail(no);
            if (window.YijingUI.gotoScreen) window.YijingUI.gotoScreen(3);
          }
        }
        card.addEventListener('mousedown', onDown);
        card.addEventListener('touchstart', onDown, { passive: true });
        card.addEventListener('mouseup', onDocUp);
        card.addEventListener('mouseleave', onDocUp);
        card.addEventListener('touchend', onDocUp);
        card.addEventListener('click', onClick);
      });
    }
    document.addEventListener('mousemove', onDocMove);
    document.addEventListener('touchmove', onDocMove, { passive: true });

    window.YijingStates = {
      showEmpty: function() {
        today.innerHTML = '<div class="group-cap">今 日</div><div class="state-card state-empty"><div class="state-icon">⌛</div><div class="state-title">今 日 尚 未 起 卦</div><div class="state-desc">默念您所问之事，<br>点击底部「起卦」开始</div></div>';
        week.innerHTML  = '<div class="group-cap">本 周</div><div class="state-card state-empty"><div class="state-icon">☷</div><div class="state-title">本 月 尚 无 记 录</div><div class="state-desc">卦象可循，方寸不乱</div></div>';
      },
      showError: function() {
        today.innerHTML = '<div class="group-cap">今 日</div><div class="state-card state-error"><div class="state-icon">!</div><div class="state-title">记 录 加 载 失 败</div><div class="state-desc">请检查网络后下拉刷新</div><button class="state-retry">重 试</button></div>';
        week.innerHTML  = '<div class="group-cap">本 周</div><div class="state-card state-error"><div class="state-icon">!</div><div class="state-title">本 月 数 据 暂 不 可 用</div><div class="state-desc">服务暂不可用</div><button class="state-retry">重 试</button></div>';
        today.querySelector('.state-retry').onclick = window.YijingStates.showNormal;
        week.querySelector('.state-retry').onclick = window.YijingStates.showNormal;
      },
      showLoading: function() {
        const sk = '<div class="skeleton-block w-90"></div><div class="skeleton-block w-60"></div><div class="skeleton-block w-80"></div>';
        today.innerHTML = '<div class="group-cap">今 日</div><div class="state-card state-loading">' + sk + '</div>';
        week.innerHTML  = '<div class="group-cap">本 周</div><div class="state-card state-loading">' + sk + '</div>';
      },
      showNormal: function() {
        renderCurrentMonth();
      }
    };
    window.YijingUI = window.YijingUI || {};
    window.YijingUI.changeMonth = function(y, m) { currentYear = y; currentMonth = m; setNavState(); renderCurrentMonth(); };
    /* 起卦写入新记录后调用: 重算月份范围 → 跳到最新月 → 重绘筛选芯片与列表 */
    window.YijingUI.refreshHistory = function() {
      refreshRange(false);
      setNavState();
      renderHexFilterChips();
      renderCurrentMonth();
      renderStats();
      if (window.YijingUI.refreshRecent) window.YijingUI.refreshRecent();
      if (window.YijingUI.refreshMe) window.YijingUI.refreshMe();
    };
  })();

  /* ============ 04 屏六爻展开/折叠 (图标化按钮) ============ */
  (function bindYaoToggle() {
    const toggle = document.getElementById('yaoExpandToggle');
    if (!toggle) return;
    const list = toggle.parentElement;
    const collapsed = list ? list.querySelectorAll('.yao-row.collapsed') : [];
    if (collapsed.length === 0) {
      toggle.style.display = 'none';
      return;
    }
    let expanded = false;
    toggle.addEventListener('click', () => {
      expanded = !expanded;
      const rows = list.querySelectorAll('.yao-row');
      if (expanded) {
        rows.forEach(r => r.classList.remove('collapsed'));
        toggle.classList.add('collapsed-state');
        toggle.querySelector('.yao-toggle-text').textContent = '收 起 末 四 爻';
      } else {
        const firstTwo = list.querySelectorAll('.yao-row:not(.collapsed)');
        rows.forEach((r, i) => { if (i >= 2) r.classList.add('collapsed'); });
        toggle.classList.remove('collapsed-state');
        toggle.querySelector('.yao-toggle-text').textContent = '展 开 全 部 六 爻';
      }
    });
  })();


  /* ============ 02 屏起卦方式 → 推演 → 04 屏结果 → 06 屏历史 闭环 ============ */
  (function bindDivinationFlow() {
    const list = document.getElementById('method-list');
    if (!list) return;

    const METHOD_NAME = { numeric: '数字起卦', yarrow: '蓍草演卦', coin: '铜钱起卦' };

    function getOverlay() {
      let ov = document.getElementById('skeletonOverlay');
      if (!ov) {
        ov = document.createElement('div');
        ov.className = 'skeleton-overlay';
        ov.id = 'skeletonOverlay';
        ov.innerHTML =
          '<div class="skeleton-card">' +
            '<div class="skeleton-icon">卦</div>' +
            '<div class="skeleton-text">易道 推演中</div>' +
            '<div class="skeleton-sub">从天地人三才之间，解读您的疑问</div>' +
            '<div class="skeleton-progress"><div class="skeleton-bar"></div></div>' +
          '</div>';
        document.body.appendChild(ov);
      }
      return ov;
    }
    function showLoading(text, sub) {
      const ov = getOverlay();
      const t = ov.querySelector('.skeleton-text'), s = ov.querySelector('.skeleton-sub');
      if (t && text) t.textContent = text;
      if (s && sub) s.textContent = sub;
      ov.classList.remove('hidden');
    }
    function hideLoading() {
      const ov = document.getElementById('skeletonOverlay');
      if (ov) ov.classList.add('hidden');
    }
    /* 02 屏问题卡内的 toast */
    function qToast(msg) {
      const t = document.getElementById('qToast');
      if (!t) return;
      t.innerHTML = '<span class="ic">✎</span><span>' + escapeHtml(msg) + '</span>';
      t.classList.add('show');
      clearTimeout(qToast._t);
      qToast._t = setTimeout(() => t.classList.remove('show'), 2400);
    }
    function currentDirection() {
      const active = document.querySelector('#tag-row .tag.active');
      return active ? active.textContent.replace(/\s/g, '') : '';
    }

    /* ===== 铜钱抛掷仪式: 六轮三枚, 呈现引擎真实掷出的正反面 ===== */
    const CoinToss = (function () {
      const YAO_CN = ['初', '二', '三', '四', '五', '上'];
      let ov = null, timers = [], doneFn = null, playing = false;

      function clearTimers() { timers.forEach(clearTimeout); timers = []; }

      function build() {
        const el = document.createElement('div');
        el.className = 'coin-overlay';
        el.setAttribute('role', 'dialog');
        el.setAttribute('aria-label', '铜钱起卦');
        el.innerHTML =
          '<div class="coin-round" aria-live="polite"></div>' +
          '<div class="coin-tray">' +
            '<div class="coin"><div class="coin-inner"><div class="cface cb"></div><div class="cface cz">易</div></div></div>' +
            '<div class="coin"><div class="coin-inner"><div class="cface cb"></div><div class="cface cz">易</div></div></div>' +
            '<div class="coin"><div class="coin-inner"><div class="cface cb"></div><div class="cface cz">易</div></div></div>' +
          '</div>' +
          '<div class="coin-lines"></div>' +
          '<div class="coin-skip">轻触任意处跳过</div>';
        return el;
      }

      function escEnd(e) { if (e.key === 'Escape') end(); }

      function end() {
        if (!playing) return;
        playing = false;
        clearTimers();
        document.removeEventListener('keydown', escEnd);
        if (ov) {
          ov.removeEventListener('click', end);
          ov.classList.remove('show');
          const o = ov; ov = null;
          setTimeout(function () { o.remove(); }, 320);
        }
        const cb = doneFn; doneFn = null;
        if (cb) cb();
      }

      /** 播放抛掷动画; 返回 true 表示已接管流程, false 表示调用方需自行回退 */
      function play(res, cb) {
        try {
          if (playing) return false;
          playing = true; doneFn = cb;
          ov = build();
          document.body.appendChild(ov);
          requestAnimationFrame(function () { ov.classList.add('show'); });
          ov.addEventListener('click', end);
          document.addEventListener('keydown', escEnd);

          const ROUND = 920, SETTLE = 640;
          const coins = ov.querySelectorAll('.coin');
          const inners = ov.querySelectorAll('.coin-inner');
          const roundEl = ov.querySelector('.coin-round');
          const linesEl = ov.querySelector('.coin-lines');

          res.tosses.forEach(function (faces, i) {
            timers.push(setTimeout(function () {
              const isMoving = res.moving.indexOf(i) >= 0;
              const line = res.lines[i];
              const quality = line === 'yang' ? (isMoving ? '老阳' : '少阳') : (isMoving ? '老阴' : '少阴');
              roundEl.innerHTML = '第<b>' + YAO_CN[i] + '爻</b> · ' + quality;
              /* 三枚铜钱: 先复位再抛出, 落定角度由真实正反面决定 (背=方孔面) */
              inners.forEach(function (c, k) {
                c.style.transition = 'none';
                c.style.transform = 'rotateY(0deg)';
                void c.offsetWidth;
                c.style.transition = '';
                c.style.transform = 'rotateY(' + (1440 + (faces[k] ? 0 : 180)) + 'deg)';
              });
              coins.forEach(function (c) {
                c.classList.remove('coin-drop');
                void c.offsetWidth;
                c.classList.add('coin-drop');
              });
              /* 落定后成爻 */
              timers.push(setTimeout(function () {
                const y = document.createElement('div');
                y.className = 'coin-yao ' + line + (isMoving ? ' moving' : '');
                y.innerHTML = line === 'yin' ? '<div class="seg"></div><div class="seg"></div>' : '<div class="seg"></div>';
                linesEl.appendChild(y);
              }, SETTLE));
            }, i * ROUND));
          });

          timers.push(setTimeout(function () {
            roundEl.innerHTML = '六 爻 已 成';
          }, res.tosses.length * ROUND));
          timers.push(setTimeout(end, res.tosses.length * ROUND + 950));
          return true;
        } catch (e) {
          playing = false;
          if (ov) { ov.remove(); ov = null; }
          clearTimers();
          return false;
        }
      }

      return { play: play, isPlaying: function () { return playing; } };
    })();

    function run(methodId) {
      if (typeof YijingEngine === 'undefined') { qToast('起卦引擎未就绪'); return; }
      const q = (window.YijingUI && window.YijingUI.getQuestion) ? window.YijingUI.getQuestion() : '';
      if (!q || q.length < 4) {
        qToast('请先写下您所问之事（至少 4 字）');
        const input = document.getElementById('qInput');
        if (input) { input.click(); input.focus && input.focus(); }
        return;
      }
      const label = METHOD_NAME[methodId] || '起卦';

      let res;
      try { res = YijingEngine.cast(methodId, q); }
      catch (e) { qToast('起卦失败，请重试'); return; }

      function finish() {
        const ben = YijingEngine.hexByLines(res.lines);
        const tf = YijingEngine.transform(ben.no, res.moving);

        const summary =
          '得「' + ben.name + '卦」，上' + tf.upperClassic + '下' + tf.lowerClassic + '，' + (res.moving.length
            ? '动爻在' + tf.yaoChanges.map(c => c.from).join('、') + '，变卦为「' + tf.changed.name + '卦」。'
            : '六爻皆静，以本卦断之。') +
          '体卦' + tf.ti.name + '（' + tf.ti.wuxing + '），用卦' + tf.yong.name + '（' + tf.yong.wuxing + '），' +
          tf.relation + '，' + tf.verdict + '：' + tf.verdictText + ' ' + (ben.intro || '');

        /* 1) 05 屏变卦推演同步 */
        if (window.YijingUI && window.YijingUI.setTransform) {
          window.YijingUI.setTransform(ben.no, res.moving);
        }
        /* 2) 写入历史 → 06 屏刷新 */
        YijingHistory.add(buildHistoryRecord(ben, res, q, currentDirection(), label));
        if (window.YijingUI && window.YijingUI.refreshHistory) window.YijingUI.refreshHistory();
        /* 3) 04 屏渲染结果 */
        if (window.YijingUI && window.YijingUI.openDetail) {
          window.YijingUI.openDetail(ben.no, {
            question: q, moving: res.moving, method: label, summary: summary
          });
        }
        qToast('已成卦：' + ben.name + '卦' + (res.moving.length ? ' → ' + tf.changed.name + '卦' : ''));
      }

      /* 铜钱起卦: 抛掷仪式动效呈现真实六掷; reduced-motion 或动画启动失败时回退骨架屏 */
      const reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
      if (methodId === 'coin' && res && res.tosses && !reduce) {
        if (CoinToss.play(res, finish)) return;
        /* play 被拒: 上一场仪式仍在进行 → 提示稍候, 不落入骨架屏路径覆盖动画 */
        if (CoinToss.isPlaying()) { qToast('铜钱仪式进行中，请稍候'); return; }
        /* 其余失败 (动画初始化异常) → 回退骨架屏 */
      }

      showLoading('易道 推演中', label + ' · ' + (q.length > 16 ? q.slice(0, 16) + '…' : q));
      setTimeout(finish, 1600);
    }

    list.addEventListener('click', function (e) {
      const card = e.target.closest('.method-card');
      if (!card || !card.dataset.method) return;
      card.classList.add('pressing');
      setTimeout(() => card.classList.remove('pressing'), 260);
      run(card.dataset.method);
    });

    /* 01 屏快捷入口: 手动起卦 / 随机起卦 */
    document.querySelectorAll('.quick-item').forEach(function (item) {
      item.style.cursor = 'pointer';
      item.addEventListener('click', function () {
        const n = (item.querySelector('.quick-name') || {}).textContent || '';
        if (n.indexOf('随机') >= 0) {
          run('coin');
        } else if (n.indexOf('历史') >= 0) {
          /* 历史记录: 跳到 06 屏 */
          if (window.YijingUI && window.YijingUI.gotoScreen) window.YijingUI.gotoScreen(5);
        } else {
          /* 手动起卦: 跳到 02 屏并聚焦输入框 */
          const p2 = document.getElementById('phoneDivination');
          if (p2 && p2.scrollIntoView) p2.scrollIntoView({ behavior: 'smooth', block: 'center' });
          setTimeout(function () {
            const input = document.getElementById('qInput');
            if (input) input.click();
          }, 420);
        }
      });
    });

    window.YijingUI = window.YijingUI || {};
    window.YijingUI.castHex = run;
  })();

  /* ============ 更多占法: 八字 / 小六壬 / 梅花易数 (屏2) ============ */
  (function bindMoreDivination() {
    const D = window.YijingDivination;
    const baziCard = document.getElementById('div-bazi');
    const xlrCard = document.getElementById('div-xlr');
    const meihuaCard = document.getElementById('div-meihua');
    if (!D || !baziCard || !xlrCard || !meihuaCard) return;
    const baziForm = document.getElementById('baziForm');
    const meihuaForm = document.getElementById('meihuaForm');
    const meihuaNumRow = document.getElementById('meihuaNumRow');
    const result = document.getElementById('divResult');
    const ZHI_NAMES = ['子','丑','寅','卯','辰','巳','午','未','申','酉','戌','亥'];

    /* iter25: 更多占法子页切换 — 屏2 默认只显示起卦方式 + 入口卡 */
    const moreEntry = document.getElementById('moreDivEntry');
    const moreList = document.getElementById('more-div-list');
    const moreBack = document.getElementById('moreDivBack');
    const methodList = document.getElementById('method-list');
    function enterMorePage() {
      if (!moreList || !methodList) return;
      methodList.hidden = true;
      if (moreEntry) moreEntry.hidden = true;
      moreList.hidden = false;
      const content = document.querySelector('#phoneDivination .content');
      if (content) content.scrollTop = 0;
      if (moreBack) moreBack.focus({ preventScroll: true });
    }
    function exitMorePage() {
      if (!moreList || !methodList) return;
      moreList.hidden = true;
      if (moreEntry) moreEntry.hidden = false;
      methodList.hidden = false;
      hideAll();
      result.hidden = true;
      const content = document.querySelector('#phoneDivination .content');
      if (content) content.scrollTop = 0;
    }
    function bindActivate(el, fn) {
      if (!el) return;
      el.addEventListener('click', fn);
      el.addEventListener('keydown', e => {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); fn(); }
      });
    }
    bindActivate(moreEntry, enterMorePage);
    bindActivate(moreBack, exitMorePage);
    window.YijingUI = window.YijingUI || {};
    window.YijingUI.enterMorePage = enterMorePage;
    window.YijingUI.exitMorePage = exitMorePage;

    function toast(msg) {
      const t = document.getElementById('qToast');
      if (!t) return;
      t.innerHTML = '<span class="ic">✎</span><span>' + escapeHtml(msg) + '</span>';
      t.classList.add('show');
      clearTimeout(toast._t);
      toast._t = setTimeout(() => t.classList.remove('show'), 2400);
    }
    function showOnly(el) {
      baziForm.hidden = el !== baziForm;
      meihuaForm.hidden = el !== meihuaForm;
      if (el) el.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
    }
    function hideAll() {
      baziForm.hidden = true;
      meihuaForm.hidden = true;
    }
    function currentQuestion() {
      if (window.YijingUI && window.YijingUI.getQuestion) {
        const q = window.YijingUI.getQuestion();
        if (q && q.length >= 4) return q;
      }
      return '';
    }
    /* 统一入历史: type 区分占法, 旧记录无 type 视为 iching */
    function addHistory(rec) {
      if (typeof YijingHistory === 'undefined' || !YijingHistory.add) return;
      YijingHistory.add(rec);
      if (window.YijingUI && window.YijingUI.refreshHistory) window.YijingUI.refreshHistory();
    }
    const DIV_TAG = { bazi: ['八字','gold'], xlr: ['六壬','pine'], meihua: ['梅花','cinnabar'] };
    function historyBase(type, methodName, question) {
      const now = new Date();
      const tag = DIV_TAG[type] || ['', 'gold'];
      return {
        type: type,
        direction: tag[0], directionColor: tag[1],
        date: '今日 ' + String(now.getHours()).padStart(2, '0') + ':' + String(now.getMinutes()).padStart(2, '0'),
        ts: now.getTime(),
        month: now.getFullYear() + '-' + String(now.getMonth() + 1).padStart(2, '0'),
        day: now.getDate(),
        question: question ? '问：' + question : '问：心中所念之事',
        method: methodName
      };
    }

    /* ---- 八字 ---- */
    const hourSel = document.getElementById('baziHour');
    if (hourSel && !hourSel.options.length) {
      for (let h = 0; h < 24; h++) {
        const idx = Math.floor(((h + 1) % 24) / 2);
        const label = ZHI_NAMES[idx] + '时 ' + String(h).padStart(2, '0') + ':00-' + String((h + 1) % 24).padStart(2, '0') + ':00';
        hourSel.add(new Option(label, h));
      }
      hourSel.selectedIndex = 12;
    }
    /* 性别分段控件 */
    const genderGroup = document.getElementById('baziGender');
    const hourUnknownBox = document.getElementById('baziHourUnknown');
    let baziGender = 'male';
    if (genderGroup) {
      genderGroup.querySelectorAll('.g-btn').forEach(btn => {
        btn.addEventListener('click', () => {
          baziGender = btn.dataset.g;
          genderGroup.querySelectorAll('.g-btn').forEach(b2 => {
            const on = b2 === btn;
            b2.classList.toggle('active', on);
            b2.setAttribute('aria-pressed', on ? 'true' : 'false');
          });
        });
      });
    }
    /* 大运流年渲染: 起运行 + 8 步时间轴 + 可展开流年表 */
    function renderDaYun(dy) {
      if (!dy || !dy.qiYun || !dy.steps.length) return '';
      const qy = dy.qiYun;
      const dirLabel = dy.forward ? '顺行' : '逆行';
      const edgeNote = qy.nearEdge ? '<span class="dy-edge">临界节气，起运岁数或有微差</span>' : '';
      const startYear = new Date(qy.startTs).getFullYear();
      let stepsHtml = '', panelsHtml = '';
      const curIdx = Math.max(dy.steps.findIndex(s => s.current), 0);
      dy.steps.forEach((s, i) => {
        stepsHtml +=
          '<div class="dy-step' + (s.current ? ' current' : '') + (s.past ? ' past' : '') +
            '" data-step="' + i + '" role="button" tabindex="0" aria-expanded="' + (i === curIdx) + '"' +
            ' aria-label="' + s.gz + '大运' + s.startYear + '至' + s.endYear + '年，' + s.ganGod + '">' +
            '<div class="gz">' + s.gz + '</div>' +
            '<div class="god">' + s.ganGod + '</div>' +
            '<div class="yrs">' + s.startYear + '-' + s.endYear + '</div>' +
          '</div>';
        const rows = s.liuNian.map(ln => {
          const chips = ln.events.map(e =>
            '<span class="ln-chip ' + e.type + '">' +
              (e.type === 'chong' ? '冲' : e.type === 'he' ? '合' : '刑') + ' ' +
              (e.palace === -1 ? '大运' : D.DaYun.PALACE[e.palace]) +
            '</span>').join('');
          return '<div class="ln-row' + (ln.current ? ' current' : '') + '">' +
            '<div class="yr"><b>' + ln.year + '</b><span>' + ln.gz + '</span>' + (ln.current ? '<i class="now">今岁</i>' : '') + '</div>' +
            '<div class="body">' +
              '<div class="ln-top"><span class="god">' + ln.god + '</span>' + chips + '</div>' +
              '<div class="ln-text">' + escapeHtml(ln.text) + '</div>' +
            '</div>' +
          '</div>';
        }).join('');
        panelsHtml +=
          '<div class="dy-liunian" data-step="' + i + '"' + (i === curIdx ? '' : ' hidden') + '>' +
            '<div class="ln-head">' + s.gz + '大运 · ' + s.startYear + '-' + s.endYear + ' 流年</div>' +
            (rows || '<div class="ln-empty">该步流年超出节气表范围</div>') +
          '</div>';
      });
      return '' +
        '<div class="section-cap" style="font-size:12px;">大 运 排 布</div>' +
        '<div class="dy-meta-line"><span class="dir">' + dirLabel + '</span>' +
          '<span>' + qy.years + '岁' + (qy.months ? qy.months + '个月' : '') + '起运 · 至' + qy.termName + ' · 起于' + startYear + '年</span>' + edgeNote + '</div>' +
        '<div class="dy-timeline" role="tablist">' + stepsHtml + '</div>' +
        panelsHtml;
    }
    function bindDaYun() {
      const steps = result.querySelectorAll('.dy-step');
      const panels = result.querySelectorAll('.dy-liunian');
      steps.forEach(step => {
        const toggle = () => {
          const i = step.dataset.step;
          panels.forEach(p2 => { p2.hidden = p2.dataset.step !== i; });
          steps.forEach(s2 => s2.setAttribute('aria-expanded', s2.dataset.step === i ? 'true' : 'false'));
          const target = result.querySelector('.dy-liunian[data-step="' + i + '"]');
          if (target) target.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
        };
        step.addEventListener('click', toggle);
        step.addEventListener('keydown', e => {
          if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); toggle(); }
        });
      });
    }
    function runBazi(recallRec) {
      /* 历史回看传入记录对象 (含 birthTs); 按钮点击传入 Event 需忽略 */
      const rec = (recallRec && typeof recallRec === 'object' && typeof recallRec.birthTs === 'number') ? recallRec : null;
      let y, m, d, h, gender, hourUnknown;
      if (rec) {
        /* 历史回看: 用存的出生数据重排, 不再入历史 */
        const bd = new Date(rec.birthTs);
        y = bd.getFullYear(); m = bd.getMonth() + 1; d = bd.getDate(); h = bd.getHours();
        gender = rec.gender || 'male';
        hourUnknown = !!rec.hourUnknown;
        document.getElementById('baziYear').value = y;
        document.getElementById('baziMonth').value = m;
        document.getElementById('baziDay').value = d;
        hourSel.value = String(h);
        if (hourUnknownBox) hourUnknownBox.checked = hourUnknown;
        if (genderGroup) genderGroup.querySelector('.g-btn[data-g="' + gender + '"]').click();
      } else {
        y = parseInt(document.getElementById('baziYear').value, 10);
        m = parseInt(document.getElementById('baziMonth').value, 10);
        d = parseInt(document.getElementById('baziDay').value, 10);
        h = parseInt(hourSel.value, 10);
        gender = baziGender;
        hourUnknown = !!(hourUnknownBox && hourUnknownBox.checked);
      }
      if (!(y >= 1901 && y <= 2100) || !(m >= 1 && m <= 12) || !(d >= 1 && d <= 31) || !(h >= 0 && h <= 23)) {
        toast('请完整填写出生年月日时'); return;
      }
      const birth = new Date(y, m - 1, d, h, 0);
      const dy = D.DaYun.analyze(birth, gender, { hourUnknown: hourUnknown });
      const r = dy ? dy.bazi : D.BaZi.compute(birth);
      if (!r) { toast('排盘失败，请检查日期'); return; }
      const wxMax = Math.max.apply(null, Object.values(r.wuxing)) || 1;
      const pillarsHtml = r.pillars.map(p =>
        '<div class="bazi-pillar' + (hourUnknown && p.pos === '时' ? ' approx' : '') + '">' +
          '<div class="pos">' + p.pos + '柱' + (hourUnknown && p.pos === '时' ? '<i>近似</i>' : '') + '</div>' +
          '<div class="gz">' + p.gan + p.zhi + '</div>' +
          '<div class="god">' + p.ganGod + '</div>' +
        '</div>').join('');
      const wxHtml = Object.keys(r.wuxing).map(el => {
        const n = r.wuxing[el];
        return '<div class="wx-bar"><span class="el">' + el + '</span>' +
          '<div class="track"><div class="fill" style="width:' + Math.round(n / wxMax * 100) + '%"></div></div>' +
          '<span class="num">' + n + '</span></div>';
      }).join('');
      /* 藏干十神 (日支为主) */
      const dayHidden = r.pillars[2].hidden.map(hh =>
        '<span class="hidden-god">' + hh.gan + ' · ' + hh.god + '</span>').join('');
      const lunar = r.lunar;
      const verdict = '此造' + (gender === 'female' ? '坤造' : '乾造') + '，日主<b>' + r.dayGan + '</b>（' + r.dayElement + '），生于' +
        (lunar ? lunar.yearGanZhi + '年' + lunar.monthLabel + lunar.day + '日' : '') + ' ' + r.shichen + (hourUnknown ? '（近似）' : '') + '。' +
        '五行之中<b>' + (function () { let mk = '', mv = -1; Object.keys(r.wuxing).forEach(k => { if (r.wuxing[k] > mv) { mv = r.wuxing[k]; mk = k; } }); return mk; })() + '</b>最旺，' +
        '日主<b>' + r.strength + '</b>。' +
        '日支藏干' + dayHidden + '，与日主亲疏之象已列于上，可参详格局配置。';
      result.innerHTML =
        '<div class="div-head"><div class="div-title">八字排盘</div>' +
          '<div class="div-sub">' + escapeHtml((lunar ? lunar.yearGanZhi + '年 ' : '') + y + '年' + m + '月' + d + '日 ' + r.shichen + (hourUnknown ? ' · 时辰未知' : '')) + '</div></div>' +
        '<div class="bazi-pillars">' + pillarsHtml + '</div>' +
        '<div class="section-cap" style="font-size:12px;">五 行 分 布</div>' +
        '<div class="wx-bars">' + wxHtml + '</div>' +
        '<div class="div-verdict">' + verdict + '</div>' +
        renderDaYun(dy);
      result.hidden = false;
      hideAll();
      bindDaYun();
      result.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
      if (rec) return; /* 回看不再入历史 */
      addHistory(Object.assign(historyBase('bazi', '八字解析', currentQuestion()), {
        name: r.pillars[0].gan + r.pillars[0].zhi + '年 · ' + r.dayGan + r.dayElement + '命',
        hexNo: null, lines: null, moving: [],
        birthTs: birth.getTime(), gender: gender, hourUnknown: hourUnknown,
        baziSummary: r.pillars.map(p => p.gz).join(' ')
      }));
    }

    /* ---- 小六壬 ---- */
    function runXlr() {
      const r = D.XiaoLiuRen.divine(new Date());
      if (!r) { toast('起课失败'); return; }
      const palacesHtml = D.XiaoLiuRen.PALACES.map((p, i) =>
        '<div class="xlr-palace' + (i === r.hourPalaceIdx ? ' hit' : '') + '">' +
          '<div class="nm">' + p.name + '</div>' +
          '<div class="lk ' + (p.luck === '吉' ? 'ji' : 'xiong') + '">' + p.luck + '</div>' +
        '</div>').join('');
      const q = currentQuestion();
      result.innerHTML =
        '<div class="div-head"><div class="div-title">小六壬</div>' +
          '<div class="div-sub">' + escapeHtml(r.summary) + '</div></div>' +
        '<div class="xlr-path">月落<b>' + r.monthPalace.name + '</b> → 日落<b>' + r.dayPalace.name + '</b> → 时落<b>' + r.hourPalace.name + '</b></div>' +
        '<div class="xlr-palaces">' + palacesHtml + '</div>' +
        '<div class="xlr-text">「' + r.hourPalace.text + '」</div>' +
        '<div class="div-verdict">落宫<b>' + r.hourPalace.name + '</b>，' + (r.hourPalace.luck === '吉'
          ? '主吉。宜' + r.hourPalace.dir + '方行事，所谋有信。'
          : '主凶。慎口舌是非，所谋宜缓，静待时机。') + (q ? '所问：' + escapeHtml(q.slice(0, 20)) : '') + '</div>';
      result.hidden = false;
      hideAll();
      result.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
      addHistory(Object.assign(historyBase('xlr', '小六壬', q), {
        name: '小六壬 · ' + r.hourPalace.name,
        hexNo: null, lines: null, moving: [],
        xlrPalace: r.hourPalace.name, xlrLuck: r.hourPalace.luck
      }));
    }

    /* ---- 梅花易数 ---- */
    let mhMode = 'time';
    meihuaForm.querySelectorAll('.meihua-tab').forEach(tab => {
      tab.addEventListener('click', () => {
        mhMode = tab.dataset.m;
        meihuaForm.querySelectorAll('.meihua-tab').forEach(t2 => {
          const on = t2 === tab;
          t2.classList.toggle('active', on);
          t2.setAttribute('aria-selected', on ? 'true' : 'false');
        });
        meihuaNumRow.hidden = mhMode !== 'num';
      });
    });
    function runMeihua() {
      let r = null;
      if (mhMode === 'time') r = D.MeiHua.byTime(new Date());
      else if (mhMode === 'dice') r = D.MeiHua.byDice();
      else {
        const a = parseInt(document.getElementById('meihuaA').value, 10);
        const b = parseInt(document.getElementById('meihuaB').value, 10);
        if (!(a >= 1 && b >= 1)) { toast('请输入两个正整数'); return; }
        r = D.MeiHua.byNumbers(a, b);
      }
      if (!r) { toast('起卦失败'); return; }
      const tf = r.transform;
      const body = tf
        ? '本卦<b>' + tf.ben.name + '</b>，上' + r.upper + '下' + r.lower + '，动爻在<b>第' + (r.movingIdx + 1) + '爻</b>。' +
          '体卦<b>' + tf.ti.name + '</b>（' + tf.ti.wuxing + '），用卦<b>' + tf.yong.name + '</b>（' + tf.yong.wuxing + '），' +
          tf.relation + '，' + tf.verdict + '：' + tf.verdictText
        : '上卦' + r.upper + '下卦' + r.lower + '，动爻第' + (r.movingIdx + 1) + '爻。';
      const q = currentQuestion();
      result.innerHTML =
        '<div class="div-head"><div class="div-title">梅花易数</div>' +
          '<div class="div-sub">' + escapeHtml(r.method + ' · ' + r.source) + '</div></div>' +
        '<div class="mh-trigrams">' +
          '<div class="mh-tri"><div class="nm">' + r.upper + '</div><div class="num">上卦 · ' + r.upperNum + '</div></div>' +
          '<div class="mh-mid">☰<br>之</div>' +
          '<div class="mh-tri"><div class="nm">' + r.lower + '</div><div class="num">下卦 · ' + r.lowerNum + '</div></div>' +
        '</div>' +
        '<div class="mh-body">' + body + (tf && tf.changed ? '<br>变卦为<b>' + tf.changed.name + '</b>卦。' : '') + '</div>';
      result.hidden = false;
      result.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
      if (mhMode !== 'num') hideAll();
      addHistory(Object.assign(historyBase('meihua', '梅花易数·' + r.method, q), {
        name: '梅花 · ' + (tf ? tf.ben.name + '之' + tf.changed.name : r.upper + r.lower),
        hexNo: r.hexNo, lines: r.lines, moving: [r.movingIdx]
      }));
    }

    /* ---- 接线 ---- */
    bindActivate(baziCard, () => { showOnly(baziForm); result.hidden = true; });
    bindActivate(xlrCard, () => { hideAll(); runXlr(); });
    bindActivate(meihuaCard, () => { showOnly(meihuaForm); result.hidden = true; });
    bindActivate(document.getElementById('baziGo'), runBazi);
    bindActivate(document.getElementById('baziCancel'), () => { baziForm.hidden = true; });
    bindActivate(document.getElementById('meihuaGo'), runMeihua);
    bindActivate(document.getElementById('meihuaCancel'), () => { meihuaForm.hidden = true; });
    window.YijingUI.runXlr = runXlr;
    window.YijingUI.runMeihuaDice = function () { mhMode = 'dice'; runMeihua(); };
    /* 八字历史回看: 回屏2 重排完整排盘 (含大运流年), 不再入历史 */
    window.YijingUI.recallBazi = function (rec) {
      if (!rec || !rec.birthTs) return false;
      if (window.YijingUI.gotoScreen) window.YijingUI.gotoScreen(2);
      enterMorePage(); /* iter25: 回看先进更多占法子页 */
      showOnly(baziForm);
      setTimeout(function () { runBazi(rec); }, 60);
      return true;
    };
  })();

  /* ============ 02 屏输入框 (光标 + 字数 + 回车提交) ============ */
  (function bindQInput() {
    const input = document.getElementById('qInput');
    const placeholder = document.getElementById('qPlaceholder');
    const text = document.getElementById('qText');
    const count = document.getElementById('qCount');
    const toast = document.getElementById('qToast');
    if (!input) return;
    const MAX = 50;
    let value = '';
    let autoTimer = null;
    let toastTimer = null;
    function update() {
      const len = value.length;
      text.textContent = value;
      if (len === 0) input.classList.add('empty');
      else input.classList.remove('empty');
      count.querySelector('.current').textContent = len;
      if (len >= MAX) input.classList.add('warn');
      else input.classList.remove('warn');
    }
    function fakePrint(chars, delay, onDone) {
      let i = 0;
      if (autoTimer) clearInterval(autoTimer);
      autoTimer = setInterval(() => {
        if (i >= chars.length) { clearInterval(autoTimer); if (onDone) onDone(); return; }
        if (value.length < MAX) value += chars[i];
        i++;
        update();
      }, delay);
    }
    function showToast(msg, icon) {
      if (!toast) return;
      /* 用户输入会拼入回显 (如「已收：…」), 必须转义防 XSS */
      toast.innerHTML = '<span class="ic">' + escapeHtml(icon || '✓') + '</span><span>' + escapeHtml(msg) + '</span>';
      toast.classList.add('show');
      clearTimeout(toastTimer);
      toastTimer = setTimeout(() => toast.classList.remove('show'), 2200);
    }
    function submit() {
      const trimmed = value.trim();
      if (trimmed.length === 0) {
        showToast('请先写点什么……', '✎');
        return false;
      }
      if (trimmed.length < 4) {
        showToast('问题太短，至少 4 个字', '!');
        return false;
      }
      showToast('已收：「' + trimmed.substring(0, 18) + (trimmed.length > 18 ? '…' : '') + '」', '✓');
      try { sessionStorage.setItem('yijing.qInput.lastValue', trimmed); } catch (e) {}
      if (window.YijingUI && typeof window.YijingUI.onQuestionSubmit === 'function') {
        window.YijingUI.onQuestionSubmit(trimmed);
      }
      setTimeout(() => { value = ''; update(); }, 1500);
      return true;
    }
    input.addEventListener('click', () => {
      if (value === '') {
        fakePrint('我近期的事业运筹方向是……', 110);
      }
    });
    placeholder.addEventListener('click', () => input.click());
    input.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && !e.shiftKey && !e.isComposing) {
        e.preventDefault();
        if (autoTimer) { clearInterval(autoTimer); autoTimer = null; }
        submit();
      } else if (e.key === 'Backspace' && autoTimer) {
        clearInterval(autoTimer); autoTimer = null;
      }
    });
    update();
    setTimeout(() => {
      if (value === '') input.click();
    }, 2400);
    window.YijingUI = window.YijingUI || {};
    window.YijingUI.submitQuestion = submit;
    window.YijingUI.getQuestion = function() {
      return value.trim() || (function() { try { return sessionStorage.getItem('yijing.qInput.lastValue') || ''; } catch (e) { return ''; } })();
    };
    window.YijingUI.setQuestion = function(v) { value = String(v || '').slice(0, MAX); update(); };
  })();

  /* ============ 04 屏 Tab 切换 (记忆 + 键盘 + 滑动) ============ */
