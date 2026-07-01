import { google } from "googleapis";

function getHeader(headers, name) {
  const header = headers?.find((h) => h.name.toLowerCase() === name.toLowerCase());
  return header?.value ?? "";
}

function toSummary(message) {
  const headers = message.payload?.headers ?? [];
  return {
    id: message.id,
    threadId: message.threadId,
    from: getHeader(headers, "From"),
    subject: getHeader(headers, "Subject") || "(no subject)",
    date: getHeader(headers, "Date"),
    snippet: message.snippet ?? "",
    unread: message.labelIds?.includes("UNREAD") ?? false,
    labelIds: message.labelIds ?? [],
  };
}

/**
 * Lists messages in the mailbox (metadata only - no bodies) for a lightweight
 * inbox view. `q` accepts standard Gmail search syntax.
 */
export async function listMessages(auth, { maxResults = 25, labelIds = ["INBOX"], q } = {}) {
  const gmail = google.gmail({ version: "v1", auth });

  const listRes = await gmail.users.messages.list({
    userId: "me",
    maxResults,
    labelIds,
    q,
  });

  const ids = listRes.data.messages ?? [];
  if (ids.length === 0) return [];

  const messages = await Promise.all(
    ids.map(({ id }) =>
      gmail.users.messages.get({
        userId: "me",
        id,
        format: "metadata",
        metadataHeaders: ["From", "Subject", "Date"],
      })
    )
  );

  return messages.map((res) => toSummary(res.data));
}

function decodeBase64Url(data) {
  return Buffer.from(data, "base64url").toString("utf-8");
}

/** Walks a message payload's MIME tree to find the best-effort text body. */
export function extractBody(payload) {
  if (!payload) return { text: "", html: "" };

  let text = "";
  let html = "";

  function walk(part) {
    if (!part) return;
    const mimeType = part.mimeType ?? "";
    if (mimeType === "text/plain" && part.body?.data) {
      text += decodeBase64Url(part.body.data);
    } else if (mimeType === "text/html" && part.body?.data) {
      html += decodeBase64Url(part.body.data);
    }
    part.parts?.forEach(walk);
  }

  walk(payload);
  return { text, html };
}

/** Fetches a single message with full payload (headers + body parts). */
export async function getMessage(auth, messageId) {
  const gmail = google.gmail({ version: "v1", auth });
  const { data } = await gmail.users.messages.get({
    userId: "me",
    id: messageId,
    format: "full",
  });
  return data;
}

/** Fetches an entire thread with full payloads for every message in it. */
export async function getThread(auth, threadId) {
  const gmail = google.gmail({ version: "v1", auth });
  const { data } = await gmail.users.threads.get({
    userId: "me",
    id: threadId,
    format: "full",
  });
  return data;
}
