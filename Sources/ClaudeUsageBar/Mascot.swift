import SwiftUI

enum Brand {
    /// Coral do botão (contraste suficiente com texto branco).
    static let coral = Color(red: 0.80, green: 0.38, blue: 0.25)
    /// Coral do mascote.
    static let mascot = Color(red: 0.85, green: 0.50, blue: 0.37)
    static let ink = Color(red: 0.10, green: 0.09, blue: 0.09)
    static let pink = Color(red: 1.0, green: 0.38, blue: 0.55)
}

enum Mood {
    case calm, busy, strained, asleep
    init(_ used: Double) {
        switch used {
        case ..<45: self = .calm
        case ..<80: self = .busy
        case ..<100: self = .strained
        default: self = .asleep
        }
    }
}

/// Reações de um toque no mascote.
enum ReactionKind: CaseIterable {
    case hop, wave, spin, love, party

    var duration: Double {
        switch self {
        case .hop: 1.0
        case .wave: 1.6
        case .spin: 1.0
        case .love: 2.0
        case .party: 2.5
        }
    }
}

struct MascotReaction: Equatable {
    var kind: ReactionKind
    var start: Double          // timeIntervalSinceReferenceDate
}

/// O mascote é o medidor: o corpo é um "tanque" que esvazia conforme o uso,
/// e a expressão/animação muda com o nível (calmo → ocupado → suando → dormindo).
/// Também reage a toques (`reaction`) e comemora quando a janela renova (`celebrating`).
/// Grade 16×12 (corpo 14×10, braços nas laterais, 4 pernas), desenhada em Canvas.
struct Mascot: View, Animatable {
    var used: Double            // animável: controla o nível do tanque
    var level: Double           // valor real: define o humor
    var unit: CGFloat
    var animated = true
    var time: Double? = nil     // instante fixo (usado para gerar GIFs/quadros e na barra de menu)
    var reaction: MascotReaction? = nil
    var celebrating = false

    var animatableData: Double {
        get { used }
        set { used = newValue }
    }

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        if animated {
            TimelineView(.animation) { ctx in
                canvas(t: ctx.date.timeIntervalSinceReferenceDate)
            }
        } else {
            canvas(t: time ?? 0)
        }
    }

    private func canvas(t: Double) -> some View {
        Canvas { gc, _ in draw(&gc, t: t) }
            .frame(width: 18 * unit, height: 14 * unit)
    }

    private func draw(_ gc: inout GraphicsContext, t: Double) {
        let u = unit
        let mood = Mood(level)

        // Reação ativa (se houver).
        var kind: ReactionKind? = nil
        var rp = 0.0
        if let r = reaction, t >= r.start, t - r.start < r.kind.duration {
            kind = r.kind
            rp = (t - r.start) / r.kind.duration
        }
        let party = celebrating || kind == .party
        let happy = kind != nil || celebrating

        var dx: CGFloat = 0, dy: CGFloat = 0
        if party {
            dy = -CGFloat((abs(sin(t * .pi * 3)) * 2).rounded()) * u
        } else if kind == .hop {
            dy = -CGFloat((abs(sin(rp * .pi * 2)) * 3).rounded()) * u
        } else if kind == nil {
            switch mood {
            case .calm:
                if t.truncatingRemainder(dividingBy: 2.4) / 2.4 < 0.10 { dy = -u }
            case .busy:
                if t.truncatingRemainder(dividingBy: 1.2) / 1.2 < 0.12 { dy = -u }
            case .strained:
                dx = (Int(t * 14) % 2 == 0 ? 0.4 : -0.4) * u
            case .asleep:
                break
            }
        }

        // Giro: "vira" o sprite em torno do eixo vertical.
        if kind == .spin {
            var sx = cos(rp * .pi * 4)
            if abs(sx) < 0.08 { sx = sx < 0 ? -0.08 : 0.08 }
            gc.translateBy(x: 9 * u, y: 0)
            gc.scaleBy(x: sx, y: 1)
            gc.translateBy(x: -9 * u, y: 0)
        }

        func fill(_ c: CGFloat, _ r: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color) {
            let rect = CGRect(x: (1 + c) * u + dx, y: (1 + r) * u + dy, width: w * u, height: h * u)
            gc.fill(Path(rect), with: .color(color))
        }

        // Corpo-tanque: fundo esmaecido + preenchimento proporcional ao que resta.
        let remaining = CGFloat(max(0, min(100, 100 - used)))
        let fillRows = remaining / 100 * 10
        fill(1, 0, 14, 10, Brand.mascot.opacity(0.22))
        fill(1, 10 - fillRows, 14, fillRows, Brand.mascot)

        // Pernas (marcham quando o ritmo está alto ou em festa).
        let step = Int(t * (party ? 6 : 4))
        for (i, c) in [1, 3, 12, 14].enumerated() {
            var h: CGFloat = 2
            if (mood == .busy || mood == .strained || party) && (i + step) % 2 == 0 { h = 1 }
            fill(CGFloat(c), 10, 1, h, Brand.mascot)
        }

        // Braços.
        var left: CGFloat = 3, right: CGFloat = 3
        if party {
            let s = Int(t * 6) % 2 == 0
            left = s ? 1 : 2; right = s ? 2 : 1                                                    // mãos pro alto
        } else if kind == .wave {
            right = Int(t * 8) % 2 == 0 ? 0 : 1                                                    // aceno largo
        } else if kind != nil {
            left = 2; right = 2
        } else {
            switch mood {
            case .calm:
                if t.truncatingRemainder(dividingBy: 7) > 5.8 { right = Int(t * 4) % 2 == 0 ? 1 : 2 }
            case .busy:
                let s = Int(t * 3) % 2 == 0
                left = s ? 3 : 4; right = s ? 4 : 3
            case .strained:
                left = 1; right = 1
            case .asleep:
                left = 5; right = 5
            }
        }
        fill(0, left, 1, 2, Brand.mascot)
        fill(15, right, 1, 2, Brand.mascot)

        // Olhos (claros quando caem na parte vazia do tanque, no tema escuro).
        let eyeOnFill = (10 - fillRows) <= 3.5
        let eye = eyeOnFill || scheme == .light ? Brand.ink : Color.white.opacity(0.92)
        let blinking = (animated || time != nil) && t.truncatingRemainder(dividingBy: 4.3) > 4.15
        for c in [4, 11] {
            let c = CGFloat(c)
            if happy {                                   // olhos felizes: ^ ^
                fill(c - 1, 4, 1, 1, eye); fill(c, 3, 1, 1, eye); fill(c + 1, 4, 1, 1, eye)
                continue
            }
            switch mood {
            case .asleep:   fill(c - 0.5, 4, 2, 1, eye)
            case .strained: fill(c - 0.5, 3, 2, 2, eye)
            default:        blinking ? fill(c, 4, 1, 1, eye) : fill(c, 3, 1, 2, eye)
            }
        }

        // Gota de suor.
        if mood == .strained && !happy {
            let k = t.truncatingRemainder(dividingBy: 1.2) / 1.2
            fill(13, CGFloat(k) * 4, 1, 2, Color(red: 0.55, green: 0.80, blue: 1.0).opacity(1 - k * 0.7))
        }

        // Zzz.
        if mood == .asleep && !happy {
            for i in 0..<2 {
                let k = (t * 0.5 + Double(i) * 0.5).truncatingRemainder(dividingBy: 1)
                let text = Text("z")
                    .font(.system(size: u * (2.4 + CGFloat(i)), weight: .bold, design: .rounded))
                    .foregroundStyle(Color.secondary.opacity(1 - k))
                gc.draw(text, at: CGPoint(x: 15 * u + CGFloat(k) * u * 2, y: 4 * u - CGFloat(k) * u * 3))
            }
        }

        // Corações subindo.
        if kind == .love {
            let heart = ["01010", "11111", "01110", "00100"]
            for i in 0..<3 {
                let k = (rp * 1.6 + Double(i) / 3).truncatingRemainder(dividingBy: 1)
                let hx = CGFloat(2 + i * 5) + CGFloat(sin(k * 6 + Double(i))) * 0.6
                let hy = 5 - CGFloat(k) * 8
                for (ri, row) in heart.enumerated() {
                    for (ci, ch) in row.enumerated() where ch == "1" {
                        fill(hx + CGFloat(ci) * 0.7, hy + CGFloat(ri) * 0.7, 0.7, 0.7, Brand.pink.opacity(1 - k * 0.8))
                    }
                }
            }
        }

        // Confete.
        if party {
            let palette: [Color] = [Brand.mascot, .mint, .cyan, Brand.pink, .orange, .purple]
            for i in 0..<16 {
                let seed = Double(i)
                let k = (t * 0.7 + seed * 0.173).truncatingRemainder(dividingBy: 1)
                let cx = CGFloat((i * 7) % 16) + CGFloat(sin(t * 3 + seed)) * 0.4
                fill(cx, CGFloat(k) * 13 - 1, 1, 1, palette[i % palette.count])
            }
        }
    }
}
