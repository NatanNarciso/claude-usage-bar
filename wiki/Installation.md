# Installation

**Requirements:** macOS 14 Sonoma+, Claude Code installed and logged in (Pro or Max).

## From a release
1. Download `ClaudeUsageBar-x.y.z.dmg` from [Releases](../releases).
2. Verify (optional): `shasum -a 256 -c SHA256SUMS.txt`
3. Drag **Claude Usage** into **Applications** and open it.

### "Apple could not verify…" warning
Releases are not notarized yet (that requires a paid Apple Developer account). Either:
- **Right-click → Open → Open** the first time, or
- Run `xattr -dr com.apple.quarantine "/Applications/Claude Usage.app"`

### Permissions
- **Keychain**: macOS asks once so the app can read your Claude Code login. Choose *Always Allow* to avoid repeat prompts.
- **Notifications**: for the 80% / 95% alerts.

## Launch at login
The app registers itself as a login item on first launch (it must live in `/Applications` or `~/Applications`). Disable it in **System Settings → General → Login Items**.

## Uninstall
Quit from the popover (**Sair/Quit**), delete the app, and remove it from Login Items.
