const API_BASE = import.meta.env.VITE_API_URL || "http://localhost:5000";

async function request(path, options = {}) {
  const res = await fetch(`${API_BASE}${path}`, {
    credentials: "include",
    headers: { "Content-Type": "application/json" },
    ...options,
  });

  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.error || `Request failed: ${res.status}`);
  }

  return res.json();
}

export const api = {
  base: API_BASE,
  getStatus: () => request("/auth/status"),
  logout: () => request("/auth/logout", { method: "POST" }),
  getInbox: (params = {}) => {
    const qs = new URLSearchParams(params).toString();
    return request(`/api/inbox${qs ? `?${qs}` : ""}`);
  },
  getMessage: (id) => request(`/api/messages/${id}`),
};
