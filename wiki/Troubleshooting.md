# Troubleshooting

| Symptom | Fix |
|---|---|
| Icon shows `–` | Open Claude Code once and log in; click **Refresh now** |
| "Claude Code login not found" / "Login do Claude Code não encontrado" | The Keychain item is missing — log in with `claude` |
| "Session expired" / "Sessão expirada" | Open Claude Code to refresh your login, then refresh the app |
| "Unexpected response from the API" / "Resposta inesperada da API" | The [undocumented endpoint](Undocumented-API) may have changed — please open an issue |
| Keychain prompt keeps appearing | Choose **Always Allow** |
| No notifications | System Settings → Notifications → Claude Usage |
| Doesn't start at login | Make sure the app is in `/Applications` or `~/Applications`; check Login Items |
| Can't open: "unidentified developer" | See [Installation](Installation) |

Still stuck? [Open an issue](../issues/new/choose) (never paste your token).
