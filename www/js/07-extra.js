/* ============================================================
 * yijing-app · js/07-extra.js (iter29 模块化拆分)
 * 原 index.html 内联 script 按架构层切分 (保持 IIFE 顺序不变)
 * 依赖: data.js / terms.js / divination.js 先加载
 * ============================================================ */

  (function bindMiscActions() {
    function go(n) {
      if (window.YijingUI && window.YijingUI.gotoScreen) window.YijingUI.gotoScreen(n);
    }
    function bindActivate(el, fn) {
      if (!el) return;
      el.addEventListener('click', fn);
      el.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); fn(); }
      });
    }

    /* 屏4: 查看变卦推演 → 屏5 */
    bindActivate(document.getElementById('toTransformBtn'), function () { go(4); });

    /* 屏1: 最近占卜「查看全部」→ 屏6 历史记录 */
    bindActivate(document.getElementById('recentAllLink'), function () { go(5); });

    /* 屏4: 收藏当前卦（localStorage 持久化） */
    const fav = document.getElementById('detailFav');
    const FAV_KEY = 'yijing.favHexes';
    function loadFavs() {
      try { return JSON.parse(localStorage.getItem(FAV_KEY) || '[]'); } catch (e) { return []; }
    }
    function paintFav() {
      const no = window.YijingUI && window.YijingUI._detailHexNo;
      if (!fav || !no) return;
      const on = loadFavs().indexOf(no) >= 0;
      fav.classList.toggle('on', on);
      fav.textContent = on ? '♥' : '♡';
      fav.setAttribute('aria-label', on ? '取消收藏此卦' : '收藏此卦');
    }
    bindActivate(fav, function () {
      const no = window.YijingUI && window.YijingUI._detailHexNo;
      if (!no) return;
      const list = loadFavs();
      const i = list.indexOf(no);
      if (i >= 0) list.splice(i, 1); else list.push(no);
      try { localStorage.setItem(FAV_KEY, JSON.stringify(list)); } catch (e) {}
      paintFav();
      /* pop 反馈: 移除再触发, 支持连续点击 */
      fav.classList.remove('pop');
      void fav.offsetWidth;
      fav.classList.add('pop');
      try { document.dispatchEvent(new CustomEvent('yijing:favchange')); } catch (e) {}
    });
    document.addEventListener('yijing:detailchange', paintFav);
    paintFav();
  })();

  /* ============ 卦象分享卡生成 (canvas → Web Share / 下载) ============ */
  const YijingShare = (function () {
    const GOLD = '#c9a876', TEXT = '#efe2c8', MUTED = '#b0a088', CINNABAR = '#d04d3e';
    const SERIF = '"Noto Serif SC", "Songti SC", "SimSun", serif';
    const SANS = '"Noto Sans SC", "PingFang SC", "Microsoft YaHei", sans-serif';

    /* 按宽度断行（中文按字断，英文按空格） */
    function wrap(ctx, text, maxW) {
      const out = [];
      text.split('\n').forEach(para => {
        let line = '';
        for (const ch of para) {
          const test = line + ch;
          if (ctx.measureText(test).width > maxW && line) { out.push(line); line = ch; }
          else line = test;
        }
        if (line) out.push(line);
      });
      return out;
    }
    function centerLines(ctx, lines, y, lh) {
      lines.forEach((l, i) => ctx.fillText(l, ctx.canvas.width / 2, y + i * lh));
    }

    /** 绘制卦象分享卡, 返回 canvas */
    function draw(hexNo, moving, question) {
      const lib = (typeof YIJING_DATA !== 'undefined') ? YIJING_DATA.HEX_LIBRARY : null;
      const hex = lib ? lib[hexNo - 1] : null;
      if (!hex) return null;
      const mv = moving || [];
      const W = 720, H = 1040;
      const c = document.createElement('canvas');
      c.width = W; c.height = H;
      const g = c.getContext('2d');

      /* 背景 + 氛围光 */
      const bg = g.createLinearGradient(0, 0, 0, H);
      bg.addColorStop(0, '#241809');
      bg.addColorStop(1, '#100b06');
      g.fillStyle = bg; g.fillRect(0, 0, W, H);
      const glow = g.createRadialGradient(W / 2, 300, 40, W / 2, 300, 420);
      glow.addColorStop(0, 'rgba(201,168,118,0.10)');
      glow.addColorStop(1, 'rgba(201,168,118,0)');
      g.fillStyle = glow; g.fillRect(0, 0, W, H);
      g.strokeStyle = 'rgba(201,168,118,0.35)';
      g.lineWidth = 2;
      g.strokeRect(24, 24, W - 48, H - 48);

      g.textAlign = 'center';
      g.textBaseline = 'alphabetic';

      /* 序号 */
      g.fillStyle = GOLD;
      g.font = '500 22px ' + SANS;
      let cnNo = String(hex.no);
      if (typeof YijingEngine !== 'undefined' && YijingEngine.cnNumber) {
        try { cnNo = YijingEngine.cnNumber(hex.no); } catch (e) {}
      }
      if ('letterSpacing' in g) g.letterSpacing = '6px';
      g.fillText('第 ' + cnNo + ' 卦', W / 2, 108);
      if ('letterSpacing' in g) g.letterSpacing = '0px';

      /* 卦象（自上而下: 上爻 → 初爻） */
      const lw = 220, lh = 18, gap = 22;
      const startY = 190;
      for (let k = 0; k < 6; k++) {
        const idx = 5 - k;                       /* 数组下标 */
        const t = hex.lines[idx];
        const isMoving = mv.indexOf(idx) >= 0;
        const yang = (t !== 'yin');
        const y = startY + k * (lh + gap);
        g.fillStyle = isMoving ? CINNABAR : GOLD;
        if (yang) {
          g.fillRect((W - lw) / 2, y, lw, lh);
        } else {
          const half = (lw - 44) / 2;
          g.fillRect((W - lw) / 2, y, half, lh);
          g.fillRect((W - lw) / 2 + half + 44, y, half, lh);
        }
        if (isMoving) {
          g.fillStyle = CINNABAR;
          g.font = '500 18px ' + SANS;
          g.fillText('动', (W + lw) / 2 + 26, y + lh);
        }
      }
      /* 上下卦标注 */
      g.fillStyle = MUTED;
      g.font = '400 20px ' + SERIF;
      g.fillText(hex.trigramU + ' 上 · ' + hex.trigramUName + '　' +
                 hex.trigramD + ' 下 · ' + hex.trigramDName, W / 2, startY + 6 * (lh + gap) + 34);

      /* 卦名 */
      g.fillStyle = TEXT;
      g.font = '700 76px ' + SERIF;
      if ('letterSpacing' in g) g.letterSpacing = '8px';
      g.fillText(hex.name + ' 卦', W / 2, 520);
      if ('letterSpacing' in g) g.letterSpacing = '0px';

      g.fillStyle = GOLD;
      g.font = '400 22px ' + SANS;
      g.fillText(hex.en || '', W / 2, 560);
      g.font = '500 26px ' + SERIF;
      if ('letterSpacing' in g) g.letterSpacing = '3px';
      g.fillText(hex.desc || '', W / 2, 600);
      if ('letterSpacing' in g) g.letterSpacing = '0px';

      /* 分隔线 */
      g.strokeStyle = 'rgba(201,168,118,0.28)';
      g.lineWidth = 1;
      g.beginPath(); g.moveTo(140, 636); g.lineTo(W - 140, 636); g.stroke();

      /* 卦辞 */
      let y = 694;
      if (hex.guaci) {
        g.fillStyle = TEXT;
        g.font = '600 30px ' + SERIF;
        const qlines = wrap(g, '「' + hex.guaci + '」', W - 160);
        centerLines(g, qlines.slice(0, 3), y, 46);
        y += qlines.slice(0, 3).length * 46;
      }
      /* 白话 */
      if (hex.intro) {
        g.fillStyle = MUTED;
        g.font = '400 22px ' + SANS;
        const ilines = wrap(g, hex.intro, W - 160);
        centerLines(g, ilines.slice(0, 5), y + 26, 34);
      }
      /* 所问之事 */
      if (question) {
        g.fillStyle = 'rgba(208,77,62,0.9)';
        g.font = '400 20px ' + SERIF;
        const q = wrap(g, '所问：' + question, W - 200);
        centerLines(g, q.slice(0, 2), H - 132, 30);
      }
      /* 页脚: 干支纪日 + 公历 */
      g.fillStyle = 'rgba(176,160,136,0.75)';
      g.font = '400 20px ' + SANS;
      const d = new Date();
      const stamp = d.getFullYear() + '-' + String(d.getMonth() + 1).padStart(2, '0') + '-' +
                    String(d.getDate()).padStart(2, '0');
      let gz = '';
      if (window.YijingCalendar) {
        try {
          gz = YijingCalendar.ganzhiYear(d) + '年 ' + YijingCalendar.ganzhiMonth(d) + '月 ' +
               YijingCalendar.ganzhiDay(d) + '日　';
        } catch (e) {}
      }
      if ('letterSpacing' in g) g.letterSpacing = '2px';
      g.fillText('易 道 · 卦 象 解 读　' + gz + stamp, W / 2, H - 62);
      if ('letterSpacing' in g) g.letterSpacing = '0px';
      return c;
    }

    function toBlob(canvas) {
      return new Promise(resolve => {
        if (!canvas.toBlob) return resolve(null);
        canvas.toBlob(b => resolve(b), 'image/png');
      });
    }
    function download(blob, filename) {
      try {
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url; a.download = filename;
        document.body.appendChild(a); a.click(); document.body.removeChild(a);
        setTimeout(() => URL.revokeObjectURL(url), 1500);
        return true;
      } catch (e) { return false; }
    }

    /** 生成并分享当前卦 (Web Share 优先, 否则下载 PNG) */
    async function share(hexNo, moving, question) {
      const canvas = draw(hexNo, moving, question);
      if (!canvas) return { ok: false, how: 'nodata' };
      const blob = await toBlob(canvas);
      if (!blob) return { ok: false, how: 'noblob' };
      const filename = 'yijing-' + hexNo + '.png';
      try {
        const file = new File([blob], filename, { type: 'image/png' });
        if (navigator.canShare && navigator.canShare({ files: [file] }) && navigator.share) {
          await navigator.share({
            files: [file],
            title: '易道 · 第' + hexNo + '卦',
            text: (typeof YIJING_DATA !== 'undefined' && YIJING_DATA.HEX_LIBRARY[hexNo - 1]
                   ? YIJING_DATA.HEX_LIBRARY[hexNo - 1].name + '卦' : '')
          });
          return { ok: true, how: 'share' };
        }
      } catch (e) {
        if (e && e.name === 'AbortError') return { ok: true, how: 'cancel' };
      }
      return { ok: download(blob, filename), how: 'download' };
    }

    return { draw: draw, share: share };
  })();
  window.YijingShare = YijingShare;

  /* 全局轻提示 (全局唯一 #globalToast, 供分享卡/设置面板等复用) */
  window.yijingToast = function (msg) {
    let t = document.getElementById('globalToast');
    if (!t) {
      t = document.createElement('div');
      t.id = 'globalToast';
      t.style.cssText = 'position:fixed;left:50%;bottom:calc(84px + env(safe-area-inset-bottom,0px));' +
        'transform:translateX(-50%) translateY(8px);z-index:9999;padding:10px 18px;border-radius:999px;' +
        'background:rgba(35,26,17,0.94);border:1px solid rgba(201,168,118,0.35);color:#c9a876;' +
        'font-size:13px;letter-spacing:1px;opacity:0;transition:opacity .28s,transform .28s;pointer-events:none;';
      document.body.appendChild(t);
    }
    t.textContent = msg;
    requestAnimationFrame(() => { t.style.opacity = '1'; t.style.transform = 'translateX(-50%) translateY(0)'; });
    clearTimeout(t._t);
    t._t = setTimeout(() => {
      t.style.opacity = '0'; t.style.transform = 'translateX(-50%) translateY(8px)';
    }, 2000);
  };

  (function bindShareCard() {
    const btn = document.getElementById('detailShare');
    if (!btn) return;
    let busy = false;
    const toast = window.yijingToast;
    async function act() {
      if (busy) return;
      const no = window.YijingUI && window.YijingUI._detailHexNo;
      if (!no) { toast('请先打开一卦'); return; }
      busy = true;
      btn.style.opacity = '0.5';
      try {
        if (document.fonts && document.fonts.ready) await document.fonts.ready;
        const mv = (window.YijingUI && window.YijingUI._detailMoving) || [];
        const q = (window.YijingUI && window.YijingUI.getQuestion) ? window.YijingUI.getQuestion() : '';
        const res = await YijingShare.share(no, mv, q);
        if (res.how === 'download') toast('分享卡已生成并下载');
        else if (res.how === 'nodata' || res.how === 'noblob') toast('生成失败，请重试');
      } catch (e) {
        toast('生成失败，请重试');
      } finally {
        busy = false;
        btn.style.opacity = '';
      }
    }
    btn.addEventListener('click', act);
    btn.addEventListener('keydown', e => {
      if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); act(); }
    });
  })();

  /* ============ 01 屏 ⚙ 设置面板: 导出 / 清空本地数据 ============ */
  (function bindSettingsSheet() {
    /* 屏1 ⚙ 与屏7 ⚙ 共用同一面板 */
    const btns = [].slice.call(document.querySelectorAll('#settingsBtn, #meSettingsBtn'));
    if (!btns.length) return;
    let btn = null; /* 最近触发的按钮, 关闭后归还焦点 */
    const toast = window.yijingToast;
    let sheet = null;
    let confirmTimer = null;

    function favList() {
      try {
        const f = JSON.parse(localStorage.getItem('yijing.favHexes') || '[]');
        return Array.isArray(f) ? f : [];
      } catch (e) { return []; }
    }

    function bindSheet() {
      sheet.addEventListener('click', e => { if (e.target === sheet) close(); });
      sheet.querySelector('#settingsClose').addEventListener('click', close);
      /* 导入 JSON: 合并历史与收藏 (按 ts 去重) */
      const fileInput = document.createElement('input');
      fileInput.type = 'file';
      fileInput.accept = 'application/json,.json';
      fileInput.style.display = 'none';
      sheet.appendChild(fileInput);
      fileInput.addEventListener('change', () => {
        const file = fileInput.files && fileInput.files[0];
        fileInput.value = '';
        if (!file) return;
        const reader = new FileReader();
        reader.onload = () => {
          try {
            const data = JSON.parse(reader.result);
            const incoming = Array.isArray(data.history) ? data.history : [];
            const incomingFavs = Array.isArray(data.favorites) ? data.favorites : [];
            if (!incoming.length && !incomingFavs.length) {
              toast('文件中没有可导入的数据');
              return;
            }
            /* 历史按 ts 去重合并 (无 ts 的以 question+name 组合键) */
            const cur = (typeof YijingHistory !== 'undefined') ? YijingHistory.load() : [];
            const key = h => h.ts ? 't' + h.ts : 'k' + h.name + '|' + h.question;
            const seen = {};
            cur.forEach(h => { seen[key(h)] = 1; });
            let added = 0;
            incoming.forEach(h => {
              if (h && !seen[key(h)]) { seen[key(h)] = 1; cur.push(h); added++; }
            });
            if (added) YijingHistory.save(cur);
            /* 收藏并集 */
            const favSet = {};
            favList().forEach(n => { favSet[n] = 1; });
            let favAdded = 0;
            incomingFavs.forEach(n => {
              const no = parseInt(n, 10);
              if (no >= 1 && no <= 64 && !favSet[no]) { favSet[no] = 1; favAdded++; }
            });
            localStorage.setItem('yijing.favHexes', JSON.stringify(Object.keys(favSet).map(Number).sort((a, b) => a - b)));
            document.dispatchEvent(new CustomEvent('yijing:favchange'));
            if (window.YijingUI && window.YijingUI.refreshHistory) window.YijingUI.refreshHistory();
            refreshMeta();
            toast('已导入：新增 ' + added + ' 条记录' + (favAdded ? ' · ' + favAdded + ' 卦收藏' : ''));
          } catch (e) {
            toast('导入失败：文件不是有效的 JSON');
          }
        };
        reader.readAsText(file);
      });
      sheet.querySelector('#settingsImport').addEventListener('click', () => fileInput.click());
      sheet.querySelector('#settingsExport').addEventListener('click', () => {
        const payload = {
          app: 'yijing-app',
          exportedAt: new Date().toISOString(),
          history: (typeof YijingHistory !== 'undefined') ? YijingHistory.load() : [],
          favorites: favList()
        };
        const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
        const a = document.createElement('a');
        const d = new Date();
        const pad = n => String(n).padStart(2, '0');
        a.href = URL.createObjectURL(blob);
        a.download = 'yijing-history-' + d.getFullYear() + pad(d.getMonth() + 1) + pad(d.getDate()) + '.json';
        document.body.appendChild(a);
        a.click();
        setTimeout(() => { URL.revokeObjectURL(a.href); a.remove(); }, 800);
        toast('已导出 JSON 数据');
      });
      sheet.querySelector('#settingsClear').addEventListener('click', () => {
        if (confirmTimer) {
          /* 二次确认 → 执行清空 */
          if (typeof YijingHistory !== 'undefined') YijingHistory.clear();
          if (window.YijingUI && window.YijingUI.refreshHistory) window.YijingUI.refreshHistory();
          resetClearBtn();
          refreshMeta();
          toast('历史记录已清空');
        } else {
          sheet.querySelector('#settingsClear .settings-item-name').textContent = '确认清空？再点一次';
          confirmTimer = setTimeout(resetClearBtn, 3000);
        }
      });
      /* 重置为示例数据: 恢复 data.js 内置 HISTORY 样例 (保留收藏), 独立二次确认 */
      let resetTimer = null;
      function resetResetBtn() {
        const name = sheet.querySelector('#settingsReset .settings-item-name');
        if (name) name.textContent = '重置为示例数据';
        clearTimeout(resetTimer);
        resetTimer = null;
      }
      sheet.querySelector('#settingsReset').addEventListener('click', () => {
        if (resetTimer) {
          if (typeof YIJING_DATA !== 'undefined' && Array.isArray(YIJING_DATA.HISTORY) &&
              typeof YijingHistory !== 'undefined') {
            YijingHistory.save(YIJING_DATA.HISTORY.slice());
            if (window.YijingUI && window.YijingUI.refreshHistory) window.YijingUI.refreshHistory();
          }
          resetResetBtn();
          refreshMeta();
          toast('已恢复示例数据');
        } else {
          const name = sheet.querySelector('#settingsReset .settings-item-name');
          if (name) name.textContent = '确认重置？再点一次';
          resetTimer = setTimeout(resetResetBtn, 3000);
        }
      });
      document.addEventListener('keydown', e => {
        if (e.key === 'Escape' && sheet && !sheet.classList.contains('hidden')) close();
      });
    }

    function getSheet() {
      if (sheet) return sheet;
      sheet = document.createElement('div');
      sheet.className = 'settings-overlay hidden';
      sheet.setAttribute('role', 'dialog');
      sheet.setAttribute('aria-modal', 'true');
      sheet.setAttribute('aria-label', '设置与数据管理');
      sheet.innerHTML =
        '<div class="settings-card">' +
          '<div class="settings-title">设 置</div>' +
          '<div class="settings-sub" id="settingsMeta">本地记录 0 条 · 收藏 0 卦</div>' +
          '<button class="settings-item" id="settingsExport" type="button">' +
            '<span class="settings-item-name">导出历史数据</span>' +
            '<span class="settings-item-desc">下载 JSON 文件，含起卦记录与收藏</span>' +
          '</button>' +
          '<button class="settings-item" id="settingsImport" type="button">' +
            '<span class="settings-item-name">导入历史数据</span>' +
            '<span class="settings-item-desc">选择导出的 JSON，合并到本地（自动去重）</span>' +
          '</button>' +
          '<button class="settings-item danger" id="settingsClear" type="button">' +
            '<span class="settings-item-name">清空历史记录</span>' +
            '<span class="settings-item-desc">仅清除本地起卦记录，操作可二次确认</span>' +
          '</button>' +
          '<button class="settings-item" id="settingsReset" type="button">' +
            '<span class="settings-item-name">重置为示例数据</span>' +
            '<span class="settings-item-desc">恢复内置演示记录，收藏不受影响</span>' +
          '</button>' +
          '<button class="settings-close" id="settingsClose" type="button">关 闭</button>' +
        '</div>';
      document.body.appendChild(sheet);
      bindSheet();
      return sheet;
    }

    function refreshMeta() {
      if (!sheet) return;
      const meta = sheet.querySelector('#settingsMeta');
      if (!meta) return;
      const hist = (typeof YijingHistory !== 'undefined') ? YijingHistory.load().length : 0;
      meta.textContent = '本地记录 ' + hist + ' 条 · 收藏 ' + favList().length + ' 卦';
    }

    function resetClearBtn() {
      if (!sheet) return;
      const name = sheet.querySelector('#settingsClear .settings-item-name');
      if (name) name.textContent = '清空历史记录';
      clearTimeout(confirmTimer);
      confirmTimer = null;
    }

    function open() {
      getSheet();
      refreshMeta();
      resetClearBtn();
      sheet.classList.remove('hidden');
      const c = sheet.querySelector('#settingsClose');
      if (c) c.focus();
    }
    function close() {
      if (!sheet) return;
      sheet.classList.add('hidden');
      resetClearBtn();
      const name = sheet.querySelector('#settingsReset .settings-item-name');
      if (name) name.textContent = '重置为示例数据';
      if (btn && btn.focus) try { btn.focus(); } catch (e) {}
    }

    btns.forEach(b => {
      b.addEventListener('click', function () { btn = b; open(); });
      b.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); btn = b; open(); }
      });
    });
    window.YijingUI = window.YijingUI || {};
    window.YijingUI.openSettings = open;
  })();

  /* ============ 07 屏「我的」: 统计 / 收藏 / 方向与方式偏好 ============ */
  (function renderMePage() {
    const METHOD_LABEL = { numeric: '数字起卦', yarrow: '蓍草演卦', coin: '铜钱起卦' };
    function el(id) { return document.getElementById(id); }
    function favList() {
      try {
        const f = JSON.parse(localStorage.getItem('yijing.favHexes') || '[]');
        return Array.isArray(f) ? f : [];
      } catch (e) { return []; }
    }
    function dayKey(d) { return d.getFullYear() + '-' + d.getMonth() + '-' + d.getDate(); }

    function renderBars(box, counts, colorOf, onClick) {
      if (!box) return;
      const entries = Object.keys(counts).map(k => [k, counts[k]]).sort((a, b) => b[1] - a[1]);
      if (!entries.length) {
        box.innerHTML = '<div class="me-empty-tip">尚无记录 · 先起一卦</div>';
        return;
      }
      const max = Math.max.apply(null, entries.map(e => e[1]));
      entries.forEach(function (pair) {
        const k = pair[0], c = pair[1];
        const pct = Math.max(6, Math.round(c / max * 100));
        const cls = colorOf(k) && colorOf(k) !== 'gold' ? ' ' + colorOf(k) : '';
        const bar = document.createElement('div');
        bar.className = 'me-bar' + (onClick ? ' clickable' : '');
        bar.innerHTML =
            '<div class="bar-head"><span>' + escapeHtml(k) + '</span><span class="cnt">' + c + ' 次</span></div>' +
            '<div class="bar-track"><div class="bar-fill' + cls + '" style="width:' + pct + '%"></div></div>';
        if (onClick) {
          bar.setAttribute('role', 'button');
          bar.setAttribute('tabindex', '0');
          bar.setAttribute('aria-label', '查看' + k + '相关记录');
          const go = function () { onClick(k, c); };
          bar.addEventListener('click', go);
          bar.addEventListener('keydown', function (e) {
            if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); go(); }
          });
        }
        box.appendChild(bar);
      });
    }

    function renderMe() {
      const list = (typeof window.YijingHistory !== 'undefined') ? window.YijingHistory.load() : [];
      const favs = favList();
      const LIB = (typeof YIJING_DATA !== 'undefined') ? YIJING_DATA.HEX_LIBRARY : [];

      el('meTotal').textContent = String(list.length);
      el('meFav').textContent = String(favs.length);

      /* 连续天数: 有 ts 的记录按日聚合, 自今日(否则昨日)向前数 */
      let streak = 0;
      const days = {};
      list.forEach(h => { if (h.ts) days[dayKey(new Date(h.ts))] = 1; });
      if (Object.keys(days).length) {
        const cursor = new Date();
        if (!days[dayKey(cursor)]) cursor.setDate(cursor.getDate() - 1);
        while (days[dayKey(cursor)]) { streak++; cursor.setDate(cursor.getDate() - 1); }
      }
      el('meStreak').textContent = String(streak);

      /* 始于: 最早一条真实记录 */
      const tsList = list.filter(h => h.ts).map(h => h.ts).sort((a, b) => a - b);
      if (tsList.length) {
        const d = new Date(tsList[0]);
        el('meSince').textContent = '始于 ' + (d.getMonth() + 1) + '月' + d.getDate() + '日 · 心诚则灵';
      } else {
        el('meSince').textContent = '初卦未成 · 静候一问';
      }

      /* 收藏 chips (点击直达 04 屏解析) */
      const row = el('meFavRow');
      row.innerHTML = '';
      favs.slice().sort((a, b) => a - b).forEach(no => {
        const hex = LIB[no - 1];
        if (!hex) return;
        const chip = document.createElement('div');
        chip.className = 'me-fav-chip';
        chip.setAttribute('role', 'button');
        chip.setAttribute('tabindex', '0');
        chip.setAttribute('aria-label', '查看' + hex.name + '卦解析');
        chip.innerHTML =
          '<div class="glyph">' + (hex.trigramU || '☰') + (hex.trigramD || '☰') + '</div>' +
          '<div class="fname">' + escapeHtml(hex.name) + '</div>' +
          '<div class="fno">第 ' + no + ' 卦</div>';
        const go = function () {
          if (window.YijingUI && window.YijingUI.openDetail) {
            window.YijingUI.openDetail(no);
            if (window.YijingUI.gotoScreen) window.YijingUI.gotoScreen(3);
          }
        };
        chip.addEventListener('click', go);
        chip.addEventListener('keydown', function (e) {
          if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); go(); }
        });
        row.appendChild(chip);
      });

      /* 问卦方向 / 起卦方式分布 (仅真实记录, 可点击跳 06 屏筛选) */
      const dirCounts = {}, methodCounts = {}, dirColor = {};
      list.forEach(h => {
        const d = h.direction || '综合';
        dirCounts[d] = (dirCounts[d] || 0) + 1;
        if (h.directionColor) dirColor[d] = h.directionColor;
        const m = METHOD_LABEL[h.method] || (h.method ? h.method : '其他');
        methodCounts[m] = (methodCounts[m] || 0) + 1;
      });
      const gotoHistory = function () {
        if (window.YijingUI && window.YijingUI.gotoScreen) window.YijingUI.gotoScreen(5);
      };
      const dirBox = el('meDirectionBars'); dirBox.innerHTML = '';
      const mBox = el('meMethodBars'); mBox.innerHTML = '';
      renderBars(dirBox, dirCounts, function (k) { return dirColor[k] || 'gold'; }, function (k) {
        /* 方向条 → 06 屏 + 该方向筛选 */
        if (window.YijingUI && window.YijingUI.filterByDirection) window.YijingUI.filterByDirection(k);
        gotoHistory();
      });
      renderBars(mBox, methodCounts, function () { return 'gold'; }, function () {
        /* 方式条 → 06 屏, 不带筛选 (清除可能的方向筛选) */
        if (window.YijingUI && window.YijingUI.filterByDirection) window.YijingUI.filterByDirection('');
        gotoHistory();
      });
    }

    ['meFavAll', 'meHistoryLink'].forEach(function (id) {
      const b = el(id);
      if (!b) return;
      b.addEventListener('click', function () {
        if (window.YijingUI && window.YijingUI.gotoScreen) {
          window.YijingUI.gotoScreen(id === 'meFavAll' ? 2 : 5);
        }
      });
      b.addEventListener('keydown', function (e) {
        if (e.key === 'Enter' || e.key === ' ') { e.preventDefault(); b.click(); }
      });
    });

    document.addEventListener('yijing:favchange', renderMe);
    window.YijingUI = window.YijingUI || {};
    window.YijingUI.refreshMe = renderMe;
    renderMe();
  })();

  /* ============ 骨架屏: 模拟"获取数据 → 渲染"流程 ============ */
  (function bootstrap() {
    const overlay = document.getElementById('skeletonOverlay');
    if (!overlay) return;
    if (typeof YijingAPI !== 'undefined' && YijingAPI.getHexLibrary) {
      YijingAPI.getHexLibrary().then(hexes => {
        const grid = document.getElementById('hex-grid-rows');
        if (grid) {
          grid.innerHTML = '';
          for (let i = 0; i < hexes.length; i += 2) {
            const a = hexes[i], b = hexes[i+1];
            const row = document.createElement('div');
            row.className = 'hex-row';
            row.innerHTML = renderHexCard(a, i === 0) + (b ? renderHexCard(b, false) : '');
            grid.appendChild(row);
          }
          appendMoreHint(grid, hexes.length);
        }
      });
    }
    const ready = (typeof YIJING_DATA !== 'undefined');
    const delay = ready ? 600 : 1400;
    setTimeout(() => {
      overlay.classList.add('hidden');
      /* 保留节点 (仅隐藏) 供起卦流程复用为「推演中」loading */
    }, delay);
  })();

  /* ============ URL 参数触发 P9 调试入口 ============ */
  (function urlP9Trigger() {
    try {
      const p = new URLSearchParams(location.search);
      const p9 = p.get('p9');

      /* ?hex=3&moving=1,4 → 05 屏直接推演第 3 卦、初二爻/五爻为动爻 */
      const hexNo = parseInt(p.get('hex'), 10);
      const mvRaw = p.get('moving');
      if (hexNo >= 1 && hexNo <= 64 && mvRaw && window.YijingUI && YijingUI.setTransform) {
        const mv = mvRaw.split(',').map(s => parseInt(s.trim(), 10)).filter(n => n >= 0 && n <= 5);
        YijingUI.setTransform(hexNo, mv);
      }

      if (!p9) return;
      setTimeout(() => {
        if (p9 === 'hero' && window.YijingUI && YijingUI.openHeroFullscreen) {
          YijingUI.openHeroFullscreen();
        } else if (p9 === 'yao' && window.YijingUI && YijingUI.switchTab) {
          YijingUI.switchTab('yaoci');
        } else if (p9 === 'filter') {
          const hex = parseInt(p.get('hex') || '1', 10);
          const chip = document.querySelector('.hex-filter-chip[data-hex="' + hex + '"]');
          if (chip) chip.click();
        }
      }, 1400);
    } catch (e) { /* noop */ }
  })();

  /* ============ URL 参数: 画廊视图 (平铺所有页面) ============ */
  (function urlGalleryView() {
    try {
      const p = new URLSearchParams(location.search);
      if (p.get('view') !== 'gallery') return;
      const wait = (ms) => new Promise(r => setTimeout(r, ms));
      wait(1500).then(() => {
        const vp = document.querySelector('.viewport');
        const canvas = document.querySelector('.canvas');
        const phonesWrap = document.querySelector('.phones');
        if (!vp || !canvas || !phonesWrap) return;

        // body 切换为块级、可滚动
        document.body.style.display = 'block';
        document.body.style.overflow = 'auto';
        document.body.style.height = 'auto';
        document.body.style.minHeight = '100vh';

        // 取消等比缩放，让画布以真实尺寸平铺
        vp.style.position = 'relative';
        vp.style.transform = 'none';
        vp.style.transformOrigin = 'top left';
        vp.style.width = 'auto';
        vp.style.height = 'auto';
        vp.style.left = '0';
        vp.style.top = '0';
        vp.style.padding = '40px 24px 60px';

        // 6 屏改两行 3 列 + 缩小到 320px 宽
        const phones = phonesWrap.querySelectorAll('.phone');
        const W = 320, H = 693;
        const scale = W / 390;
        phones.forEach((ph, i) => {
          ph.style.width = '390px';
          ph.style.height = '844px';
          ph.style.transform = 'scale(' + scale + ')';
          ph.style.transformOrigin = 'top left';
          ph.style.marginBottom = '0';
        });
        // 重写 phones 容器为 3 列网格
        phonesWrap.style.display = 'grid';
        phonesWrap.style.gridTemplateColumns = 'repeat(3, ' + W + 'px)';
        phonesWrap.style.gap = '32px 32px';
        phonesWrap.style.justifyContent = 'center';
        phonesWrap.style.alignItems = 'start';
        phonesWrap.style.padding = '0';

        // 控制布局盒为缩小后尺寸；若已被统一屏框包裹则直接复用，避免二次嵌套
        phones.forEach((ph, i) => {
          const frame = ph.parentElement && ph.parentElement.classList.contains('phone-frame')
            ? ph.parentElement : null;
          if (frame) {
            frame.style.width = W + 'px';
            frame.style.height = (H + 36) + 'px';
            const lb = frame.querySelector('.phone-label');
            if (lb) {
              lb.style.fontSize = '11px';
              lb.style.letterSpacing = '2px';
              lb.style.marginTop = '10px';
              lb.style.color = 'rgba(201,168,118,0.7)';
            }
            return;
          }
          if (ph.parentElement && ph.parentElement.classList.contains('phone-wrap')) return;
          const wrap = document.createElement('div');
          wrap.className = 'phone-wrap';
          wrap.style.cssText = 'position:relative;width:' + W + 'px;height:' + (H + 36) + 'px;';
          // 取出 phone 内的 phone-label 让它显示在 wrapper 底部
          const label = ph.querySelector('.phone-label');
          if (label) {
            label.style.position = 'absolute';
            label.style.bottom = '0';
            label.style.left = '0';
            label.style.right = '0';
            label.style.textAlign = 'center';
            label.style.fontSize = '11px';
            label.style.letterSpacing = '2px';
            label.style.color = 'rgba(201,168,118,0.7)';
          }
          ph.parentNode.insertBefore(wrap, ph);
          wrap.appendChild(ph);
        });

        // canvas title 缩放到画布中心
        const title = document.querySelector('.canvas-title');
        if (title) {
          title.style.width = '100%';
          title.style.height = 'auto';
          title.style.padding = '20px 0';
          title.style.marginBottom = '24px';
          title.querySelectorAll('*').forEach(el => {
            if (el.style) {
              const fs = parseFloat(getComputedStyle(el).fontSize);
              if (!isNaN(fs) && fs > 24) el.style.fontSize = '22px';
              if (!isNaN(fs) && fs <= 24 && fs >= 14) el.style.fontSize = '12px';
            }
          });
          // 移除 title 两侧的金线
          const styleEl = document.createElement('style');
          styleEl.textContent = '.canvas-title::before,.canvas-title::after{content:none !important;}';
          document.head.appendChild(styleEl);
        }
        canvas.style.width = '100%';
        canvas.style.maxWidth = '1100px';
        canvas.style.margin = '0 auto';

        // 添加画廊模式标识
        document.body.setAttribute('data-view', 'gallery');
        console.log('[Gallery] 已切换至画廊平铺视图');
      });
    } catch (e) { console.warn('[Gallery] error:', e); }
  })();

  /* ============ PWA: Service Worker 注册 ============ */
  (function registerPWA() {
    if (!('serviceWorker' in navigator)) {
      console.warn('[PWA] Service Worker not supported');
      return;
    }
    window.addEventListener('load', () => {
      navigator.serviceWorker.register('./sw.js', { scope: './' })
        .then((reg) => {
          console.log('[PWA] SW registered, scope:', reg.scope);
          // 检查更新
          reg.addEventListener('updatefound', () => {
            const newSw = reg.installing;
            console.log('[PWA] New SW installing...');
            newSw && newSw.addEventListener('statechange', () => {
              if (newSw.state === 'installed' && navigator.serviceWorker.controller) {
                showPwaUpdateToast(reg);
              }
            });
          });
          // 30s 后请求版本
          setTimeout(() => {
            if (navigator.serviceWorker.controller) {
              const ch = new MessageChannel();
              ch.port1.onmessage = (e) => console.log('[PWA] SW version:', e.data && e.data.version);
              navigator.serviceWorker.controller.postMessage({ type: 'GET_VERSION' }, [ch.port2]);
            }
          }, 2000);
        })
        .catch((err) => console.error('[PWA] SW registration failed:', err));
    });

    function showPwaUpdateToast(reg) {
      const toast = document.createElement('div');
      toast.style.cssText = [
        'position:fixed', 'bottom:24px', 'left:50%', 'transform:translateX(-50%)',
        'padding:12px 20px', 'border-radius:24px',
        'background:linear-gradient(135deg,#d04d3e 0%,#992d23 100%)',
        'color:#fff8e7', 'font-family:Noto Sans SC,sans-serif', 'font-size:13px',
        'letter-spacing:1.5px', 'box-shadow:0 8px 24px rgba(0,0,0,0.5)',
        'z-index:99999', 'display:flex', 'align-items:center', 'gap:12px',
        'animation:swToastIn 0.4s cubic-bezier(0.16,1,0.3,1) both'
      ].join(';');
      toast.innerHTML = '<span>发现新版本</span>';
      const btn = document.createElement('span');
      btn.textContent = '立 即 更 新 ↻';
      btn.style.cssText = 'background:rgba(255,255,255,0.18);padding:4px 10px;border-radius:12px;cursor:pointer;';
      btn.onclick = () => {
        const w = reg.waiting;
        if (w) { w.postMessage({ type: 'SKIP_WAITING' }); }
        setTimeout(() => location.reload(), 400);
      };
      toast.appendChild(btn);
      document.body.appendChild(toast);
    }
  })();
