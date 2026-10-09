# Privacy and Security

- **What is read:** your Claude Code OAuth token from the Keychain.
- **Where it goes:** only to `api.anthropic.com`, as a Bearer token. Nowhere else.
- **What is stored:** nothing on disk. Last values are kept in memory only.
- **Telemetry:** none. No analytics, no crash reports, no auto-update pings.
- **Auditable:** ~550 lines of Swift in [`Sources/ClaudeUsageBar`](../tree/main/Sources/ClaudeUsageBar).

Report vulnerabilities privately — see [SECURITY.md](../blob/main/SECURITY.md).

Never share screenshots or logs that include your token.
