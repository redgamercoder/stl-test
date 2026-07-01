import { LogOut, Sparkles } from "lucide-react";

export default function Header({ user, onLogout }) {
  return (
    <header className="flex items-center justify-between border-b border-black/5 bg-white/80 px-8 py-4 backdrop-blur">
      <div className="flex items-center gap-2">
        <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-accent/10">
          <Sparkles className="h-4 w-4 text-accent" strokeWidth={2} />
        </div>
        <span className="text-base font-semibold tracking-tight text-ink">Mailpilot</span>
      </div>

      <div className="flex items-center gap-3">
        {user?.picture ? (
          <img src={user.picture} alt="" className="h-8 w-8 rounded-full" referrerPolicy="no-referrer" />
        ) : (
          <div className="h-8 w-8 rounded-full bg-black/10" />
        )}
        <div className="hidden text-right sm:block">
          <p className="text-sm font-medium text-ink leading-tight">{user?.name}</p>
          <p className="text-xs text-subtle leading-tight">{user?.email}</p>
        </div>
        <button
          onClick={onLogout}
          className="ml-2 flex h-8 w-8 items-center justify-center rounded-full text-subtle transition hover:bg-black/5 hover:text-ink"
          title="Sign out"
        >
          <LogOut className="h-4 w-4" strokeWidth={1.75} />
        </button>
      </div>
    </header>
  );
}
