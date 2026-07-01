# Mailpilot — AI Email Agent

An AI email agent that reads a connected Gmail account, analyzes/organizes/drafts
using the Claude API, and takes actions via tool use.

**Status: Phase 1 (Foundation)** — Google OAuth2, a Gmail API wrapper, and a
real inbox view. No Claude/AI logic yet — that's Phase 2.

## Stack

- **Frontend**: React + Vite + Tailwind (`client/`)
- **Backend**: Node.js + Express (`server/`)
- **Auth**: Google OAuth2 (Gmail readonly/modify/send + Calendar scopes)
- **DB**: SQLite (`better-sqlite3`) — stores OAuth tokens only for now;
  later phases add email metadata, sender profiles, and action logs
  (never raw email bodies — those are always fetched fresh from Gmail)

## 1. Create Google OAuth credentials

1. Go to the [Google Cloud Console](https://console.cloud.google.com/apis/credentials).
2. Create a project (or use an existing one).
3. Enable the **Gmail API** and **Google Calendar API** under "APIs & Services > Library".
4. Configure the **OAuth consent screen** (External is fine for testing; add
   your own Google account as a test user).
5. Under "Credentials", create an **OAuth client ID** of type **Web application**.
   - Authorized redirect URI: `http://localhost:5000/auth/google/callback`
6. Copy the generated **Client ID** and **Client Secret**.

## 2. Configure environment variables

```bash
cp server/.env.example server/.env
cp client/.env.example client/.env
```

Edit `server/.env` and fill in `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, and a
random `SESSION_SECRET`. Leave `ANTHROPIC_API_KEY` blank for now — it's used
starting in Phase 2.

## 3. Install and run

```bash
# Terminal 1 - backend
cd server
npm install
npm run dev      # http://localhost:5000

# Terminal 2 - frontend
cd client
npm install
npm run dev      # http://localhost:5173
```

Open http://localhost:5173, click **Connect Gmail**, sign in, and you should
land back on a real inbox view of your Gmail account.

OAuth tokens (including the refresh token) persist in `server/data.db`, and
sessions persist in `server/sessions.db`, so you'll stay signed in across
server restarts and browser sessions until you log out.

## Project structure

```
server/
  src/
    config.js        # env var loading
    db.js             # SQLite setup + user token storage
    googleAuth.js      # OAuth2 client + token refresh persistence
    gmail.js          # Gmail API wrapper (listMessages, getMessage, getThread)
    routes/auth.js     # /auth/google, /auth/google/callback, /auth/status, /auth/logout
    routes/inbox.js    # /api/inbox, /api/messages/:id, /api/threads/:id
    middleware/requireAuth.js
    index.js          # Express app entry

client/
  src/
    api.js            # fetch wrapper (credentials: include)
    App.jsx           # auth-gated routing
    pages/Login.jsx
    pages/Inbox.jsx
    components/Header.jsx
    components/EmailListItem.jsx
```

## What's next (Phase 2+)

See the project brief for the full roadmap: Claude API tool-use pipeline for
triage/scoring/drafting, an action layer with approve/reject confirmation UI,
and the 25 feature modules (priority inbox, auto-drafting, phishing detection,
daily briefing, etc.).
