import Foundation
import Combine

public final class AuthManager: ObservableObject {
    public static let shared = AuthManager()

    private let userDefaults = UserDefaults.standard
    private let listenKeyKey = "difm_listen_key"
    private let usernameKey = "difm_username"
    private let favoritesKey = "difm_favorites"
    private let qualityKey = "difm_audio_quality"

    @Published public var listenKey: String {
        didSet {
            userDefaults.set(listenKey, forKey: listenKeyKey)
        }
    }

    @Published public var username: String {
        didSet {
            userDefaults.set(username, forKey: usernameKey)
        }
    }

    @Published public var favoriteChannelIds: Set<Int> {
        didSet {
            let array = Array(favoriteChannelIds)
            userDefaults.set(array, forKey: favoritesKey)
        }
    }

    @Published public var selectedQuality: AudioQuality {
        didSet {
            userDefaults.set(selectedQuality.rawValue, forKey: qualityKey)
        }
    }

    private init() {
        self.listenKey = userDefaults.string(forKey: listenKeyKey) ?? ""
        self.username = userDefaults.string(forKey: usernameKey) ?? ""
        
        let storedFavs = userDefaults.array(forKey: favoritesKey) as? [Int] ?? []
        self.favoriteChannelIds = Set(storedFavs)

        if let qualityRaw = userDefaults.string(forKey: qualityKey),
           let quality = AudioQuality(rawValue: qualityRaw) {
            self.selectedQuality = quality
        } else {
            self.selectedQuality = .premiumHigh
        }
    }

    public var isAuthenticated: Bool {
        return !listenKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public func setListenKeyDirectly(_ key: String) {
        self.listenKey = key.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func logout() {
        self.listenKey = ""
        self.username = ""
    }

    public func isFavorite(channelId: Int) -> Bool {
        favoriteChannelIds.contains(channelId)
    }

    public func toggleFavorite(channelId: Int) {
        if favoriteChannelIds.contains(channelId) {
            favoriteChannelIds.remove(channelId)
        } else {
            favoriteChannelIds.insert(channelId)
        }
    }
}
