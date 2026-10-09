import SwiftUI
import ImageIO
import UniformTypeIdentifiers

// Gera os GIFs de docs/assets a partir do próprio Mascot.swift.
// Uso: scripts/make-gif.sh

let bg = Color(red: 0.13, green: 0.14, blue: 0.17)

func caption(_ title: String, _ sub: String) -> some View {
    VStack(spacing: 3) {
        Text(title).font(.system(size: 17, weight: .semibold, design: .rounded)).foregroundStyle(.white)
        Text(sub).font(.system(size: 13)).foregroundStyle(.white.opacity(0.55))
    }
}

/// 1) Os quatro humores.
struct StatesSheet: View {
    var t: Double
    let states: [(String, Double)] = [("Calm", 19), ("Busy", 62), ("Sweating", 88), ("Asleep", 100)]
    var body: some View {
        HStack(spacing: 30) {
            ForEach(states, id: \.0) { s in
                VStack(spacing: 10) {
                    Mascot(used: s.1, level: s.1, unit: 8, animated: false, time: t)
                    caption(s.0, "\(Int(s.1))% used")
                }
            }
        }
        .padding(.horizontal, 36).padding(.vertical, 30)
        .background(bg).environment(\.colorScheme, .dark)
    }
}

/// 2) Reações ao clique + comemoração. Cada uma repete no próprio ritmo (período 3 s).
struct ReactionsSheet: View {
    var t: Double
    let items: [(String, ReactionKind)] = [("Hop", .hop), ("Wave", .wave), ("Spin", .spin), ("Love", .love), ("Party", .party)]
    var body: some View {
        HStack(spacing: 22) {
            ForEach(items, id: \.0) { item in
                VStack(spacing: 10) {
                    Mascot(used: 24, level: 24, unit: 7, animated: false,
                           time: t.truncatingRemainder(dividingBy: 3.0),
                           reaction: MascotReaction(kind: item.1, start: 0.3))
                    caption(item.0, "click!")
                }
            }
        }
        .padding(.horizontal, 30).padding(.vertical, 28)
        .background(bg).environment(\.colorScheme, .dark)
    }
}

/// 3) Barra de menu: 70% (parado), 88% (treme), 95% (treme + pulsa), comemorando.
struct MenuBarSheet: View {
    var t: Double
    var pulse: Bool { Int(t / 0.4) % 2 == 1 }
    let items: [(String, Double, Bool)] = [("70%", 70, false), ("88%", 88, false), ("95%", 95, false), ("Renewed!", 100, true)]
    var body: some View {
        VStack(spacing: 14) {
            ForEach(items, id: \.0) { item in
                let used = item.2 ? 100.0 : item.1
                let animating = (used >= 80 && used < 100) || item.2
                HStack(spacing: 8) {
                    Mascot(used: item.2 ? 5 : used, level: item.2 ? 5 : used, unit: 3, animated: false,
                           time: animating && pulse ? 0.25 : 0, celebrating: item.2)
                        .opacity(used >= 90 && used < 100 && pulse ? 0.5 : 1)
                    Text(item.2 ? "5%" : item.0).font(.system(size: 22, weight: .medium)).foregroundStyle(.white)
                    Spacer()
                    Text(item.2 ? "Renewed!" : "").font(.system(size: 14)).foregroundStyle(.white.opacity(0.6))
                }
                .padding(.horizontal, 16).padding(.vertical, 4)
                .frame(width: 300)
                .background(Color.black.opacity(0.45), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(24)
        .background(LinearGradient(colors: [Color(red: 0.2, green: 0.25, blue: 0.5), Color(red: 0.35, green: 0.2, blue: 0.45)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
        .environment(\.colorScheme, .dark)
    }
}

@MainActor
func makeGIF<V: View>(_ path: String, seconds: Double, fps: Double = 12, scale: CGFloat = 1.5, _ content: (Double) -> V) {
    let n = Int(fps * seconds)
    guard let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL,
                                                     UTType.gif.identifier as CFString, n, nil) else { exit(1) }
    CGImageDestinationSetProperties(dest, [kCGImagePropertyGIFDictionary as String:
                                            [kCGImagePropertyGIFLoopCount as String: 0]] as CFDictionary)
    for i in 0..<n {
        let r = ImageRenderer(content: content(Double(i) / fps))
        r.scale = scale
        guard let cg = r.cgImage else { continue }
        CGImageDestinationAddImage(dest, cg, [kCGImagePropertyGIFDictionary as String:
                                                [kCGImagePropertyGIFDelayTime as String: 1.0 / fps]] as CFDictionary)
    }
    print(CGImageDestinationFinalize(dest) ? "OK \(path)" : "FAIL \(path)")
}

@main
struct RenderGIF {
    @MainActor static func main() {
        let dir = CommandLine.arguments[1]
        makeGIF("\(dir)/mascot-states.gif", seconds: 8) { StatesSheet(t: $0) }
        makeGIF("\(dir)/mascot-reactions.gif", seconds: 6) { ReactionsSheet(t: $0) }
        makeGIF("\(dir)/mascot-menubar.gif", seconds: 4.8) { MenuBarSheet(t: $0) }
    }
}
