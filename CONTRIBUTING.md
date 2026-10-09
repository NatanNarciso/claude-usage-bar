# Contributing

Thanks for helping! Ideas, bug reports, translations and **new mascot animations** are all welcome.

## Setup

```bash
./build.sh --install   # build + install + launch
```

Requires macOS 14+ and the Xcode Command Line Tools. No Xcode project needed.

## Project layout

| File | Purpose |
|---|---|
| `Sources/ClaudeUsageBar/UsageService.swift` | Keychain token, API call, thresholds, notifications |
| `Sources/ClaudeUsageBar/Views.swift` | Menu-bar label, popover, ring, forecast |
| `Sources/ClaudeUsageBar/Mascot.swift` | Pixel-art mascot (Canvas), moods and animations |
| `Sources/ClaudeUsageBar/Localization.swift` + `Resources/*.lproj` | Strings (English default, Portuguese) via `L("key")` |
| `build.sh` / `scripts/make-dmg.sh` | Build the `.app` and package `.dmg`/`.zip` |
| `scripts/make-gif.sh`, `scripts/make-screenshots.sh` | Regenerate README GIF and popover screenshots (`tools/`) |

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for data flow and design decisions.

## Guidelines

- **Never hardcode user-facing text**: add the key to **both** `en.lproj` and `pt.lproj`.
- Keep it **tiny and private**: no telemetry, no new network destinations, avoid dependencies.
- Match the existing code style; keep the UI native-feeling (SF fonts, system colors, HIG spacing).
- No yellow in status colors (green → orange → red).
- For UI changes, attach a screenshot or short clip to the PR.
- Never commit tokens, logs containing tokens, or real usage data.

## Pull requests

1. Open an issue first for big changes.
2. Branch from `main`, keep PRs focused.
3. Make sure `./build.sh` succeeds.
4. Fill in the PR template.

By contributing you agree your work is released under the [MIT License](LICENSE).
