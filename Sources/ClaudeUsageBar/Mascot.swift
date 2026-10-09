import SwiftUI

enum Brand {
    /// Coral do botão (contraste suficiente com texto branco).
    static let coral = Color(red: 0.80, green: 0.38, blue: 0.25)
    /// Coral do mascote.
    static let mascot = Color(red: 0.85, green: 0.50, blue: 0.37)
    static let ink = Color(red: 0.10, green: 0.09, blue: 0.09)
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

/// O mascote é o medidor: o corpo é um "tanque" que esvazia conforme o uso,
/// e a expressão/animação muda com o nível (calmo → ocupado → suando → dormindo).
/// Grade 16×12 (corpo 14×10, braços nas laterais, 4 pernas), desenhada em Canvas.
struct Mascot: View, Animatable {
    var used: Double            // animável: controla o nível do tanque
    var level: Double           // valor real: define o humor
    var unit: CGFloat
    var animated = true

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
            canvas(t: 0)
        }
    }

    private func canvas(t: Double) -> some View {
        Canvas { gc, _ in draw(&gc, t: t) }
            .frame(width: 18 * unit, height: 14 * unit)
    }

    private func draw(_ gc: inout GraphicsContext, t: Double) {
        let u = unit
        let mood = Mood(level)

        var dx: CGFloat = 0, dy: CGFloat = 0
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

        func fill(_ c: CGFloat, _ r: CGFloat, _ w: CGFloat, _ h: CGFloat, _ color: Color) {
            let rect = CGRect(x: (1 + c) * u + dx, y: (1 + r) * u + dy, width: w * u, height: h * u)
            gc.fill(Path(rect), with: .color(color))
        }

        // Corpo-tanque: fundo esmaecido + preenchimento proporcional ao que resta.
        let remaining = CGFloat(max(0, min(100, 100 - used)))
        let fillRows = remaining / 100 * 10
        fill(1, 0, 14, 10, Brand.mascot.opacity(0.22))
        fill(1, 10 - fillRows, 14, fillRows, Brand.mascot)

        // Pernas (marcham quando o ritmo está alto).
        let step = Int(t * 4)
        for (i, c) in [1, 3, 12, 14].enumerated() {
            var h: CGFloat = 2
            if (mood == .busy || mood == .strained) && (i + step) % 2 == 0 { h = 1 }
            fill(CGFloat(c), 10, 1, h, Brand.mascot)
        }

        // Braços.
        var left: CGFloat = 3, right: CGFloat = 3
        switch mood {
        case .calm:
            if t.truncatingRemainder(dividingBy: 7) > 5.8 { right = Int(t * 4) % 2 == 0 ? 1 : 2 }   // acena
        case .busy:
            let s = Int(t * 3) % 2 == 0
            left = s ? 3 : 4; right = s ? 4 : 3                                                    // "digitando"
        case .strained:
            left = 1; right = 1                                                                    // mãos pra cima
        case .asleep:
            left = 5; right = 5
        }
        fill(0, left, 1, 2, Brand.mascot)
        fill(15, right, 1, 2, Brand.mascot)

        // Olhos (claros quando caem na parte vazia do tanque, no tema escuro).
        let eyeOnFill = (10 - fillRows) <= 3.5
        let eye = eyeOnFill || scheme == .light ? Brand.ink : Color.white.opacity(0.92)
        let blinking = animated && t.truncatingRemainder(dividingBy: 4.3) > 4.15
        for c in [4, 11] {
            let c = CGFloat(c)
            switch mood {
            case .asleep:   fill(c - 0.5, 4, 2, 1, eye)
            case .strained: fill(c - 0.5, 3, 2, 2, eye)
            default:        blinking ? fill(c, 4, 1, 1, eye) : fill(c, 3, 1, 2, eye)
            }
        }

        // Gota de suor.
        if mood == .strained {
            let k = t.truncatingRemainder(dividingBy: 1.2) / 1.2
            fill(13, CGFloat(k) * 4, 1, 2, Color(red: 0.55, green: 0.80, blue: 1.0).opacity(1 - k * 0.7))
        }

        // Zzz.
        if mood == .asleep {
            for i in 0..<2 {
                let k = (t * 0.5 + Double(i) * 0.5).truncatingRemainder(dividingBy: 1)
                let text = Text("z")
                    .font(.system(size: u * (2.4 + CGFloat(i)), weight: .bold, design: .rounded))
                    .foregroundStyle(Color.secondary.opacity(1 - k))
                gc.draw(text, at: CGPoint(x: 15 * u + CGFloat(k) * u * 2, y: 4 * u - CGFloat(k) * u * 3))
            }
        }
    }
}
