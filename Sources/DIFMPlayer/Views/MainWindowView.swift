import SwiftUI

public struct MainWindowView: View {
    @StateObject private var viewModel = AppViewModel()

    public init() {}

    public var body: some View {
        Group {
            if viewModel.isMiniMode {
                MiniPlayerView(viewModel: viewModel)
            } else {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        SidebarView(viewModel: viewModel)
                        StationGridView(viewModel: viewModel)
                    }
                    BottomPlayerBar(viewModel: viewModel)
                }
            }
        }
        .frame(
            minWidth: viewModel.isMiniMode ? 300 : 820,
            maxWidth: .infinity,
            minHeight: viewModel.isMiniMode ? 90 : 540,
            maxHeight: .infinity
        )
        .sheet(isPresented: $viewModel.showLoginSheet) {
            LoginSheet(viewModel: viewModel) {
                viewModel.showLoginSheet = false
            }
        }
        .sheet(item: $viewModel.selectedStationForDetails) { channel in
            StationDetailSheet(channel: channel, viewModel: viewModel) {
                viewModel.selectedStationForDetails = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleMiniPlayer)) { _ in
            viewModel.toggleMiniMode()
        }
        .onAppear {
            // Apply initial window styling
            DispatchQueue.main.async {
                if let window = NSApplication.shared.windows.first {
                    window.title = "DI.FM Player"
                    window.titlebarAppearsTransparent = true
                    window.titleVisibility = .hidden
                    window.backgroundColor = NSColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1.0)
                }
            }
        }
    }
}
