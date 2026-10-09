# Roadmap

## v0.2 — Alive mascot
- **Menu-bar alert (>90%)**: the menu-bar mascot alternates two frames (shake + hands up) while usage ≥ 80%, and pulses ≥ 90%. Frames are pre-rendered and swapped by a timer that only runs in that state, so idle cost stays ~0.
- **Clickable mascot**: clicking it in the popover plays a random one-shot reaction (hop with squash, wave, spin, sparkles) + light haptic. Easter egg after 10 clicks.
- **"Window renewed" celebration**: when `resets_at` moves forward / usage drops sharply between polls, the mascot celebrates (confetti pixels, new `.celebrating` mood), and a notification says the limit is back.
- ✅ **Localization**: English (default) and Portuguese (`Resources/*.lproj`, follows macOS language).

## v0.3 — Reliability & insight
- Rolling pace forecast (last 30–60 min) instead of window average
- Usage history (local file) with a mini chart
- Local-log fallback (`~/.claude/projects`) when the API is unavailable
- Token refresh when the session expires
- Preferences window (refresh interval, thresholds)

## v1.0 — Distribution
- Developer ID signing + hardened runtime + notarization + stapled `.dmg` (needs Apple Developer Program)
- Homebrew tap (`brew install --cask`)
- Auto-update (Sparkle)

## Launch checklist
- [x] Mascot-states GIF and popover screenshots (`scripts/make-gif.sh`, `scripts/make-screenshots.sh`)
- [ ] Optional: real screen recording of the live popover
- [ ] Social preview image (1280×640) and repo topics: `macos`, `menubar`, `swiftui`, `claude`, `claude-code`, `anthropic`
- [ ] GitHub Release `v0.1.0` with `.dmg`, `.zip`, `SHA256SUMS.txt`
- [ ] Enable GitHub Wiki + run `scripts/publish-wiki.sh`
- [ ] Posts: Show HN, r/ClaudeAI, X/Twitter, dev.to, Product Hunt
- [x] Mascot stays; project is free/open source with an unofficial-project disclaimer
