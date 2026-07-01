import { Mail } from "lucide-react";
import { api } from "../api";
import { useQueryError } from "../App.jsx";

const ERROR_MESSAGES = {
  oauth_failed: "We couldn't complete the Google sign-in. Please try again.",
  session: "We couldn't start your session. Please try again.",
  access_denied: "Access was denied. Gmail access is required to use Mailpilot.",
};

export default function Login() {
  const error = useQueryError();

  return (
    <div className="flex h-screen flex-col items-center justify-center bg-canvas px-6">
      <div className="w-full max-w-sm rounded-xl2 bg-white p-10 text-center shadow-card">
        <div className="mx-auto mb-6 flex h-14 w-14 items-center justify-center rounded-2xl bg-accent/10">
          <Mail className="h-7 w-7 text-accent" strokeWidth={1.75} />
        </div>

        <h1 className="text-2xl font-semibold tracking-tight text-ink">Mailpilot</h1>
        <p className="mt-2 text-sm leading-relaxed text-subtle">
          Your inbox, triaged and drafted by AI. Connect your Gmail account to get started.
        </p>

        {error && (
          <p className="mt-4 rounded-lg bg-urgent/10 px-3 py-2 text-sm text-urgent">
            {ERROR_MESSAGES[error] || "Something went wrong. Please try again."}
          </p>
        )}

        <a
          href={`${api.base}/auth/google`}
          className="mt-8 flex w-full items-center justify-center gap-2 rounded-full bg-ink px-5 py-3 text-sm font-medium text-white transition hover:bg-black"
        >
          Connect Gmail
        </a>

        <p className="mt-4 text-xs text-subtle">
          We only request the Gmail and Calendar access needed to triage, draft,
          and schedule on your behalf. Nothing is sent without your approval.
        </p>
      </div>
    </div>
  );
}
