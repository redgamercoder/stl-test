import express from "express";
import session from "express-session";
import cors from "cors";
import path from "node:path";
import { fileURLToPath } from "node:url";
import connectSqlite3 from "connect-sqlite3";

import { config } from "./config.js";
import { authRouter } from "./routes/auth.js";
import { inboxRouter } from "./routes/inbox.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const SQLiteStore = connectSqlite3(session);

const app = express();

app.use(
  cors({
    origin: config.clientUrl,
    credentials: true,
  })
);
app.use(express.json());

app.use(
  session({
    store: new SQLiteStore({ db: "sessions.db", dir: path.join(__dirname, "..") }),
    secret: config.sessionSecret,
    resave: false,
    saveUninitialized: false,
    cookie: {
      httpOnly: true,
      sameSite: "lax",
      secure: false, // set true once served over HTTPS in production
      maxAge: 30 * 24 * 60 * 60 * 1000, // 30 days - keeps OAuth session alive across restarts
    },
  })
);

app.get("/health", (req, res) => res.json({ ok: true }));

app.use("/auth", authRouter);
app.use("/api", inboxRouter);

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: "internal_error" });
});

app.listen(config.port, () => {
  console.log(`Email agent server listening on http://localhost:${config.port}`);
});
