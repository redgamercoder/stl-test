import { useEffect, useState } from "react";
import { Routes, Route, Navigate, useSearchParams } from "react-router-dom";
import { api } from "./api";
import Login from "./pages/Login.jsx";
import Inbox from "./pages/Inbox.jsx";

export default function App() {
  const [auth, setAuth] = useState({ loading: true, authenticated: false, user: null });

  async function refreshAuth() {
    try {
      const status = await api.getStatus();
      setAuth({ loading: false, authenticated: status.authenticated, user: status.user ?? null });
    } catch {
      setAuth({ loading: false, authenticated: false, user: null });
    }
  }

  useEffect(() => {
    refreshAuth();
  }, []);

  if (auth.loading) {
    return (
      <div className="flex h-screen items-center justify-center bg-canvas">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-accent border-t-transparent" />
      </div>
    );
  }

  return (
    <Routes>
      <Route
        path="/login"
        element={auth.authenticated ? <Navigate to="/" replace /> : <Login />}
      />
      <Route
        path="/"
        element={
          auth.authenticated ? (
            <Inbox user={auth.user} onLogout={refreshAuth} />
          ) : (
            <Navigate to="/login" replace />
          )
        }
      />
    </Routes>
  );
}

export function useQueryError() {
  const [params] = useSearchParams();
  return params.get("error");
}
