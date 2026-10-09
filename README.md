<div align="center">

# Claude Usage Bar

**A tiny pixel mascot that lives in your Mac's menu bar and shows how much of your Claude Code limit you've burned.**

[English](README.md) · [Português](README.pt-BR.md)

<img src="docs/assets/mascot-states.png" alt="The four mascot states: calm, busy, sweating, asleep" width="720">

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-black?logo=apple)
![Swift](https://img.shields.io/badge/Swift-6-orange?logo=swift)
![License: MIT](https://img.shields.io/badge/license-MIT-blue)
![No telemetry](https://img.shields.io/badge/telemetry-none-brightgreen)

</div>

---

Ever been deep in a Claude Code session and hit the limit with no warning? **Claude Usage Bar** puts your 5-hour window and weekly limit one glance away — and makes it fun.

The mascot **is** the gauge: its body is a tank that drains as you spend your limit, and its mood tells you how you're doing at a glance.

| Used | Mood | What it does |
|---|---|---|
| < 45% | 😌 Calm | Blinks, hops, sometimes waves |
| 45–80% | ⌨️ Busy | Types away, little legs marching |
| 80–99% | 😅 Sweating | Shakes, hands up, wide eyes, sweat drop |
| 100% | 😴 Asleep | Fully drained, eyes closed, *zzz* |

## Features

- 🟠 **Live menu-bar gauge** — the mascot icon + `%` of your 5-hour window, updated automatically
- 🎯 **Popover with details** — ring with gradient, "X% left", time until reset, weekly limit
- 🔮 **Pace forecast** — *"At this pace you'll hit the limit at 1:40 PM"* (or *"you'll reach reset with ~45% to spare"*)
- 🔔 **Notifications** at 80% and 95% (once per window)
- 🚀 **Launch at login**
- 🪶 **Tiny** — ~0% CPU, a few MB of RAM, one network request every 90 s
- 🔒 **Private** — no telemetry, no accounts, no third-party servers (see [Privacy](#privacy))

## Install

> The app is not yet notarized by Apple (that needs a paid developer account), so macOS will warn you the first time.

1. Download the latest `ClaudeUsageBar-x.y.z.dmg` from [**Releases**](../../releases).
2. Drag **Claude Usage** to **Applications**.
3. First launch: **right-click → Open → Open** (or run `xattr -dr com.apple.quarantine "/Applications/Claude Usage.app"`).
4. Allow the **Keychain** prompt (to read your Claude Code login) and **notifications**.

You can also [build from source](#build-from-source) — it takes ~10 seconds and needs no Xcode.

**Requirements:** macOS 14 Sonoma or later · [Claude Code](https://claude.com/claude-code) installed and logged in.

## How it works

Claude Code stores its login in your macOS Keychain. Claude Usage Bar reads that token and asks the same usage endpoint that Claude Code's own `/usage` command uses, then draws the result. That's all.

> ⚠️ That endpoint is **undocumented** and may change without notice. If it does, the app shows the last known value plus an error. See [How it works](../../wiki/How-it-works) for details.

## Privacy

- Your token is read from the Keychain **locally** and sent **only** to `api.anthropic.com` — never stored, logged or sent anywhere else.
- No analytics, no crash reporting, no telemetry.
- The code is ~600 lines of Swift. Read it: [`Sources/ClaudeUsageBar`](Sources/ClaudeUsageBar).

More in [Privacy & Security](../../wiki/Privacy-and-Security) and [SECURITY.md](SECURITY.md).

## Build from source

```bash
git clone https://github.com/YOUR_USER/claude-usage-bar.git
cd claude-usage-bar
./build.sh --install     # builds, copies to ~/Applications and launches
./scripts/make-dmg.sh    # optional: creates dist/*.dmg and .zip
```

Only the Xcode **Command Line Tools** (Swift 5.9+) are required.

## Roadmap

See [docs/ROADMAP.md](docs/ROADMAP.md). Next up: menu-bar pulse at >90%, clickable mascot reactions, "limit renewed" celebration, English/Portuguese localization, signed & notarized releases.

## Contributing

PRs and ideas are very welcome — especially new mascot animations! Read [CONTRIBUTING.md](CONTRIBUTING.md).

## Disclaimer

Claude Usage Bar is an **unofficial, community project**. It is not affiliated with, endorsed by, or sponsored by Anthropic. "Claude" and "Claude Code" are trademarks of Anthropic, PBC. The pixel mascot is an homage to the Claude Code terminal character.

## License

[MIT](LICENSE)
