# Roadmap

## v0.1 — Alive mascot ✅
- ✅ **Menu-bar alert**: alternates two frames (shake + hands up) at 80–99% and pulses at 90–99%. Timer only runs in that state; disabled with *Reduce Motion*.
- ✅ **Clickable mascot**: random reaction (hop, wave, spin, love) + light haptic; party every 10th click.
- ✅ **"Window renewed" celebration**: confetti state + "Your limit is back!" notification.
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
