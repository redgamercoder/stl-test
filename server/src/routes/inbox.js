import { Router } from "express";
import { requireAuth } from "../middleware/requireAuth.js";
import { listMessages, getMessage, getThread, extractBody } from "../gmail.js";

export const inboxRouter = Router();

inboxRouter.use(requireAuth);

inboxRouter.get("/inbox", async (req, res) => {
  try {
    const maxResults = Math.min(Number(req.query.maxResults) || 25, 50);
    const messages = await listMessages(req.oauthClient, { maxResults, q: req.query.q });
    res.json({ messages });
  } catch (err) {
    console.error("Failed to list messages", err);
    res.status(502).json({ error: "gmail_fetch_failed" });
  }
});

inboxRouter.get("/messages/:id", async (req, res) => {
  try {
    const message = await getMessage(req.oauthClient, req.params.id);
    const headers = message.payload?.headers ?? [];
    const getHeader = (name) => headers.find((h) => h.name.toLowerCase() === name.toLowerCase())?.value ?? "";

    res.json({
      id: message.id,
      threadId: message.threadId,
      from: getHeader("From"),
      to: getHeader("To"),
      subject: getHeader("Subject") || "(no subject)",
      date: getHeader("Date"),
      unread: message.labelIds?.includes("UNREAD") ?? false,
      labelIds: message.labelIds ?? [],
      body: extractBody(message.payload),
    });
  } catch (err) {
    console.error("Failed to get message", err);
    res.status(502).json({ error: "gmail_fetch_failed" });
  }
});

inboxRouter.get("/threads/:id", async (req, res) => {
  try {
    const thread = await getThread(req.oauthClient, req.params.id);
    res.json(thread);
  } catch (err) {
    console.error("Failed to get thread", err);
    res.status(502).json({ error: "gmail_fetch_failed" });
  }
});
