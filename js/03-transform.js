/* ============================================================
 * yijing-app · js/03-transform.js (iter29 模块化拆分)
 * 原 index.html 内联 script 按架构层切分 (保持 IIFE 顺序不变)
 * 依赖: data.js / terms.js / divination.js 先加载
 * ============================================================ */

  (function bindTransformSlider() {
    const card = document.getElementById('transformCard');
    const slider = document.getElementById('transformSlider');
    const dots = document.getElementById('transformDots');
    if (!card || !slider || !dots) return;
    const VIEWS = slider.querySelectorAll('.view');
    const dotEls = dots.querySelectorAll('.dot');
    let currentIdx = 0;
    const total = VIEWS.length;
    let isDragging = false;
    let startX = 0;
    let dragDelta = 0;
    let startTime = 0;

    function goTo(idx, animate) {
      if (idx < 0) idx = 0;
      if (idx >= total) idx = total - 1;
      currentIdx = idx;
      if (animate !== false) {
        slider.style.transition = 'transform 0.5s cubic-bezier(0.16, 1, 0.3, 1)';
      } else {
        slider.style.transition = 'none';
      }
      /* iter26: slider 宽 300% / view 各 33.333%, 切换 = -33.333% per view (而非 -100%) */
      slider.style.transform = 'translateX(calc(' + (-idx * 100) + '% / 3))';
      dotEls.forEach((d, i) => d.classList.toggle('active', i === idx));
    }

    function getEventX(e) {
      if (e.touches && e.touches.length) return e.touches[0].clientX;
      return e.clientX;
    }

    function onStart(e) {
      if (e.target.closest('.line')) return;
      isDragging = true;
      startX = getEventX(e);
      dragDelta = 0;
      startTime = Date.now();
      card.classList.add('dragging');
      slider.style.transition = 'none';
    }
    function onMove(e) {
      if (!isDragging) return;
      const x = getEventX(e);
      dragDelta = x - startX;
      const w = card.offsetWidth;
      /* iter26: 配合 33.333% per view, basePct 也需除 3 */
      const basePct = (-currentIdx * 100 / 3);
      const dragPct = (dragDelta / w) * 100 / 3;
      slider.style.transform = 'translateX(calc(' + basePct + '% + ' + dragPct + '%))';
    }
    function onEnd(e) {
      if (!isDragging) return;
      isDragging = false;
      card.classList.remove('dragging');
      const w = card.offsetWidth;
      const dist = dragDelta;
      const elapsed = Date.now() - startTime;
      const velocity = Math.abs(dist) / elapsed;
      const threshold = w * 0.2;
      let next = currentIdx;
      if (dist > threshold || (dist > 30 && velocity > 0.3)) {
        next = currentIdx - 1;
      } else if (dist < -threshold || (dist < -30 && velocity > 0.3)) {
        next = currentIdx + 1;
      }
      next = Math.max(0, Math.min(total - 1, next));
      goTo(next, true);
    }

    card.addEventListener('mousedown', onStart);
    document.addEventListener('mousemove', onMove);
    document.addEventListener('mouseup', onEnd);
    card.addEventListener('touchstart', onStart, { passive: true });
    card.addEventListener('touchmove', onMove, { passive: true });
    card.addEventListener('touchend', onEnd);
    card.addEventListener('mouseleave', () => { if (isDragging) onEnd({}); });

    dotEls.forEach((d, i) => {
      d.addEventListener('click', () => goTo(i, true));
    });

    goTo(0, false);
    window.YijingUI = window.YijingUI || {};
    window.YijingUI.transformGoTo = goTo;
  })();

  /* ============ 05 屏 真实变卦推演 (本卦 + 动爻 → 变卦 / 互卦 / 体用) ============ */
  (function bindHexTransform() {
    const E = (typeof YijingEngine !== 'undefined') ? YijingEngine : null;
    const benStack = document.getElementById('tfBenStack');
    const chgStack = document.getElementById('tfChgStack');
    const diffStack = document.getElementById('tfDiffStack');
    if (!E || !benStack || !chgStack || !diffStack) return;

    const el = id => document.getElementById(id);
    const benLabel = el('tfBenLabel'), benName = el('tfBenName');
    const chgLabel = el('tfChgLabel'), chgName = el('tfChgName');
    const mvText = el('tfMovingText'), mvDesc = el('tfMovingDesc');
    const dName = el('tfDetailName'), dNo = el('tfDetailNo'), dQuote = el('tfDetailQuote'), dBody = el('tfDetailBody');
    const rLabel = el('tfReasonLabel'), rBody = el('tfReasonBody');
    const toast = el('hexToast');
    let toastTimer = null;

    /* 默认状态: 本卦乾 (第 1 卦), 九三爻动 → 变卦履 (第 10 卦) */
    let state = { no: 1, moving: [2] };

    function showToast(msg) {
      if (!toast) return;
      toast.textContent = msg;
      toast.classList.add('show');
      clearTimeout(toastTimer);
      toastTimer = setTimeout(() => toast.classList.remove('show'), 1800);
    }

    /* 六爻 HTML: 自上而下 (上爻 → 初爻) */
    function stackHtml(lines, moving, opts) {
      const o = opts || {};
      return HEX_DRAW_ORDER.map(i => {
        const t = lines[i];
        const isMv = moving.indexOf(i) >= 0;
        const cls = (t === 'yin' ? ' yin' : '') + (isMv ? ' moving' : '');
        if (t === 'yin') {
          return '<div class="row">' +
            '<div class="line' + cls + '"' + (o.interactive ? ' data-yao="' + i + '"' : '') + '></div>' +
            '<div class="line" style="width:4px;background:transparent;"></div>' +
            '<div class="line' + cls + '"' + (o.interactive ? ' data-yao="' + i + '"' : '') + '></div>' +
            '</div>';
        }
        return '<div class="row"><div class="line' + cls + '"' + (o.interactive ? ' data-yao="' + i + '"' : '') + '></div></div>';
      }).join('');
    }

    function diffRow(lbl, from, to) {
      return '<div class="diff-row"><span class="lbl">' + lbl + '</span>' +
        '<span class="from">' + from + '</span><span class="arr">→</span>' +
        '<span class="to">' + to + '</span></div>';
    }

    function reasonText(r) {
      const p = [];
      const benVirtue = (r.ben.desc || '').split(' · ')[1] || r.ben.desc || '';
      p.push('本卦「' + r.ben.name + '」，上' + r.upperClassic + '下' + r.lowerClassic +
             '（' + r.ben.trigramUName + r.ben.trigramDName + r.ben.name + '），' + benVirtue + '。');
      if (!r.moving.length) {
        p.push('六爻皆静，无动爻则不生变卦，宜直接以本卦卦辞断之，守常而行。');
      } else {
        const names = r.yaoChanges.map(c => c.from).join('、');
        const flip = r.yaoChanges.map(c => (c.fromYang ? '阳爻变阴' : '阴爻变阳')).join('、');
        const dir = [];
        if (r.upperClassic !== r.upperClassicTo) dir.push('上卦由' + r.upperClassic + '转' + r.upperClassicTo);
        if (r.lowerClassic !== r.lowerClassicTo) dir.push('下卦由' + r.lowerClassic + '转' + r.lowerClassicTo);
        p.push('动爻在' + names + '，' + flip + '，' + (dir.length ? dir.join('，') : '卦体不变') +
               '，故成' + r.changed.trigramUName + r.changed.trigramDName + r.changed.name +
               '（第 ' + E.cnNumber(r.changed.no) + ' 卦）。');
      }
      p.push('体卦' + r.ti.name + '（' + r.ti.wuxing + '），用卦' + r.yong.name + '（' + r.yong.wuxing + '），' +
             r.relation + '，' + r.verdict + '：' + r.verdictText);
      p.push('互卦「' + r.hu.name + '」，' + (r.hu.desc || '') + '，可参看事情发展的中间过程。');
      return p.join('<br><br>');
    }

    function render() {
      const r = E.transform(state.no, state.moving);
      const ben = r.ben, chg = r.changed;

      benStack.innerHTML = stackHtml(r.benLines, r.moving, { interactive: true });
      /* 变卦中由动爻变来的爻保持朱红, 便于对照 */
      chgStack.innerHTML = stackHtml(r.changedLines, r.moving, { interactive: false });

      if (benLabel) benLabel.textContent = '本 卦 · ' + ben.name;
      if (benName) benName.textContent = ben.name;
      if (chgLabel) chgLabel.textContent = (r.moving.length ? '变 卦 · ' + chg.name : '无 变 卦');
      if (chgName) chgName.textContent = chg.name;

      /* 推演视图 */
      const yaoFrom = r.yaoChanges.length ? r.yaoChanges.map(c => c.from).join('、') : '—';
      const yaoTo   = r.yaoChanges.length ? r.yaoChanges.map(c => c.to).join('、') : '—';
      diffStack.innerHTML =
        diffRow('上卦', r.upperClassic, r.upperClassicTo) +
        diffRow('下卦', r.lowerClassic, r.lowerClassicTo) +
        diffRow('动爻', yaoFrom, yaoTo) +
        diffRow('互卦', ben.name, r.hu.name) +
        diffRow('体用', r.ti.name + r.ti.wuxing, r.yong.name + r.yong.wuxing) +
        diffRow('吉凶', r.relation, r.verdict);

      /* 动爻提示条 */
      if (mvText) {
        mvText.textContent = r.moving.length
          ? r.yaoChanges.map(c => c.from).join('、') + ' 爻动'
          : '六 爻 皆 静';
      }
      if (mvDesc) {
        mvDesc.textContent = r.moving.length
          ? r.yaoChanges.map(c => (c.fromYang ? '阳爻变阴' : '阴爻变阳')).join('，') +
            '，上' + r.upperClassic + '下' + r.lowerClassic + ' → 上' + r.upperClassicTo + '下' + r.lowerClassicTo
          : '静卦守常，以本卦卦辞断之';
      }

      /* 变卦详情卡 */
      if (dName) dName.textContent = chg.name + ' 卦 · ' + chg.trigramUName + chg.trigramDName + chg.name;
      if (dNo) dNo.textContent = '第 ' + E.cnNumber(chg.no) + ' 卦';
      if (dQuote) dQuote.textContent = '「' + (chg.guaci || '') + '」';
      if (dBody) {
        dBody.textContent = (chg.intro || chg.desc || '') +
          (r.moving.length ? '变卦提示：' + r.relation + '，' + r.verdictText : '');
      }

      /* 推演卡 */
      if (rLabel) rLabel.textContent = '从 ' + ben.name + ' 至 ' + chg.name + ' 之 推 演';
      if (rBody) rBody.innerHTML = reasonText(r);

      /* 爻点击: 切换动爻 */
      benStack.querySelectorAll('.line[data-yao]').forEach(line => {
        line.addEventListener('click', function(e) {
          e.stopPropagation();
          const idx = parseInt(this.dataset.yao, 10);
          const pos = state.moving.indexOf(idx);
          const benHex = E.hexByNo(state.no);
          if (pos >= 0) state.moving.splice(pos, 1);
          else state.moving.push(idx);
          state.moving.sort((a, b) => a - b);
          render();
          const nm = E.yaoName(idx, benHex.lines[idx] === 'yang');
          showToast(pos >= 0 ? nm + ' · 取消动爻' : nm + ' · 设为动爻');
        });
      });

      window.YijingUI = window.YijingUI || {};
      window.YijingUI._transformState = state;
      return r;
    }

    render();
    setTimeout(() => showToast('点击任意爻设为动爻'), 1800);

    /* 对外接口: setTransform(本卦序号, 动爻数组) */
    window.YijingUI = window.YijingUI || {};
    window.YijingUI.setTransform = function(benNo, moving) {
      state = { no: benNo, moving: (moving || []).slice() };
      return render();
    };
    window.YijingUI.getTransform = function() {
      return { no: state.no, moving: state.moving.slice() };
    };
    window.YijingUI.renderTransform = render;
  })();

  /* ============ 06 屏 月份切换 + 状态卡 ============ */
