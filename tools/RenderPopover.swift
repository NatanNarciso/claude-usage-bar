import SwiftUI
import AppKit

// Gera docs/assets/popover-<idioma>-<tema>.png com o PopoverView real e dados de exemplo.
// Uso: scripts/make-screenshots.sh

@MainActor
struct Shot {
    static func render(lang: String, dark: Bool, used: Double, week: Double, to path: String) {
        localizationBundle = Bundle(path: "Resources/\(lang).lproj")!
        UsageService.snapshotMode = true
        let now = Date()
        // Janela de 5h com ~2h40 decorridas, o que dá uma previsão realista.
        let five = UsageWindow(utilization: used, resetsAt: now.addingTimeInterval(2 * 3600 + 20 * 60))
        let seven = UsageWindow(utilization: week, resetsAt: now.addingTimeInterval(3 * 86400))
        let svc = UsageService(sampleFive: five, sampleSeven: seven)
        let view = PopoverView(service: svc)
            .background(dark ? Color(red: 0.16, green: 0.16, blue: 0.18) : Color(red: 0.96, green: 0.96, blue: 0.97))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .environment(\.colorScheme, dark ? .dark : .light)
            .padding(24)
        let r = ImageRenderer(content: view)
        r.scale = 2
        if let img = r.nsImage, let tiff = img.tiffRepresentation,
           let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
            try? png.write(to: URL(fileURLWithPath: path))
            print("OK \(path)")
        }
    }
}

@main
struct RenderPopover {
    @MainActor static func main() {
        _ = NSApplication.shared
        for lang in ["en", "pt"] {
            for dark in [true, false] {
                Shot.render(lang: lang, dark: dark, used: 24, week: 52,
                            to: "docs/assets/popover-\(lang)-\(dark ? "dark" : "light").png")
            }
        }
    }
}
