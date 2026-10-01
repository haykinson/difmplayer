import SwiftUI
import AppKit

@main
struct DIFMPlayerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .preferredColorScheme(.dark)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandMenu("Playback") {
                Button("Play / Pause") {
                    PlayerManager.shared.togglePlayPause()
                }
                .keyboardShortcut(.space, modifiers: [])

                Button("Next Station") {
                    PlayerManager.shared.nextStation()
                }
                .keyboardShortcut(.rightArrow, modifiers: [.command])

                Button("Previous Station") {
                    PlayerManager.shared.previousStation()
                }
                .keyboardShortcut(.leftArrow, modifiers: [.command])
            }

            CommandMenu("View") {
                Button("Toggle Mini Player") {
                    NotificationCenter.default.post(name: .toggleMiniPlayer, object: nil)
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

extension Notification.Name {
    static let toggleMiniPlayer = Notification.Name("difm_toggle_mini_player")
}
