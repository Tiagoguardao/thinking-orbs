import SwiftUI

public enum ThinkingOrbTheme: String, CaseIterable, Sendable {
    case auto
    case dark
    case light
}

public enum ThinkingOrbPaint {
    public static func grayscale(ink: Double, isDark: Bool) -> Double {
        let clampedInk = min(1, max(0, ink))
        let white = isDark ? 1 - clampedInk : clampedInk
        return (white * 255).rounded() / 255
    }
}

public struct ThinkingOrb: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    private let state: ThinkingOrbState
    private let size: ThinkingOrbSize
    private let theme: ThinkingOrbTheme
    private let speed: Double
    private let paused: Bool
    private let renderTime: TimeInterval?

    public init(
        state: ThinkingOrbState = .working,
        size: ThinkingOrbSize = .px64,
        theme: ThinkingOrbTheme = .auto,
        speed: Double = 1,
        paused: Bool = false,
        renderTime: TimeInterval? = nil
    ) {
        self.state = state
        self.size = size
        self.theme = theme
        self.speed = speed
        self.paused = paused
        self.renderTime = renderTime
    }

    public var body: some View {
        Group {
            if let renderTime {
                orbCanvas(time: renderTime)
            } else {
                TimelineView(.animation(paused: paused || reduceMotion || scenePhase != .active)) { _ in
                    orbCanvas(time: timelineTime)
                }
            }
        }
        .frame(width: size.rawValue, height: size.rawValue)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibilityLabel))
        .accessibilityAddTraits(.isImage)
    }

    private var timelineTime: TimeInterval {
        if reduceMotion { return 0.6 }
        return ProcessInfo.processInfo.systemUptime
            * ThinkingOrbEngine.baseSpeed(state: state, size: size)
            * speed
    }

    private var isDark: Bool {
        switch theme {
        case .auto:
            colorScheme == .dark
        case .dark:
            true
        case .light:
            false
        }
    }

    private var accessibilityLabel: String {
        switch state {
        case .working: "Working…"
        case .searching: "Searching…"
        case .solving: "Solving…"
        case .listening: "Listening…"
        case .connecting: "Connecting…"
        case .weaving: "Weaving…"
        case .composing: "Composing…"
        case .breathing: "Thinking…"
        case .shaping: "Shaping…"
        }
    }

    private func orbCanvas(time: TimeInterval) -> some View {
        let frame = ThinkingOrbEngine.frame(state: state, size: size, time: time)

        return Canvas(opaque: false, colorMode: .nonLinear, rendersAsynchronously: false) { context, _ in
            for line in frame.lines {
                var path = Path()
                path.move(to: CGPoint(x: line.x1, y: line.y1))
                path.addLine(to: CGPoint(x: line.x2, y: line.y2))
                context.stroke(
                    path,
                    with: .color(orbColor(ink: line.ink, alpha: line.alpha)),
                    lineWidth: line.width
                )
            }

            for dot in frame.dots {
                let diameter = dot.radius * 2
                let rectangle = CGRect(
                    x: dot.x - dot.radius,
                    y: dot.y - dot.radius,
                    width: diameter,
                    height: diameter
                )
                context.fill(
                    Path(ellipseIn: rectangle),
                    with: .color(orbColor(ink: dot.ink, alpha: dot.alpha))
                )
            }
        }
    }

    private func orbColor(ink: Double, alpha: Double) -> Color {
        let grayscale = ThinkingOrbPaint.grayscale(ink: ink, isDark: isDark)
        return Color(
            .sRGB,
            red: grayscale,
            green: grayscale,
            blue: grayscale,
            opacity: alpha
        )
    }
}
