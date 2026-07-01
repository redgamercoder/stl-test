import { Router } from "express";
import { config } from "../config.js";
import { getAuthUrl, exchangeCodeForTokens, getGoogleProfile } from "../googleAuth.js";
import { upsertUser, getUserById } from "../db.js";

export const authRouter = Router();

authRouter.get("/google", (req, res) => {
  res.redirect(getAuthUrl());
});

authRouter.get("/google/callback", async (req, res) => {
  const { code, error } = req.query;

  if (error) {
    return res.redirect(`${config.clientUrl}/login?error=${encodeURIComponent(error)}`);
  }

  try {
    const { client, tokens } = await exchangeCodeForTokens(code);
    const profile = await getGoogleProfile(client);

    const user = upsertUser({
      googleId: profile.id,
      email: profile.email,
      name: profile.name,
      picture: profile.picture,
      accessToken: tokens.access_token,
      refreshToken: tokens.refresh_token, // only present on first consent
      expiryDate: tokens.expiry_date,
    });

    req.session.regenerate((err) => {
      if (err) {
        console.error("Session regenerate failed", err);
        return res.redirect(`${config.clientUrl}/login?error=session`);
      }
      req.session.userId = user.id;
      res.redirect(config.clientUrl);
    });
  } catch (err) {
    console.error("OAuth callback failed", err);
    res.redirect(`${config.clientUrl}/login?error=oauth_failed`);
  }
});

authRouter.get("/status", (req, res) => {
  const userId = req.session.userId;
  if (!userId) return res.json({ authenticated: false });

  const user = getUserById(userId);
  if (!user) return res.json({ authenticated: false });

  res.json({
    authenticated: true,
    user: { email: user.email, name: user.name, picture: user.picture },
  });
});

authRouter.post("/logout", (req, res) => {
  req.session.destroy(() => {
    res.clearCookie("connect.sid");
    res.json({ ok: true });
  });
});
