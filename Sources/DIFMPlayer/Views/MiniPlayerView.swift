import SwiftUI

public struct MiniPlayerView: View {
    @ObservedObject public var viewModel: AppViewModel
    @ObservedObject private var player = PlayerManager.shared

    @State private var isHovered: Bool = false

    public var body: some View {
        HStack(spacing: 12) {
            // Cover Art
            ZStack {
                AsyncImageView(
                    url: player.currentTrack?.artworkURL ?? player.currentChannel?.artworkURL,
                    cornerRadius: 8
                )
                .frame(width: 72, height: 72)
                .shadow(radius: 4)

                if player.isPlaying {
                    VStack {
                        Spacer()
                        HStack {
                            EqualizerView(isPlaying: true, barColor: Color(red: 0.12, green: 0.84, blue: 0.38))
                                .padding(4)
                                .background(Color.black.opacity(0.6))
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                            Spacer()
                        }
                    }
                    .padding(3)
                }
            }

            // Stream Name & Currently Playing Track Info
            VStack(alignment: .leading, spacing: 3) {
                // Name of stream
                Text(player.currentChannel?.name ?? viewModel.currentNetwork.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                // Currently playing track title
                if let track = player.currentTrack {
                    Text(track.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 0.12, green: 0.84, blue: 0.38))
                        .lineLimit(1)

                    Text(track.artist)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(1)
                } else {
                    Text(player.isPlaying ? "Playing stream" : "Paused")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Playback Controls: Pause and Skip button
            HStack(spacing: 10) {
                // Play / Pause Button
                Button(action: {
                    player.togglePlayPause()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 32, height: 32)

                        if player.isBuffering {
                            ProgressView()
                                .scaleEffect(0.6)
                                .colorInvert()
                        } else {
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.black)
                                .offset(x: player.isPlaying ? 0 : 1)
                        }
                    }
                }
                .buttonStyle(.plain)
                .help(player.isPlaying ? "Pause" : "Play")

                // Skip / Next Station Button
                Button(action: {
                    player.nextStation()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(6)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Skip to next station")

                // Expand back to full mode button
                Button(action: {
                    viewModel.toggleMiniMode()
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(6)
                        .background(Color.white.opacity(0.05))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Restore Full Window")
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(minWidth: 300, minHeight: 90)
        .background(
            Color(red: 0.08, green: 0.08, blue: 0.10)
                .opacity(0.96)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
