# Security Policy

## What the app touches

- Reads the **Claude Code OAuth token** from your macOS Keychain (item `Claude Code-credentials`) via `/usr/bin/security`.
- Sends it **only** to `https://api.anthropic.com/api/oauth/usage` as a Bearer token.
- Keeps nothing on disk. No telemetry.

## Trust model

The token belongs to your Claude Code login and carries that login's full scope. Only install Claude Usage Bar from **source you built yourself** or from the **official GitHub releases** of this repository, and verify the checksum (see below). Releases are not yet signed or notarized.

## Reporting a vulnerability

Please **do not open a public issue** for security problems. Use GitHub's **"Report a vulnerability"** (Security tab → Advisories) on this repository. You'll get a response within a few days.

## Supported versions

Only the latest release receives fixes.

## Verifying downloads

Each release publishes `SHA256SUMS.txt`:

```bash
shasum -a 256 -c SHA256SUMS.txt
```
