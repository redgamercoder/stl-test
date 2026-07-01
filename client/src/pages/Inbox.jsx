import { useEffect, useState } from "react";
import { Inbox as InboxIcon, RefreshCw } from "lucide-react";
import { api } from "../api";
import Header from "../components/Header.jsx";
import EmailListItem from "../components/EmailListItem.jsx";

export default function Inbox({ user, onLogout }) {
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  async function loadInbox() {
    setLoading(true);
    setError(null);
    try {
      const { messages } = await api.getInbox({ maxResults: 25 });
      setMessages(messages);
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    loadInbox();
  }, []);

  async function handleLogout() {
    await api.logout();
    onLogout();
  }

  const unreadCount = messages.filter((m) => m.unread).length;

  return (
    <div className="min-h-screen bg-canvas">
      <Header user={user} onLogout={handleLogout} />

      <main className="mx-auto max-w-2xl px-6 py-10">
        <div className="mb-6 flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-semibold tracking-tight text-ink">Inbox</h1>
            <p className="mt-1 text-sm text-subtle">
              {loading ? "Loading…" : `${unreadCount} unread · ${messages.length} shown`}
            </p>
          </div>
          <button
            onClick={loadInbox}
            className="flex h-9 w-9 items-center justify-center rounded-full border border-black/5 bg-white text-subtle shadow-card transition hover:text-ink"
            title="Refresh"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? "animate-spin" : ""}`} strokeWidth={1.75} />
          </button>
        </div>

        {error && (
          <div className="mb-6 rounded-xl2 bg-urgent/10 px-4 py-3 text-sm text-urgent">
            Couldn't load your inbox: {error}
          </div>
        )}

        {loading ? (
          <div className="space-y-3">
            {Array.from({ length: 6 }).map((_, i) => (
              <div key={i} className="h-[74px] animate-pulse rounded-xl2 bg-white/60 shadow-card" />
            ))}
          </div>
        ) : messages.length === 0 ? (
          <div className="flex flex-col items-center justify-center rounded-xl2 border border-dashed border-black/10 py-20 text-center">
            <InboxIcon className="mb-3 h-8 w-8 text-subtle" strokeWidth={1.5} />
            <p className="text-sm text-subtle">No messages found.</p>
          </div>
        ) : (
          <div className="space-y-3">
            {messages.map((email) => (
              <EmailListItem key={email.id} email={email} onClick={() => {}} />
            ))}
          </div>
        )}
      </main>
    </div>
  );
}
