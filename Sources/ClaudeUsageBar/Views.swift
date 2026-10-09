import SwiftUI

func usageColor(_ pct: Double) -> Color {
    pct >= 90 ? .red : pct >= 70 ? .orange : .green
}

func countdown(to date: Date, now: Date) -> String {
    let s = max(0, Int(date.timeIntervalSince(now)))
    let d = s / 86400, h = (s % 86400) / 3600, m = (s % 3600) / 60
    if d > 0 { return "\(d)d \(h)h" }
    if h > 0 { return "\(h)h \(m)min" }
    return "\(m)min"
}

struct MenuLabel: View {
    @ObservedObject var service: UsageService
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "gauge.with.dots.needle.50percent")
            Text(service.fiveHour.map { "\(Int($0.utilization))%" } ?? "–")
        }
    }
}

struct RingView: View {
    let window: UsageWindow
    var body: some View {
        let color = usageColor(window.utilization)
        ZStack {
            Circle().stroke(color.opacity(0.15), lineWidth: 14)
            Circle()
                .trim(from: 0, to: window.utilization / 100)
                .stroke(color.gradient, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.6), value: window.utilization)
            VStack(spacing: 0) {
                Text("\(Int(window.utilization))%")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("usado").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(width: 130, height: 130)
    }
}

struct PopoverView: View {
    @ObservedObject var service: UsageService

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { ctx in
            VStack(spacing: 14) {
                Text("Claude Code · Pro").font(.headline)

                if let five = service.fiveHour {
                    RingView(window: five)
                    VStack(spacing: 2) {
                        Text("Restam \(Int(five.remaining))% nesta janela de 5h")
                            .font(.subheadline.weight(.medium))
                        Text("Renova em \(countdown(to: five.resetsAt, now: ctx.date))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                } else if service.errorMessage == nil {
                    ProgressView().padding(40)
                }

                if let week = service.sevenDay {
                    Divider()
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Semana").font(.subheadline.weight(.medium))
                            Spacer()
                            Text("\(Int(week.utilization))% · renova em \(countdown(to: week.resetsAt, now: ctx.date))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        ProgressView(value: week.utilization, total: 100)
                            .tint(usageColor(week.utilization))
                    }
                }

                if let err = service.errorMessage {
                    Text(err).font(.caption).foregroundStyle(.red).multilineTextAlignment(.center)
                }

                Divider()
                HStack {
                    if let t = service.lastUpdate {
                        Text("Atualizado \(t.formatted(date: .omitted, time: .shortened))")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { service.refresh() } label: { Image(systemName: "arrow.clockwise") }
                        .buttonStyle(.borderless).disabled(service.isLoading)
                    Button("Sair") { NSApplication.shared.terminate(nil) }
                        .buttonStyle(.borderless).font(.caption)
                }
            }
            .padding(16)
            .frame(width: 260)
        }
    }
}
