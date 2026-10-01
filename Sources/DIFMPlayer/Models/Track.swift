import Foundation

public struct TrackVotes: Codable, Hashable {
    public let up: Int?
    public let down: Int?
}

public struct Track: Identifiable, Hashable, Codable {
    public let id: Int?
    public let title: String
    public let artist: String
    public let duration: Double?
    public let startTime: Date?
    public let artUrl: String?
    public let releaseName: String?
    public let votes: TrackVotes?

    public init(
        id: Int? = nil,
        title: String,
        artist: String,
        duration: Double? = nil,
        startTime: Date? = nil,
        artUrl: String? = nil,
        releaseName: String? = nil,
        votes: TrackVotes? = nil
    ) {
        self.id = id
        self.title = title
        self.artist = artist
        self.duration = duration
        self.startTime = startTime
        self.artUrl = artUrl
        self.releaseName = releaseName
        self.votes = votes
    }

    public var artworkURL: URL? {
        guard var path = artUrl else { return nil }
        if path.hasPrefix("//") {
            path = "https:" + path
        } else if !path.hasPrefix("http") {
            path = "https://" + path
        }
        return URL(string: path)
    }

    public var formattedDuration: String {
        guard let duration = duration, duration > 0 else { return "" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// Model for decoding the /currently_playing response items
public struct CurrentlyPlayingItem: Codable {
    public let channelId: Int
    public let channelKey: String
    public let track: CurrentlyPlayingTrack?

    enum CodingKeys: String, CodingKey {
        case channelId = "channel_id"
        case channelKey = "channel_key"
        case track
    }
}

public struct CurrentlyPlayingTrack: Codable {
    public let id: Int?
    public let displayArtist: String?
    public let displayTitle: String?
    public let startTime: String?
    public let duration: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case displayArtist = "display_artist"
        case displayTitle = "display_title"
        case startTime = "start_time"
        case duration
    }
}

// Model for decoding /track_history/channel/{id} items
public struct TrackHistoryItem: Codable {
    public let trackId: Int?
    public let displayArtist: String?
    public let artist: String?
    public let displayTitle: String?
    public let title: String?
    public let duration: Double?
    public let started: Int?
    public let artUrl: String?
    public let release: String?
    public let votes: TrackVotes?

    enum CodingKeys: String, CodingKey {
        case trackId = "track_id"
        case displayArtist = "display_artist"
        case artist
        case displayTitle = "display_title"
        case title
        case duration
        case started
        case artUrl = "art_url"
        case release
        case votes
    }

    public func toTrack() -> Track {
        let artistName = displayArtist ?? artist ?? "Unknown Artist"
        let trackTitle = displayTitle ?? title ?? "Unknown Title"
        let startDate: Date? = started != nil ? Date(timeIntervalSince1970: TimeInterval(started!)) : nil
        return Track(
            id: trackId,
            title: trackTitle,
            artist: artistName,
            duration: duration,
            startTime: startDate,
            artUrl: artUrl,
            releaseName: release,
            votes: votes
        )
    }
}
