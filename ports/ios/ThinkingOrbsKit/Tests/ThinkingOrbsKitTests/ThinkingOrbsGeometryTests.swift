import Testing
import ThinkingOrbsKit
import Foundation

@Test("Searching 64-point geometry matches the reference frame")
func searchingGeometryMatchesReferenceFrame() {
    let frame = ThinkingOrbEngine.frame(state: .searching, size: .px64, time: 0.6)

    #expect(frame.dots.count == 204)
    #expect(frame.lines.isEmpty)

    let first = frame.dots[0]
    #expect(abs(first.x - 33.490622) < 0.0001)
    #expect(abs(first.y - 32.435651) < 0.0001)
    #expect(abs(first.z - -0.998247) < 0.0001)
    #expect(abs(first.radius - 0.3) < 0.0001)
    #expect(abs(first.ink - 0.619527) < 0.0001)
    #expect(abs(first.alpha - 0.45) < 0.0001)
}

@Test("Every searching frame matches the published golden vectors")
func allSearchingFramesMatchGoldenVectors() throws {
    let golden = try loadGoldenFile()

    for expected in golden.cases where expected.state == "searching" {
        let size: ThinkingOrbSize = expected.size == 64 ? .px64 : .px20
        let frame = ThinkingOrbEngine.frame(state: .searching, size: size, time: expected.time)
        try expect(frame, matches: expected, tolerance: golden.tolerance)
    }
}

@Test("Every working frame matches the published golden vectors")
func allWorkingFramesMatchGoldenVectors() throws {
    let golden = try loadGoldenFile()

    for expected in golden.cases where expected.state == "working" {
        let size: ThinkingOrbSize = expected.size == 64 ? .px64 : .px20
        let frame = ThinkingOrbEngine.frame(state: .working, size: size, time: expected.time)
        try expect(frame, matches: expected, tolerance: golden.tolerance)
    }
}

@Test("Every published state and size matches the golden geometry")
func allPublishedGeometryMatchesGoldenVectors() throws {
    let golden = try loadGoldenFile()

    for expected in golden.cases {
        let state = try #require(ThinkingOrbState(rawValue: expected.state))
        let size: ThinkingOrbSize = expected.size == 64 ? .px64 : .px20
        let frame = ThinkingOrbEngine.frame(state: state, size: size, time: expected.time)
        try expect(frame, matches: expected, tolerance: golden.tolerance)
    }
}

private struct GoldenFile: Decodable {
    let tolerance: Double
    let cases: [GoldenCase]
}

private struct GoldenCase: Decodable {
    let key: String
    let state: String
    let size: Int
    let time: Double
    let dotCount: Int
    let lineCount: Int
    let dots: [Double]
    let lines: [Double]

    enum CodingKeys: String, CodingKey {
        case key, state, size, dotCount, lineCount, dots, lines
        case time = "t"
    }
}

private func loadGoldenFile() throws -> GoldenFile {
    let url = try #require(
        Bundle.module.url(
            forResource: "orbs-golden",
            withExtension: "json",
            subdirectory: "Fixtures"
        )
    )
    let data = try Data(contentsOf: url)
    return try JSONDecoder().decode(GoldenFile.self, from: data)
}

private func expect(
    _ frame: ThinkingOrbFrame,
    matches expected: GoldenCase,
    tolerance: Double
) throws {
    #expect(frame.dots.count == expected.dotCount, "\(expected.key) dot count")
    #expect(frame.lines.count == expected.lineCount, "\(expected.key) line count")

    let actualRecords = frame.dots.map { [$0.x, $0.y, $0.z, $0.radius, $0.ink, $0.alpha] }
    let expectedRecords = stride(from: 0, to: expected.dots.count, by: 6).map {
        Array(expected.dots[$0..<($0 + 6)])
    }
    let actualDots = expected.state == "breathing"
        ? canonicalDotValues(actualRecords, tolerance: tolerance)
        : actualRecords.flatMap { $0 }
    let expectedDots = expected.state == "breathing"
        ? canonicalDotValues(expectedRecords, tolerance: tolerance)
        : expectedRecords.flatMap { $0 }
    #expect(actualDots.count == expectedDots.count)
    for (index, pair) in zip(actualDots, expectedDots).enumerated() {
        #expect(abs(pair.0 - pair.1) < tolerance, "\(expected.key) dot value \(index)")
    }

    let actualLines = frame.lines.flatMap {
        [$0.x1, $0.y1, $0.x2, $0.y2, $0.ink, $0.alpha, $0.width]
    }
    #expect(actualLines.count == expected.lines.count)
    for (index, pair) in zip(actualLines, expected.lines).enumerated() {
        #expect(abs(pair.0 - pair.1) < tolerance, "\(expected.key) line value \(index)")
    }
}

private func canonicalDotValues(
    _ dots: [[Double]],
    tolerance: Double
) -> [Double] {
    dots.sorted { first, second in
        for index in [2, 0, 1, 3, 4, 5] {
            let firstBucket = Int((first[index] / tolerance).rounded())
            let secondBucket = Int((second[index] / tolerance).rounded())
            if firstBucket != secondBucket {
                return firstBucket < secondBucket
            }
        }
        return false
    }
    .flatMap { $0 }
}
