# Security Policy

## What the app touches

- Reads the **Claude Code OAuth token** from your macOS Keychain (item `Claude Code-credentials`) via `/usr/bin/security`.
- Sends it **only** to `https://api.anthropic.com/api/oauth/usage` as a Bearer token.
- Keeps nothing on disk. No telemetry.

## Reporting a vulnerability

Please **do not open a public issue** for security problems. Use GitHub's **"Report a vulnerability"** (Security tab → Advisories) on this repository. You'll get a response within a few days.

## Supported versions

Only the latest release receives fixes.

## Verifying downloads

Each release publishes `SHA256SUMS.txt`:

```bash
shasum -a 256 -c SHA256SUMS.txt
```
