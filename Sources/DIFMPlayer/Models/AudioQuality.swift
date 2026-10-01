import Foundation

public enum AudioQuality: String, CaseIterable, Identifiable, Codable {
    case premiumHigh = "premium_high"
    case premiumMedium = "premium_medium"
    case premiumStandard = "premium"
    case premiumLow = "premium_low"
    case publicMedium = "public3"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .premiumHigh:
            return "320k MP3 (Ultra HQ)"
        case .premiumMedium:
            return "128k AAC (Balanced HQ)"
        case .premiumStandard:
            return "256k MP3 (High Quality)"
        case .premiumLow:
            return "64k AAC (Low Data)"
        case .publicMedium:
            return "Public Stream (Free)"
        }
    }

    public var shortBadge: String {
        switch self {
        case .premiumHigh:
            return "320k"
        case .premiumMedium:
            return "128k AAC"
        case .premiumStandard:
            return "256k"
        case .premiumLow:
            return "64k"
        case .publicMedium:
            return "FREE"
        }
    }

    public var isPremiumOnly: Bool {
        return self != .publicMedium
    }
}
