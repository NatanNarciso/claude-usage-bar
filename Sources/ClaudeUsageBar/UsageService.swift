import Foundation
import SwiftUI
import AppKit
import UserNotifications
import ServiceManagement

struct UsageWindow: Equatable {
    var utilization: Double   // 0...100
    var resetsAt: Date
    var remaining: Double { max(0, 100 - utilization) }
}

@MainActor
final class UsageService: ObservableObject {
    @Published var fiveHour: UsageWindow?
    @Published var sevenDay: UsageWindow?
    @Published var errorMessage: String?
    @Published var lastUpdate: Date?
    @Published var isLoading = false
    /// Alterna a cada tick do timer de animação (só roda em alerta ≥80% ou durante a comemoração).
    @Published var pulse = false
    @Published var isCelebrating = false
    /// Cursor sobre o ícone da barra de menu; `hoverTick` avança enquanto durar (anima o aceno).
    @Published var hovering = false
    @Published var hoverTick = 0
    /// Animação sorteada a cada entrada do cursor (nunca repete a anterior).
    @Published var hoverKind: ReactionKind = .wave

    /// Quando verdadeiro, as views mostram o estado final sem animar (usado nos snapshots de tools/).
    nonisolated(unsafe) static var snapshotMode = false

    private var timer: Timer?
    private var animTimer: Timer?
    private var hoverTimer: Timer?
    private var mouseMonitors: [Any] = []
    private var notified: Set<String> = []

    /// Serviço de exemplo para gerar imagens: sem rede, Keychain, timer nem notificações.
    init(sampleFive: UsageWindow, sampleSeven: UsageWindow) {
        fiveHour = sampleFive
        sevenDay = sampleSeven
        lastUpdate = Date()
    }

    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
        if SMAppService.mainApp.status != .enabled { try? SMAppService.mainApp.register() }
        startHoverTracking()
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 90, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
    }

    func refresh() {
        guard !isLoading else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let token = try Self.readToken()
                let (five, seven) = try await Self.fetch(token: token)
                let previous = fiveHour
                fiveHour = five
                sevenDay = seven
                detectRenewal(previous: previous, current: five)
                updateAnimation()
                errorMessage = nil
                lastUpdate = Date()
                checkThresholds()
            } catch {
                // Mantém o último valor conhecido na tela e sinaliza o erro.
                errorMessage = error.localizedDescription
            }
        }
    }

    // MARK: - Hover no ícone da barra de menu

    /// O SwiftUI não expõe hover do ícone da barra de menu; acompanhamos o cursor e comparamos
    /// com o frame da janela do status item. Eventos de mouse não exigem permissão especial.
    private func startHoverTracking() {
        let handler: (NSEvent) -> Void = { [weak self] _ in Task { @MainActor in self?.checkHover() } }
        if let g = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved, handler: handler) { mouseMonitors.append(g) }
        if let l = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved, handler: { e in handler(e); return e }) { mouseMonitors.append(l) }
    }

    private func checkHover() {
        guard !NSWorkspace.shared.accessibilityDisplayShouldReduceMotion else { return }
        let window = NSApp.windows.first { String(describing: type(of: $0)).contains("StatusBar") }
        let inside = window?.frame.insetBy(dx: -2, dy: -2).contains(NSEvent.mouseLocation) ?? false
        guard inside != hovering else { return }
        hovering = inside
        hoverTimer?.invalidate()
        hoverTimer = nil
        if inside {
            hoverTick = 0
            hoverKind = ReactionKind.allCases.filter { $0 != hoverKind }.randomElement() ?? .wave
            hoverTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.hoverTick += 1 }
            }
        }
    }

    // MARK: - Animação da barra de menu e comemoração

    /// A janela de 5h virou quando o horário de reset salta para frente.
    private func detectRenewal(previous: UsageWindow?, current: UsageWindow?) {
        guard let p = previous, let c = current, c.resetsAt.timeIntervalSince(p.resetsAt) > 600 else { return }
        if p.utilization >= 50 { celebrate(for: 8) }
        if p.utilization >= 80 {
            let n = UNMutableNotificationContent()
            n.title = L("notif.renewed.title")
            n.body = L("notif.renewed.body", Int(c.remaining))
            n.sound = .default
            UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "renewed-\(c.resetsAt.timeIntervalSince1970)", content: n, trigger: nil))
        }
    }

    func celebrate(for seconds: Double) {
        isCelebrating = true
        updateAnimation()
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { [weak self] in
            self?.isCelebrating = false
            self?.updateAnimation()
        }
    }

    /// Liga o timer só quando há algo para animar (80–99% ou comemorando); respeita "Reduzir movimento".
    private func updateAnimation() {
        let used = fiveHour?.utilization ?? 0
        let reduce = NSWorkspace.shared.accessibilityDisplayShouldReduceMotion
        let needs = !reduce && ((used >= 80 && used < 100) || isCelebrating)
        if needs {
            guard animTimer == nil else { return }
            animTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.pulse.toggle() }
            }
        } else {
            animTimer?.invalidate()
            animTimer = nil
            pulse = false
        }
    }

    // MARK: - Dados

    private static func readToken() throws -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        p.arguments = ["find-generic-password", "-s", "Claude Code-credentials", "-w"]
        let out = Pipe()
        p.standardOutput = out
        p.standardError = Pipe()
        try p.run()
        p.waitUntilExit()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        guard p.terminationStatus == 0,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let oauth = json["claudeAiOauth"] as? [String: Any],
              let token = oauth["accessToken"] as? String
        else { throw UsageError.noToken }
        return token
    }

    private static func fetch(token: String) async throws -> (UsageWindow?, UsageWindow?) {
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/api/oauth/usage")!)
        req.timeoutInterval = 15
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        req.setValue("claude-code/2.0", forHTTPHeaderField: "User-Agent")
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let http = resp as? HTTPURLResponse, http.statusCode == 401 || http.statusCode == 403 {
            throw UsageError.expired
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw UsageError.badResponse
        }
        return (window(json["five_hour"]), window(json["seven_day"]))
    }

    private static func window(_ any: Any?) -> UsageWindow? {
        guard let d = any as? [String: Any],
              let u = (d["utilization"] as? NSNumber)?.doubleValue,
              let s = d["resets_at"] as? String else { return nil }
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = f.date(from: s) ?? ISO8601DateFormatter().date(from: s) else { return nil }
        return UsageWindow(utilization: u, resetsAt: date)
    }

    // MARK: - Notificações (uma vez por janela e por limiar)

    private func checkThresholds() {
        notify(window: fiveHour, label: L("window.five"))
        notify(window: sevenDay, label: L("window.week"))
    }

    private func notify(window: UsageWindow?, label: String) {
        guard let w = window else { return }
        for threshold in [80.0, 95.0] where w.utilization >= threshold {
            let key = "\(label)-\(Int(threshold))-\(w.resetsAt.timeIntervalSince1970.rounded() / 60)"
            guard !notified.contains(key) else { continue }
            notified.insert(key)
            let c = UNMutableNotificationContent()
            c.title = L("notif.title", Int(w.utilization), label)
            c.body = L("notif.body", Int(w.remaining), w.resetsAt.formatted(date: .omitted, time: .shortened))
            c.sound = .default
            UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: key, content: c, trigger: nil))
        }
    }
}

enum UsageError: LocalizedError {
    case noToken, expired, badResponse
    var errorDescription: String? {
        switch self {
        case .noToken: L("error.noToken")
        case .expired: L("error.expired")
        case .badResponse: L("error.badResponse")
        }
    }
}
