# Architecture

Claude Usage Bar is a single-target SwiftUI menu-bar app (~800 lines, no dependencies). It is built with plain `swiftc` + a shell script, so only the Xcode Command Line Tools are needed.

## Data flow

```
Keychain ──(security CLI)──▶ UsageService ──▶ api.anthropic.com/api/oauth/usage
                                  │
                         @Published state
                                  │
        ┌─────────────────────────┼──────────────────────────┐
   MenuLabel (bar icon)      PopoverView (panel)       Notifications
```

## Files

| File | Responsibility |
|---|---|
| `App.swift` | `@main`, `MenuBarExtra` with window style; one `UsageService` |
| `UsageService.swift` | Reads the token, polls every 90 s, publishes `fiveHour` / `sevenDay`, thresholds (80/95%), renewal detection, animation and hover timers, launch-at-login (`SMAppService`) |
| `Views.swift` | `MenuLabel` (renders the mascot to an `NSImage` via `ImageRenderer`), `PopoverView`, `RingView`, forecast, grouped-list components |
| `Mascot.swift` | 16×12 pixel sprite in `Canvas`: tank fill, moods, reactions, celebration, confetti |
| `Localization.swift` + `Resources/*.lproj` | `L("key")` helper; English default, Portuguese |
| `tools/` + `scripts/` | Renderers for README GIFs/screenshots, `.dmg` packaging, wiki publishing |

## Key decisions

- **Mascot = gauge.** Remaining limit is the filled part of the body (`10 − fillRows`); mood is derived from *used* (`Mood(level)`): <45 calm, <80 busy, <100 strained, 100 asleep.
- **`Mascot` is `Animatable`** on `used`, so the tank fills smoothly when the ring animates. `level` (real value) is separate so mood doesn't flicker mid-animation.
- **Deterministic frames.** Every animation is a pure function of time `t` (`draw(t:)`). The popover feeds it `TimelineView(.animation)`; the menu bar and GIF/screenshot tools pass a fixed `time`, so the same code renders live UI, menu-bar frames and docs assets.
- **Menu-bar icon is an image** (not a template) so colors survive. It is re-rendered only when state changes; alert/celebration use a 0.4 s timer that exists **only** while needed, and hover uses a 0.15 s timer **only** while the cursor is over the icon. Everything honours *Reduce Motion*.
- **Hover** has no SwiftUI API for status items, so mouse-moved monitors (global + local) are compared with the status item window's frame.
- **Renewal detection**: the 5-hour `resets_at` jumps forward by >10 min between polls.
- **Forecast** uses the average pace of the current window (`utilization / elapsed`); a rolling window is on the roadmap.
- **No telemetry, no persistence.** Values live in memory; the token is never stored or logged.
- **Build**: `swiftc` directly (SwiftPM from the Command Line Tools fails to link its manifest on this setup) + ad-hoc `codesign`; `LSUIElement` hides the Dock icon.

## Testing notes

There is no unit-test target yet (XCTest needs full Xcode). Behaviour is verified by rendering frames (`scripts/make-gif.sh`, `scripts/make-screenshots.sh`) and by simulating mouse movement for hover. Candidates for tests once Xcode is available: `forecast()`, `detectRenewal`, `window()` date parsing.
