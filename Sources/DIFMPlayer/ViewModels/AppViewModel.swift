import Foundation
import SwiftUI
import Combine

public enum StationCategory: String, CaseIterable, Identifiable {
    case all = "All"
    case favorites = "Favorites"
    case trance = "Trance"
    case house = "House"
    case techno = "Techno"
    case chillout = "Chillout"
    case dnb = "D&B"
    case ambient = "Ambient"
    case club = "Club"

    public var id: String { rawValue }

    public func matches(channel: Channel) -> Bool {
        switch self {
        case .all:
            return true
        case .favorites:
            return AuthManager.shared.isFavorite(channelId: channel.id)
        case .trance:
            let k = channel.key.lowercased()
            let n = channel.name.lowercased()
            return k.contains("trance") || n.contains("trance") || k.contains("psy")
        case .house:
            let k = channel.key.lowercased()
            let n = channel.name.lowercased()
            return k.contains("house") || n.contains("house") || k.contains("disco")
        case .techno:
            let k = channel.key.lowercased()
            let n = channel.name.lowercased()
            return k.contains("techno") || n.contains("techno") || k.contains("minimal")
        case .chillout:
            let k = channel.key.lowercased()
            let n = channel.name.lowercased()
            return k.contains("chill") || n.contains("chill") || k.contains("lounge") || k.contains("lofi")
        case .dnb:
            let k = channel.key.lowercased()
            let n = channel.name.lowercased()
            return k.contains("dnb") || k.contains("drum") || k.contains("bass") || k.contains("jungle") || k.contains("dubstep") || n.contains("drum") || n.contains("bass")
        case .ambient:
            let k = channel.key.lowercased()
            let n = channel.name.lowercased()
            return k.contains("ambient") || k.contains("space") || k.contains("meditation") || n.contains("ambient")
        case .club:
            let k = channel.key.lowercased()
            let n = channel.name.lowercased()
            return k.contains("club") || k.contains("edm") || k.contains("dance") || k.contains("handsup") || k.contains("hard") || n.contains("club")
        }
    }
}

@MainActor
public final class AppViewModel: ObservableObject {
    @Published public var currentNetwork: Network = .difm {
        didSet {
            loadChannels()
        }
    }

    @Published public private(set) var channels: [Channel] = []
    @Published public private(set) var currentlyPlayingMap: [Int: Track] = [:]
    @Published public private(set) var isLoadingChannels: Bool = false
    @Published public var searchText: String = ""
    @Published public var selectedCategory: StationCategory = .all
    @Published public var isMiniMode: Bool = false
    @Published public var showLoginSheet: Bool = false
    @Published public var showSettingsSheet: Bool = false
    @Published public var selectedStationForDetails: Channel? = nil

    private var nowPlayingTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    public let player = PlayerManager.shared
    public let auth = AuthManager.shared

    public init() {
        // Provide channels list for Next/Prev station buttons in PlayerManager
        player.channelsProvider = { [weak self] in
            self?.filteredChannels ?? []
        }

        // Forward changes from AuthManager so favorites view updates reactively
        auth.objectWillChange
            .sink { [weak self] _ in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)

        loadChannels()
        startNowPlayingPolling()
    }

    deinit {
        nowPlayingTimer?.invalidate()
    }

    public var filteredChannels: [Channel] {
        var list = channels

        // Category filter
        if selectedCategory != .all {
            list = list.filter { selectedCategory.matches(channel: $0) }
        }

        // Search query
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if !query.isEmpty {
            list = list.filter { channel in
                let nameMatch = channel.name.lowercased().contains(query)
                let descMatch = channel.effectiveDescription.lowercased().contains(query)
                let trackMatch = currentlyPlayingMap[channel.id]?.title.lowercased().contains(query) ?? false
                let artistMatch = currentlyPlayingMap[channel.id]?.artist.lowercased().contains(query) ?? false
                return nameMatch || descMatch || trackMatch || artistMatch
            }
        }

        return list
    }

    public func loadChannels() {
        isLoadingChannels = true
        Task {
            do {
                let fetched = try await AudioAddictAPI.shared.fetchChannels(network: currentNetwork)
                self.channels = fetched
                self.isLoadingChannels = false
                await refreshNowPlaying()
            } catch {
                self.isLoadingChannels = false
            }
        }
    }

    public func refreshNowPlaying() async {
        do {
            let map = try await AudioAddictAPI.shared.fetchCurrentlyPlaying(network: currentNetwork)
            self.currentlyPlayingMap = map
        } catch {
            // Silently continue with cached
        }
    }

    private func startNowPlayingPolling() {
        nowPlayingTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.refreshNowPlaying()
            }
        }
    }

    public func toggleMiniMode() {
        isMiniMode.toggle()
        applyWindowMode()
    }

    public func applyWindowMode() {
        guard let window = NSApplication.shared.windows.first(where: { $0.isVisible || $0.canBecomeKey }) else { return }

        if isMiniMode {
            // Save full frame if not already mini
            if window.frame.width > 360 {
                UserDefaults.standard.set(NSStringFromRect(window.frame), forKey: "difm_last_full_frame")
            }

            // Enter mini mode: compact floating window
            window.level = .floating
            window.styleMask.insert(.utilityWindow)
            window.standardWindowButton(.zoomButton)?.isHidden = true
            window.isMovableByWindowBackground = true

            var currentOrigin = window.frame.origin
            currentOrigin.y += (window.frame.height - 110)
            let miniFrame = NSRect(x: currentOrigin.x, y: currentOrigin.y, width: 330, height: 110)
            window.setFrame(miniFrame, display: true, animate: true)
            window.minSize = NSSize(width: 300, height: 100)
            window.maxSize = NSSize(width: 450, height: 140)
        } else {
            // Restore full window
            window.level = .normal
            window.styleMask.remove(.utilityWindow)
            window.standardWindowButton(.zoomButton)?.isHidden = false
            window.minSize = NSSize(width: 820, height: 540)
            window.maxSize = NSSize(width: 2560, height: 1600)

            if let savedFrameStr = UserDefaults.standard.string(forKey: "difm_last_full_frame") {
                let savedFrame = NSRectFromString(savedFrameStr)
                if savedFrame.width >= 800 && savedFrame.height >= 500 {
                    window.setFrame(savedFrame, display: true, animate: true)
                    return
                }
            }

            // Default comfortable size
            let defaultFrame = NSRect(x: window.frame.origin.x, y: window.frame.origin.y - 450, width: 1040, height: 680)
            window.setFrame(defaultFrame, display: true, animate: true)
        }
    }
}
