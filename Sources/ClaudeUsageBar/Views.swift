import SwiftUI

// MARK: - Cores e helpers

func usageColor(_ pct: Double) -> Color {
    pct >= 90 ? .red : pct >= 70 ? .orange : .green
}

/// Gradiente do arco: começa em verde e termina na cor do nível atual.
func ringGradientColors(_ pct: Double) -> [Color] {
    switch pct {
    case ..<70: [Color.mint, Color.green]
    case ..<90: [Color.green, Color.yellow, Color.orange]
    default: [Color.orange, Color.red, Color(red: 1, green: 0.2, blue: 0.35)]
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
                        icon: "exclamationmark.octagon.fill", color: .red)
    }
    let start = w.resetsAt.addingTimeInterval(-5 * 3600)
    let elapsed = now.timeIntervalSince(start)
    guard w.utilization >= 1, elapsed >= 300 else {
        return Forecast(title: "Tudo tranquilo",
                        detail: "Ainda sem uso relevante nesta janela.",
                        icon: "leaf.fill", color: .green)
    }
    let rate = w.utilization / elapsed                       // % por segundo
    let hit = now.addingTimeInterval((100 - w.utilization) / rate)
    if hit < w.resetsAt {
        return Forecast(title: "Ritmo acelerado",
                        detail: "Mantendo esse ritmo, o limite acaba às \(hit.formatted(date: .omitted, time: .shortened)), antes de renovar.",
                        icon: "flame.fill", color: hit.timeIntervalSince(now) < 3600 ? .red : .orange)
    }
    let leftAtReset = max(0, 100 - (w.utilization + rate * w.resetsAt.timeIntervalSince(now)))
    return Forecast(title: "Ritmo tranquilo",
                    detail: "Mantendo esse ritmo, você chega ao reset com cerca de \(Int(leftAtReset))% sobrando.",
                    icon: "checkmark.seal.fill", color: .green)
}

// MARK: - Barra de menu

struct MiniRing: View {
    let pct: Double
    var body: some View {
        ZStack {
            Circle().stroke(Color.gray.opacity(0.35), lineWidth: 3)
            Circle()
                .trim(from: 0, to: max(0.02, pct / 100))
                .stroke(usageColor(pct), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 16, height: 16)
        .padding(1)
    }
}

struct MenuLabel: View {
    @ObservedObject var service: UsageService
    var body: some View {
        HStack(spacing: 4) {
            Image(nsImage: ringImage)
            Text(service.fiveHour.map { "\(Int($0.utilization))%" } ?? "–")
        }
    }

    // Renderiza o anel como imagem colorida (não-template) para manter as cores na barra.
    private var ringImage: NSImage {
        let r = ImageRenderer(content: MiniRing(pct: service.fiveHour?.utilization ?? 0))
        r.scale = 3
        let img = r.nsImage ?? NSImage()
        img.isTemplate = false
        return img
    }
}

// MARK: - Anel principal

struct RingView: View {
    let window: UsageWindow
    @State private var shown: Double = 0

    var body: some View {
        let p = max(0.001, shown / 100)
        let colors = ringGradientColors(window.utilization)
        ZStack {
            Circle().stroke(Color.primary.opacity(0.08), lineWidth: 16)
            Circle()
                .trim(from: 0, to: p)
                .stroke(
                    AngularGradient(colors: colors, center: .center,
                                    startAngle: .degrees(0), endAngle: .degrees(max(1, 360 * p))),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: colors.last!.opacity(0.45), radius: 8)
            VStack(spacing: 0) {
                Text("\(Int(window.utilization))%")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .contentTransition(.numericText(value: window.utilization))
                Text("usado").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(width: 140, height: 140)
        .onAppear { withAnimation(.easeOut(duration: 1.0)) { shown = window.utilization } }
        .onChange(of: window.utilization) { _, v in withAnimation(.spring(duration: 0.8)) { shown = v } }
    }
}

// MARK: - Cartões

struct Card<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08)))
    }
}

struct GradientBar: View {
    let pct: Double
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.primary.opacity(0.08))
                Capsule()
                    .fill(LinearGradient(colors: ringGradientColors(pct), startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(8, g.size.width * pct / 100))
                    .animation(.spring(duration: 0.8), value: pct)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Painel

struct PopoverView: View {
    @ObservedObject var service: UsageService

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { ctx in
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "sparkle").foregroundStyle(.orange)
                    Text("Claude Code").font(.headline)
                    Text("Pro").font(.caption2.weight(.semibold))
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2), in: Capsule())
                    Spacer()
                }

                if let five = service.fiveHour {
                    RingView(window: five).padding(.vertical, 4)
                    VStack(spacing: 2) {
                        Text("Restam \(Int(five.remaining))% nesta janela")
                            .font(.subheadline.weight(.semibold))
                        Text("Renova em \(countdown(to: five.resetsAt, now: ctx.date))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    let f = forecast(five, now: ctx.date)
                    Card {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: f.icon).font(.title3).foregroundStyle(f.color)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(f.title).font(.subheadline.weight(.semibold))
                                Text(f.detail).font(.caption).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                } else if service.errorMessage == nil {
                    ProgressView().padding(40)
                }

                if let week = service.sevenDay {
                    Card {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Semana").font(.subheadline.weight(.semibold))
                                Spacer()
                                Text("\(Int(week.utilization))%")
                                    .font(.subheadline.weight(.bold).monospacedDigit())
                                    .foregroundStyle(usageColor(week.utilization))
                            }
                            GradientBar(pct: week.utilization)
                            Text("Renova em \(countdown(to: week.resetsAt, now: ctx.date))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }

                if let err = service.errorMessage {
                    Text(err).font(.caption).foregroundStyle(.red).multilineTextAlignment(.center)
                }

                Button { service.refresh() } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(service.isLoading ? 360 : 0))
                            .animation(service.isLoading ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default,
                                       value: service.isLoading)
                        Text(service.isLoading ? "Atualizando…" : "Atualizar agora")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent).tint(.orange).controlSize(.large)
                .disabled(service.isLoading)

                HStack {
                    if let t = service.lastUpdate {
                        Text("Última atualização às \(t.formatted(date: .omitted, time: .shortened))")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Sair") { NSApplication.shared.terminate(nil) }
                        .buttonStyle(.borderless).font(.caption)
                }
            }
            .padding(16)
            .frame(width: 280)
        }
    }
}
