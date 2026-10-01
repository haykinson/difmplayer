import SwiftUI
import AppKit

public final class ImageCache {
    public static let shared = NSCache<NSURL, NSImage>()
}

public struct AsyncImageView: View {
    public let url: URL?
    public let placeholderSystemName: String
    public let cornerRadius: CGFloat

    @State private var loadedImage: NSImage? = nil
    @State private var isLoading: Bool = false

    public init(url: URL?, placeholderSystemName: String = "radio", cornerRadius: CGFloat = 8) {
        self.url = url
        self.placeholderSystemName = placeholderSystemName
        self.cornerRadius = cornerRadius
    }

    public var body: some View {
        ZStack {
            if let image = loadedImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.15, green: 0.16, blue: 0.20), Color(red: 0.10, green: 0.10, blue: 0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    Image(systemName: placeholderSystemName)
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.35))
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { _ in
            loadImage()
        }
    }

    private func loadImage() {
        guard let url = url else {
            loadedImage = nil
            return
        }

        // Check memory cache
        if let cached = ImageCache.shared.object(forKey: url as NSURL) {
            self.loadedImage = cached
            return
        }

        isLoading = true
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data = data, let image = NSImage(data: data) else {
                DispatchQueue.main.async { self.isLoading = false }
                return
            }

            ImageCache.shared.setObject(image, forKey: url as NSURL)
            DispatchQueue.main.async {
                self.loadedImage = image
                self.isLoading = false
            }
        }.resume()
    }
}
