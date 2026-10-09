import SwiftUI
import ImageIO
import UniformTypeIdentifiers

// Gera docs/assets/mascot-states.gif a partir do próprio Mascot.swift.
// Uso: scripts/make-gif.sh

struct Sheet: View {
    var t: Double
    let states: [(String, Double)] = [("Calm", 19), ("Busy", 62), ("Sweating", 88), ("Asleep", 100)]
    var body: some View {
        HStack(spacing: 30) {
            ForEach(states, id: \.0) { s in
                VStack(spacing: 10) {
                    Mascot(used: s.1, level: s.1, unit: 8, animated: false, time: t)
                    Text(s.0).font(.system(size: 17, weight: .semibold, design: .rounded)).foregroundStyle(.white)
                    Text("\(Int(s.1))% used").font(.system(size: 13)).foregroundStyle(.white.opacity(0.55))
                }
            }
        }
        .padding(.horizontal, 36).padding(.vertical, 30)
        .background(Color(red: 0.13, green: 0.14, blue: 0.17))
        .environment(\.colorScheme, .dark)
    }
}

@main
struct RenderGIF {
    @MainActor static func main() {
        let out = CommandLine.arguments[1]
        let fps = 12.0, seconds = 8.0
        let n = Int(fps * seconds)
        guard let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL,
                                                         UTType.gif.identifier as CFString, n, nil) else { exit(1) }
        CGImageDestinationSetProperties(dest, [kCGImagePropertyGIFDictionary as String:
                                                [kCGImagePropertyGIFLoopCount as String: 0]] as CFDictionary)
        for i in 0..<n {
            let r = ImageRenderer(content: Sheet(t: Double(i) / fps))
            r.scale = 1.5
            guard let cg = r.cgImage else { continue }
            CGImageDestinationAddImage(dest, cg, [kCGImagePropertyGIFDictionary as String:
                                                    [kCGImagePropertyGIFDelayTime as String: 1.0 / fps]] as CFDictionary)
        }
        print(CGImageDestinationFinalize(dest) ? "OK \(out)" : "FAIL")
    }
}
