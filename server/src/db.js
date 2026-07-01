import Database from "better-sqlite3";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
export const db = new Database(path.join(__dirname, "..", "data.db"));

db.pragma("journal_mode = WAL");

// Phase 1: OAuth-connected users only. Later phases add tables for
// processed email metadata, sender profiles, action logs, and prefs
// (never raw email bodies - those are always fetched fresh from Gmail).
db.exec(`
  CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    google_id TEXT UNIQUE NOT NULL,
    email TEXT NOT NULL,
    name TEXT,
    picture TEXT,
    access_token TEXT,
    refresh_token TEXT,
    token_expiry INTEGER,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    updated_at TEXT NOT NULL DEFAULT (datetime('now'))
  );
`);

export function upsertUser({ googleId, email, name, picture, accessToken, refreshToken, expiryDate }) {
  const existing = db.prepare("SELECT * FROM users WHERE google_id = ?").get(googleId);

  if (existing) {
    db.prepare(
      `UPDATE users SET
        email = ?, name = ?, picture = ?, access_token = ?,
        refresh_token = COALESCE(?, refresh_token),
        token_expiry = ?, updated_at = datetime('now')
       WHERE google_id = ?`
    ).run(email, name, picture, accessToken, refreshToken, expiryDate, googleId);
    return db.prepare("SELECT * FROM users WHERE google_id = ?").get(googleId);
  }

  const info = db
    .prepare(
      `INSERT INTO users (google_id, email, name, picture, access_token, refresh_token, token_expiry)
       VALUES (?, ?, ?, ?, ?, ?, ?)`
    )
    .run(googleId, email, name, picture, accessToken, refreshToken, expiryDate);

  return db.prepare("SELECT * FROM users WHERE id = ?").get(info.lastInsertRowid);
}

export function getUserById(id) {
  return db.prepare("SELECT * FROM users WHERE id = ?").get(id);
}

export function updateUserTokens(id, { accessToken, refreshToken, expiryDate }) {
  db.prepare(
    `UPDATE users SET
      access_token = ?,
      refresh_token = COALESCE(?, refresh_token),
      token_expiry = ?,
      updated_at = datetime('now')
     WHERE id = ?`
  ).run(accessToken, refreshToken, expiryDate, id);
}
