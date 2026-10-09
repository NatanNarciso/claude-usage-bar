# How it works

1. **Token** — Claude Code keeps its OAuth login in the macOS Keychain (`Claude Code-credentials`). The app reads it with `/usr/bin/security`.
2. **Usage** — it calls `GET https://api.anthropic.com/api/oauth/usage` (the same data behind Claude Code's `/usage`), with the `anthropic-beta: oauth-2025-04-20` header.
3. **Windows** — the response includes `five_hour` and `seven_day`, each with `utilization` (0–100) and `resets_at`.
4. **Refresh** — every 90 seconds, or on demand with **Atualizar agora / Refresh now**.
5. **Forecast** — `rate = utilization / time elapsed in the 5h window`; if `now + (100 − u)/rate` is before the reset, you're on pace to hit the limit.
6. **Alerts** — one notification per window and per threshold (80%, 95%).

## Caveats
- Full details of the request/response: [Undocumented API](Undocumented-API).
- The endpoint is **undocumented**. It can change or break at any time.
- The forecast assumes your average pace continues; a rolling-window forecast is planned.
- Usage from claude.ai or other devices counts toward the same limit and is included, since the server reports it.
