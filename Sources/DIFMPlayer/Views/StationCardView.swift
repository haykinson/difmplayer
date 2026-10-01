import SwiftUI

public struct StationCardView: View {
    public let channel: Channel
    public let currentTrack: Track?
    public let isPlayingThisChannel: Bool
    public let onPlay: () -> Void
    public let onSelectDetails: () -> Void

    @ObservedObject private var auth = AuthManager.shared
    @State private var isHovered: Bool = false

    public init(
        channel: Channel,
        currentTrack: Track?,
        isPlayingThisChannel: Bool,
        onPlay: @escaping () -> Void,
        onSelectDetails: @escaping () -> Void
    ) {
        self.channel = channel
        self.currentTrack = currentTrack
        self.isPlayingThisChannel = isPlayingThisChannel
        self.onPlay = onPlay
        self.onSelectDetails = onSelectDetails
    }

    private var isFavorite: Bool {
        auth.isFavorite(channelId: channel.id)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Artwork container
            ZStack(alignment: .bottomTrailing) {
                AsyncImageView(url: channel.artworkURL, cornerRadius: 10)
                    .aspectRatio(1, contentMode: .fit)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                isPlayingThisChannel ? Color(red: 0.12, green: 0.84, blue: 0.38) : Color.white.opacity(0.08),
                                lineWidth: isPlayingThisChannel ? 2 : 1
                            )
                    )
                    .shadow(color: isPlayingThisChannel ? Color(red: 0.12, green: 0.84, blue: 0.38).opacity(0.3) : Color.black.opacity(0.4), radius: 8, x: 0, y: 4)

                // Top left "NOW PLAYING" badge if active
                if isPlayingThisChannel {
                    VStack {
                        HStack {
                            HStack(spacing: 4) {
                                EqualizerView(isPlaying: true, barColor: .white)
                                Text("PLAYING")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color(red: 0.12, green: 0.84, blue: 0.38))
                            .clipShape(Capsule())
                            .shadow(radius: 2)

                            Spacer()

                            // Favorite Button
                            favoriteButton
                        }
                        .padding(8)
                        Spacer()
                    }
                } else {
                    // Top right favorite button on normal card
                    VStack {
                        HStack {
                            Spacer()
                            favoriteButton
                        }
                        .padding(8)
                        Spacer()
                    }
                }

                // Hover Play Button (Spotify style)
                if isHovered || isPlayingThisChannel {
                    Button(action: onPlay) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.12, green: 0.84, blue: 0.38))
                                .frame(width: 44, height: 44)
                                .shadow(color: .black.opacity(0.5), radius: 6, x: 0, y: 3)

                            Image(systemName: isPlayingThisChannel ? "pause.fill" : "play.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.black)
                                .offset(x: isPlayingThisChannel ? 0 : 1.5)
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(10)
                    .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }

            // Station Information
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(channel.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer()

                    // Info / History button
                    Button(action: onSelectDetails) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(isHovered ? 0.7 : 0.2))
                    }
                    .buttonStyle(.plain)
                    .help("View Track History & Station Info")
                }

                // Currently playing track title / artist
                if let track = currentTrack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.title)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(isPlayingThisChannel ? Color(red: 0.12, green: 0.84, blue: 0.38) : .white.opacity(0.85))
                            .lineLimit(1)

                        Text(track.artist)
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                    }
                } else {
                    Text(channel.effectiveDescription)
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.45))
                        .lineLimit(2)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
        )
        .contentShape(Rectangle())
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
        .onTapGesture {
            onPlay()
        }
    }

    private var favoriteButton: some View {
        Button(action: {
            auth.toggleFavorite(channelId: channel.id)
        }) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 14))
                .foregroundColor(isFavorite ? Color(red: 0.12, green: 0.84, blue: 0.38) : .white.opacity(0.8))
                .padding(6)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .opacity((isHovered || isFavorite) ? 1.0 : 0.0)
    }
}
