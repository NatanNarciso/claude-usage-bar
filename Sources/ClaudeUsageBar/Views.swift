import SwiftUI

// MARK: - Cores semânticas (sem amarelo)

func usageColor(_ pct: Double) -> Color {
    pct >= 90 ? Color(red: 1.00, green: 0.27, blue: 0.23)
        : pct >= 70 ? Color(red: 1.00, green: 0.58, blue: 0.04)
        : Color(red: 0.20, green: 0.78, blue: 0.35)
}

/// Gradiente do arco, sempre dentro da mesma família de cor do nível.
func ringGradientColors(_ pct: Double) -> [Color] {
    switch pct {
    case ..<70: [Color(red: 0.30, green: 0.85, blue: 0.62), Color(red: 0.20, green: 0.78, blue: 0.35)]
    case ..<90: [Color(red: 1.00, green: 0.66, blue: 0.20), Color(red: 1.00, green: 0.45, blue: 0.10)]
    default:    [Color(red: 1.00, green: 0.42, blue: 0.30), Color(red: 0.92, green: 0.16, blue: 0.28)]
    }
}

func countdown(to date: Date, now: Date) -> String {
    let s = max(0, Int(date.timeIntervalSince(now)))
    let d = s / 86400, h = (s % 86400) / 3600, m = (s % 3600) / 60
    if d > 0 { return "\(d)d \(h)h" }
    if h > 0 { return "\(h)h \(m)min" }
    return "\(m)min"
}

struct Forecast {
    var title: String
    var detail: String
    var icon: String
    var color: Color
}

/// Projeta o ritmo médio da janela (uso ÷ tempo decorrido) até o reset.
func forecast(_ w: UsageWindow, now: Date) -> Forecast {
    let reset = w.resetsAt.formatted(date: .omitted, time: .shortened)
    if w.utilization >= 100 {
        return Forecast(title: "Limite atingido",
                        detail: "Você poderá usar de novo às \(reset).",
                        icon: "moon.zzz.fill", color: usageColor(100))
    }
    let start = w.resetsAt.addingTimeInterval(-5 * 3600)
    let elapsed = now.timeIntervalSince(start)
    guard w.utilization >= 1, elapsed >= 300 else {
        return Forecast(title: "Tudo tranquilo",
                        detail: "Ainda sem uso relevante nesta janela.",
                        icon: "leaf.fill", color: usageColor(0))
    }
    let rate = w.utilization / elapsed                       // % por segundo
    let hit = now.addingTimeInterval((100 - w.utilization) / rate)
    if hit < w.resetsAt {
        return Forecast(title: "Ritmo acelerado",
                        detail: "Mantendo esse ritmo, o limite acaba às \(hit.formatted(date: .omitted, time: .shortened)), antes de renovar.",
                        icon: "bolt.fill", color: usageColor(hit.timeIntervalSince(now) < 3600 ? 95 : 75))
    }
    let leftAtReset = max(0, 100 - (w.utilization + rate * w.resetsAt.timeIntervalSince(now)))
    return Forecast(title: "Ritmo tranquilo",
                    detail: "Mantendo esse ritmo, você chega ao reset com cerca de \(Int(leftAtReset))% sobrando.",
                    icon: "checkmark", color: usageColor(0))
}

// MARK: - Barra de menu

struct MenuLabel: View {
    @ObservedObject var service: UsageService

    var body: some View {
        HStack(spacing: 5) {
            Image(nsImage: mascotImage)
            Text(service.fiveHour.map { "\(Int($0.utilization))%" } ?? "–")
        }
    }

    // Mascote estático (colorido, não-template) com o tanque no nível atual.
    private var mascotImage: NSImage {
        let used = service.fiveHour?.utilization ?? 0
        let dark = NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        let r = ImageRenderer(content:
            Mascot(used: used, level: used, unit: 1.3, animated: false)
                .environment(\.colorScheme, dark ? .dark : .light))
        r.scale = 3
        let img = r.nsImage ?? NSImage()
        img.isTemplate = false
        return img
    }
}

// MARK: - Anel + mascote

struct RingView: View {
    let window: UsageWindow
    @State private var shown: Double = 0

    var body: some View {
        let p = max(0.001, shown / 100)
        let colors = ringGradientColors(window.utilization)
        ZStack {
            Circle().stroke(Color.primary.opacity(0.08), lineWidth: 12)
            Circle()
                .trim(from: 0, to: p)
                .stroke(
                    AngularGradient(colors: colors, center: .center,
                                    startAngle: .degrees(0), endAngle: .degrees(max(1, 360 * p))),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: colors.last!.opacity(0.35), radius: 6)
            VStack(spacing: 2) {
                Mascot(used: shown, level: window.utilization, unit: 4)
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text("\(Int(window.utilization))")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .contentTransition(.numericText(value: window.utilization))
                    Text("%")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .offset(y: 4)
        }
        .frame(width: 184, height: 184)
        .onAppear { withAnimation(.easeOut(duration: 1.1)) { shown = window.utilization } }
        .onChange(of: window.utilization) { _, v in withAnimation(.spring(duration: 0.8)) { shown = v } }
    }
}

// MARK: - Componentes estilo Apple

struct Tile: View {
    let icon: String
    let color: Color
    var body: some View {
        Image(systemName: icon)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(color.gradient, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

struct GradientBar: View {
    let pct: Double
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.10))
                Capsule()
                    .fill(LinearGradient(colors: ringGradientColors(pct), startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(6, g.size.width * pct / 100))
                    .animation(.spring(duration: 0.8), value: pct)
            }
        }
        .frame(height: 6)
    }
}

struct CoralButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(Brand.coral.opacity(configuration.isPressed ? 0.8 : 1),
                        in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Painel

struct PopoverView: View {
    @ObservedObject var service: UsageService

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { ctx in
            VStack(spacing: 16) {
                HStack {
                    Text("Claude Code").font(.headline)
                    Spacer()
                    Text("Pro")
                        .font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        .padding(.horizontal, 8).padding(.vertical, 2)
                        .background(Color.primary.opacity(0.08), in: Capsule())
                }

                if let five = service.fiveHour {
                    VStack(spacing: 14) {
                        RingView(window: five)
                        VStack(spacing: 2) {
                            Text("Restam \(Int(five.remaining))%")
                                .font(.title3.weight(.semibold))
                            Text("Renova em \(countdown(to: five.resetsAt, now: ctx.date))")
                                .font(.subheadline).foregroundStyle(.secondary)
                        }
                    }
                } else if service.errorMessage == nil {
                    ProgressView().padding(60)
                }

                if let five = service.fiveHour {
                    let f = forecast(five, now: ctx.date)
                    VStack(spacing: 0) {
                        HStack(alignment: .top, spacing: 12) {
                            Tile(icon: f.icon, color: f.color)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(f.title).font(.subheadline.weight(.semibold))
                                Text(f.detail).font(.footnote).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(12)

                        if let week = service.sevenDay {
                            Divider().padding(.leading, 54)
                            HStack(alignment: .top, spacing: 12) {
                                Tile(icon: "calendar", color: .blue)
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text("Esta semana").font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Text("\(Int(week.utilization))%")
                                            .font(.subheadline.weight(.semibold).monospacedDigit())
                                            .foregroundStyle(usageColor(week.utilization))
                                    }
                                    GradientBar(pct: week.utilization)
                                    Text("Renova em \(countdown(to: week.resetsAt, now: ctx.date))")
                                        .font(.footnote).foregroundStyle(.secondary)
                                }
                            }
                            .padding(12)
                        }
                    }
                    .background(Color.primary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }

                if let err = service.errorMessage {
                    Text(err).font(.footnote).foregroundStyle(.red).multilineTextAlignment(.center)
                }

                VStack(spacing: 10) {
                    Button { service.refresh() } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .rotationEffect(.degrees(service.isLoading ? 360 : 0))
                                .animation(service.isLoading ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default,
                                           value: service.isLoading)
                            Text(service.isLoading ? "Atualizando…" : "Atualizar agora")
                        }
                    }
                    .buttonStyle(CoralButtonStyle())
                    .opacity(service.isLoading ? 0.65 : 1)
                    .disabled(service.isLoading)

                    HStack {
                        if let t = service.lastUpdate {
                            Text("Atualizado às \(t.formatted(date: .omitted, time: .shortened))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Sair") { NSApplication.shared.terminate(nil) }
                            .buttonStyle(.plain).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .padding(20)
            .frame(width: 320)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.88))
        }
    }
}
