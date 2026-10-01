import SwiftUI

public struct StationDetailSheet: View {
    public let channel: Channel
    @ObservedObject public var viewModel: AppViewModel
    public let onClose: () -> Void

    @State private var history: [Track] = []
    @State private var isLoadingHistory: Bool = true

    public init(channel: Channel, viewModel: AppViewModel, onClose: @escaping () -> Void) {
        self.channel = channel
        self.viewModel = viewModel
        self.onClose = onClose
    }

    private var isPlayingThisChannel: Bool {
        viewModel.player.currentChannel?.id == channel.id && viewModel.player.isPlaying
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header bar
            HStack {
                Text(channel.name)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 14)
            .background(Color(red: 0.12, green: 0.12, blue: 0.14))

            Divider().background(Color.white.opacity(0.1))

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hero Station Info
                    HStack(alignment: .top, spacing: 18) {
                        AsyncImageView(url: channel.artworkURL, cornerRadius: 12)
                            .frame(width: 110, height: 110)
                            .shadow(radius: 6)

                        VStack(alignment: .leading, spacing: 8) {
                            Text(channel.name)
                                .font(.system(size: 20, weight: .heavy))
                                .foregroundColor(.white)

                            Text(channel.effectiveDescription)
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.7))
                                .lineLimit(3)

                            HStack(spacing: 12) {
                                Button(action: {
                                    if isPlayingThisChannel {
                                        viewModel.player.togglePlayPause()
                                    } else {
                                        viewModel.player.play(channel: channel, network: viewModel.currentNetwork)
                                    }
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: isPlayingThisChannel ? "pause.fill" : "play.fill")
                                        Text(isPlayingThisChannel ? "Pause" : "Play Channel")
                                            .fontWeight(.bold)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(Color(red: 0.12, green: 0.84, blue: 0.38))
                                    .foregroundColor(.black)
                                    .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)

                                Button(action: {
                                    viewModel.auth.toggleFavorite(channelId: channel.id)
                                }) {
                                    Image(systemName: viewModel.auth.isFavorite(channelId: channel.id) ? "heart.fill" : "heart")
                                        .font(.system(size: 16))
                                        .foregroundColor(viewModel.auth.isFavorite(channelId: channel.id) ? Color(red: 0.12, green: 0.84, blue: 0.38) : .white)
                                        .padding(8)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Recent Track History
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Track History")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.white)

                            Spacer()

                            if isLoadingHistory {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        }

                        if history.isEmpty && !isLoadingHistory {
                            Text("No recent track history available.")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.vertical, 10)
                        } else {
                            VStack(spacing: 8) {
                                ForEach(history) { track in
                                    HStack(spacing: 12) {
                                        AsyncImageView(url: track.artworkURL ?? channel.artworkURL, cornerRadius: 6)
                                            .frame(width: 44, height: 44)

                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(track.title)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(.white)
                                                .lineLimit(1)

                                            Text(track.artist)
                                                .font(.system(size: 12))
                                                .foregroundColor(.white.opacity(0.6))
                                                .lineLimit(1)
                                        }

                                        Spacer()

                                        if let votes = track.votes, let up = votes.up, up > 0 {
                                            HStack(spacing: 4) {
                                                Image(systemName: "hand.thumbsup.fill")
                                                    .font(.system(size: 11))
                                                    .foregroundColor(Color(red: 0.12, green: 0.84, blue: 0.38).opacity(0.8))
                                                Text("\(up)")
                                                    .font(.system(size: 11, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.6))
                                            }
                                        }

                                        if !track.formattedDuration.isEmpty {
                                            Text(track.formattedDuration)
                                                .font(.system(size: 11, design: .monospaced))
                                                .foregroundColor(.white.opacity(0.4))
                                        }
                                    }
                                    .padding(8)
                                    .background(Color.white.opacity(0.04))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .frame(width: 520, height: 500)
        .background(Color(red: 0.08, green: 0.08, blue: 0.10))
        .onAppear {
            loadHistory()
        }
    }

    private func loadHistory() {
        isLoadingHistory = true
        Task {
            do {
                let fetched = try await AudioAddictAPI.shared.fetchTrackHistory(
                    network: viewModel.currentNetwork,
                    channelId: channel.id
                )
                self.history = fetched
                self.isLoadingHistory = false
            } catch {
                self.isLoadingHistory = false
            }
        }
    }
}
