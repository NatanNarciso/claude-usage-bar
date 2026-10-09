# The undocumented usage endpoint

Claude Usage Bar depends on an endpoint that **Anthropic has not documented or announced for third parties**. This page records exactly what the app relies on, so breakage is easy to diagnose and fix.

> **Status:** observed working on 2026-10-09 with a Claude Pro account. Use at your own risk; nothing here is guaranteed by Anthropic.

## Request

```
GET https://api.anthropic.com/api/oauth/usage
Authorization: Bearer <Claude Code OAuth access token>
anthropic-beta: oauth-2025-04-20
User-Agent: claude-code/2.0
```

The token comes from the macOS Keychain item `Claude Code-credentials` (JSON, field `claudeAiOauth.accessToken`), read with `/usr/bin/security find-generic-password -s "Claude Code-credentials" -w`.

## Response (fields the app uses)

```jsonc
{
  "five_hour": { "utilization": 15.0, "resets_at": "2026-10-09T14:20:00.373033+00:00" },
  "seven_day": { "utilization": 52.0, "resets_at": "2026-10-12T12:00:00.373054+00:00" }
}
```

| Field | Type | Meaning |
|---|---|---|
| `utilization` | number, 0–100 | Percent of the window already used |
| `resets_at` | ISO-8601 with fractional seconds | When the window renews |

Other keys in the payload (per-model windows, dollar limits, experimental fields) are **ignored**. Unknown keys must never break parsing.

## How the app degrades

| Situation | App behaviour |
|---|---|
| Keychain item missing | Shows "Claude Code login not found" |
| HTTP 401 / 403 | Shows "Session expired…" and keeps the last values |
| Network error / timeout | Keeps the last values and shows the error |
| Missing/renamed `five_hour` or `seven_day` | Shows "Unexpected response from the API" |

The app never retries aggressively: one request every 90 s, plus manual refresh.

## If it breaks

1. Run the request above with your own token **in a private terminal** and compare the JSON with the table.
2. Open an issue with the **sanitized** JSON structure (replace numbers/dates if you like). **Never paste your token.**
3. Parsing lives in `UsageService.swift` (`fetch` and `window`) — usually a small fix.

## Planned mitigations
- Fallback estimate from local Claude Code logs (`~/.claude/projects`)
- Token refresh via the stored refresh token
- Optional switch to an official endpoint, if Anthropic ever ships one
