import SwiftUI

public struct BottomPlayerBar: View {
    @ObservedObject public var viewModel: AppViewModel
    @ObservedObject private var player = PlayerManager.shared
    @ObservedObject private var auth = AuthManager.shared

    public var body: some View {
        HStack(spacing: 16) {
            // LEFT: Track & Station Artwork + Title + Artist
            HStack(spacing: 12) {
                if let channel = player.currentChannel {
                    AsyncImageView(url: player.currentTrack?.artworkURL ?? channel.artworkURL, cornerRadius: 6)
                        .frame(width: 52, height: 52)
                        .shadow(radius: 4)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(player.currentTrack?.title ?? channel.name)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)

                        Text(player.currentTrack?.artist ?? channel.name)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.65))
                            .lineLimit(1)

                        HStack(spacing: 4) {
                            Text(channel.name)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color(red: 0.12, green: 0.84, blue: 0.38))

                            if let qualityBadge = auth.selectedQuality.shortBadge as String? {
                                Text("• \(qualityBadge)")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                        }
                    }

                    // Heart button
                    Button(action: {
                        auth.toggleFavorite(channelId: channel.id)
                    }) {
                        Image(systemName: auth.isFavorite(channelId: channel.id) ? "heart.fill" : "heart")
                            .font(.system(size: 15))
                            .foregroundColor(auth.isFavorite(channelId: channel.id) ? Color(red: 0.12, green: 0.84, blue: 0.38) : .white.opacity(0.4))
                    }
                    .buttonStyle(.plain)
                    .padding(.leading, 4)
                } else {
                    // Empty placeholder when no channel is playing
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.05))
                            .frame(width: 52, height: 52)
                            .overlay(
                                Image(systemName: "radio")
                                    .foregroundColor(.white.opacity(0.3))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Select a station to play")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                            Text(viewModel.currentNetwork.name)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                }
            }
            .frame(width: 260, alignment: .leading)

            Spacer()

            // CENTER: Controls & Live Status
            VStack(spacing: 4) {
                HStack(spacing: 20) {
                    // Previous Station
                    Button(action: {
                        player.previousStation()
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(player.currentChannel != nil ? .white.opacity(0.8) : .white.opacity(0.25))
                    }
                    .buttonStyle(.plain)
                    .disabled(player.currentChannel == nil)
                    .help("Previous Station")

                    // Play / Pause Button
                    Button(action: {
                        player.togglePlayPause()
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 36, height: 36)

                            if player.isBuffering {
                                ProgressView()
                                    .scaleEffect(0.65)
                                    .colorInvert()
                            } else {
                                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.black)
                                    .offset(x: player.isPlaying ? 0 : 1)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(player.currentChannel == nil)
                    .help(player.isPlaying ? "Pause" : "Play")

                    // Next / Skip Station
                    Button(action: {
                        player.nextStation()
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 16))
                            .foregroundColor(player.currentChannel != nil ? .white.opacity(0.8) : .white.opacity(0.25))
                    }
                    .buttonStyle(.plain)
                    .disabled(player.currentChannel == nil)
                    .help("Next Station (Skip)")
                }

                // Live status indicator & elapsed time
                HStack(spacing: 6) {
                    if player.isPlaying {
                        Circle()
                            .fill(Color(red: 0.12, green: 0.84, blue: 0.38))
                            .frame(width: 6, height: 6)
                        Text("LIVE")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(Color(red: 0.12, green: 0.84, blue: 0.38))
                    } else if player.isBuffering {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 6, height: 6)
                        Text("BUFFERING")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.orange)
                    }

                    if player.elapsedSeconds > 0 {
                        Text(formatTime(player.elapsedSeconds))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }

            Spacer()

            // RIGHT: Audio Quality, Volume Slider & Mini Player Toggle
            HStack(spacing: 14) {
                // Quality Picker Menu
                Menu {
                    ForEach(AudioQuality.allCases) { q in
                        Button(action: {
                            auth.selectedQuality = q
                            if let ch = player.currentChannel {
                                player.play(channel: ch, network: viewModel.currentNetwork)
                            }
                        }) {
                            HStack {
                                Text(q.displayName)
                                if auth.selectedQuality == q {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Text(auth.selectedQuality.shortBadge)
                        .font(.system(size: 10, weight: .black))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .foregroundColor(.white.opacity(0.9))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .menuStyle(.borderlessButton)
                .help("Select Audio Quality")

                // Volume Control
                HStack(spacing: 6) {
                    Button(action: {
                        if player.volume > 0 {
                            player.volume = 0
                        } else {
                            player.volume = 0.8
                        }
                    }) {
                        Image(systemName: volumeIcon)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                            .frame(width: 16)
                    }
                    .buttonStyle(.plain)

                    Slider(value: $player.volume, in: 0...1)
                        .accentColor(Color(red: 0.12, green: 0.84, blue: 0.38))
                        .frame(width: 75)
                }

                // Mini Mode Toggle Button
                Button(action: {
                    viewModel.toggleMiniMode()
                }) {
                    Image(systemName: "pip.enter")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.75))
                        .padding(6)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help("Mini Player Mode")
            }
            .frame(width: 250, alignment: .trailing)
        }
        .padding(.horizontal, 20)
        .frame(height: 76)
        .background(Color(red: 0.10, green: 0.10, blue: 0.12))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1),
            alignment: .top
        )
    }

    private var volumeIcon: String {
        if player.volume == 0 {
            return "speaker.slash.fill"
        } else if player.volume < 0.33 {
            return "speaker.wave.1.fill"
        } else if player.volume < 0.66 {
            return "speaker.wave.2.fill"
        } else {
            return "speaker.wave.3.fill"
        }
    }

    private func formatTime(_ seconds: Double) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
