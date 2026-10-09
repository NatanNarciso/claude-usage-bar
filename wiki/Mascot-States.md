# Mascot states

The mascot is a 16×12 pixel sprite drawn with SwiftUI `Canvas`. Its body is a **tank**: the filled part equals the limit you have **left**.

| Used | Mood | Behaviour |
|---|---|---|
| < 45% | Calm | Blinks every ~4 s, hops, waves now and then |
| 45–79% | Busy | Arms alternate (typing), legs march |
| 80–99% | Sweating | Shakes, hands up, wide eyes, sweat drop |
| 100% | Asleep | Empty tank, closed eyes, floating *z z* |

Source: [`Mascot.swift`](../blob/main/Sources/ClaudeUsageBar/Mascot.swift). Want to add a new animation? See [CONTRIBUTING](../blob/main/CONTRIBUTING.md).

## Interactions

**Click the mascot** (popover) for a random one-shot reaction:

| Reaction | What it does |
|---|---|
| Hop | Two little jumps |
| Wave | Waves its right arm |
| Spin | Turns around |
| Love | Floating hearts |
| Party | Confetti — guaranteed on every 10th click |

Reactions also wake a sleeping mascot (happy eyes).

## Menu-bar alerts

| Used | Menu-bar mascot |
|---|---|
| 80–89% | Alternates two frames: shaking, hands up, sweat drop |
| 90–99% | Same, plus a soft pulse (opacity) |
| 100% | Asleep (static) |
| Window renewed | Celebrates for ~8 s (confetti) + "Your limit is back!" notification if you were at 80%+ |

The animation timer only runs while an alert or celebration is active, so idle cost stays ~0. It is disabled entirely when macOS **Reduce Motion** is on.

How renewal is detected: the 5-hour window's `resets_at` jumps forward by more than 10 minutes between two polls.
