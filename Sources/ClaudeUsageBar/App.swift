import SwiftUI

@main
struct ClaudeUsageBarApp: App {
    @StateObject private var service = UsageService()

    var body: some Scene {
        MenuBarExtra {
            PopoverView(service: service)
        } label: {
            MenuLabel(service: service)
        }
        .menuBarExtraStyle(.window)
    }
}
