import { google } from "googleapis";
import { config } from "./config.js";
import { updateUserTokens } from "./db.js";

export function createOAuthClient() {
  return new google.auth.OAuth2(
    config.google.clientId,
    config.google.clientSecret,
    config.google.redirectUri
  );
}

export function getAuthUrl() {
  const client = createOAuthClient();
  return client.generateAuthUrl({
    access_type: "offline",
    prompt: "consent", // ensures a refresh_token is returned even on repeat logins
    scope: config.google.scopes,
  });
}

export async function exchangeCodeForTokens(code) {
  const client = createOAuthClient();
  const { tokens } = await client.getToken(code);
  client.setCredentials(tokens);
  return { client, tokens };
}

export async function getGoogleProfile(client) {
  const oauth2 = google.oauth2({ auth: client, version: "v2" });
  const { data } = await oauth2.userinfo.get();
  return data; // { id, email, name, picture, ... }
}

/**
 * Builds an authenticated OAuth2 client for a stored user, wiring up a
 * listener that persists refreshed access/refresh tokens back to the DB.
 */
export function createOAuthClientForUser(user) {
  const client = createOAuthClient();
  client.setCredentials({
    access_token: user.access_token,
    refresh_token: user.refresh_token,
    expiry_date: user.token_expiry,
  });

  client.on("tokens", (tokens) => {
    updateUserTokens(user.id, {
      accessToken: tokens.access_token ?? user.access_token,
      refreshToken: tokens.refresh_token ?? null,
      expiryDate: tokens.expiry_date ?? user.token_expiry,
    });
  });

  return client;
}
