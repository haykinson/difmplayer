import SwiftUI

public struct EqualizerView: View {
    public let isPlaying: Bool
    public let barColor: Color

    @State private var bar1Height: CGFloat = 0.3
    @State private var bar2Height: CGFloat = 0.8
    @State private var bar3Height: CGFloat = 0.5
    @State private var bar4Height: CGFloat = 0.9

    private let timer = Timer.publish(every: 0.18, on: .main, in: .common).autoconnect()

    public init(isPlaying: Bool, barColor: Color = Color(red: 0.12, green: 0.84, blue: 0.38)) {
        self.isPlaying = isPlaying
        self.barColor = barColor
    }

    public var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            bar(height: bar1Height)
            bar(height: bar2Height)
            bar(height: bar3Height)
            bar(height: bar4Height)
        }
        .frame(width: 14, height: 14)
        .onReceive(timer) { _ in
            guard isPlaying else {
                withAnimation(.easeOut(duration: 0.2)) {
                    bar1Height = 0.2
                    bar2Height = 0.2
                    bar3Height = 0.2
                    bar4Height = 0.2
                }
                return
            }
            withAnimation(.easeInOut(duration: 0.18)) {
                bar1Height = CGFloat.random(in: 0.3...1.0)
                bar2Height = CGFloat.random(in: 0.2...0.9)
                bar3Height = CGFloat.random(in: 0.4...1.0)
                bar4Height = CGFloat.random(in: 0.2...0.8)
            }
        }
    }

    private func bar(height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(barColor)
            .frame(width: 2, height: max(2, height * 14))
    }
}
