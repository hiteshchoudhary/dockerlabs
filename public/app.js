/* Chai aur Docker Lab — frontend */
/* global marked, Terminal, FitAddon */

(() => {
  'use strict';

  // ── state ────────────────────────────────────────────────────────────────
  const LS_LEGACY_PROGRESS = 'cad-progress-v1'; // pre-SQLite store, migrated once
  const LS_LEGACY_LAST = 'cad-last-chapter';
  const LS_WELCOMED = 'cad-welcomed';
  const LS_MODE = 'cad-mode';
  const LS_THEME = 'cad-theme';

  let meta = null; // { title, modules: [{id,title,subtitle,chapters:[{id,title,hasBonus}]}] }
  let flat = []; // flattened chapters with module refs
  let numOf = new Map(); // chapter id -> global chapter number (book-style)
  let currentId = null;

  const $ = (sel, el = document) => el.querySelector(sel);
  const pad = (n) => String(n).padStart(2, '0');

  // ── progress: SQLite on the lab server (./data/progress.db), cached here ──
  let progressCache = {}; // { "<module>/<chapter>": { main, bonus } }
  let lastId = null;
  const progress = () => progressCache;
  const chapterState = (id) => progressCache[id] || {};

  const api = (url, opts) => fetch(url, opts).then((r) => (r.ok ? r.json() : Promise.reject(new Error(r.statusText))));

  async function loadProgress() {
    const d = await api('/api/progress');
    progressCache = d.progress || {};
    lastId = d.last || null;
  }

  // one-time move of the old localStorage store into SQLite
  async function migrateLegacyProgress() {
    const raw = localStorage.getItem(LS_LEGACY_PROGRESS);
    if (!raw) return;
    try {
      const d = await api('/api/progress/import', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ progress: JSON.parse(raw) }),
      });
      progressCache = d.progress || progressCache;
      const legacyLast = localStorage.getItem(LS_LEGACY_LAST);
      if (legacyLast && !lastId) await setLast(legacyLast);
      localStorage.removeItem(LS_LEGACY_PROGRESS);
      localStorage.removeItem(LS_LEGACY_LAST);
    } catch { /* leave the old store in place; try again next boot */ }
  }

  async function setLast(id) {
    lastId = id;
    api('/api/progress/last', {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id }),
    }).catch(() => {});
  }

  async function resetProgress() {
    const d = await api('/api/progress', { method: 'DELETE' });
    progressCache = d.progress || {};
    lastId = null;
  }

  // ── theme ────────────────────────────────────────────────────────────────

  const theme = () => document.documentElement.dataset.theme || 'dark';
  // white-outline mascot on dark surfaces, grey-outline on light
  const mascotSrc = () => `/assets/brand/chai-mascot-${theme() === 'light' ? 'dark' : 'light'}.png`;

  function applyTheme(t) {
    document.documentElement.dataset.theme = t;
    localStorage.setItem(LS_THEME, t);
    document.querySelectorAll('img.mascot').forEach((img) => { img.src = mascotSrc(); });
  }

  // ── markdown helpers ─────────────────────────────────────────────────────

  function renderMarkdown(md) {
    return marked.parse(md, { breaks: false });
  }

  // ":::notebook Title ... :::" → "Under the hood" aside
  function renderStory(md) {
    const re = /^:::notebook[ \t]*(.*)\n([\s\S]*?)\n:::[ \t]*$/gm;
    let html = '';
    let last = 0;
    let m;
    while ((m = re.exec(md)) !== null) {
      html += renderMarkdown(md.slice(last, m.index));
      html += `<aside class="notebook"><div class="notebook-head"><span class="eyebrow">Under the hood</span><span>${marked.parseInline(m[1] || 'Internals')}</span></div><div class="prose-inner">${renderMarkdown(m[2])}</div></aside>`;
      last = m.index + m[0].length;
    }
    html += renderMarkdown(md.slice(last));
    return html;
  }

  function escapeHtml(s) {
    return s.replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
  }

  // blockquotes that open with **Hitesh:** become dialogue cards
  function upgradeDialogues(root) {
    root.querySelectorAll('blockquote').forEach((bq) => {
      const strong = bq.querySelector('p strong');
      if (!strong || !/^hitesh\b/i.test(strong.textContent.trim())) return;
      strong.remove();
      const body = document.createElement('div');
      body.className = 'dialogue-body';
      body.innerHTML = `<div class="dialogue-name">Hitesh <span>· Founder, ChaiCode</span></div>` + bq.innerHTML;
      bq.className = 'dialogue';
      bq.innerHTML = `<div class="dialogue-avatar"><img class="mascot" src="${mascotSrc()}" alt=""></div>`;
      bq.appendChild(body);
    });
  }

  function stripH1(md) {
    return md.replace(/^#\s+.+\n?/m, '');
  }

  // ── sidebar: tray of glasses + module nav ────────────────────────────────

  function glassSvg(idx, frac) {
    const H = 26; // inner liquid height range
    const h = Math.round(H * frac);
    const y = 3 + (H - h);
    return `
      <svg width="24" height="34" viewBox="0 0 24 34">
        <path class="steam s1" d="M9 -2 q 2 -3 0 -6" />
        <path class="steam s2" d="M15 -2 q -2 -3 0 -6" />
        <clipPath id="gcut${idx}"><path d="M5 3 L19 3 L17.2 29 L6.8 29 Z"/></clipPath>
        <rect class="chai" clip-path="url(#gcut${idx})" x="4" y="${y}" width="16" height="${h}"/>
        <path class="outline" d="M4.4 2.4 L19.6 2.4 L17.7 29.6 L6.3 29.6 Z"/>
      </svg>`;
  }

  function totals(p) {
    let done = 0, all = 0, stars = 0;
    flat.forEach((c) => { all++; if ((p[c.id] || {}).main) done++; if ((p[c.id] || {}).bonus) stars++; });
    return { done, all, stars };
  }

  function renderSidebar() {
    const p = progress();

    // tray
    const glasses = $('#glasses');
    glasses.innerHTML = meta.modules.map((mod, i) => {
      const total = mod.chapters.length;
      const done = mod.chapters.filter((c) => (p[c.id] || {}).main).length;
      const frac = total ? done / total : 0;
      return `<div class="glass ${frac >= 1 ? 'full' : ''}" title="${escapeHtml(mod.title)} — ${done}/${total} exercises">${glassSvg(i, frac)}</div>`;
    }).join('');

    const t = totals(p);
    $('#tray-pct').textContent = `${Math.round(t.all ? (t.done / t.all) * 100 : 0)}%`;
    $('#tray-stats').innerHTML = `<b>${t.done}</b> of ${t.all} exercises · <b>${t.stars}</b> challenges`;
    $('#progress-fill').style.width = `${t.all ? (t.done / t.all) * 100 : 0}%`;

    // module nav
    const nav = $('#modules');
    nav.innerHTML = '';
    meta.modules.forEach((mod, mi) => {
      const done = mod.chapters.filter((c) => (p[c.id] || {}).main).length;
      const head = document.createElement('div');
      head.className = 'module-head';
      head.innerHTML = `<span>${pad(mi + 1)} · ${escapeHtml(mod.title)}</span><span class="count ${done === mod.chapters.length ? 'all' : ''}">${done}/${mod.chapters.length}</span>`;
      nav.appendChild(head);
      mod.chapters.forEach((ch) => {
        const st = p[ch.id] || {};
        const btn = document.createElement('button');
        btn.className = 'chapter-link' + (st.main ? ' done' : '') + (ch.id === currentId ? ' active' : '');
        btn.title = ch.title;
        btn.innerHTML = `
          <span class="chapter-num">${st.main ? '✓' : pad(numOf.get(ch.id))}</span>
          <span class="chapter-title">${escapeHtml(ch.title)}</span>
          ${st.bonus ? '<span class="chapter-star">★</span>' : ''}`;
        btn.addEventListener('click', () => openChapter(ch.id));
        nav.appendChild(btn);
      });
    });
    const active = $('.chapter-link.active', nav);
    if (active) active.scrollIntoView({ block: 'nearest' });
  }

  // ── topbar ───────────────────────────────────────────────────────────────

  function setCrumbs(entry) {
    const el = $('#crumbs');
    if (!entry) {
      el.innerHTML = `<span class="crumb-cur">Contents</span>`;
      return;
    }
    el.innerHTML = `
      <button class="crumb-link" id="crumb-home">Contents</button>
      <span class="crumb-sep">/</span>
      <span>Part ${entry.moduleIndex + 1} · ${escapeHtml(entry.moduleTitle)}</span>
      <span class="crumb-sep">/</span>
      <span class="crumb-cur">Chapter ${numOf.get(entry.id)}</span>`;
    $('#crumb-home').addEventListener('click', () => goHome());
  }

  function setMode(m) {
    localStorage.setItem(LS_MODE, m);
    $('#episode').classList.toggle('task-mode', m === 'task');
    document.querySelectorAll('#mode-toggle button').forEach((b) => b.classList.toggle('on', b.dataset.mode === m));
  }

  // ── episode rendering ────────────────────────────────────────────────────

  async function fetchMd(id, file) {
    const res = await fetch(`/api/chapter/${id}/${file}`);
    if (!res.ok) return null;
    return res.text();
  }

  // ── routing: /lab/<module>/<chapter>, and / for home ────────────────────

  function parseRoute() {
    const m = location.pathname.match(/^\/lab\/([^/]+)\/([^/]+)\/?$/);
    if (m) {
      const id = `${decodeURIComponent(m[1])}/${decodeURIComponent(m[2])}`;
      if (flat.some((f) => f.id === id)) return id;
    }
    return null;
  }

  function goHome(push = true) {
    currentId = null;
    if (push) history.pushState({}, '', '/');
    else history.replaceState({}, '', '/');
    renderHome();
  }

  function renderHome() {
    document.title = 'Chai aur Docker — Lab';
    const p = progress();
    const t = totals(p);
    const resume = flat.find((f) => f.id === lastId) || flat[0];
    const ep = $('#episode');
    ep.classList.remove('task-mode');
    setCrumbs(null);
    $('#mode-toggle').hidden = true;
    ep.innerHTML = `
      <div class="home">
        <div class="home-hero">
          <img class="mascot" src="${mascotSrc()}" alt="">
          <div>
            <h1>Chai <em>aur</em> Docker</h1>
            <p class="home-tag">${escapeHtml(meta.tagline)}</p>
          </div>
          ${resume ? `<button class="btn btn-hot home-hero-cta" id="home-resume">${lastId ? 'Resume' : 'Start'} · Chapter ${numOf.get(resume.id)} →</button>` : ''}
        </div>
        <div class="home-overview">
          <div class="stat"><b>${t.done} <small style="font-weight:400;color:var(--text-3);font-size:14px">/ ${t.all}</small></b><span>exercises completed</span></div>
          <div class="stat"><b>${t.stars}</b><span>challenges earned</span></div>
          <div class="stat"><b>${meta.modules.length}</b><span>parts · ${t.all} chapters</span></div>
        </div>
        ${meta.modules.map((mod, mi) => {
          const done = mod.chapters.filter((c) => (p[c.id] || {}).main).length;
          const pct = mod.chapters.length ? (done / mod.chapters.length) * 100 : 0;
          return `
          <section class="home-module">
            <div class="hm-head">
              <div class="hm-title"><span class="eyebrow">Part ${mi + 1}</span>${escapeHtml(mod.title)}</div>
              <span class="hm-count">${done}/${mod.chapters.length} done</span>
            </div>
            ${mod.subtitle ? `<p class="hm-sub">${escapeHtml(mod.subtitle)}</p>` : ''}
            <div class="hm-bar"><i style="width:${pct}%"></i></div>
            <div class="hm-chapters">
              ${mod.chapters.map((ch) => {
                const st = p[ch.id] || {};
                return `<button class="home-ch" data-id="${ch.id}">
                  <span class="chapter-num ${st.main ? 'done' : ''}">${st.main ? '✓' : pad(numOf.get(ch.id))}</span>
                  <span class="hc-title">${escapeHtml(ch.title)}</span>
                  ${st.bonus ? '<span class="chapter-star">★</span>' : ''}
                  <span class="hc-arrow">→</span>
                </button>`;
              }).join('')}
            </div>
          </section>`;
        }).join('')}
      </div>`;
    $('#episode-scroll').scrollTop = 0;
    ep.querySelectorAll('.home-ch').forEach((el) =>
      el.addEventListener('click', () => openChapter(el.dataset.id)));
    const rb = $('#home-resume');
    if (rb) rb.addEventListener('click', () => openChapter(resume.id));
    renderSidebar();
  }

  // ── confirm dialog (no native alerts) ────────────────────────────────────

  function confirmDialog({ title, body, action }) {
    return new Promise((resolve) => {
      const overlay = $('#confirm');
      $('#confirm-title').textContent = title;
      $('#confirm-body').textContent = body;
      const ok = $('#confirm-ok'); const cancel = $('#confirm-cancel');
      ok.textContent = action;
      const close = (v) => { overlay.hidden = true; ok.onclick = cancel.onclick = overlay.onclick = null; window.removeEventListener('keydown', onKey); resolve(v); };
      const onKey = (e) => { if (e.key === 'Escape') close(false); };
      ok.onclick = () => close(true);
      cancel.onclick = () => close(false);
      overlay.onclick = (e) => { if (e.target === overlay) close(false); };
      window.addEventListener('keydown', onKey);
      overlay.hidden = false;
      cancel.focus();
    });
  }

  async function openChapter(id, push = true) {
    const entry = flat.find((f) => f.id === id);
    if (!entry) return;
    currentId = id;
    setLast(id);
    const url = `/lab/${id}`;
    if (push) history.pushState({ id }, '', url);
    else history.replaceState({ id }, '', url);
    document.title = `${entry.title} — Chai aur Docker`;

    const [storyMd, taskMd, bonusMd, hintsMd] = await Promise.all([
      fetchMd(id, 'story'), fetchMd(id, 'task'),
      entry.hasBonus ? fetchMd(id, 'bonus') : Promise.resolve(null),
      fetchMd(id, 'hints'),
    ]);

    const ep = $('#episode');
    const st = chapterState(id);
    const hints = (hintsMd || '').split(/\n---\n/).map((h) => h.trim()).filter(Boolean);

    setCrumbs(entry);
    $('#mode-toggle').hidden = false;

    ep.innerHTML = `
      <div class="ep-kicker">
        <span class="eyebrow">Chapter ${numOf.get(entry.id)}</span>
        <span class="sep">·</span>
        <span class="eyebrow" style="color:var(--text-3)">Part ${entry.moduleIndex + 1} — ${escapeHtml(entry.moduleTitle)}</span>
      </div>
      <h1 class="ep-title">${escapeHtml(entry.title)}</h1>
      <div class="ep-meta">
        ${st.main ? '<span class="badge ok">✓ Exercise done</span>' : '<span class="badge">Exercise pending</span>'}
        ${entry.hasBonus ? (st.bonus ? '<span class="badge accent">★ Challenge done</span>' : '<span class="badge">★ Challenge available</span>') : ''}
      </div>
      ${entry.hasDoodle ? `<img class="ep-doodle" src="/api/chapter/${id}/doodle" alt="">` : ''}
      <div class="prose" id="story">${renderStory(stripH1(storyMd || ''))}</div>

      <section class="quest" id="quest-main">
        <div class="quest-head">
          <div class="quest-label"><span class="eyebrow">Exercise</span>Hands-on</div>
          <div class="quest-status">${st.main ? '<div class="stamp">Completed</div>' : ''}</div>
        </div>
        <div class="prose">${renderMarkdown(stripH1(taskMd || ''))}</div>
        <div class="quest-actions">
          <button class="btn btn-hot" id="verify-main">Verify exercise</button>
          <button class="btn btn-ghost" id="hint-btn">Reveal a hint <span id="hint-count" style="color:var(--text-3)">0/${hints.length}</span></button>
          <button class="btn btn-ghost" id="reset-btn" title="Removes only this chapter's chai- containers">Reset chapter</button>
        </div>
        <div id="hints-area"></div>
        <div id="out-main"></div>
      </section>

      ${bonusMd ? `
      <section class="quest bonus" id="quest-bonus">
        <div class="quest-head">
          <div class="quest-label"><span class="eyebrow">Challenge</span>Optional</div>
          <div class="quest-status">${st.bonus ? '<div class="stamp bonus-stamp">Completed</div>' : ''}</div>
        </div>
        <div class="prose">${renderMarkdown(stripH1(bonusMd))}</div>
        <div class="quest-actions">
          <button class="btn btn-ghost" id="verify-bonus">Verify challenge ★</button>
        </div>
        <div id="out-bonus"></div>
      </section>` : ''}

      <nav class="ep-nav">
        ${entry.prev ? `<button class="prev" id="nav-prev"><span class="nav-dir">← Previous · Chapter ${numOf.get(entry.prev.id)}</span><span class="nav-title">${escapeHtml(entry.prev.title)}</span></button>` : ''}
        ${entry.next ? `<button class="next" id="nav-next"><span class="nav-dir">Next · Chapter ${numOf.get(entry.next.id)} →</span><span class="nav-title">${escapeHtml(entry.next.title)}</span></button>` : ''}
      </nav>
    `;

    upgradeDialogues(ep);
    setMode(localStorage.getItem(LS_MODE) || 'story');
    $('#episode-scroll').scrollTop = 0;
    ep.animate([{ opacity: 0, transform: 'translateY(6px)' }, { opacity: 1, transform: 'none' }],
      { duration: 250, easing: 'cubic-bezier(0.22,1,0.36,1)' });

    // wire actions
    $('#verify-main').addEventListener('click', () => runVerify('main'));
    const vb = $('#verify-bonus');
    if (vb) vb.addEventListener('click', () => runVerify('bonus'));

    let hintsPoured = 0;
    $('#hint-btn').addEventListener('click', () => {
      if (hintsPoured >= hints.length) return;
      const div = document.createElement('div');
      div.className = 'hint-card';
      div.innerHTML = `<span class="hint-n eyebrow">Hint ${hintsPoured + 1} of ${hints.length}</span>${renderMarkdown(hints[hintsPoured])}`;
      $('#hints-area').appendChild(div);
      hintsPoured += 1;
      $('#hint-count').textContent = `${hintsPoured}/${hints.length}`;
      if (hintsPoured >= hints.length) $('#hint-btn').disabled = true;
    });

    $('#reset-btn').addEventListener('click', async () => {
      const btn = $('#reset-btn');
      btn.disabled = true; btn.textContent = 'Resetting…';
      const res = await fetch('/api/reset', {
        method: 'POST', headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ id: currentId }),
      }).then((r) => r.json()).catch(() => ({ ok: false, output: 'Could not reach the lab server.' }));
      showOutput('main', res.output || '', res.ok);
      btn.disabled = false; btn.textContent = 'Reset chapter';
    });

    const prev = $('#nav-prev'); const next = $('#nav-next');
    if (prev) prev.addEventListener('click', () => openChapter(entry.prev.id));
    if (next) next.addEventListener('click', () => openChapter(entry.next.id));

    renderSidebar();
  }

  function showOutput(kind, text, ok) {
    const box = $(`#out-${kind}`);
    box.innerHTML = '';
    const pre = document.createElement('pre');
    pre.className = `verify-out ${ok ? 'ok' : 'err'}`;
    pre.textContent = text;
    box.appendChild(pre);
  }

  async function runVerify(kind) {
    const btn = $(kind === 'bonus' ? '#verify-bonus' : '#verify-main');
    const original = btn.textContent;
    btn.disabled = true;
    let dots = 0;
    const tick = setInterval(() => { btn.textContent = 'Checking' + '.'.repeat((dots++ % 3) + 1); }, 320);

    const res = await fetch('/api/verify', {
      method: 'POST', headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ id: currentId, kind }),
    }).then((r) => r.json()).catch(() => ({ ok: false, output: 'Could not reach the lab server.' }));

    clearInterval(tick);
    btn.disabled = false;
    btn.textContent = original;

    showOutput(kind, res.output || '(no output)', res.ok);

    if (res.ok) {
      const quest = $(kind === 'bonus' ? '#quest-bonus' : '#quest-main');
      const status = $('.quest-status', quest);
      const first = !chapterState(currentId)[kind];
      await loadProgress().catch(() => { (progressCache[currentId] ||= {})[kind] = true; }); // server recorded it in /api/verify
      if (first || !status.querySelector('.stamp')) {
        status.innerHTML = `<div class="stamp fresh${kind === 'bonus' ? ' bonus-stamp' : ''}">Completed</div>`;
      }
      // refresh the header badges without re-rendering the chapter
      const metaEl = $('.ep-meta');
      if (metaEl) {
        const s = chapterState(currentId);
        metaEl.innerHTML = `${s.main ? '<span class="badge ok">✓ Exercise done</span>' : '<span class="badge">Exercise pending</span>'}
          ${$('#quest-bonus') ? (s.bonus ? '<span class="badge accent">★ Challenge done</span>' : '<span class="badge">★ Challenge available</span>') : ''}`;
      }
      renderSidebar();
    }
  }

  // ── doctor (is docker up?) ───────────────────────────────────────────────

  async function checkDoctor() {
    const pill = $('#doctor-pill');
    const banner = $('#docker-banner');
    try {
      const d = await fetch('/api/doctor').then((r) => r.json());
      pill.className = `pill ${d.docker ? 'on' : 'off'}`;
      $('.pill-text', pill).textContent = d.docker ? `Docker ${d.version}` : 'Docker down';
      banner.hidden = d.docker;
    } catch {
      pill.className = 'pill off';
      $('.pill-text', pill).textContent = 'Lab server lost';
    }
  }

  // ── terminal ─────────────────────────────────────────────────────────────

  function setupTerminal() {
    const term = new Terminal({
      cursorBlink: true,
      fontFamily: "'JetBrains Mono', ui-monospace, monospace",
      fontSize: 13,
      lineHeight: 1.4,
      scrollback: 4000,
      theme: {
        background: '#0a0c10',
        foreground: '#d7dbe2',
        cursor: '#f0a04b',
        cursorAccent: '#0a0c10',
        selectionBackground: 'rgba(240,160,75,0.3)',
        black: '#1e232c', red: '#f0706a', green: '#4cc38a', yellow: '#e5b45b',
        blue: '#7aa2f7', magenta: '#bb9af7', cyan: '#7dcfff', white: '#d7dbe2',
        brightBlack: '#6e7581', brightRed: '#ff8f88', brightGreen: '#6fe0a6',
        brightYellow: '#f5cf7a', brightBlue: '#9ab8ff', brightMagenta: '#d3b8ff',
        brightCyan: '#a0e0ff', brightWhite: '#f2f4f7',
      },
    });
    const fit = new FitAddon.FitAddon();
    term.loadAddon(fit);
    term.open($('#terminal'));

    let ws;
    const connect = () => {
      ws = new WebSocket(`${location.protocol === 'https:' ? 'wss' : 'ws'}://${location.host}/term`);
      ws.onopen = () => {
        fit.fit();
        ws.send(`\x00RESIZE:${term.cols},${term.rows}`);
      };
      ws.onmessage = (e) => term.write(e.data);
      ws.onclose = () => term.write('\r\n\x1b[2m── shell ended · press Enter to restart ──\x1b[0m\r\n');
    };
    connect();

    term.onData((d) => {
      if (ws.readyState === WebSocket.OPEN) ws.send(d);
      else if (d === '\r') { term.reset(); connect(); }
    });

    const drawer = $('#term-drawer');
    const refit = () => {
      if (drawer.classList.contains('collapsed')) return;
      try { fit.fit(); } catch {}
      if (ws && ws.readyState === WebSocket.OPEN) ws.send(`\x00RESIZE:${term.cols},${term.rows}`);
    };
    window.addEventListener('resize', refit);
    document.fonts?.ready.then(refit);

    // drag-resize
    const handle = $('#term-handle');
    handle.addEventListener('mousedown', (e) => {
      e.preventDefault();
      handle.classList.add('dragging');
      const startY = e.clientY;
      const startH = drawer.offsetHeight;
      const move = (ev) => {
        const h = Math.min(window.innerHeight * 0.7, Math.max(120, startH + (startY - ev.clientY)));
        drawer.style.height = `${h}px`;
        refit();
      };
      const up = () => {
        handle.classList.remove('dragging');
        window.removeEventListener('mousemove', move);
        window.removeEventListener('mouseup', up);
      };
      window.addEventListener('mousemove', move);
      window.addEventListener('mouseup', up);
    });

    const toggle = () => {
      const collapsed = drawer.classList.toggle('collapsed');
      $('#term-toggle').textContent = collapsed ? 'Expand' : 'Collapse';
      $('#term-btn').classList.toggle('on', !collapsed);
      if (!collapsed) setTimeout(refit, 50);
    };
    $('#term-toggle').addEventListener('click', toggle);
    $('#term-btn').addEventListener('click', toggle);

    return { focus: () => term.focus() };
  }

  // ── command palette ──────────────────────────────────────────────────────

  function setupPalette() {
    const overlay = $('#palette');
    const input = $('#palette-input');
    const list = $('#palette-list');
    let sel = 0;
    let items = [];

    const open = () => { overlay.hidden = false; input.value = ''; render(''); input.focus(); };
    const close = () => { overlay.hidden = true; };

    function render(q) {
      const p = progress();
      items = flat.filter((f) => f.title.toLowerCase().includes(q) || f.moduleTitle.toLowerCase().includes(q));
      sel = 0;
      list.innerHTML = items.length ? items.map((f, i) => `
        <button class="palette-item ${i === sel ? 'sel' : ''}" data-i="${i}">
          <span class="pi-mod">ch ${pad(numOf.get(f.id))}</span>
          <span>${escapeHtml(f.title)}</span>
          ${(p[f.id] || {}).main ? '<span class="pi-done">✓ done</span>' : ''}
        </button>`).join('') : '<div class="palette-empty">No chapters match.</div>';
      list.querySelectorAll('.palette-item').forEach((el) =>
        el.addEventListener('click', () => { openChapter(items[+el.dataset.i].id); close(); }));
    }

    input.addEventListener('input', () => render(input.value.trim().toLowerCase()));
    input.addEventListener('keydown', (e) => {
      if (e.key === 'ArrowDown') { sel = Math.min(sel + 1, items.length - 1); }
      else if (e.key === 'ArrowUp') { sel = Math.max(sel - 1, 0); }
      else if (e.key === 'Enter') { if (items[sel]) { openChapter(items[sel].id); close(); } return; }
      else if (e.key === 'Escape') { close(); return; }
      else return;
      e.preventDefault();
      list.querySelectorAll('.palette-item').forEach((el, i) => el.classList.toggle('sel', i === sel));
      list.querySelectorAll('.palette-item')[sel]?.scrollIntoView({ block: 'nearest' });
    });

    overlay.addEventListener('click', (e) => { if (e.target === overlay) close(); });
    window.addEventListener('keydown', (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') { e.preventDefault(); overlay.hidden ? open() : close(); }
    });
    $('#palette-open').addEventListener('click', open);
  }

  // ── boot ─────────────────────────────────────────────────────────────────

  async function boot() {
    applyTheme(theme());
    $('#theme-btn').addEventListener('click', () => applyTheme(theme() === 'light' ? 'dark' : 'light'));
    $('#progress-reset').addEventListener('click', async () => {
      const yes = await confirmDialog({
        title: 'Reset all progress?',
        body: 'Every completed exercise and challenge will be unmarked. Your workspace files and Docker resources are not touched. Progress lives in data/progress.db on this machine.',
        action: 'Reset progress',
      });
      if (!yes) return;
      await resetProgress();
      if (currentId) openChapter(currentId, false); else renderHome();
    });
    document.querySelectorAll('#mode-toggle button').forEach((b) =>
      b.addEventListener('click', () => { setMode(b.dataset.mode); if (b.dataset.mode === 'task') $('#episode-scroll').scrollTop = 0; }));

    meta = await fetch('/api/meta').then((r) => r.json());
    document.title = 'Chai aur Docker — Lab';

    flat = [];
    meta.modules.forEach((mod, mi) => {
      mod.chapters.forEach((ch, ci) => {
        flat.push({ ...ch, moduleIndex: mi, moduleTitle: mod.title, chapterIndex: ci });
      });
    });
    flat.forEach((f, i) => { f.prev = flat[i - 1] || null; f.next = flat[i + 1] || null; });
    numOf = new Map(flat.map((f, i) => [f.id, i + 1]));

    // welcome overlay: first visit only — refreshes land straight on the route
    const welcome = $('#welcome');
    if (localStorage.getItem(LS_WELCOMED)) {
      welcome.remove();
    } else {
      $('#welcome-cta').addEventListener('click', () => {
        localStorage.setItem(LS_WELCOMED, '1');
        welcome.classList.add('gone');
      });
    }

    await loadProgress();
    await migrateLegacyProgress();

    $('#app').hidden = false;
    renderSidebar();

    const routeId = parseRoute();
    if (routeId) await openChapter(routeId, false);
    else goHome(false);

    window.addEventListener('popstate', () => {
      const id = parseRoute();
      if (id) openChapter(id, false);
      else { currentId = null; renderHome(); }
    });

    setupTerminal();
    setupPalette();
    checkDoctor();
    setInterval(checkDoctor, 20_000);
    $('#banner-retry').addEventListener('click', checkDoctor);
    $('#brand').addEventListener('click', () => goHome());
  }

  boot().catch((err) => {
    document.body.innerHTML = `<pre style="padding:40px;color:#f0706a;font-family:monospace">Lab failed to start: ${err.message}\nIs the server running? Try: npm start</pre>`;
  });
})();
