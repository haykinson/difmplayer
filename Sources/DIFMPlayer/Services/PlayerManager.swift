import Foundation
import AVFoundation
import MediaPlayer
import Combine
import AppKit

public final class PlayerManager: ObservableObject {
    public static let shared = PlayerManager()

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var timeObserverToken: Any?
    private var statusObserver: NSKeyValueObservation?
    private var timeControlObserver: NSKeyValueObservation?
    private var likelyToKeepUpObserver: NSKeyValueObservation?
    private var cancellables = Set<AnyCancellable>()

    // Track polling timer
    private var trackPollingTimer: Timer?
    private var elapsedTimer: Timer?

    @Published public private(set) var currentChannel: Channel?
    @Published public private(set) var currentTrack: Track?
    @Published public private(set) var recentTracks: [Track] = []
    @Published public private(set) var isPlaying: Bool = false
    @Published public private(set) var isBuffering: Bool = false
    @Published public private(set) var playbackError: String?
    @Published public var volume: Float = 0.8 {
        didSet {
            player?.volume = volume
            UserDefaults.standard.set(volume, forKey: "difm_player_volume")
        }
    }
    @Published public private(set) var elapsedSeconds: Double = 0

    // Reference to all channels list for next/prev station switching
    public var channelsProvider: (() -> [Channel])?

    private init() {
        let savedVol = UserDefaults.standard.float(forKey: "difm_player_volume")
        self.volume = savedVol > 0 ? savedVol : 0.8
        setupRemoteCommands()
    }

    deinit {
        cleanup()
    }

    private func cleanup() {
        trackPollingTimer?.invalidate()
        elapsedTimer?.invalidate()
        statusObserver?.invalidate()
        timeControlObserver?.invalidate()
        likelyToKeepUpObserver?.invalidate()
        player?.pause()
        player = nil
    }

    // MARK: - Playback Control

    public func play(channel: Channel, network: Network = .difm) {
        self.currentChannel = channel
        self.playbackError = nil
        self.isBuffering = true

        // Clean up previous playback observers
        statusObserver?.invalidate()
        timeControlObserver?.invalidate()
        likelyToKeepUpObserver?.invalidate()

        Task { @MainActor in
            do {
                let auth = AuthManager.shared
                let quality = auth.selectedQuality
                let listenKey = auth.listenKey

                guard !listenKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    self.isBuffering = false
                    self.isPlaying = false
                    self.playbackError = "DI.FM Premium Listen Key required. Click 'Log In' to connect."
                    return
                }

                let streamURL = try await AudioAddictAPI.shared.fetchStreamURL(
                    channelKey: channel.key,
                    network: network,
                    quality: quality,
                    listenKey: listenKey
                )

                // Setup AVPlayer for live streaming
                let item = AVPlayerItem(url: streamURL)
                item.preferredForwardBufferDuration = 1.0
                self.playerItem = item

                if self.player == nil {
                    let newPlayer = AVPlayer(playerItem: item)
                    newPlayer.automaticallyWaitsToMinimizeStalling = false
                    self.player = newPlayer
                } else {
                    self.player?.automaticallyWaitsToMinimizeStalling = false
                    self.player?.replaceCurrentItem(with: item)
                }

                self.player?.volume = self.volume
                self.setupObservers(for: item)
                self.player?.playImmediately(atRate: 1.0)

                self.startTrackPolling(for: channel, network: network)
                self.updateNowPlayingInfo()
            } catch {
                self.isBuffering = false
                self.isPlaying = false
                self.playbackError = "Failed to load stream: \(error.localizedDescription)"
            }
        }
    }

    public func togglePlayPause() {
        guard player != nil else {
            if let channel = currentChannel {
                play(channel: channel)
            }
            return
        }

        if isPlaying {
            pause()
        } else {
            resume()
        }
    }

    public func pause() {
        player?.pause()
        isPlaying = false
        isBuffering = false
        updateNowPlayingInfo()
    }

    public func resume() {
        if player != nil {
            player?.playImmediately(atRate: 1.0)
            isPlaying = true
            isBuffering = false
            updateNowPlayingInfo()
        } else if let channel = currentChannel {
            play(channel: channel)
        }
    }

    public func stop() {
        cleanup()
        isPlaying = false
        isBuffering = false
        currentTrack = nil
        currentChannel = nil
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
    }

    public func nextStation() {
        guard let channels = channelsProvider?(), !channels.isEmpty else { return }
        guard let current = currentChannel, let currentIndex = channels.firstIndex(where: { $0.id == current.id }) else {
            if let first = channels.first {
                play(channel: first)
            }
            return
        }
        let nextIndex = (currentIndex + 1) % channels.count
        play(channel: channels[nextIndex])
    }

    public func previousStation() {
        guard let channels = channelsProvider?(), !channels.isEmpty else { return }
        guard let current = currentChannel, let currentIndex = channels.firstIndex(where: { $0.id == current.id }) else {
            if let first = channels.first {
                play(channel: first)
            }
            return
        }
        let prevIndex = (currentIndex - 1 + channels.count) % channels.count
        play(channel: channels[prevIndex])
    }

    // MARK: - AVPlayer Observers

    private func setupObservers(for item: AVPlayerItem) {
        statusObserver = item.observe(\.status, options: [.new, .old]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch item.status {
                case .readyToPlay:
                    self.isBuffering = false
                    self.isPlaying = true
                    self.playbackError = nil
                    self.player?.playImmediately(atRate: 1.0)
                case .failed:
                    self.isBuffering = false
                    self.isPlaying = false
                    self.playbackError = item.error?.localizedDescription ?? "Playback error"
                case .unknown:
                    break
                @unknown default:
                    break
                }
            }
        }

        likelyToKeepUpObserver = item.observe(\.isPlaybackLikelyToKeepUp, options: [.new]) { [weak self] item, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if item.isPlaybackLikelyToKeepUp {
                    self.isBuffering = false
                    self.isPlaying = true
                    self.playbackError = nil
                    self.player?.playImmediately(atRate: 1.0)
                }
            }
        }

        if let player = player {
            timeControlObserver = player.observe(\.timeControlStatus, options: [.new]) { [weak self] player, _ in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch player.timeControlStatus {
                    case .playing:
                        self.isPlaying = true
                        self.isBuffering = false
                        self.playbackError = nil
                    case .paused:
                        self.isPlaying = false
                        self.isBuffering = false
                    case .waitingToPlayAtSpecifiedRate:
                        if !self.isPlaying {
                            self.isBuffering = true
                        }
                    @unknown default:
                        break
                    }
                }
            }
        }
    }

    // MARK: - Metadata & Polling

    private func startTrackPolling(for channel: Channel, network: Network) {
        trackPollingTimer?.invalidate()
        elapsedTimer?.invalidate()

        // Fetch immediately
        fetchTrackMetadata(for: channel, network: network)

        // Poll every 8 seconds
        trackPollingTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            guard let self = self, let activeChannel = self.currentChannel, activeChannel.id == channel.id else { return }
            self.fetchTrackMetadata(for: activeChannel, network: network)
        }

        // Elapsed time counter
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            if let start = self.currentTrack?.startTime {
                self.elapsedSeconds = max(0, Date().timeIntervalSince(start))
            } else {
                self.elapsedSeconds += 1.0
            }
        }
    }

    private func fetchTrackMetadata(for channel: Channel, network: Network) {
        Task { @MainActor in
            do {
                // Fetch track history for channel to get current song + high-res artwork
                let history = try await AudioAddictAPI.shared.fetchTrackHistory(network: network, channelId: channel.id)
                self.recentTracks = history

                if let current = history.first {
                    if self.currentTrack?.id != current.id {
                        self.currentTrack = current
                        if let start = current.startTime {
                            self.elapsedSeconds = max(0, Date().timeIntervalSince(start))
                        } else {
                            self.elapsedSeconds = 0
                        }
                        self.updateNowPlayingInfo()
                    }
                }
            } catch {
                // Fallback to currently_playing map if history fails
                do {
                    let map = try await AudioAddictAPI.shared.fetchCurrentlyPlaying(network: network)
                    if let track = map[channel.id] {
                        if self.currentTrack?.title != track.title || self.currentTrack?.artist != track.artist {
                            self.currentTrack = track
                            self.updateNowPlayingInfo()
                        }
                    }
                } catch {
                    // Ignore metadata polling errors
                }
            }
        }
    }

    // MARK: - System Now Playing & Remote Control

    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.isEnabled = true
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.resume()
            return .success
        }

        commandCenter.pauseCommand.isEnabled = true
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }

        commandCenter.togglePlayPauseCommand.isEnabled = true
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }

        commandCenter.nextTrackCommand.isEnabled = true
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.nextStation()
            return .success
        }

        commandCenter.previousTrackCommand.isEnabled = true
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.previousStation()
            return .success
        }
    }

    private func updateNowPlayingInfo() {
        var info = [String: Any]()

        let channelName = currentChannel?.name ?? "DI.FM"
        let songTitle = currentTrack?.title ?? channelName
        let artistName = currentTrack?.artist ?? "DI.FM Stream"

        info[MPMediaItemPropertyTitle] = songTitle
        info[MPMediaItemPropertyArtist] = artistName
        info[MPMediaItemPropertyAlbumTitle] = channelName
        info[MPNowPlayingInfoPropertyIsLiveStream] = true
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        if let duration = currentTrack?.duration, duration > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = duration
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = elapsedSeconds
        }

        MPNowPlayingInfoCenter.default().nowPlayingInfo = info

        // Load artwork asynchronously
        if let artURL = currentTrack?.artworkURL ?? currentChannel?.artworkURL {
            URLSession.shared.dataTask(with: artURL) { data, _, _ in
                guard let data = data, let image = NSImage(data: data) else { return }
                DispatchQueue.main.async {
                    var updated = MPNowPlayingInfoCenter.default().nowPlayingInfo ?? [:]
                    let artwork = MPMediaItemArtwork(boundsSize: image.size) { _ in image }
                    updated[MPMediaItemPropertyArtwork] = artwork
                    MPNowPlayingInfoCenter.default().nowPlayingInfo = updated
                }
            }.resume()
        }
    }
}
