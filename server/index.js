'use strict';

/*
 * Chai aur Docker Lab — local lab server
 * Serves the story-mode UI, discovers chapter content from ./chapters,
 * runs verify/cleanup scripts, and exposes a real shell over WebSocket.
 * Everything runs on the learner's machine; there is no cloud component.
 */

const path = require('path');
const fs = require('fs');
const http = require('http');
const { spawn } = require('child_process');
const express = require('express');
const { WebSocketServer } = require('ws');
const progressStore = require('./progress');

let pty = null;
try {
  pty = require('node-pty');
} catch (err) {
  console.warn('[lab] node-pty could not load — the in-browser terminal is disabled.');
  console.warn('[lab] The lab still works: use your own terminal next to the browser.');
}

const PORT = Number(process.env.PORT || 4321);
const ROOT = path.join(__dirname, '..');
const CHAPTERS_DIR = path.join(ROOT, 'chapters');
const WORKSPACE_DIR = path.join(ROOT, 'workspace');
const DATA_DIR = path.join(ROOT, 'data'); // local SQLite progress; never shipped

const SEGMENT = /^\d{2}-[a-z0-9-]+$/; // valid module/chapter folder names
const CONTENT_FILES = { story: 'story.md', task: 'task.md', bonus: 'bonus.md', hints: 'hints.md' };

// ---------------------------------------------------------------------------
// Content discovery — modules and chapters are just folders; adding content
// never requires touching this server.
// ---------------------------------------------------------------------------

function readIf(p) {
  try { return fs.readFileSync(p, 'utf8'); } catch { return null; }
}

function titleFrom(md, fallback) {
  const m = (md || '').match(/^#\s+(.+)$/m);
  return m ? m[1].trim() : fallback;
}

function discover() {
  const moduleDirs = fs.readdirSync(CHAPTERS_DIR).filter((d) => SEGMENT.test(d)).sort();
  return moduleDirs.map((mdir) => {
    const mpath = path.join(CHAPTERS_DIR, mdir);
    let meta = {};
    try { meta = JSON.parse(readIf(path.join(mpath, 'module.json')) || '{}'); } catch {}
    const chapterDirs = fs.readdirSync(mpath).filter((d) => SEGMENT.test(d)).sort();
    const chapters = chapterDirs.map((cdir) => {
      const cpath = path.join(mpath, cdir);
      return {
        id: `${mdir}/${cdir}`,
        title: titleFrom(readIf(path.join(cpath, 'story.md')), cdir),
        hasBonus: fs.existsSync(path.join(cpath, 'bonus.md')),
        hasDoodle: fs.existsSync(path.join(cpath, 'doodle.png')),
      };
    });
    return { id: mdir, title: meta.title || mdir, subtitle: meta.subtitle || '', chapters };
  });
}

function chapterPath(id) {
  const parts = String(id || '').split('/');
  if (parts.length !== 2 || !parts.every((p) => SEGMENT.test(p))) return null;
  const p = path.join(CHAPTERS_DIR, parts[0], parts[1]);
  return fs.existsSync(p) ? p : null;
}

// ---------------------------------------------------------------------------
// Script runner — verify.sh / verify-bonus.sh / cleanup.sh
// ---------------------------------------------------------------------------

function runScript(scriptPath, cwd) {
  return new Promise((resolve) => {
    const child = spawn('bash', [scriptPath], {
      cwd,
      env: { ...process.env, LAB_ROOT: ROOT, LAB_WORKSPACE: WORKSPACE_DIR },
    });
    let out = '';
    let done = false;
    const timer = setTimeout(() => {
      out += '\n[lab] Timed out after 120s — is a command waiting for input?';
      child.kill('SIGKILL');
    }, 120_000);
    const finish = (code) => {
      if (done) return;
      done = true;
      clearTimeout(timer);
      resolve({ code, output: out.trim() });
    };
    child.stdout.on('data', (d) => (out += d));
    child.stderr.on('data', (d) => (out += d));
    child.on('error', (err) => { out += `\n[lab] ${err.message}`; finish(1); });
    child.on('close', finish);
  });
}

// ---------------------------------------------------------------------------
// HTTP API
// ---------------------------------------------------------------------------

const app = express();
app.use(express.json());
const progress = progressStore.open(DATA_DIR);

app.get('/api/meta', (req, res) => {
  res.json({
    title: 'Chai aur Docker',
    tagline: 'A practical Docker book by Hitesh — read, do, verify. Entirely on your machine.',
    terminal: Boolean(pty),
    modules: discover(),
  });
});

app.get('/api/chapter/:mod/:chap/doodle', (req, res) => {
  const cpath = chapterPath(`${req.params.mod}/${req.params.chap}`);
  const p = cpath && path.join(cpath, 'doodle.png');
  if (!p || !fs.existsSync(p)) return res.status(404).end();
  res.sendFile(p);
});

app.get('/api/chapter/:mod/:chap/:file', (req, res) => {
  const { mod, chap, file } = req.params;
  const cpath = chapterPath(`${mod}/${chap}`);
  const fname = CONTENT_FILES[file];
  if (!cpath || !fname) return res.status(404).json({ error: 'not found' });
  const md = readIf(path.join(cpath, fname));
  if (md === null) return res.status(404).json({ error: 'not found' });
  res.type('text/markdown').send(md);
});

app.post('/api/verify', async (req, res) => {
  const { id, kind } = req.body || {};
  const cpath = chapterPath(id);
  if (!cpath) return res.status(404).json({ error: 'unknown chapter' });
  const script = kind === 'bonus' ? 'verify-bonus.sh' : 'verify.sh';
  const scriptPath = path.join(cpath, script);
  if (!fs.existsSync(scriptPath)) return res.status(404).json({ error: 'no verifier' });
  const { code, output } = await runScript(scriptPath, cpath);
  if (code === 0) progress.mark(id, kind === 'bonus' ? 'bonus' : 'main');
  res.json({ ok: code === 0, output });
});

// ---------------------------------------------------------------------------
// Progress — stored in ./data/progress.db on this machine only
// ---------------------------------------------------------------------------

app.get('/api/progress', (req, res) => {
  res.json({ progress: progress.all(), last: progress.getLast() });
});

app.post('/api/progress/last', (req, res) => {
  const { id } = req.body || {};
  if (!chapterPath(id)) return res.status(404).json({ error: 'unknown chapter' });
  progress.setLast(id);
  res.json({ ok: true });
});

// one-time migration from the pre-SQLite localStorage store
app.post('/api/progress/import', (req, res) => {
  const blob = (req.body || {}).progress || {};
  const valid = Object.fromEntries(Object.entries(blob).filter(([id]) => chapterPath(id)));
  const imported = progress.importFrom(valid);
  res.json({ ok: true, imported, progress: progress.all() });
});

app.delete('/api/progress/:mod/:chap', (req, res) => {
  const id = `${req.params.mod}/${req.params.chap}`;
  if (!chapterPath(id)) return res.status(404).json({ error: 'unknown chapter' });
  progress.unmark(id);
  res.json({ ok: true, progress: progress.all() });
});

app.delete('/api/progress', (req, res) => {
  progress.resetAll();
  res.json({ ok: true, progress: {} });
});

app.post('/api/reset', async (req, res) => {
  const cpath = chapterPath((req.body || {}).id);
  if (!cpath) return res.status(404).json({ error: 'unknown chapter' });
  const scriptPath = path.join(cpath, 'cleanup.sh');
  if (!fs.existsSync(scriptPath)) return res.json({ ok: true, output: 'Nothing to clean.' });
  const { code, output } = await runScript(scriptPath, cpath);
  res.json({ ok: code === 0, output });
});

app.get('/api/doctor', (req, res) => {
  const child = spawn('docker', ['info', '--format', '{{.ServerVersion}}']);
  let out = '';
  const timer = setTimeout(() => child.kill('SIGKILL'), 5_000);
  child.stdout.on('data', (d) => (out += d));
  child.on('error', () => { clearTimeout(timer); res.json({ docker: false }); });
  child.on('close', (code) => {
    clearTimeout(timer);
    if (!res.headersSent) res.json({ docker: code === 0, version: out.trim() });
  });
});

// Static: app + vendored client libraries (no CDN — the lab works offline).
app.use(express.static(path.join(ROOT, 'public')));
app.use('/vendor/xterm', express.static(path.join(ROOT, 'node_modules', '@xterm', 'xterm')));
app.use('/vendor/addon-fit', express.static(path.join(ROOT, 'node_modules', '@xterm', 'addon-fit')));
app.use('/vendor/marked', express.static(path.join(ROOT, 'node_modules', 'marked')));

// SPA fallback: /lab/<module>/<chapter> (and any future route) serves the app,
// so a refresh lands the learner exactly where they were.
app.get('*', (req, res, next) => {
  if (req.path.startsWith('/api/') || req.path.includes('.')) return next();
  res.sendFile(path.join(ROOT, 'public', 'index.html'));
});

// ---------------------------------------------------------------------------
// Terminal — a real shell on the learner's machine, opened in ./workspace
// ---------------------------------------------------------------------------

const server = http.createServer(app);
const wss = new WebSocketServer({ server, path: '/term' });

wss.on('connection', (ws) => {
  if (!pty) {
    ws.send('\r\n  The in-browser terminal is unavailable (node-pty failed to install).\r\n  Use your own terminal — everything else works.\r\n');
    ws.close();
    return;
  }
  const shell = process.env.SHELL || (process.platform === 'win32' ? 'powershell.exe' : 'bash');
  let term;
  try {
    term = pty.spawn(shell, [], {
      name: 'xterm-256color',
      cols: 100,
      rows: 28,
      cwd: WORKSPACE_DIR,
      env: process.env,
    });
  } catch (err) {
    console.warn(`[lab] could not spawn shell: ${err.message}`);
    ws.send(`\r\n  Could not start a shell (${err.message}).\r\n  Use your own terminal — everything else works.\r\n`);
    ws.close();
    return;
  }
  term.onData((d) => { if (ws.readyState === ws.OPEN) ws.send(d); });
  term.onExit(() => ws.close());
  ws.on('message', (msg) => {
    const s = msg.toString();
    if (s.startsWith('\x00RESIZE:')) {
      const [cols, rows] = s.slice(8).split(',').map(Number);
      if (cols > 0 && rows > 0) try { term.resize(cols, rows); } catch {}
      return;
    }
    term.write(s);
  });
  ws.on('close', () => { try { term.kill(); } catch {} });
});

server.listen(PORT, () => {
  const url = `http://localhost:${PORT}`;
  console.log('');
  console.log('  ☕ Chai aur Docker Lab');
  console.log(`  Brewing at ${url}`);
  console.log('');
  if (!process.env.LAB_NO_OPEN) {
    const opener = process.platform === 'darwin' ? 'open' : process.platform === 'win32' ? 'start' : 'xdg-open';
    spawn(opener, [url], { stdio: 'ignore', detached: true }).on('error', () => {});
  }
});
