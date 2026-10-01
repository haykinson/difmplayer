import Foundation

public struct Network: Identifiable, Hashable, Codable {
    public let id: String
    public let name: String
    public let shortName: String
    public let listenURL: String
    public let description: String

    public init(id: String, name: String, shortName: String, listenURL: String, description: String) {
        self.id = id
        self.name = name
        self.shortName = shortName
        self.listenURL = listenURL
        self.description = description
    }

    public var domain: String {
        switch id {
        case "di": return "di.fm"
        default: return "\(shortName).com"
        }
    }

    public static let difm = Network(
        id: "di",
        name: "DI.FM",
        shortName: "di",
        listenURL: "https://listen.di.fm",
        description: "Electronic music radio with 90+ curated channels"
    )

    public static let radiotunes = Network(
        id: "radiotunes",
        name: "RadioTunes",
        shortName: "radiotunes",
        listenURL: "https://listen.radiotunes.com",
        description: "Wide variety of musical genres from 70s to smooth jazz"
    )

    public static let rockradio = Network(
        id: "rockradio",
        name: "RockRadio",
        shortName: "rockradio",
        listenURL: "https://listen.rockradio.com",
        description: "Classic rock, hard rock, alternative, metal and more"
    )

    public static let jazzradio = Network(
        id: "jazzradio",
        name: "JazzRadio",
        shortName: "jazzradio",
        listenURL: "https://listen.jazzradio.com",
        description: "Smooth jazz, swing, bebop, bossa nova and classic jazz"
    )

    public static let classicalradio = Network(
        id: "classicalradio",
        name: "Classical Radio",
        shortName: "classicalradio",
        listenURL: "https://listen.classicalradio.com",
        description: "Orchestral, piano, opera, baroque, and movie soundtracks"
    )

    public static let zenradio = Network(
        id: "zenradio",
        name: "Zen Radio",
        shortName: "zenradio",
        listenURL: "https://listen.zenradio.com",
        description: "Relaxing, meditative, spa, healing and ambient sounds"
    )

    public static let allNetworks: [Network] = [
        .difm,
        .radiotunes,
        .rockradio,
        .jazzradio,
        .classicalradio,
        .zenradio
    ]
}
