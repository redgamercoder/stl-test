import { getUserById } from "../db.js";
import { createOAuthClientForUser } from "../googleAuth.js";

export function requireAuth(req, res, next) {
  const userId = req.session.userId;
  if (!userId) {
    return res.status(401).json({ error: "not_authenticated" });
  }

  const user = getUserById(userId);
  if (!user) {
    req.session.destroy(() => {});
    return res.status(401).json({ error: "not_authenticated" });
  }

  req.user = user;
  req.oauthClient = createOAuthClientForUser(user);
  next();
}
