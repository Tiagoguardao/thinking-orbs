#if os(macOS)
import AppKit
import SwiftUI
import ThinkingOrbsKit

@main
struct ThinkingOrbsSnapshot {
    @MainActor
    static func main() throws {
        if CommandLine.arguments.dropFirst().first == "--benchmark" {
            runGeometryBenchmark()
            return
        }
        if CommandLine.arguments.dropFirst().first == "--probe" {
            let path = CommandLine.arguments.dropFirst(2).first ?? "build/parity/probe/swift"
            try renderProbes(to: URL(fileURLWithPath: path, isDirectory: true))
            return
        }
        let outputDirectory = URL(
            fileURLWithPath: CommandLine.arguments.dropFirst().first ?? "build/parity/swift",
            isDirectory: true
        )
        try FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )

        let times: [Double] = [0.6, 1.7, 3.3, 5.1]
        var captureCount = 0
        for state in ThinkingOrbState.allCases {
            for size in ThinkingOrbSize.allCases.sorted(by: { $0.rawValue > $1.rawValue }) {
                for theme in [ThinkingOrbTheme.dark, .light] {
                    for time in times {
                        let view = ThinkingOrb(
                            state: state,
                            size: size,
                            theme: theme,
                            paused: true,
                            renderTime: time
                        )
                        let renderer = ImageRenderer(content: view)
                        renderer.scale = 2
                        renderer.proposedSize = ProposedViewSize(
                            width: size.rawValue,
                            height: size.rawValue
                        )
                        guard let image = renderer.nsImage,
                              let tiff = image.tiffRepresentation,
                              let bitmap = NSBitmapImageRep(data: tiff),
                              let png = bitmap.representation(using: .png, properties: [:]) else {
                            throw SnapshotError.renderFailed(state.rawValue)
                        }
                        let themeKey = theme == .dark ? "d" : "l"
                        let name = "\(state.rawValue)-\(Int(size.rawValue))-\(themeKey)-\(time).png"
                        try png.write(to: outputDirectory.appendingPathComponent(name))
                        captureCount += 1
                    }
                }
            }
        }
        print("Generated \(captureCount) Swift captures at \(outputDirectory.path)")
    }

    private static func runGeometryBenchmark() {
        let states: [ThinkingOrbState] = [
            .composing, .working, .searching, .weaving,
            .composing, .working, .weaving, .searching,
        ]
        let iterations = 600
        var renderedDots = 0
        let start = ProcessInfo.processInfo.systemUptime
        for iteration in 0..<iterations {
            let time = Double(iteration) / 60
            for state in states {
                renderedDots += ThinkingOrbEngine.frame(
                    state: state,
                    size: .px64,
                    time: time
                ).dots.count
            }
        }
        let duration = ProcessInfo.processInfo.systemUptime - start
        let instanceFrames = Double(iterations * states.count)
        let averageMilliseconds = duration / instanceFrames * 1_000
        print(
            "8-orb geometry benchmark: \(iterations) frames, \(renderedDots) dots, "
                + String(format: "%.4f ms per orb-frame", averageMilliseconds)
        )
    }

    @MainActor
    private static func renderProbes(to outputDirectory: URL) throws {
        try FileManager.default.createDirectory(at: outputDirectory, withIntermediateDirectories: true)
        for radius in [0.35, 0.5, 1.0, 2.0, 5.0] {
            for dark in [true, false] {
                let grayscale = (dark ? 0.7 : 0.3) * 255
                let view = Canvas { context, _ in
                    let rectangle = CGRect(x: 10 - radius, y: 10 - radius, width: radius * 2, height: radius * 2)
                    let channel = grayscale.rounded() / 255
                    context.fill(
                        Path(ellipseIn: rectangle),
                        with: .color(
                            Color(.sRGB, red: channel, green: channel, blue: channel, opacity: 0.65)
                        )
                    )
                }
                .frame(width: 20, height: 20)
                let renderer = ImageRenderer(content: view)
                renderer.scale = 2
                renderer.proposedSize = ProposedViewSize(width: 20, height: 20)
                guard let image = renderer.nsImage,
                      let tiff = image.tiffRepresentation,
                      let bitmap = NSBitmapImageRep(data: tiff),
                      let png = bitmap.representation(using: .png, properties: [:]) else {
                    throw SnapshotError.renderFailed("probe")
                }
                let radiusKey = radius == floor(radius) ? String(Int(radius)) : String(radius)
                let name = "probe-r\(radiusKey)-\(dark ? "d" : "l").png"
                try png.write(to: outputDirectory.appendingPathComponent(name))
            }
        }
        for dark in [true, false] {
            let view = Canvas { context, _ in
                let channel = ((dark ? 0.7 : 0.3) * 255).rounded() / 255
                for index in 0..<24 {
                    let x = 10 + sin(Double(index) * 1.7) * 0.8
                    let y = 10 + cos(Double(index) * 2.3) * 0.8
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - 1.3, y: y - 1.3, width: 2.6, height: 2.6)),
                        with: .color(
                            Color(.sRGB, red: channel, green: channel, blue: channel, opacity: 0.15)
                        )
                    )
                }
            }
            .frame(width: 20, height: 20)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            renderer.proposedSize = ProposedViewSize(width: 20, height: 20)
            guard let image = renderer.nsImage,
                  let tiff = image.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: tiff),
                  let png = bitmap.representation(using: .png, properties: [:]) else {
                throw SnapshotError.renderFailed("overlap-probe")
            }
            try png.write(
                to: outputDirectory.appendingPathComponent("probe-overlap-\(dark ? "d" : "l").png")
            )
        }
        print("Generated 12 Swift raster probes at \(outputDirectory.path)")
    }
}

private enum SnapshotError: Error {
    case renderFailed(String)
}
#else
@main
struct ThinkingOrbsSnapshot {
    static func main() {
        fatalError("ThinkingOrbsSnapshot runs on macOS only")
    }
}
#endif
