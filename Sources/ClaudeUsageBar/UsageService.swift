import Foundation
import SwiftUI
import UserNotifications

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

    private var timer: Timer?
    private var notified: Set<String> = []

    init() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
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
                fiveHour = five
                sevenDay = seven
                errorMessage = nil
                lastUpdate = Date()
                checkThresholds()
            } catch {
                // Mantém o último valor conhecido na tela e sinaliza o erro.
                errorMessage = error.localizedDescription
            }
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
        notify(window: fiveHour, label: "janela de 5h")
        notify(window: sevenDay, label: "limite semanal")
    }

    private func notify(window: UsageWindow?, label: String) {
        guard let w = window else { return }
        for threshold in [80.0, 95.0] where w.utilization >= threshold {
            let key = "\(label)-\(Int(threshold))-\(w.resetsAt.timeIntervalSince1970.rounded() / 60)"
            guard !notified.contains(key) else { continue }
            notified.insert(key)
            let c = UNMutableNotificationContent()
            c.title = "Claude Code: \(Int(w.utilization))% da \(label)"
            c.body = "Restam \(Int(w.remaining))%. Renova \(w.resetsAt.formatted(date: .omitted, time: .shortened))."
            c.sound = .default
            UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: key, content: c, trigger: nil))
        }
    }
}

enum UsageError: LocalizedError {
    case noToken, expired, badResponse
    var errorDescription: String? {
        switch self {
        case .noToken: "Login do Claude Code não encontrado no Keychain."
        case .expired: "Sessão expirada. Abra o Claude Code para renovar o login."
        case .badResponse: "Resposta inesperada da API."
        }
    }
}
