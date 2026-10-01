import SwiftUI

public struct SidebarView: View {
    @ObservedObject public var viewModel: AppViewModel

    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // App Branding Header
            HStack(spacing: 10) {
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.12, green: 0.84, blue: 0.38), Color(red: 0.05, green: 0.55, blue: 0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .frame(width: 34, height: 34)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Image(systemName: "waveform")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(viewModel.currentNetwork.name)
                        .font(.system(size: 16, weight: .black))
                        .foregroundColor(.white)
                    Text("Native Player")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 18)

            // AudioAddict Network Selector
            Menu {
                ForEach(Network.allNetworks) { net in
                    Button(action: {
                        viewModel.currentNetwork = net
                    }) {
                        HStack {
                            Text(net.name)
                            if viewModel.currentNetwork.id == net.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                HStack {
                    Image(systemName: "dot.radiowaves.left.and.right")
                        .foregroundColor(Color(red: 0.12, green: 0.84, blue: 0.38))
                    Text(viewModel.currentNetwork.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .menuStyle(.borderlessButton)
            .padding(.horizontal, 16)

            Divider().background(Color.white.opacity(0.08))

            // Navigation Sections
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Main Library Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LIBRARY")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.35))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 2)

                        sidebarRow(
                            title: "All Stations",
                            icon: "music.note.list",
                            isSelected: viewModel.selectedCategory == .all,
                            badge: "\(viewModel.channels.count)"
                        ) {
                            viewModel.selectedCategory = .all
                        }

                        sidebarRow(
                            title: "Favorites",
                            icon: "heart.fill",
                            isSelected: viewModel.selectedCategory == .favorites,
                            badge: "\(viewModel.auth.favoriteChannelIds.count)",
                            accentColor: Color(red: 0.12, green: 0.84, blue: 0.38)
                        ) {
                            viewModel.selectedCategory = .favorites
                        }
                    }

                    // Genres Filter Section
                    VStack(alignment: .leading, spacing: 4) {
                        Text("GENRES")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.35))
                            .padding(.horizontal, 16)
                            .padding(.bottom, 2)

                        ForEach(StationCategory.allCases.filter { $0 != .all && $0 != .favorites }) { cat in
                            sidebarRow(
                                title: cat.rawValue,
                                icon: iconForCategory(cat),
                                isSelected: viewModel.selectedCategory == cat
                            ) {
                                viewModel.selectedCategory = cat
                            }
                        }
                    }
                }
            }

            Spacer()

            Divider().background(Color.white.opacity(0.08))

            // Bottom Profile / Premium Status Card
            VStack(alignment: .leading, spacing: 8) {
                if viewModel.auth.isAuthenticated {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color(red: 0.12, green: 0.84, blue: 0.38))
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 1) {
                            Text("Premium Active")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            if !viewModel.auth.username.isEmpty {
                                Text(viewModel.auth.username)
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.5))
                            } else {
                                Text(viewModel.auth.selectedQuality.displayName)
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }

                        Spacer()

                        Button(action: {
                            viewModel.showLoginSheet = true
                        }) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .buttonStyle(.plain)
                        .help("Account Settings")
                    }
                    .padding(10)
                    .background(Color.white.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Button(action: {
                        viewModel.showLoginSheet = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 14))
                            Text("Log In (Premium)")
                                .font(.system(size: 12, weight: .bold))
                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(red: 0.12, green: 0.84, blue: 0.38))
                        .foregroundColor(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(width: 210)
        .background(Color(red: 0.07, green: 0.07, blue: 0.09))
    }

    private func sidebarRow(
        title: String,
        icon: String,
        isSelected: Bool,
        badge: String? = nil,
        accentColor: Color? = nil
    , action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(isSelected ? (accentColor ?? Color(red: 0.12, green: 0.84, blue: 0.38)) : .white.opacity(0.6))
                    .frame(width: 18)

                Text(title)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.75))

                Spacer()

                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(isSelected ? .black : .white.opacity(0.5))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(isSelected ? Color(red: 0.12, green: 0.84, blue: 0.38) : Color.white.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 8)
    }

    private func iconForCategory(_ category: StationCategory) -> String {
        switch category {
        case .all: return "music.note.list"
        case .favorites: return "heart.fill"
        case .trance: return "sparkles"
        case .house: return "building.2"
        case .techno: return "gearshape.2"
        case .chillout: return "moon.stars"
        case .dnb: return "waveform.path.ecg"
        case .ambient: return "wind"
        case .club: return "speaker.wave.3.fill"
        }
    }
}
