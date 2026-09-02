/* ============================================================
 * yijing-app · js/06-layout-nav.js (iter29 模块化拆分)
 * 原 index.html 内联 script 按架构层切分 (保持 IIFE 顺序不变)
 * 依赖: data.js / terms.js / divination.js 先加载
 * ============================================================ */

  (function framePhones() {
    const phones = document.querySelector('.phones');
    if (!phones) return;
    const SCREEN_NAMES = ['01 今日一卦', '02 起卦方式', '03 六十四卦', '04 卦辞解析', '05 变卦推演', '06 历史记录'];
    [].slice.call(phones.querySelectorAll('.phone')).forEach(function (ph, i) {
      ph.setAttribute('role', 'group');
      ph.setAttribute('aria-label', SCREEN_NAMES[i] || ('屏幕 ' + (i + 1)));
      if (ph.parentElement && ph.parentElement.classList.contains('phone-frame')) return;
      const frame = document.createElement('div');
      frame.className = 'phone-frame';
      ph.parentNode.insertBefore(frame, ph);
      frame.appendChild(ph);
      const label = ph.querySelector('.phone-label');
      if (label) frame.appendChild(label);
    });
  })();

  /* ============ 等比缩放（仅 fit 模式：≥1600px 设计画廊全览） ============ */
  (function fitViewport() {
    const vp = document.querySelector('.viewport');
    if (!vp) return;
    const isGallery = (new URLSearchParams(location.search).get('view') === 'gallery');
    const baseW = 2940, baseH = 1300;
    function fit() {
      // app / grid 模式由 CSS 接管布局，不做缩放（缩放到 200px 宽会不可读）
      if (isGallery || YijingLayout.mode() !== 'fit') {
        vp.style.transform = 'none';
        vp.style.transformOrigin = 'top left';
        return;
      }
      const scale = Math.min(window.innerWidth / baseW, window.innerHeight / baseH);
      const offX = (window.innerWidth - baseW * scale) / 2;
      const offY = (window.innerHeight - baseH * scale) / 2;
      vp.style.transform = 'translate(' + offX + 'px,' + offY + 'px) scale(' + scale + ')';
      vp.style.transformOrigin = 'top left';
    }
    fit();
    window.addEventListener('resize', fit);
    // 跨越断点（平板旋转 / 窗口缩放）时重新适配
    [YijingLayout.mqApp, YijingLayout.mqGrid].forEach(function (mq) {
      if (!mq) return;
      if (mq.addEventListener) mq.addEventListener('change', fit);
      else if (mq.addListener) mq.addListener(fit);
    });
  })();

  /* ============ 移动端 App 模式：横向轮播 + 屏序指示器 + 返回导航 ============ */
  (function bindAppMode() {
    const phones = document.querySelector('.phones');
    if (!phones) return;
    const pager = document.getElementById('appPager');
    const hint = document.getElementById('appHint');
    const slides = [].slice.call(phones.querySelectorAll('.phone'));
    if (!slides.length) return;
    /* 屏数随实际屏动态提示 */
    if (hint) hint.textContent = '← 左右滑动切换 · 共 ' + slides.length + ' 屏 →';

    /* 屏序指示器 */
    let dots = [];
    if (pager) {
      pager.innerHTML = '';
      dots = slides.map(function (_, i) {
        const d = document.createElement('div');
        d.className = 'pg-dot' + (i === 0 ? ' on' : '');
        pager.appendChild(d);
        return d;
      });
    }

    let current = 0;
    function setActive(i) {
      if (i === current) return;
      current = i;
      dots.forEach(function (d, k) { d.classList.toggle('on', k === i); });
      try {
        document.dispatchEvent(new CustomEvent('yijing:screenchange', { detail: { index: i } }));
      } catch (e) {}
    }

    function goTo(i, smooth) {
      i = Math.max(0, Math.min(slides.length - 1, i));
      const target = slides[i];
      if (!target) return;
      if (smooth === false) phones.scrollLeft = target.offsetLeft;
      else if (phones.scrollTo) phones.scrollTo({ left: target.offsetLeft, behavior: 'smooth' });
      else phones.scrollLeft = target.offsetLeft;
      setActive(i);
    }

    /* 滚动位置 → 当前屏 (rAF 节流) */
    let ticking = false;
    phones.addEventListener('scroll', function () {
      if (ticking) return;
      ticking = true;
      requestAnimationFrame(function () {
        const mid = phones.scrollLeft + phones.clientWidth / 2;
        let best = 0, bestD = Infinity;
        slides.forEach(function (s, i) {
          const d = Math.abs(s.offsetLeft + s.offsetWidth / 2 - mid);
          if (d < bestD) { bestD = d; best = i; }
        });
        setActive(best);
        ticking = false;
      });
    }, { passive: true });

    /* 首屏滑动提示：仅提示一次 */
    if (hint) {
      const HINT_KEY = 'yijing.appHint.v1';
      let seen = false;
      try { seen = localStorage.getItem(HINT_KEY) === '1'; } catch (e) {}
      if (!seen) {
        setTimeout(function () {
          hint.classList.add('show');
          setTimeout(function () {
            hint.classList.remove('show');
            try { localStorage.setItem(HINT_KEY, '1'); } catch (e) {}
          }, 3200);
        }, 2000);
      }
    }

    /* 屏内返回箭头：App 模式下回到上一屏，桌面保持装饰 */
    slides.forEach(function (slide, i) {
      if (i === 0) return;
      const back = slide.querySelector('.detail-header .icon-btn');
      if (!back) return;
      back.style.cursor = 'pointer';
      back.addEventListener('click', function (e) {
        if (!YijingAppMode.is()) return;
        e.stopPropagation();
        goTo(i - 1, true);
      });
    });

    /* 屏4 头部 ↗：触发与底部「生成分享卡」相同的行为 */
    const detailHdrBtns = document.querySelectorAll('#phoneDetail .detail-header .icon-btn');
    const hdrBack = detailHdrBtns[0];
    const hdrShare = detailHdrBtns[1];
    if (hdrShare) {
      hdrShare.style.cursor = 'pointer';
      hdrShare.setAttribute('role', 'button');
      hdrShare.setAttribute('aria-label', '生成分享卡');
      hdrShare.addEventListener('click', function () {
        const b = document.getElementById('detailShare');
        if (b) b.click();
      });
    }
    /* 屏4 头部 ←：返回来路屏 (无记录时回 03 屏) */
    if (hdrBack) {
      hdrBack.style.cursor = 'pointer';
      hdrBack.setAttribute('role', 'button');
      hdrBack.setAttribute('aria-label', '返回');
      hdrBack.addEventListener('click', function () {
        const backTo = (window.YijingUI && window.YijingUI._detailBackTo != null)
          ? window.YijingUI._detailBackTo : 2;
        if (window.YijingUI && window.YijingUI.gotoScreen) window.YijingUI.gotoScreen(backTo);
      });
    }

    window.YijingUI = window.YijingUI || {};
    window.YijingUI.appGoTo = goTo;
    window.YijingUI.appSlideCount = slides.length;
    window.YijingUI.appCurrent = function () { return current; };
  })();

  /* ============ 底部 tabbar 导航 + hash 深链 (PWA shortcuts) ============ */
  (function bindTabbarNav() {
    const phones = document.querySelector('.phones');
    const slides = phones ? [].slice.call(phones.querySelectorAll('.phone')) : [];
    const tabs = [].slice.call(document.querySelectorAll('.tabbar .tab[data-goto]'));
    if (!tabs.length || !slides.length) return;

    /* 当前屏 → tab 高亮映射；屏4/5 为详情屏，保持原高亮 */
    const SCREEN_TO_TAB = { 0: 0, 1: 2, 2: 1, 5: 3, 6: 3 };

    function gotoScreen(n, opts) {
      n = Math.max(0, Math.min(slides.length - 1, n));
      const target = slides[n];
      if (!target) return;
      /* 进入屏4 时记录来路屏, 供顶栏 ← 返回 */
      if (n === 3 && window.YijingUI && typeof YijingUI.appCurrent === 'function') {
        window.YijingUI._detailBackTo = YijingUI.appCurrent();
      }
      const mode = (window.YijingLayout && YijingLayout.mode()) || 'fit';
      if (mode === 'app' && window.YijingUI && YijingUI.appGoTo) {
        YijingUI.appGoTo(n, true);
      } else if (mode === 'grid') {
        target.scrollIntoView({ behavior: 'smooth', block: 'start' });
      } else {
        /* fit 画廊无滚动，闪烁提示目标屏 */
        target.classList.remove('flash');
        void target.offsetWidth;
        target.classList.add('flash');
        setTimeout(function () { target.classList.remove('flash'); }, 1200);
      }
      /* Android 返回键 / 浏览器返回: 主屏导航压栈, 详情屏 (3/4) 由主屏栈回退承接 */
      if (!(opts && opts.fromPop)) pushHistory(n);
    }

    /* ===== History 栈: 让 Android 硬件返回键回上一屏而非退出 ===== */
    const HASH_MAP = { today: 0, start: 1, hexagrams: 2, history: 5, me: 6 };
    const HASH_BY_SCREEN = {};
    Object.keys(HASH_MAP).forEach(function (k) { HASH_BY_SCREEN[HASH_MAP[k]] = k; });
    function pushHistory(n) {
      /* 已在该屏条目 (深链直达 / 重复点击) 不再压栈 */
      if (history.state && history.state.screen === n) return;
      const h = HASH_BY_SCREEN[n];
      if (h) {
        history.pushState({ screen: n }, '', '#' + h);
      } else {
        /* 详情屏: 同 URL 压栈仅记录 state, 返回键仍可回到来路屏 */
        history.pushState({ screen: n }, '', location.href);
      }
    }
    window.addEventListener('popstate', function (e) {
      /* 目标屏优先取压栈时存的 state, 其次按 hash, 兜底回屏1 */
      let n = (e.state && typeof e.state.screen === 'number') ? e.state.screen
             : HASH_MAP[(location.hash || '').replace('#', '')];
      if (n === undefined) n = 0;
      gotoScreen(n, { fromPop: true });
    });

    tabs.forEach(function (tab) {
      const n = parseInt(tab.dataset.goto, 10);
      tab.addEventListener('click', function () { gotoScreen(n); });
      tab.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); gotoScreen(n); }
      });
    });

    function syncTabs(i) {
      const t = SCREEN_TO_TAB[i];
      if (t === undefined) return;
      tabs.forEach(function (tab, k) {
        const on = k === t;
        tab.classList.toggle('active', on);
        tab.setAttribute('aria-selected', on ? 'true' : 'false');
      });
    }
    document.addEventListener('yijing:screenchange', function (e) { syncTabs(e.detail.index); });

    /* manifest shortcuts 深链: #today → 屏1 · #start → 屏2 · #history → 屏6 · #me → 屏7 */
    function applyHash() {
      const h = (location.hash || '').replace('#', '');
      if (h && HASH_MAP[h] !== undefined) gotoScreen(HASH_MAP[h]);
    }
    window.addEventListener('hashchange', applyHash);
    /* 骨架屏结束后再定位，避免被初始渲染覆盖; 并为入口屏补一条 state 供返回 */
    setTimeout(function () {
      applyHash();
      try {
        const cur = (window.YijingUI && typeof YijingUI.appCurrent === 'function') ? YijingUI.appCurrent() : 0;
        history.replaceState({ screen: cur }, '', location.hash || '#today');
      } catch (err) { /* 隐私模式等场景忽略 */ }
    }, 1600);

    window.YijingUI = window.YijingUI || {};
    window.YijingUI.gotoScreen = gotoScreen;
  })();

  /* ============ 杂项按钮接线: 屏4变卦入口 / 收藏 / 屏1查看全部 ============ */
