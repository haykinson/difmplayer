import Foundation

public enum APIError: LocalizedError {
    case invalidURL
    case authenticationFailed(String)
    case playlistEmpty
    case networkError(Error)

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "The request URL is invalid."
        case .authenticationFailed(let message):
            return "Authentication failed: \(message)"
        case .playlistEmpty:
            return "No stream URL found in playlist."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

public final class AudioAddictAPI {
    public static let shared = AudioAddictAPI()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }

    public struct AuthResponse: Codable {
        public let listenKey: String?
        public let apiKey: String?
        public let error: String?

        enum CodingKeys: String, CodingKey {
            case listenKey = "listen_key"
            case apiKey = "api_key"
            case error
        }
    }

    // Authenticate with AudioAddict using email/username and password
    public func authenticate(network: Network, username: String, password: String) async throws -> AuthResponse {
        guard let url = URL(string: "https://api.audioaddict.com/v1/\(network.shortName)/members/authenticate") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let parameters: [String: String] = [
            "username": username,
            "password": password
        ]

        let bodyString = parameters
            .compactMap { key, value in
                let allowed = CharacterSet.urlQueryAllowed
                guard let encodedKey = key.addingPercentEncoding(withAllowedCharacters: allowed),
                      let encodedValue = value.addingPercentEncoding(withAllowedCharacters: allowed) else {
                    return nil
                }
                return "\(encodedKey)=\(encodedValue)"
            }
            .joined(separator: "&")

        request.httpBody = bodyString.data(using: .utf8)

        let (data, response) = try await session.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorMsg = String(data: data, encoding: .utf8) ?? "HTTP \(httpResponse.statusCode)"
            throw APIError.authenticationFailed(errorMsg)
        }

        let decoded = try JSONDecoder().decode(AuthResponse.self, from: data)
        if let error = decoded.error {
            throw APIError.authenticationFailed(error)
        }
        guard let listenKey = decoded.listenKey, !listenKey.isEmpty else {
            throw APIError.authenticationFailed("No listen key received from API.")
        }

        return decoded
    }

    // Fetch all channels for a network
    public func fetchChannels(network: Network) async throws -> [Channel] {
        guard let url = URL(string: "https://api.audioaddict.com/v1/\(network.shortName)/channels") else {
            throw APIError.invalidURL
        }

        let (data, _) = try await session.data(from: url)
        let channels = try JSONDecoder().decode([Channel].self, from: data)
        return channels.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    // Fetch currently playing track for all channels on a network
    public func fetchCurrentlyPlaying(network: Network) async throws -> [Int: Track] {
        guard let url = URL(string: "https://api.audioaddict.com/v1/\(network.shortName)/currently_playing") else {
            throw APIError.invalidURL
        }

        let (data, _) = try await session.data(from: url)
        let items = try JSONDecoder().decode([CurrentlyPlayingItem].self, from: data)

        var result: [Int: Track] = [:]
        let dateFormatter = ISO8601DateFormatter()

        for item in items {
            guard let track = item.track else { continue }
            let artist = track.displayArtist ?? "Unknown Artist"
            let title = track.displayTitle ?? "Unknown Track"
            var startDate: Date? = nil
            if let startStr = track.startTime {
                startDate = dateFormatter.date(from: startStr)
            }

            result[item.channelId] = Track(
                id: track.id,
                title: title,
                artist: artist,
                duration: track.duration,
                startTime: startDate,
                artUrl: nil,
                releaseName: nil,
                votes: nil
            )
        }

        return result
    }

    // Fetch recent track history and high-res artwork for a channel
    public func fetchTrackHistory(network: Network, channelId: Int) async throws -> [Track] {
        guard let url = URL(string: "https://api.audioaddict.com/v1/\(network.shortName)/track_history/channel/\(channelId)") else {
            throw APIError.invalidURL
        }

        let (data, _) = try await session.data(from: url)
        let historyItems = try JSONDecoder().decode([TrackHistoryItem].self, from: data)
        return historyItems.map { $0.toTrack() }
    }

    // Fetch and resolve the direct stream URL from a .pls playlist
    public func fetchStreamURL(channelKey: String, network: Network, quality: AudioQuality, listenKey: String?) async throws -> URL {
        let playlistURLString: String
        let cleanKey = listenKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if !cleanKey.isEmpty && quality != .publicMedium {
            playlistURLString = "https://listen.\(network.shortName).com/\(quality.rawValue)/\(channelKey).pls?listen_key=\(cleanKey)"
        } else {
            playlistURLString = "http://listen.\(network.shortName).com/public3/\(channelKey).pls"
        }

        guard let playlistURL = URL(string: playlistURLString) else {
            throw APIError.invalidURL
        }

        let (data, _) = try await session.data(from: playlistURL)
        guard let text = String(data: data, encoding: .utf8) else {
            throw APIError.playlistEmpty
        }

        // Parse PLS INI format: look for File1=..., File2=...
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.lowercased().hasPrefix("file1=") || trimmed.lowercased().hasPrefix("file=") {
                let parts = trimmed.split(separator: "=", maxSplits: 1).map(String.init)
                if parts.count == 2 {
                    let streamAddress = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if let streamURL = URL(string: streamAddress) {
                        return streamURL
                    }
                }
            }
        }

        // If File1 wasn't found, try any FileX=
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.lowercased().hasPrefix("file") && trimmed.contains("=") {
                let parts = trimmed.split(separator: "=", maxSplits: 1).map(String.init)
                if parts.count == 2 {
                    let streamAddress = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    if let streamURL = URL(string: streamAddress) {
                        return streamURL
                    }
                }
            }
        }

        // Fallback direct URL if playlist couldn't be parsed
        if !cleanKey.isEmpty {
            if let fallbackURL = URL(string: "http://prem1.\(network.shortName).com:80/\(channelKey)?\(cleanKey)") {
                return fallbackURL
            }
        }

        throw APIError.playlistEmpty
    }
}
