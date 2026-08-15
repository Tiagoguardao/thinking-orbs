import Foundation

public enum ThinkingOrbState: String, CaseIterable, Sendable {
    case working
    case searching
    case solving
    case listening
    case connecting
    case weaving
    case composing
    case breathing
    case shaping
}

public enum ThinkingOrbSize: Double, CaseIterable, Sendable {
    case px20 = 20
    case px64 = 64
}

public struct ThinkingOrbDot: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let z: Double
    public let radius: Double
    public let ink: Double
    public let alpha: Double
}

public struct ThinkingOrbLine: Equatable, Sendable {
    public let x1: Double
    public let y1: Double
    public let x2: Double
    public let y2: Double
    public let ink: Double
    public let alpha: Double
    public let width: Double
}

public struct ThinkingOrbFrame: Equatable, Sendable {
    public let dots: [ThinkingOrbDot]
    public let lines: [ThinkingOrbLine]
}

public enum ThinkingOrbEngine {
    public static func baseSpeed(
        state: ThinkingOrbState,
        size: ThinkingOrbSize
    ) -> Double {
        OrbSpec.preset(state: state, size: size).speed
    }

    public static func frame(
        state: ThinkingOrbState,
        size: ThinkingOrbSize,
        time: TimeInterval
    ) -> ThinkingOrbFrame {
        let options = OrbSpec.preset(state: state, size: size).options
        switch state {
        case .working:
            return orbitsFrame(size: size.rawValue, time: time, options: options)
        case .searching:
            return globeFrame(size: size.rawValue, time: time, options: options)
        case .solving:
            return rubikFrame(size: size.rawValue, time: time, options: options)
        case .listening:
            return waveFrame(size: size.rawValue, time: time, options: options)
        case .connecting:
            return webFrame(size: size.rawValue, time: time, options: options)
        case .weaving:
            return braidFrame(size: size.rawValue, time: time, options: options)
        case .composing:
            return ribbonFrame(size: size.rawValue, time: time, options: options)
        case .breathing:
            return ribbonFrame(size: size.rawValue, time: time, options: options)
        case .shaping:
            return morphFrame(size: size.rawValue, time: time, options: options)
        }
    }

    private static func orbitsFrame(
        size: Double,
        time: Double,
        options: [String: Double]
    ) -> ThinkingOrbFrame {
        let center = size / 2
        let sphereRadius = center * 0.82
        let project = projector(
            yaw: time * 0.12,
            tilt: 0.3,
            centerX: center,
            centerY: center,
            scale: 1
        )
        let radiusScale = pow(size / 300, value(options, "rsPow", default: 0.6))
        let orbitCount = intValue(options, "orbitN", default: 12)
        let ghostCount = intValue(options, "ghostN", default: 40)
        let particleCount = intValue(options, "particles", default: 3)
        var dots: [ThinkingOrbDot] = []

        for orbit in 0..<orbitCount {
            let h1 = hash(Double(orbit), 1.7)
            let h2 = hash(Double(orbit), 5.2)
            let h3 = hash(Double(orbit), 8.9)
            let orbitRadius = sphereRadius * (0.45 + 0.52 * h1)
            let theta = h1 * 2 * .pi
            let phi = acos(2 * h2 - 1)
            let normalX = sin(phi) * cos(theta)
            let normalY = cos(phi)
            let normalZ = sin(phi) * sin(theta)
            var basisUX = -normalY
            var basisUY = normalX
            let basisUZ = 0.0
            let basisULength = max(1e-6, sqrt(basisUX * basisUX + basisUY * basisUY))
            basisUX /= basisULength
            basisUY /= basisULength
            let basisVX = normalY * basisUZ - normalZ * basisUY
            let basisVY = normalZ * basisUX - normalX * basisUZ
            let basisVZ = normalX * basisUY - normalY * basisUX
            let speed = (0.25 + 0.55 * h3) * (h3 > 0.5 ? 1 : -1)

            for index in 0..<ghostCount {
                let angle = (Double(index) / Double(ghostCount)) * 2 * .pi
                let projected = project(
                    (basisUX * cos(angle) + basisVX * sin(angle)) * orbitRadius,
                    (basisUY * cos(angle) + basisVY * sin(angle)) * orbitRadius,
                    (basisUZ * cos(angle) + basisVZ * sin(angle)) * orbitRadius
                )
                let depth = (projected.z / orbitRadius + 1) / 2
                dots.append(
                    ThinkingOrbDot(
                        x: projected.x,
                        y: projected.y,
                        z: projected.z,
                        radius: value(options, "ghostR", default: 0.9) * radiusScale,
                        ink: 0.72,
                        alpha: value(options, "ghostA", default: 0.5) * (0.4 + 0.6 * depth)
                    )
                )
            }

            for particle in 0..<particleCount {
                let angle = time * speed + (Double(particle) / Double(particleCount)) * 2 * .pi + h2 * 6
                let projected = project(
                    (basisUX * cos(angle) + basisVX * sin(angle)) * orbitRadius,
                    (basisUY * cos(angle) + basisVY * sin(angle)) * orbitRadius,
                    (basisUZ * cos(angle) + basisVZ * sin(angle)) * orbitRadius
                )
                let depth = (projected.z / orbitRadius + 1) / 2
                dots.append(
                    ThinkingOrbDot(
                        x: projected.x,
                        y: projected.y,
                        z: projected.z,
                        radius: (
                            value(options, "partR", default: 1.2)
                                + value(options, "partRDepth", default: 1.6) * depth
                        ) * radiusScale,
                        ink: 0.3 - 0.22 * depth,
                        alpha: 1
                    )
                )
            }
        }

        return finalized(dots: dots)
    }

    private static func globeFrame(
        size: Double,
        time: Double,
        options: [String: Double]
    ) -> ThinkingOrbFrame {
        let latitudeRings = intValue(options, "latRings", default: 17)
        let longitudeDensity = intValue(options, "lonDensity", default: 44)

        let spin = 0.5
        let center = size / 2
        let sphereRadius = center * 0.82
        let tilt = 0.4 + 0.06 * sin(time * 0.35)
        let project = projector(
            yaw: time * spin,
            tilt: tilt,
            centerX: center,
            centerY: center,
            scale: sphereRadius
        )
        let scan = time * (spin + (1.7 - spin) * value(options, "scanMul", default: 1))
        let radiusScale = pow(size / 300, value(options, "rsPow", default: 0.6))

        var dots: [ThinkingOrbDot] = []
        for latitudeIndex in 0...latitudeRings {
            let latitude = -.pi / 2 + (Double(latitudeIndex) / Double(latitudeRings)) * .pi
            let cosineLatitude = cos(latitude)
            let sineLatitude = sin(latitude)
            let longitudeCount = max(1, Int((abs(cosineLatitude) * Double(longitudeDensity)).rounded()))

            for longitudeIndex in 0..<longitudeCount {
                let longitude = (Double(longitudeIndex) / Double(longitudeCount)) * 2 * .pi
                let projected = project(
                    cosineLatitude * cos(longitude),
                    sineLatitude,
                    cosineLatitude * sin(longitude)
                )
                let depth = (projected.z + 1) / 2
                let delta = angleDelta(longitude + time * spin, scan)
                let boost = exp(-(delta * delta) / 0.18) * max(0, projected.z)
                dots.append(
                    ThinkingOrbDot(
                        x: projected.x,
                        y: projected.y,
                        z: projected.z,
                        radius: max(
                            value(options, "rMin", default: 0.3),
                            (
                                value(options, "rBase", default: 0.6)
                                    + value(options, "rDepth", default: 1.7) * depth
                                    + value(options, "rBoost", default: 1) * boost
                            ) * radiusScale
                        ),
                        ink: value(options, "inkFar", default: 0.62)
                            - value(options, "inkSpan", default: 0.54) * depth,
                        alpha: value(options, "dimBase", default: 1)
                            + (1 - value(options, "dimBase", default: 1)) * min(1, boost)
                    )
                )
            }
        }

        dots.sort { $0.z < $1.z }
        return ThinkingOrbFrame(dots: dots, lines: [])
    }

    private struct Move {
        let axis: Int
        let lowerBound: Double
        let upperBound: Double
        let angle: Double
    }

    private static func rubikFrame(
        size: Double,
        time: Double,
        options: [String: Double]
    ) -> ThinkingOrbFrame {
        let latitudeRings = intValue(options, "latRings", default: 15)
        let longitudeDensity = intValue(options, "lonDensity", default: 40)
        let radiusBase = value(options, "rBase", default: 0.6)
        let radiusDepth = value(options, "rDepth", default: 1.7)
        let radiusActive = value(options, "rActive", default: 0.3)
        let center = size / 2
        let sphereRadius = center * 0.82
        let project = projector(
            yaw: time * 0.55,
            tilt: 0.35 + 0.1 * sin(time * 0.9),
            centerX: center,
            centerY: center,
            scale: sphereRadius
        )
        let dotRadiusScale = pow(size / 300, value(options, "rsPow", default: 0.6))
        let moveCount = intValue(options, "moveCount", default: 14)
        let moves = makeMoves(count: moveCount)
        let cycle = solveCycle(time: time, count: moveCount, slotDuration: 0.42, rest: 1.2)
        var dots: [ThinkingOrbDot] = []

        for latitudeIndex in 0...latitudeRings {
            let latitude = -.pi / 2 + (Double(latitudeIndex) / Double(latitudeRings)) * .pi
            let cosineLatitude = cos(latitude)
            let sineLatitude = sin(latitude)
            let longitudeCount = max(1, Int((abs(cosineLatitude) * Double(longitudeDensity)).rounded()))
            for longitudeIndex in 0..<longitudeCount {
                let longitude = (Double(longitudeIndex) / Double(longitudeCount)) * 2 * .pi
                let moved = applyMoves(
                    x: cosineLatitude * cos(longitude),
                    y: sineLatitude,
                    z: cosineLatitude * sin(longitude),
                    moves: moves,
                    amounts: cycle.amounts,
                    active: cycle.active
                )
                let projected = project(moved.x, moved.y, moved.z)
                let depth = (projected.z + 1) / 2
                dots.append(
                    ThinkingOrbDot(
                        x: projected.x,
                        y: projected.y,
                        z: projected.z,
                        radius: (
                            radiusBase + radiusDepth * depth + (moved.isActive ? radiusActive : 0)
                        ) * dotRadiusScale,
                        ink: value(options, "inkFar", default: 0.62)
                            - value(options, "inkSpan", default: 0.54) * depth
                            - (moved.isActive ? 0.14 : 0),
                        alpha: 1
                    )
                )
            }
        }
        return finalized(dots: dots, minimumRadius: value(options, "rMin", default: 0.3))
    }

    private static func solveCycle(
        time: Double,
        count: Int,
        slotDuration: Double,
        rest: Double
    ) -> (amounts: [Double], active: Int) {
        let cycleDuration = 2 * Double(count) * slotDuration + rest
        let cycleTime = time.truncatingRemainder(dividingBy: cycleDuration)
        var amounts = Array(repeating: 0.0, count: count)
        var active = -1
        if cycleTime < 2 * Double(count) * slotDuration {
            let slot = Int(floor(cycleTime / slotDuration))
            let progress = (cycleTime - Double(slot) * slotDuration) / slotDuration
            let clamped = min(1, progress / 0.7)
            let eased = 1 - pow(1 - clamped, 3)
            if slot < count {
                if slot > 0 {
                    for index in 0..<slot { amounts[index] = 1 }
                }
                amounts[slot] = eased
                active = slot
            } else {
                let undoIndex = 2 * count - 1 - slot
                if undoIndex > 0 {
                    for index in 0..<undoIndex { amounts[index] = 1 }
                }
                amounts[undoIndex] = 1 - eased
                active = undoIndex
            }
        }
        return (amounts, active)
    }

    private static func makeMoves(count: Int) -> [Move] {
        (0..<count).map { index in
            let value = Double(index)
            let axis = min(2, Int(floor(hash(value, 2.3) * 3)))
            let lowerBound = -1 + 0.5 * Double(min(3, Int(floor(hash(value, 5.9) * 4))))
            let direction = hash(value, 7.7) < 0.5 ? 1.0 : -1.0
            return Move(
                axis: axis,
                lowerBound: lowerBound,
                upperBound: lowerBound + 0.5,
                angle: direction * .pi / 2
            )
        }
    }

    private static func applyMoves(
        x initialX: Double,
        y initialY: Double,
        z initialZ: Double,
        moves: [Move],
        amounts: [Double],
        active: Int
    ) -> (x: Double, y: Double, z: Double, isActive: Bool) {
        var x = initialX
        var y = initialY
        var z = initialZ
        var isActive = false
        for index in moves.indices {
            guard amounts[index] > 0 else { continue }
            let move = moves[index]
            let coordinate = move.axis == 0 ? x : move.axis == 1 ? y : z
            guard coordinate >= move.lowerBound, coordinate < move.upperBound else { continue }
            if index == active { isActive = true }
            let angle = move.angle * amounts[index]
            let cosine = cos(angle)
            let sine = sin(angle)
            if move.axis == 0 {
                let nextY = y * cosine - z * sine
                z = y * sine + z * cosine
                y = nextY
            } else if move.axis == 1 {
                let nextX = x * cosine + z * sine
                z = -x * sine + z * cosine
                x = nextX
            } else {
                let nextX = x * cosine - y * sine
                y = x * sine + y * cosine
                x = nextX
            }
        }
        return (x, y, z, isActive)
    }

    private static func waveFrame(
        size: Double,
        time: Double,
        options: [String: Double]
    ) -> ThinkingOrbFrame {
        let rings = intValue(options, "rings", default: 15)
        let longitudeDensity = intValue(options, "lonDensity", default: 40)
        let radiusBase = value(options, "rBase", default: 0.6)
        let radiusDepth = value(options, "rDepth", default: 1.7)
        let center = size / 2
        let sphereRadius = center * 0.874
        let project = projector(
            yaw: time * 0.18,
            tilt: 0.38,
            centerX: center,
            centerY: center,
            scale: 1
        )
        let dotRadiusScale = pow(size / 300, value(options, "rsPow", default: 0.6))
        var dots: [ThinkingOrbDot] = []

        for ringIndex in 0...rings {
            let latitude = -.pi / 2 + (Double(ringIndex) / Double(rings)) * .pi
            let cosineLatitude = cos(latitude)
            let sineLatitude = sin(latitude)
            let wave = 0.62 * sin(time * 2.1 - Double(ringIndex) * 0.52)
                + 0.38 * sin(time * 1.27 + Double(ringIndex) * 0.83)
            let ringRadius = sphereRadius * (0.88 + 0.105 * wave)
            let longitudeCount = max(1, Int((abs(cosineLatitude) * Double(longitudeDensity)).rounded()))
            for longitudeIndex in 0..<longitudeCount {
                let longitude = (Double(longitudeIndex) / Double(longitudeCount)) * 2 * .pi
                let projected = project(
                    cosineLatitude * cos(longitude) * ringRadius,
                    sineLatitude * ringRadius,
                    cosineLatitude * sin(longitude) * ringRadius
                )
                let depth = (projected.z / sphereRadius + 1) / 2
                let crest = max(0, wave)
                dots.append(
                    ThinkingOrbDot(
                        x: projected.x,
                        y: projected.y,
                        z: projected.z,
                        radius: (radiusBase + radiusDepth * depth) * (1 + 0.4 * crest) * dotRadiusScale,
                        ink: 0.66 - 0.56 * depth - 0.1 * crest,
                        alpha: 1
                    )
                )
            }
        }
        return finalized(dots: dots, minimumRadius: value(options, "rMin", default: 0.3))
    }

    private static func braidFrame(
        size: Double,
        time: Double,
        options: [String: Double]
    ) -> ThinkingOrbFrame {
        let ghostCount = intValue(options, "ghostN", default: 150)
        let strandCount = intValue(options, "strandN", default: 52)
        let turns = value(options, "turns", default: 3)
        let radiusBase = value(options, "rBase", default: 1.2)
        let radiusDepth = value(options, "rDepth", default: 1.8)
        let center = size / 2
        let sphereRadius = center * 0.76
        let project = projector(
            yaw: time * 0.4,
            tilt: 0.3,
            centerX: center,
            centerY: center,
            scale: 1
        )
        let dotRadiusScale = pow(size / 300, value(options, "rsPow", default: 0.6))
        var dots: [ThinkingOrbDot] = []

        for index in 0..<ghostCount {
            let direction = fibonacciDirection(index: index, count: ghostCount)
            let projected = project(
                direction.x * sphereRadius,
                direction.y * sphereRadius,
                direction.z * sphereRadius
            )
            let depth = (projected.z / sphereRadius + 1) / 2
            dots.append(
                ThinkingOrbDot(
                    x: projected.x,
                    y: projected.y,
                    z: projected.z,
                    radius: 0.8 * dotRadiusScale,
                    ink: 0.78,
                    alpha: 0.1 + 0.22 * depth
                )
            )
        }

        for strand in 0..<3 {
            let phase = (Double(strand) / 3) * 2 * .pi
            for index in 0..<strandCount {
                let vertical = (fraction(Double(index) / Double(strandCount) + time * 0.045) * 2 - 1) * 0.96
                let surface = sqrt(max(0, 1 - vertical * vertical))
                let endFade = min(1, (1 - abs(vertical)) / 0.1)
                let angle = vertical * .pi * turns + phase
                let weave = 1 + 0.075 * sin(vertical * .pi * turns * 2 + phase * 2 + time * 0.8)
                let radial = surface * sphereRadius * weave
                let projected = project(
                    cos(angle) * radial,
                    vertical * sphereRadius * weave,
                    sin(angle) * radial
                )
                let depth = (projected.z / sphereRadius + 1) / 2
                dots.append(
                    ThinkingOrbDot(
                        x: projected.x,
                        y: projected.y,
                        z: projected.z,
                        radius: (radiusBase + radiusDepth * depth) * dotRadiusScale,
                        ink: 0.55 - 0.45 * depth,
                        alpha: endFade * (0.45 + 0.55 * depth)
                    )
                )
            }
        }
        return finalized(dots: dots, minimumRadius: value(options, "rMin", default: 0.3))
    }

    private static func webFrame(
        size: Double,
        time: Double,
        options: [String: Double]
    ) -> ThinkingOrbFrame {
        let nodeCount = intValue(options, "nodeN", default: 30)
        let signalCount = intValue(options, "signals", default: 5)
        let nodeRadius = value(options, "nodeR", default: 1.4)
        let nodeRadiusDepth = value(options, "nodeRDepth", default: 1.8)
        let threshold = value(options, "thr", default: 0.72)
        let center = size / 2
        let sphereRadius = center * 0.8 * value(options, "spread", default: 1)
        let project = projector(
            yaw: time * 0.12,
            tilt: 0.32,
            centerX: center,
            centerY: center,
            scale: sphereRadius
        )
        let dotRadiusScale = pow(size / 300, value(options, "rsPow", default: 0.6))
        var nodes: [(x: Double, y: Double, z: Double)] = []

        for index in 0..<nodeCount {
            let direction = fibonacciDirection(index: index, count: nodeCount)
            let x = direction.x + 0.3 * (valueNoise(Double(index) * 0.31 + 9, time * 0.24) - 0.5) * 2
            let y = direction.y + 0.3 * (valueNoise(Double(index) * 0.53 + 27, time * 0.21) - 0.5) * 2
            let z = direction.z + 0.3 * (valueNoise(Double(index) * 0.77 + 55, time * 0.27) - 0.5) * 2
            let length = sqrt(x * x + y * y + z * z)
            nodes.append((x / length, y / length, z / length))
        }

        var lines: [ThinkingOrbLine] = []
        var dots: [ThinkingOrbDot] = []

        for firstIndex in 0..<nodeCount {
            guard firstIndex + 1 < nodeCount else { continue }
            for secondIndex in (firstIndex + 1)..<nodeCount {
                let first = nodes[firstIndex]
                let second = nodes[secondIndex]
                let deltaX = first.x - second.x
                let deltaY = first.y - second.y
                let deltaZ = first.z - second.z
                let distance = sqrt(deltaX * deltaX + deltaY * deltaY + deltaZ * deltaZ)
                guard distance < threshold else { continue }
                let projectedFirst = project(first.x, first.y, first.z)
                let projectedSecond = project(second.x, second.y, second.z)
                let depth = ((projectedFirst.z + projectedSecond.z) / 2 + 1) / 2
                lines.append(
                    ThinkingOrbLine(
                        x1: projectedFirst.x,
                        y1: projectedFirst.y,
                        x2: projectedSecond.x,
                        y2: projectedSecond.y,
                        ink: 0.42,
                        alpha: (1 - distance / threshold) * (0.3 + 0.55 * depth),
                        width: max(0.6, value(options, "lineW", default: 0.8) * dotRadiusScale)
                    )
                )
            }
        }

        for index in 0..<nodeCount {
            let node = nodes[index]
            let projected = project(node.x, node.y, node.z)
            let depth = (projected.z + 1) / 2
            let pulse = 1 + 0.25 * sin(time * 1.4 + Double(index) * 2.7)
            dots.append(
                ThinkingOrbDot(
                    x: projected.x,
                    y: projected.y,
                    z: projected.z,
                    radius: (nodeRadius + nodeRadiusDepth * depth) * pulse * dotRadiusScale,
                    ink: 0.55 - 0.45 * depth,
                    alpha: 1
                )
            )
        }

        for signal in 0..<signalCount {
            let signalOffset = Double(signal) * 7.31
            let segment = floor(time * 0.55 + signalOffset)
            let firstIndex = Int(floor(hash(segment, Double(signal) * 3.1 + 1.7) * Double(nodeCount)))
            let secondIndex = Int(floor(hash(segment, Double(signal) * 5.7 + 4.2) * Double(nodeCount)))
            guard firstIndex != secondIndex else { continue }
            let progress = fraction(time * 0.55 + signalOffset)
            let first = nodes[firstIndex]
            let second = nodes[secondIndex]
            let x = linearInterpolate(first.x, second.x, progress)
            let y = linearInterpolate(first.y, second.y, progress)
            let z = linearInterpolate(first.z, second.z, progress)
            let length = max(1e-6, sqrt(x * x + y * y + z * z))
            let projected = project(x / length, y / length, z / length)
            let depth = (projected.z + 1) / 2
            dots.append(
                ThinkingOrbDot(
                    x: projected.x,
                    y: projected.y,
                    z: projected.z,
                    radius: (nodeRadius * 1.5 + nodeRadiusDepth * depth) * dotRadiusScale,
                    ink: 0.05,
                    alpha: 0.5 + 0.5 * depth
                )
            )
        }

        return finalized(
            dots: dots,
            lines: lines,
            minimumRadius: value(options, "rMin", default: 0.3)
        )
    }

    private static func ribbonFrame(
        size: Double,
        time: Double,
        options: [String: Double]
    ) -> ThinkingOrbFrame {
        let faceOn = value(options, "faceOn", default: 0) != 0
        let ghostCount = intValue(options, "ghostN", default: 150)
        let baseLanes = intValue(options, "lanes", default: 5)
        let segments = intValue(options, "segs", default: 88)
        let radiusBase = value(options, "rBase", default: 1.1)
        let radiusDepth = value(options, "rDepth", default: 1.7)
        let bandMultiplier = value(options, "bandMul", default: 1)
        let wobbleMultiplier = value(options, "wobMul", default: 1)
        let spin = value(options, "spin", default: 1)

        let center = size / 2
        let sphereRadius = center * 0.78
        let cameraTilt = 0.3
        let project = projector(
            yaw: time * 0.1 * spin,
            tilt: cameraTilt,
            centerX: center,
            centerY: center,
            scale: 1
        )
        let dotRadiusScale = pow(size / 300, value(options, "rsPow", default: 0.6))
        var dots: [ThinkingOrbDot] = []

        for index in 0..<ghostCount {
            let direction = fibonacciDirection(index: index, count: ghostCount)
            let projected = project(
                direction.x * sphereRadius,
                direction.y * sphereRadius,
                direction.z * sphereRadius
            )
            let depth = (projected.z / sphereRadius + 1) / 2
            dots.append(
                ThinkingOrbDot(
                    x: projected.x,
                    y: projected.y,
                    z: projected.z,
                    radius: 0.8 * dotRadiusScale,
                    ink: 0.78,
                    alpha: 0.1 + 0.22 * depth
                )
            )
        }

        let yawAngle = time * 0.24 * spin
        let tiltAngle = faceOn ? -cameraTilt : 0.55 + 0.3 * sin(time * 0.18) * spin
        let basisUX = cos(yawAngle)
        let basisUY = 0.0
        let basisUZ = sin(yawAngle)
        let basisVX = -basisUZ * sin(tiltAngle)
        let basisVY = cos(tiltAngle)
        let basisVZ = basisUX * sin(tiltAngle)
        let normalX = basisUY * basisVZ - basisUZ * basisVY
        let normalY = basisUZ * basisVX - basisUX * basisVZ
        let normalZ = basisUX * basisVY - basisUY * basisVX
        let wobbleAmplitude = 0.23 * wobbleMultiplier
        let baseRadius = faceOn ? sphereRadius / (1 + 0.85 * wobbleAmplitude) : sphereRadius
        let lanes = max(1, Int((Double(baseLanes) * bandMultiplier).rounded()))

        for lane in 0..<lanes {
            let laneOffset = (Double(lane) - Double(lanes - 1) / 2) * 0.075
            let edge = abs(Double(lane) - Double(lanes - 1) / 2) / max(1, Double(lanes - 1) / 2)
            for segment in 0..<segments {
                let angle = (Double(segment) / Double(segments)) * 2 * .pi
                let wobble = (
                    0.16 * sin(angle * 3 - time * 1.7 + Double(lane) * 0.22)
                        + 0.07 * sin(angle * 5 + time * 1.1)
                ) * wobbleMultiplier
                let radial = faceOn ? 1 + wobble : 1
                let offset = faceOn ? laneOffset : laneOffset + wobble
                let x = basisUX * cos(angle) + basisVX * sin(angle) + normalX * offset
                let y = basisUY * cos(angle) + basisVY * sin(angle) + normalY * offset
                let z = basisUZ * cos(angle) + basisVZ * sin(angle) + normalZ * offset
                let length = sqrt(x * x + y * y + z * z)
                let radius = baseRadius * radial
                let projected = project(
                    (x / length) * radius,
                    (y / length) * radius,
                    (z / length) * radius
                )
                let depth = (projected.z / sphereRadius + 1) / 2
                dots.append(
                    ThinkingOrbDot(
                        x: projected.x,
                        y: projected.y,
                        z: projected.z,
                        radius: (radiusBase + radiusDepth * depth) * (1 - 0.25 * edge) * dotRadiusScale,
                        ink: 0.52 - 0.44 * depth + 0.18 * edge,
                        alpha: 0.4 + 0.6 * depth
                    )
                )
            }
        }

        return finalized(dots: dots, minimumRadius: value(options, "rMin", default: 0.3))
    }

    private enum MorphShape: Int {
        case circle
        case triangle
        case square
    }

    private static func morphFrame(
        size: Double,
        time: Double,
        options: [String: Double]
    ) -> ThinkingOrbFrame {
        let dotRadius = value(options, "rDot", default: 0.021)
        let iconDensity = value(options, "iconD", default: 1)
        let spread = value(options, "spread", default: 1)
        let holdDuration = 1.4
        let morphDuration = 0.9
        let segmentDuration = holdDuration + morphDuration
        let cycleTime = time.truncatingRemainder(dividingBy: segmentDuration * 3)
        let shapeIndex = Int(floor(cycleTime / segmentDuration))
        let localTime = cycleTime - Double(shapeIndex) * segmentDuration
        let morphProgress = localTime > holdDuration
            ? smoothEase((localTime - holdDuration) / morphDuration)
            : 0
        let firstShape = MorphShape(rawValue: shapeIndex)!
        let secondShape = MorphShape(rawValue: (shapeIndex + 1) % 3)!
        let measurementCount = 160
        var points: [(x: Double, y: Double)] = []

        for index in 0..<measurementCount {
            let progress = Double(index) / Double(measurementCount)
            let first = morphPoint(shape: firstShape, progress: progress)
            let second = morphPoint(shape: secondShape, progress: progress)
            points.append((
                linearInterpolate(first.x, second.x, morphProgress) * spread,
                linearInterpolate(first.y, second.y, morphProgress) * spread
            ))
        }

        var lengths: [Double] = []
        var totalLength = 0.0
        for index in 0..<measurementCount {
            let first = points[index]
            let second = points[(index + 1) % measurementCount]
            let length = hypot(second.x - first.x, second.y - first.y)
            lengths.append(length)
            totalLength += length
        }

        let dotCount = max(6, Int((34 * iconDensity).rounded()))
        let effectiveRadius = dotRadius * 1.35 * spread
        let pulse = 1 + 0.02 * sin(localTime * 3.1)
        let center = size / 2
        var currentSegment = 0
        var accumulatedLength = 0.0
        var dots: [ThinkingOrbDot] = []

        for index in 0..<dotCount {
            let target = (Double(index) / Double(dotCount)) * totalLength
            while accumulatedLength + lengths[currentSegment] < target,
                  currentSegment < measurementCount - 1 {
                accumulatedLength += lengths[currentSegment]
                currentSegment += 1
            }
            let first = points[currentSegment]
            let second = points[(currentSegment + 1) % measurementCount]
            let progress = lengths[currentSegment] > 0
                ? min(1, (target - accumulatedLength) / lengths[currentSegment])
                : 0
            let x = linearInterpolate(first.x, second.x, progress) * pulse
            let y = linearInterpolate(first.y, second.y, progress) * pulse
            dots.append(
                ThinkingOrbDot(
                    x: center + x * size,
                    y: center + y * size,
                    z: 0,
                    radius: max(0.35, effectiveRadius * size),
                    ink: 0.1,
                    alpha: 1
                )
            )
        }
        return finalized(
            dots: dots,
            minimumRadius: value(options, "rMin", default: 0.25)
        )
    }

    private static func smoothEase(_ value: Double) -> Double {
        value * value * (3 - 2 * value)
    }

    private static func morphPoint(
        shape: MorphShape,
        progress: Double
    ) -> (x: Double, y: Double) {
        switch shape {
        case .circle:
            let angle = -.pi / 2 + progress * 2 * .pi
            return (cos(angle) * 0.24, sin(angle) * 0.24)
        case .triangle:
            return polygonPoint(
                vertices: [(0, -0.26), (0.24, 0.16), (-0.24, 0.16)],
                progress: progress
            )
        case .square:
            return polygonPoint(
                vertices: [(0, -0.2), (0.2, -0.2), (0.2, 0.2), (-0.2, 0.2), (-0.2, -0.2)],
                progress: progress
            )
        }
    }

    private static func polygonPoint(
        vertices: [(Double, Double)],
        progress: Double
    ) -> (x: Double, y: Double) {
        var lengths: [Double] = []
        var totalLength = 0.0
        for index in vertices.indices {
            let first = vertices[index]
            let second = vertices[(index + 1) % vertices.count]
            let length = hypot(second.0 - first.0, second.1 - first.1)
            lengths.append(length)
            totalLength += length
        }

        var target = progress * totalLength
        var index = 0
        while target > lengths[index], index < vertices.count - 1 {
            target -= lengths[index]
            index += 1
        }
        let first = vertices[index]
        let second = vertices[(index + 1) % vertices.count]
        let segmentProgress = lengths[index] > 0 ? min(1, target / lengths[index]) : 0
        return (
            linearInterpolate(first.0, second.0, segmentProgress),
            linearInterpolate(first.1, second.1, segmentProgress)
        )
    }

    private static func angleDelta(_ a: Double, _ b: Double) -> Double {
        atan2(sin(a - b), cos(a - b))
    }

    private static func hash(_ a: Double, _ b: Double) -> Double {
        let value = sin(a * 12.9898 + b * 78.233) * 43_758.5453
        return value - floor(value)
    }

    private static func value(
        _ options: [String: Double],
        _ key: String,
        default fallback: Double
    ) -> Double {
        options[key] ?? fallback
    }

    private static func intValue(
        _ options: [String: Double],
        _ key: String,
        default fallback: Int
    ) -> Int {
        Int(options[key] ?? Double(fallback))
    }

    private static func fraction(_ value: Double) -> Double {
        value - floor(value)
    }

    private static func linearInterpolate(_ a: Double, _ b: Double, _ fraction: Double) -> Double {
        a + (b - a) * fraction
    }

    private static func valueNoise(_ x: Double, _ y: Double) -> Double {
        let integerX = floor(x)
        let integerY = floor(y)
        var fractionalX = x - integerX
        var fractionalY = y - integerY
        fractionalX = fractionalX * fractionalX * (3 - 2 * fractionalX)
        fractionalY = fractionalY * fractionalY * (3 - 2 * fractionalY)
        let a = hash(integerX, integerY)
        let b = hash(integerX + 1, integerY)
        let c = hash(integerX, integerY + 1)
        let d = hash(integerX + 1, integerY + 1)
        return a
            + (b - a) * fractionalX
            + (c - a) * fractionalY
            + (a - b - c + d) * fractionalX * fractionalY
    }

    private static func fibonacciDirection(
        index: Int,
        count: Int
    ) -> (x: Double, y: Double, z: Double) {
        let goldenAngle = Double.pi * (3 - sqrt(5))
        let y = 1 - (2 * (Double(index) + 0.5)) / Double(count)
        let radius = sqrt(1 - y * y)
        let angle = Double(index) * goldenAngle
        return (radius * cos(angle), y, radius * sin(angle))
    }

    private static func finalized(
        dots: [ThinkingOrbDot],
        lines: [ThinkingOrbLine] = [],
        minimumRadius: Double = 0.3
    ) -> ThinkingOrbFrame {
        let visibleDots = dots
            .filter { $0.alpha >= 0.02 }
            .map {
                ThinkingOrbDot(
                    x: $0.x,
                    y: $0.y,
                    z: $0.z,
                    radius: max(minimumRadius, $0.radius),
                    ink: $0.ink,
                    alpha: $0.alpha
                )
            }
            .enumerated()
            .sorted {
                if $0.element.z == $1.element.z { return $0.offset < $1.offset }
                return $0.element.z < $1.element.z
            }
            .map(\.element)
        return ThinkingOrbFrame(
            dots: visibleDots,
            lines: lines.filter { $0.alpha >= 0.02 }
        )
    }

    private static func projector(
        yaw: Double,
        tilt: Double,
        centerX: Double,
        centerY: Double,
        scale: Double
    ) -> (_ x: Double, _ y: Double, _ z: Double) -> (x: Double, y: Double, z: Double) {
        let sineTilt = sin(tilt)
        let cosineTilt = cos(tilt)
        let sineYaw = sin(yaw)
        let cosineYaw = cos(yaw)

        return { x, y, z in
            let rotatedX = x * cosineYaw + z * sineYaw
            let firstZ = -x * sineYaw + z * cosineYaw
            let rotatedY = y * cosineTilt - firstZ * sineTilt
            let secondZ = y * sineTilt + firstZ * cosineTilt
            return (
                centerX + rotatedX * scale,
                centerY - rotatedY * scale,
                secondZ
            )
        }
    }
}
