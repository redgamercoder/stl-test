import { formatDistanceToNowStrict } from "date-fns";

function parseSender(from) {
  const match = from?.match(/^(.*?)\s*<(.+)>$/);
  if (match) return { name: match[1].replace(/"/g, "").trim() || match[2], email: match[2] };
  return { name: from || "Unknown sender", email: from || "" };
}

function initials(name) {
  return name
    .split(" ")
    .filter(Boolean)
    .slice(0, 2)
    .map((part) => part[0]?.toUpperCase())
    .join("");
}

function relativeDate(dateStr) {
  const date = new Date(dateStr);
  if (Number.isNaN(date.getTime())) return "";
  try {
    return formatDistanceToNowStrict(date, { addSuffix: true });
  } catch {
    return "";
  }
}

export default function EmailListItem({ email, onClick }) {
  const sender = parseSender(email.from);

  return (
    <button
      onClick={onClick}
      className="flex w-full items-start gap-4 rounded-xl2 border border-black/5 bg-white px-5 py-4 text-left shadow-card transition hover:border-black/10 hover:shadow-md"
    >
      <div className="mt-0.5 flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full bg-accent/10 text-xs font-semibold text-accent">
        {initials(sender.name) || "?"}
      </div>

      <div className="min-w-0 flex-1">
        <div className="flex items-baseline justify-between gap-3">
          <p className={`truncate text-sm ${email.unread ? "font-semibold text-ink" : "font-medium text-ink/80"}`}>
            {sender.name}
          </p>
          <span className="flex-shrink-0 text-xs text-subtle">{relativeDate(email.date)}</span>
        </div>
        <p className={`mt-0.5 truncate text-sm ${email.unread ? "font-medium text-ink" : "text-ink/70"}`}>
          {email.subject}
        </p>
        <p className="mt-0.5 truncate text-xs text-subtle">{email.snippet}</p>
      </div>

      {email.unread && <div className="mt-2 h-2 w-2 flex-shrink-0 rounded-full bg-accent" />}
    </button>
  );
}
