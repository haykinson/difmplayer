import Foundation

public struct Channel: Identifiable, Hashable, Codable {
    public let id: Int
    public let key: String
    public let name: String
    public let descriptionShort: String?
    public let descriptionLong: String?
    public let assetUrl: String?
    public let bannerUrl: String?
    public let images: [String: String]?

    enum CodingKeys: String, CodingKey {
        case id
        case key
        case name
        case descriptionShort = "description_short"
        case descriptionLong = "description_long"
        case assetUrl = "asset_url"
        case bannerUrl = "banner_url"
        case images
    }

    public var effectiveDescription: String {
        descriptionShort ?? descriptionLong ?? ""
    }

    public var artworkURL: URL? {
        // Try square, default, compact, or assetUrl
        let rawPath = images?["square"] ?? images?["default"] ?? images?["compact"] ?? assetUrl
        guard var path = rawPath else { return nil }
        
        // Strip URI template like "{?size,height,width,quality,pad}"
        if let braceIndex = path.firstIndex(of: "{") {
            path = String(path[..<braceIndex])
        }
        
        if path.hasPrefix("//") {
            path = "https:" + path
        } else if !path.hasPrefix("http") {
            path = "https://" + path
        }
        
        return URL(string: path)
    }

    public var bannerImageURL: URL? {
        guard var path = bannerUrl ?? images?["horizontal_banner"] else { return nil }
        if let braceIndex = path.firstIndex(of: "{") {
            path = String(path[..<braceIndex])
        }
        if path.hasPrefix("//") {
            path = "https:" + path
        } else if !path.hasPrefix("http") {
            path = "https://" + path
        }
        return URL(string: path)
    }
}
