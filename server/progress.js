'use strict';

/*
 * Progress store — a local SQLite file (node:sqlite, built into Node 22+).
 * Lives at ./data/progress.db next to the lab; never leaves the machine.
 * Replaces the old browser localStorage store so progress survives a
 * cleared browser, a different browser, or a port change.
 */

const path = require('path');
const fs = require('fs');
const { DatabaseSync } = require('node:sqlite');

const KINDS = new Set(['main', 'bonus']);

function open(dataDir) {
  fs.mkdirSync(dataDir, { recursive: true });
  const db = new DatabaseSync(path.join(dataDir, 'progress.db'));
  db.exec(`
    PRAGMA journal_mode = WAL;
    CREATE TABLE IF NOT EXISTS progress (
      chapter  TEXT NOT NULL,
      kind     TEXT NOT NULL,
      done_at  TEXT NOT NULL DEFAULT (datetime('now')),
      PRIMARY KEY (chapter, kind)
    );
    CREATE TABLE IF NOT EXISTS settings (
      key   TEXT PRIMARY KEY,
      value TEXT
    );
  `);

  const q = {
    all: db.prepare('SELECT chapter, kind, done_at FROM progress'),
    mark: db.prepare('INSERT OR IGNORE INTO progress (chapter, kind) VALUES (?, ?)'),
    unmark: db.prepare('DELETE FROM progress WHERE chapter = ?'),
    clear: db.prepare('DELETE FROM progress'),
    getSetting: db.prepare('SELECT value FROM settings WHERE key = ?'),
    setSetting: db.prepare('INSERT INTO settings (key, value) VALUES (?, ?) ON CONFLICT(key) DO UPDATE SET value = excluded.value'),
    clearSettings: db.prepare('DELETE FROM settings'),
  };

  return {
    // { "<module>/<chapter>": { main: true, bonus: true } }
    all() {
      const out = {};
      for (const row of q.all.all()) {
        (out[row.chapter] ||= {})[row.kind] = true;
      }
      return out;
    },
    mark(chapter, kind) {
      if (!KINDS.has(kind)) return;
      q.mark.run(chapter, kind);
    },
    unmark(chapter) { q.unmark.run(chapter); },
    resetAll() { q.clear.run(); q.clearSettings.run(); },
    getLast() { return (q.getSetting.get('last_chapter') || {}).value || null; },
    setLast(chapter) { q.setSetting.run('last_chapter', chapter); },
    // one-time import of the old localStorage blob; only fills gaps
    importFrom(obj) {
      let n = 0;
      for (const [chapter, st] of Object.entries(obj || {})) {
        for (const kind of KINDS) {
          if (st && st[kind]) { q.mark.run(chapter, kind); n++; }
        }
      }
      return n;
    },
    count() { return q.all.all().length; },
  };
}

module.exports = { open };
