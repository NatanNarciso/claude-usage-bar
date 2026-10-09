# Mascot states

The mascot is a 16×12 pixel sprite drawn with SwiftUI `Canvas`. Its body is a **tank**: the filled part equals the limit you have **left**.

| Used | Mood | Behaviour |
|---|---|---|
| < 45% | Calm | Blinks every ~4 s, hops, waves now and then |
| 45–79% | Busy | Arms alternate (typing), legs march |
| 80–99% | Sweating | Shakes, hands up, wide eyes, sweat drop |
| 100% | Asleep | Empty tank, closed eyes, floating *z z* |

Source: [`Mascot.swift`](../blob/main/Sources/ClaudeUsageBar/Mascot.swift). Want to add a new animation? See [CONTRIBUTING](../blob/main/CONTRIBUTING.md).
