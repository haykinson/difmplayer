import SwiftUI

public struct StationGridView: View {
    @ObservedObject public var viewModel: AppViewModel

    private let columns = [
        GridItem(.adaptive(minimum: 170, maximum: 220), spacing: 14)
    ]

    public var body: some View {
        VStack(spacing: 0) {
            // Top Bar with Search & Category Pills
            VStack(spacing: 12) {
                HStack(spacing: 14) {
                    // Search Field
                    HStack(spacing: 8) {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.white.opacity(0.4))
                            .font(.system(size: 13))

                        TextField("Search stations, artists, tracks...", text: $viewModel.searchText)
                            .textFieldStyle(.plain)
                            .font(.system(size: 13))
                            .foregroundColor(.white)

                        if !viewModel.searchText.isEmpty {
                            Button(action: { viewModel.searchText = "" }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.4))
                                    .font(.system(size: 13))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.07))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(maxWidth: 320)

                    Spacer()

                    // Quick Refresh Button
                    Button(action: {
                        Task { await viewModel.refreshNowPlaying() }
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(8)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .help("Refresh Now Playing Info")
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)

                // Category Filter Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(StationCategory.allCases) { cat in
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.15)) {
                                    viewModel.selectedCategory = cat
                                }
                            }) {
                                Text(cat.rawValue)
                                    .font(.system(size: 12, weight: viewModel.selectedCategory == cat ? .bold : .medium))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 6)
                                    .background(
                                        viewModel.selectedCategory == cat
                                            ? Color(red: 0.12, green: 0.84, blue: 0.38)
                                            : Color.white.opacity(0.07)
                                    )
                                    .foregroundColor(viewModel.selectedCategory == cat ? .black : .white)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 8)
            }
            .background(Color(red: 0.09, green: 0.09, blue: 0.11))

            Divider().background(Color.white.opacity(0.08))

            // Main Station Grid ScrollView
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Optional Featured Hero banner if a channel is active
                    if let activeChannel = viewModel.player.currentChannel,
                       let track = viewModel.player.currentTrack {
                        activeStationHero(channel: activeChannel, track: track)
                    }

                    // Section Title
                    HStack {
                        Text(sectionTitle)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Text("(\(viewModel.filteredChannels.count))")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))

                        Spacer()
                    }

                    if viewModel.isLoadingChannels && viewModel.channels.isEmpty {
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text("Loading \(viewModel.currentNetwork.name) channels...")
                                .foregroundColor(.white.opacity(0.5))
                                .font(.system(size: 13))
                        }
                        .frame(maxWidth: .infinity, minHeight: 250)
                    } else if viewModel.filteredChannels.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 36))
                                .foregroundColor(.white.opacity(0.2))
                            Text("No channels found")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                            Text("Try adjusting your search query or category filter.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .frame(maxWidth: .infinity, minHeight: 250)
                    } else {
                        LazyVGrid(columns: columns, spacing: 14) {
                            ForEach(viewModel.filteredChannels) { channel in
                                StationCardView(
                                    channel: channel,
                                    currentTrack: viewModel.currentlyPlayingMap[channel.id],
                                    isPlayingThisChannel: viewModel.player.currentChannel?.id == channel.id && viewModel.player.isPlaying,
                                    onPlay: {
                                        if viewModel.player.currentChannel?.id == channel.id {
                                            viewModel.player.togglePlayPause()
                                        } else {
                                            viewModel.player.play(channel: channel, network: viewModel.currentNetwork)
                                        }
                                    },
                                    onSelectDetails: {
                                        viewModel.selectedStationForDetails = channel
                                    }
                                )
                            }
                        }
                    }
                }
                .padding(24)
            }
        }
        .background(Color(red: 0.08, green: 0.08, blue: 0.10))
    }

    private var sectionTitle: String {
        if !viewModel.searchText.isEmpty {
            return "Search Results"
        }
        switch viewModel.selectedCategory {
        case .all: return "All Stations"
        case .favorites: return "Favorite Stations"
        default: return "\(viewModel.selectedCategory.rawValue) Stations"
        }
    }

    private func activeStationHero(channel: Channel, track: Track) -> some View {
        HStack(spacing: 18) {
            AsyncImageView(url: track.artworkURL ?? channel.artworkURL, cornerRadius: 10)
                .frame(width: 80, height: 80)
                .shadow(radius: 6)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    EqualizerView(isPlaying: viewModel.player.isPlaying, barColor: Color(red: 0.12, green: 0.84, blue: 0.38))
                    Text("NOW PLAYING ON \(channel.name.uppercased())")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.12, green: 0.84, blue: 0.38))
                }

                Text(track.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text(track.artist)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.65))
                    .lineLimit(1)
            }

            Spacer()

            Button(action: {
                viewModel.selectedStationForDetails = channel
            }) {
                Text("Station Details")
                    .font(.system(size: 12, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
