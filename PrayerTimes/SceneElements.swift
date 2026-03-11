import SwiftUI

// MARK: - StarsField

/// A field of twinkling star circles. Each star has a random position,
/// size, twinkle period, and staggered delay — all generated at init time.
/// Setting `topHeavy: true` biases star placement toward the upper 60% of
/// the screen to match night/dawn sky density.
struct StarsField: View {

    let count: Int
    let sizeRange: ClosedRange<CGFloat>
    let opacityRange: ClosedRange<Double>
    let topHeavy: Bool
    let appear: Bool
    let size: CGSize

    // MARK: Star data — generated once at init

    private struct StarData {
        let x: CGFloat          // fraction 0-1
        let y: CGFloat          // fraction 0-1
        let radius: CGFloat
        let period: Double      // twinkle animation duration (seconds)
        let delay: Double       // stagger delay (seconds)
        let peakOpacity: Double // target opacity when fully lit
    }

    private let stars: [StarData]

    init(
        count: Int,
        sizeRange: ClosedRange<CGFloat> = 1.0...4.0,
        opacityRange: ClosedRange<Double> = 0.2...0.8,
        topHeavy: Bool = false,
        appear: Bool,
        size: CGSize
    ) {
        self.count = count
        self.sizeRange = sizeRange
        self.opacityRange = opacityRange
        self.topHeavy = topHeavy
        self.appear = appear
        self.size = size

        self.stars = (0..<count).map { _ in
            let yFraction: CGFloat = topHeavy
                ? CGFloat.random(in: 0.0...0.6)
                : CGFloat.random(in: 0.0...1.0)
            return StarData(
                x: CGFloat.random(in: 0.0...1.0),
                y: yFraction,
                radius: CGFloat.random(in: sizeRange),
                period: Double.random(in: 2.0...5.0),
                delay: Double.random(in: 0.0...4.0),
                peakOpacity: Double.random(in: opacityRange)
            )
        }
    }

    var body: some View {
        ForEach(Array(stars.enumerated()), id: \.offset) { index, star in
            Circle()
                .fill(.white)
                .frame(width: star.radius, height: star.radius)
                .opacity(appear ? star.peakOpacity : opacityRange.lowerBound * 0.5)
                .position(
                    x: star.x * size.width,
                    y: star.y * size.height
                )
                .animation(
                    .easeInOut(duration: star.period)
                        .repeatForever(autoreverses: true)
                        .delay(star.delay),
                    value: appear
                )
        }
    }
}

// MARK: - CloudLayer

/// A single drifting cloud wisp rendered as a `Capsule` with a horizontal
/// gradient (transparent → color → transparent) that slowly oscillates
/// left and right across the sky.
struct CloudLayer: View {

    let width: CGFloat
    let height: CGFloat
    let color: Color
    let opacity: Double
    /// Fraction of the container height (0 = top, 1 = bottom).
    let yPosition: CGFloat
    /// Total seconds for one full drift cycle (there and back).
    let driftSpeed: Double
    /// Points the capsule travels horizontally in each direction.
    let driftDistance: CGFloat
    let size: CGSize

    @State private var drifting = false

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        color.opacity(opacity),
                        color.opacity(opacity * 1.2),
                        color.opacity(opacity),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: width, height: height)
            .offset(x: drifting ? driftDistance : -driftDistance)
            .position(x: size.width * 0.5, y: size.height * yPosition)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: driftSpeed / 2.0)
                        .repeatForever(autoreverses: true)
                ) {
                    drifting = true
                }
            }
    }
}

// MARK: - CelestialBody

/// The sun, a crescent moon, or a half-disc (rising/setting sun). The body
/// renders with a pulsing radial-gradient glow behind it.
struct CelestialBody: View {

    // MARK: Body type

    enum CelestialBodyType {
        case sun(radius: CGFloat)
        /// Creates a crescent by overlaying a dark circle offset from a bright one.
        case crescent(radius: CGFloat, shadowOffset: CGFloat)
        /// A circle clipped to its top half — used for the sunrise/sunset disc.
        case halfDisc(radius: CGFloat)
    }

    let bodyType: CelestialBodyType
    let glowRadius: CGFloat
    let glowColor: Color
    /// Relative position within the parent container (e.g. `.init(x: 0.25, y: 0.15)`).
    let position: UnitPoint
    let pulseScale: ClosedRange<CGFloat>
    let size: CGSize

    @State private var pulsing = false

    // MARK: Convenience

    private var bodyRadius: CGFloat {
        switch bodyType {
        case .sun(let r):              return r
        case .crescent(let r, _):      return r
        case .halfDisc(let r):         return r
        }
    }

    private var absolutePosition: CGPoint {
        CGPoint(x: size.width * position.x, y: size.height * position.y)
    }

    var body: some View {
        ZStack {
            glowLayer
            bodyLayer
        }
        .position(absolutePosition)
        .onAppear {
            withAnimation(
                .easeInOut(duration: 4.0)
                    .repeatForever(autoreverses: true)
            ) {
                pulsing = true
            }
        }
    }

    // MARK: Glow

    @ViewBuilder
    private var glowLayer: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        glowColor.opacity(0.55),
                        glowColor.opacity(0.18),
                        glowColor.opacity(0.04),
                        .clear
                    ],
                    center: .center,
                    startRadius: bodyRadius * 0.5,
                    endRadius: glowRadius
                )
            )
            .frame(width: glowRadius * 2, height: glowRadius * 2)
            .scaleEffect(pulsing ? pulseScale.upperBound : pulseScale.lowerBound)
            .animation(
                .easeInOut(duration: 4.0).repeatForever(autoreverses: true),
                value: pulsing
            )
    }

    // MARK: Body shape

    @ViewBuilder
    private var bodyLayer: some View {
        switch bodyType {

        case .sun(let radius):
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, glowColor.opacity(0.85)],
                        center: .center,
                        startRadius: 0,
                        endRadius: radius
                    )
                )
                .frame(width: radius * 2, height: radius * 2)

        case .crescent(let radius, let shadowOffset):
            ZStack {
                // Bright moon disc
                Circle()
                    .fill(Color(white: 0.95))
                    .frame(width: radius * 2, height: radius * 2)
                // Dark overlay circle offset to carve out the crescent
                Circle()
                    .fill(Color(red: 0.03, green: 0.04, blue: 0.14))
                    .frame(width: radius * 2, height: radius * 2)
                    .offset(x: shadowOffset, y: -shadowOffset * 0.3)
            }

        case .halfDisc(let radius):
            Circle()
                .fill(
                    RadialGradient(
                        colors: [.white, glowColor.opacity(0.9)],
                        center: .center,
                        startRadius: 0,
                        endRadius: radius
                    )
                )
                .frame(width: radius * 2, height: radius * 2)
                // Clip to upper half so it appears rising over the horizon.
                .clipShape(TopHalfClip())
        }
    }
}

// MARK: - MistLayer

/// Three overlapping ellipses at the bottom of the screen that slowly drift
/// upward while their opacity fades — simulating low-lying ground mist.
struct MistLayer: View {

    let color: Color
    /// Fraction of screen height covered by the mist band (0.05–0.15 typical).
    let heightFraction: CGFloat
    let opacity: Double
    /// Seconds for one full rise-and-return cycle.
    let riseSpeed: Double
    let size: CGSize

    @State private var rising = false

    // MARK: Ellipse configs — computed at init for stable layout

    private struct MistEllipse {
        let widthFraction: CGFloat   // fraction of screen width
        let xOffset: CGFloat         // horizontal offset from centre (points)
        let yBaseOffset: CGFloat     // vertical offset from the base line (points)
        let heightScale: CGFloat     // relative height multiplier
        let opacityScale: Double     // multiplier applied to base opacity
        let riseAmount: CGFloat      // upward travel distance during animation
        let delay: Double
    }

    private let ellipses: [MistEllipse] = [
        MistEllipse(widthFraction: 0.90, xOffset:   0, yBaseOffset:  0, heightScale: 1.0, opacityScale: 0.8, riseAmount: 18, delay: 0.0),
        MistEllipse(widthFraction: 0.70, xOffset: -60, yBaseOffset: -8, heightScale: 0.7, opacityScale: 0.5, riseAmount: 24, delay: 1.5),
        MistEllipse(widthFraction: 0.80, xOffset:  50, yBaseOffset: -4, heightScale: 0.8, opacityScale: 0.6, riseAmount: 20, delay: 3.0),
    ]

    var body: some View {
        let baseHeight = size.height * heightFraction
        let baseY = size.height - baseHeight * 0.5

        ForEach(Array(ellipses.enumerated()), id: \.offset) { _, e in
            Ellipse()
                .fill(color.opacity(opacity * e.opacityScale * (rising ? 0.4 : 1.0)))
                .frame(
                    width: size.width * e.widthFraction,
                    height: baseHeight * e.heightScale
                )
                .position(
                    x: size.width * 0.5 + e.xOffset,
                    y: baseY + e.yBaseOffset - (rising ? e.riseAmount : 0)
                )
                .animation(
                    .easeInOut(duration: riseSpeed)
                        .repeatForever(autoreverses: true)
                        .delay(e.delay),
                    value: rising
                )
        }
        .onAppear {
            rising = true
        }
    }
}

// MARK: - DustParticles

/// Small floating circles that drift upward with gentle lateral sway,
/// looping continuously. Evokes golden dust or pollen suspended in warm air.
struct DustParticles: View {

    let count: Int
    let color: Color
    let sizeRange: ClosedRange<CGFloat>
    /// Seconds for one full upward cycle (particle travels from startY to top).
    let riseSpeed: Double
    let size: CGSize

    @State private var floating = false

    // MARK: Particle data

    private struct Particle {
        let xFraction: CGFloat      // horizontal position as fraction of width
        let startYFraction: CGFloat // initial vertical position as fraction of height
        let radius: CGFloat
        let swayAmount: CGFloat     // horizontal oscillation amount (points)
        let speedScale: Double      // multiplier on riseSpeed for variety
        let delay: Double
        let opacity: Double
    }

    private let particles: [Particle]

    init(count: Int, color: Color, sizeRange: ClosedRange<CGFloat>, riseSpeed: Double, size: CGSize) {
        self.count = count
        self.color = color
        self.sizeRange = sizeRange
        self.riseSpeed = riseSpeed
        self.size = size

        self.particles = (0..<count).map { _ in
            Particle(
                xFraction: CGFloat.random(in: 0.05...0.95),
                startYFraction: CGFloat.random(in: 0.3...1.0),
                radius: CGFloat.random(in: sizeRange),
                swayAmount: CGFloat.random(in: 6...20),
                speedScale: Double.random(in: 0.7...1.4),
                delay: Double.random(in: 0.0...5.0),
                opacity: Double.random(in: 0.25...0.75)
            )
        }
    }

    var body: some View {
        ForEach(Array(particles.enumerated()), id: \.offset) { _, p in
            Circle()
                .fill(color.opacity(p.opacity))
                .frame(width: p.radius, height: p.radius)
                .offset(
                    x: floating ? p.swayAmount : -p.swayAmount,
                    y: floating ? -(size.height * p.startYFraction + size.height * 0.1) : 0
                )
                .position(
                    x: p.xFraction * size.width,
                    y: p.startYFraction * size.height
                )
                .animation(
                    .easeInOut(duration: riseSpeed * p.speedScale)
                        .repeatForever(autoreverses: false)
                        .delay(p.delay),
                    value: floating
                )
        }
        .onAppear {
            floating = true
        }
    }
}

// MARK: - DesertDunes

/// Layered rolling dune silhouettes at the bottom of the screen. Each layer is
/// a filled `Path` drawn with cubic Bézier curves for an organic sine-wave
/// silhouette. Back layers (index 0) are slightly lighter; front layers darker.
struct DesertDunes: View {

    let layers: Int
    /// One color per layer — first element is the back layer.
    let colors: [Color]
    /// Fraction of screen height occupied by the dune band (0.12–0.18 typical).
    let heightFraction: CGFloat
    let size: CGSize

    var body: some View {
        ForEach(0..<layers, id: \.self) { index in
            DunePath(
                layerIndex: index,
                totalLayers: layers,
                color: colors[min(index, colors.count - 1)],
                heightFraction: heightFraction,
                size: size
            )
        }
    }
}

/// A single dune layer path. The wave shape is parameterised by `layerIndex`
/// so each layer has a subtly different silhouette.
private struct DunePath: View {

    let layerIndex: Int
    let totalLayers: Int
    let color: Color
    let heightFraction: CGFloat
    let size: CGSize

    /// Opacity is higher (more visible) for front layers.
    private var opacity: Double {
        let base = 0.55
        let step = 0.15
        return base + Double(layerIndex) * step
    }

    var body: some View {
        duneShape
            .fill(color.opacity(opacity))
    }

    private var duneShape: Path {
        let w = size.width
        let h = size.height
        let duneHeight = h * heightFraction
        // Back layers sit slightly higher; front layers at the very bottom edge.
        let baseY = h - duneHeight * (1.0 - Double(layerIndex) * 0.12)
        // Each layer is offset by a fraction so the waves don't stack identically.
        let phaseShift = CGFloat(layerIndex) * 0.18 * w

        return Path { path in
            // Start from the bottom-left corner
            path.move(to: CGPoint(x: 0, y: h))
            // Move up to the wave start on the left edge
            path.addLine(to: CGPoint(x: 0, y: baseY + duneHeight * 0.3))

            // Segment 1: left dune rise
            let c1a = CGPoint(x: w * 0.08 + phaseShift, y: baseY - duneHeight * 0.25)
            let c1b = CGPoint(x: w * 0.22 + phaseShift, y: baseY - duneHeight * 0.55)
            let p1  = CGPoint(x: w * 0.30 + phaseShift, y: baseY - duneHeight * 0.45)
            path.addCurve(to: p1.clampedX(w), control1: c1a.clampedX(w), control2: c1b.clampedX(w))

            // Segment 2: dip between dunes
            let c2a = CGPoint(x: w * 0.38 + phaseShift, y: baseY - duneHeight * 0.30)
            let c2b = CGPoint(x: w * 0.46 + phaseShift, y: baseY + duneHeight * 0.05)
            let p2  = CGPoint(x: w * 0.52 + phaseShift, y: baseY - duneHeight * 0.10)
            path.addCurve(to: p2.clampedX(w), control1: c2a.clampedX(w), control2: c2b.clampedX(w))

            // Segment 3: central dune peak
            let c3a = CGPoint(x: w * 0.58 + phaseShift, y: baseY - duneHeight * 0.60)
            let c3b = CGPoint(x: w * 0.68 + phaseShift, y: baseY - duneHeight * 0.65)
            let p3  = CGPoint(x: w * 0.72 + phaseShift, y: baseY - duneHeight * 0.50)
            path.addCurve(to: p3.clampedX(w), control1: c3a.clampedX(w), control2: c3b.clampedX(w))

            // Segment 4: second dip and right edge descent
            let c4a = CGPoint(x: w * 0.80 + phaseShift, y: baseY - duneHeight * 0.20)
            let c4b = CGPoint(x: w * 0.90 + phaseShift, y: baseY + duneHeight * 0.10)
            let p4  = CGPoint(x: w,                      y: baseY + duneHeight * 0.20)
            path.addCurve(to: p4, control1: c4a.clampedX(w), control2: c4b.clampedX(w))

            // Close down to the bottom-right corner
            path.addLine(to: CGPoint(x: w, y: h))
            path.closeSubpath()
        }
    }
}

// CGPoint helper: clamps x to [0, maxX] so bezier control points that fall
// outside the canvas width don't produce artefacts.
private extension CGPoint {
    func clampedX(_ maxX: CGFloat) -> CGPoint {
        CGPoint(x: min(max(x, 0), maxX), y: y)
    }
}

// MARK: - TreeSilhouettes

/// Soft tree silhouettes rendered from basic SwiftUI shapes. Trees are
/// positioned along the dune horizon line at random x offsets.
struct TreeSilhouettes: View {

    enum TreeStyle: Equatable {
        case palm
        case acacia
        case cypress
        case mixed
    }

    let count: Int
    let style: TreeStyle
    let color: Color
    let opacityRange: ClosedRange<Double>
    /// Y coordinate of the ground / dune-top line, in points from the top.
    let baseY: CGFloat
    let size: CGSize

    // MARK: Tree data

    private struct TreeData {
        let x: CGFloat
        let opacity: Double
        let resolvedStyle: TreeStyle  // always .palm, .acacia, or .cypress
        let heightScale: CGFloat      // slight size variation
        let tiltAngle: Angle          // subtle lean
    }

    private let trees: [TreeData]

    init(
        count: Int,
        style: TreeStyle,
        color: Color,
        opacityRange: ClosedRange<Double>,
        baseY: CGFloat,
        size: CGSize
    ) {
        self.count = count
        self.style = style
        self.color = color
        self.opacityRange = opacityRange
        self.baseY = baseY
        self.size = size

        let baseStyles: [TreeStyle] = [.palm, .acacia, .cypress]
        self.trees = (0..<count).map { index in
            let resolved: TreeStyle
            if style == .mixed {
                resolved = baseStyles[Int.random(in: 0..<baseStyles.count)]
            } else {
                resolved = style
            }
            // Spread trees evenly with a small random jitter
            let evenX = size.width * (CGFloat(index) + 0.5) / CGFloat(count)
            let jitter = CGFloat.random(in: -size.width * 0.06...size.width * 0.06)
            return TreeData(
                x: (evenX + jitter).clamped(to: 20...(size.width - 20)),
                opacity: Double.random(in: opacityRange),
                resolvedStyle: resolved,
                heightScale: CGFloat.random(in: 0.75...1.25),
                tiltAngle: .degrees(Double.random(in: -6...6))
            )
        }
    }

    var body: some View {
        ForEach(Array(trees.enumerated()), id: \.offset) { _, tree in
            treeView(tree)
                .opacity(tree.opacity)
                .position(x: tree.x, y: baseY)
                .rotationEffect(tree.tiltAngle, anchor: .bottom)
        }
    }

    @ViewBuilder
    private func treeView(_ tree: TreeData) -> some View {
        switch tree.resolvedStyle {
        case .palm:    PalmTree(color: color, scale: tree.heightScale)
        case .acacia:  AcaciaTree(color: color, scale: tree.heightScale)
        case .cypress: CypressTree(color: color, scale: tree.heightScale)
        case .mixed:   PalmTree(color: color, scale: tree.heightScale) // fallback
        }
    }
}

// MARK: Palm Tree

private struct PalmTree: View {
    let color: Color
    let scale: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            // Trunk — thin, slightly tilted capsule
            Capsule()
                .fill(color)
                .frame(width: 5 * scale, height: 55 * scale)
                .offset(x: 2 * scale)

            // Canopy — offset ellipse at top of trunk, angled slightly outward
            Ellipse()
                .fill(color)
                .frame(width: 34 * scale, height: 18 * scale)
                .offset(x: 8 * scale, y: -(48 * scale))
                .rotationEffect(.degrees(-20))

            // Second frond
            Ellipse()
                .fill(color)
                .frame(width: 28 * scale, height: 14 * scale)
                .offset(x: -8 * scale, y: -(50 * scale))
                .rotationEffect(.degrees(15))
        }
        .frame(width: 50 * scale, height: 65 * scale, alignment: .bottom)
    }
}

// MARK: Acacia Tree

private struct AcaciaTree: View {
    let color: Color
    let scale: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            // Short, stout trunk
            Capsule()
                .fill(color)
                .frame(width: 7 * scale, height: 30 * scale)

            // Wide, flat canopy — characteristic flat-topped acacia silhouette
            Ellipse()
                .fill(color)
                .frame(width: 60 * scale, height: 18 * scale)
                .offset(y: -(24 * scale))
        }
        .frame(width: 65 * scale, height: 50 * scale, alignment: .bottom)
    }
}

// MARK: Cypress Tree

private struct CypressTree: View {
    let color: Color
    let scale: CGFloat

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tall, narrow trunk
            Capsule()
                .fill(color)
                .frame(width: 5 * scale, height: 65 * scale)

            // Tall, narrow canopy that wraps the trunk
            Ellipse()
                .fill(color)
                .frame(width: 16 * scale, height: 55 * scale)
                .offset(y: -(16 * scale))
        }
        .frame(width: 20 * scale, height: 75 * scale, alignment: .bottom)
    }
}

// MARK: - LightRays

/// Thin rectangles radiating outward from a focal point (e.g. sun position),
/// slowly rotating for a soft sunray effect. Opacity is intentionally very low.
struct LightRays: View {

    let count: Int
    let color: Color
    /// Length of each ray in points.
    let length: CGFloat
    /// Source point relative to the container (e.g. `.init(x: 0.5, y: 0.2)`).
    let origin: UnitPoint
    /// Seconds for one full 360° rotation.
    let rotationSpeed: Double
    let size: CGSize

    @State private var rotating = false

    // MARK: Ray data — generated once at init

    private struct RayData {
        let angle: Double    // base angle in degrees
        let opacity: Double
        let width: CGFloat
    }

    private let rays: [RayData]

    init(count: Int, color: Color, length: CGFloat, origin: UnitPoint, rotationSpeed: Double, size: CGSize) {
        self.count = count
        self.color = color
        self.length = length
        self.origin = origin
        self.rotationSpeed = rotationSpeed
        self.size = size

        let step = 360.0 / Double(count)
        self.rays = (0..<count).map { i in
            RayData(
                angle: Double(i) * step,
                opacity: Double.random(in: 0.04...0.10),
                width: CGFloat.random(in: 1.0...2.0)
            )
        }
    }

    var body: some View {
        let cx = size.width  * origin.x
        let cy = size.height * origin.y

        ZStack {
            ForEach(Array(rays.enumerated()), id: \.offset) { _, ray in
                Rectangle()
                    .fill(color.opacity(ray.opacity))
                    .frame(width: ray.width, height: length)
                    // Rotate first so each ray fans out from its top edge,
                    // then offset so the top edge aligns with the ZStack center (sun position).
                    .rotationEffect(.degrees(ray.angle), anchor: UnitPoint(x: 0.5, y: 0))
                    .offset(y: length * 0.5)
            }
        }
        .position(x: cx, y: cy)
        .rotationEffect(
            .degrees(rotating ? 360 : 0),
            anchor: UnitPoint(x: origin.x, y: origin.y)
        )
        .animation(
            .linear(duration: rotationSpeed)
                .repeatForever(autoreverses: false),
            value: rotating
        )
        .onAppear {
            rotating = true
        }
    }
}

// MARK: - HeatHaze

/// A thin, semi-transparent horizontal band that shimmers near the horizon,
/// evoking the wavering distortion seen above sun-baked desert sand.
struct HeatHaze: View {

    let color: Color
    /// Y fraction of the container (0 = top, 1 = bottom).
    let yPosition: CGFloat
    let size: CGSize

    @State private var shimmering = false

    var body: some View {
        Capsule()
            .fill(
                LinearGradient(
                    colors: [
                        .clear,
                        color.opacity(shimmering ? 0.06 : 0.02),
                        color.opacity(shimmering ? 0.04 : 0.01),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(width: size.width * 0.95, height: 12)
            .position(x: size.width * 0.5, y: size.height * yPosition)
            .animation(
                .easeInOut(duration: 3.0)
                    .repeatForever(autoreverses: true),
                value: shimmering
            )
            .onAppear {
                shimmering = true
            }
    }
}

// MARK: - RamadanCannon

/// A detailed traditional Ramadan cannon (مدفع رمضان) rendered with `Canvas`.
/// Features: tapered barrel with reinforcement rings, cascabel knob, trunnions,
/// proper gun carriage with trail, wooden-spoked wheels with iron rims,
/// touch hole, and decorative moldings.
///
/// Coordinate convention inside the canvas:
///   • Origin (0, 0) = ground-centre of the cannon
///   • Y increases downward (standard screen coords)
///   • The barrel points upper-left
struct RamadanCannon: View {

    let color: Color
    let highlightColor: Color
    let scale: CGFloat
    /// Position of the cannon's ground-centre in the parent coordinate space.
    let position: CGPoint

    // ── Base geometry (before scale) ────────────────────────────
    private static let barrelAngleDeg: CGFloat = 35
    private static let barrelLength: CGFloat   = 105
    private static let muzzleThick: CGFloat    = 14   // half-width at muzzle end
    private static let breechThick: CGFloat    = 20   // half-width at breech (tapered)
    private static let muzzleR: CGFloat        = 16

    private static let carriageW: CGFloat = 70
    private static let carriageH: CGFloat = 24
    private static let trailLength: CGFloat = 50  // tail extending behind wheels

    private static let wheelR: CGFloat      = 28
    private static let wheelInnerR: CGFloat = 22
    private static let hubR: CGFloat        = 7
    private static let wheelGap: CGFloat    = 52

    /// Muzzle tip in the parent's coordinate space.
    static func muzzleTip(base: CGPoint, scale: CGFloat) -> CGPoint {
        let rad = barrelAngleDeg * .pi / 180
        let pivotY = -wheelR * scale - carriageH * scale * 0.35
        let tipX = -cos(rad) * barrelLength * scale
        let tipY = pivotY - sin(rad) * barrelLength * scale
        return CGPoint(x: base.x + tipX, y: base.y + tipY)
    }

    private var canvasW: CGFloat { (Self.barrelLength + Self.carriageW + Self.trailLength + 50) * scale }
    private var canvasH: CGFloat { (Self.wheelR * 2 + Self.carriageH + Self.barrelLength * 0.7 + 30) * scale }

    var body: some View {
        Canvas { ctx, size in
            let s = scale
            let ox = size.width * 0.55
            let oy = size.height - Self.wheelR * s - 6 * s

            let wheelCY = oy
            let carriageBottom = wheelCY - Self.wheelR * s * 0.35
            let carriageTop = carriageBottom - Self.carriageH * s
            let pivotY = (carriageTop + carriageBottom) * 0.5

            let rad = Self.barrelAngleDeg * .pi / 180
            let tipX = ox - cos(rad) * Self.barrelLength * s
            let tipY = pivotY - sin(rad) * Self.barrelLength * s

            let mainColor = color
            let hiColor = highlightColor
            let shadowColor = Color.black.opacity(0.3)

            // ── Trail (extends behind and down to ground) ─────────
            drawTrail(ctx: ctx, ox: ox, carriageBottom: carriageBottom,
                      wheelCY: wheelCY, s: s, color: mainColor, hi: hiColor)

            // ── Axle ────────────────────────────────────────────
            let axleHalf = (Self.wheelGap / 2 + 10) * s
            var axlePath = Path()
            axlePath.move(to: CGPoint(x: ox - axleHalf, y: wheelCY))
            axlePath.addLine(to: CGPoint(x: ox + axleHalf, y: wheelCY))
            ctx.stroke(axlePath, with: .color(mainColor), lineWidth: 6 * s)
            // Axle highlight
            var axleHi = Path()
            axleHi.move(to: CGPoint(x: ox - axleHalf, y: wheelCY - 1.5 * s))
            axleHi.addLine(to: CGPoint(x: ox + axleHalf, y: wheelCY - 1.5 * s))
            ctx.stroke(axleHi, with: .color(hiColor.opacity(0.15)), lineWidth: 1 * s)

            // ── Wheels ──────────────────────────────────────────
            for sign: CGFloat in [-1, 1] {
                let wcx = ox + sign * Self.wheelGap / 2 * s
                drawWheel(ctx: ctx, cx: wcx, cy: wheelCY, s: s,
                          color: mainColor, hi: hiColor, shadow: shadowColor)
            }

            // ── Carriage body ───────────────────────────────────
            drawCarriage(ctx: ctx, ox: ox, carriageTop: carriageTop,
                         carriageBottom: carriageBottom, s: s,
                         color: mainColor, hi: hiColor, shadow: shadowColor)

            // ── Trunnions (barrel supports) ─────────────────────
            drawTrunnions(ctx: ctx, ox: ox, pivotY: pivotY, s: s,
                          color: mainColor, hi: hiColor)

            // ── Barrel (tapered) ────────────────────────────────
            drawBarrel(ctx: ctx, ox: ox, pivotY: pivotY,
                       tipX: tipX, tipY: tipY, rad: rad, s: s,
                       color: mainColor, hi: hiColor, shadow: shadowColor)

            // ── Cascabel (knob at breech end) ───────────────────
            drawCascabel(ctx: ctx, ox: ox, pivotY: pivotY, rad: rad, s: s,
                         color: mainColor, hi: hiColor)

            // ── Muzzle ring & bore ──────────────────────────────
            drawMuzzle(ctx: ctx, tipX: tipX, tipY: tipY, s: s,
                       color: mainColor, hi: hiColor)

            // ── Touch hole / fuse ───────────────────────────────
            drawTouchHole(ctx: ctx, ox: ox, pivotY: pivotY, rad: rad, s: s,
                          hi: hiColor)
        }
        .frame(width: canvasW, height: canvasH)
        .position(position)
    }

    // MARK: - Trail

    private func drawTrail(ctx: GraphicsContext, ox: CGFloat,
                           carriageBottom: CGFloat, wheelCY: CGFloat,
                           s: CGFloat, color: Color, hi: Color) {
        let trailEnd = ox + Self.trailLength * s
        let groundY = wheelCY + Self.wheelR * s * 0.7
        let halfW = 8 * s

        var trail = Path()
        trail.move(to: CGPoint(x: ox + Self.carriageW * s * 0.3, y: carriageBottom - halfW * 0.3))
        trail.addLine(to: CGPoint(x: trailEnd, y: groundY - halfW * 0.5))
        trail.addLine(to: CGPoint(x: trailEnd + 4 * s, y: groundY + halfW * 0.3))
        trail.addLine(to: CGPoint(x: ox + Self.carriageW * s * 0.3, y: carriageBottom + halfW * 0.3))
        trail.closeSubpath()
        ctx.fill(trail, with: .color(color))

        // Trail top edge highlight
        var trailHi = Path()
        trailHi.move(to: CGPoint(x: ox + Self.carriageW * s * 0.3, y: carriageBottom - halfW * 0.3))
        trailHi.addLine(to: CGPoint(x: trailEnd, y: groundY - halfW * 0.5))
        ctx.stroke(trailHi, with: .color(hi.opacity(0.2)), lineWidth: 1 * s)

        // Trail end cap (rounded)
        let capR = 5 * s
        let capRect = CGRect(x: trailEnd - capR * 0.5, y: groundY - capR,
                             width: capR * 2, height: capR * 2)
        ctx.fill(Ellipse().path(in: capRect), with: .color(color))
        ctx.stroke(Ellipse().path(in: capRect), with: .color(hi.opacity(0.15)), lineWidth: 1 * s)
    }

    // MARK: - Carriage

    private func drawCarriage(ctx: GraphicsContext, ox: CGFloat,
                              carriageTop: CGFloat, carriageBottom: CGFloat,
                              s: CGFloat, color: Color, hi: Color, shadow: Color) {
        let cLeft  = ox - Self.carriageW * s * 0.45
        let cRight = ox + Self.carriageW * s * 0.45

        // Main carriage body (trapezoid with slight curve)
        var cPath = Path()
        cPath.move(to: CGPoint(x: cLeft + 6 * s, y: carriageTop))
        cPath.addLine(to: CGPoint(x: cRight - 6 * s, y: carriageTop))
        cPath.addLine(to: CGPoint(x: cRight + 3 * s, y: carriageBottom))
        cPath.addLine(to: CGPoint(x: cLeft - 3 * s, y: carriageBottom))
        cPath.closeSubpath()
        ctx.fill(cPath, with: .color(color))

        // Top highlight
        var topHi = Path()
        topHi.move(to: CGPoint(x: cLeft + 6 * s, y: carriageTop))
        topHi.addLine(to: CGPoint(x: cRight - 6 * s, y: carriageTop))
        ctx.stroke(topHi, with: .color(hi.opacity(0.35)), lineWidth: 1.5 * s)

        // Bottom shadow
        var botSh = Path()
        botSh.move(to: CGPoint(x: cLeft - 3 * s, y: carriageBottom))
        botSh.addLine(to: CGPoint(x: cRight + 3 * s, y: carriageBottom))
        ctx.stroke(botSh, with: .color(shadow), lineWidth: 1 * s)

        // Vertical reinforcement lines on carriage
        for frac: CGFloat in [0.3, 0.7] {
            let lx = cLeft + (cRight - cLeft) * frac
            var line = Path()
            line.move(to: CGPoint(x: lx, y: carriageTop + 2 * s))
            line.addLine(to: CGPoint(x: lx, y: carriageBottom - 2 * s))
            ctx.stroke(line, with: .color(hi.opacity(0.12)), lineWidth: 1 * s)
        }

        // Elevation wedge (under barrel, between carriage cheeks)
        let wedgeW = 18 * s
        let wedgeH = 8 * s
        let wedgeCX = ox
        let wedgeBottom = carriageTop
        var wedge = Path()
        wedge.move(to: CGPoint(x: wedgeCX - wedgeW * 0.5, y: wedgeBottom))
        wedge.addLine(to: CGPoint(x: wedgeCX + wedgeW * 0.5, y: wedgeBottom))
        wedge.addLine(to: CGPoint(x: wedgeCX + wedgeW * 0.3, y: wedgeBottom - wedgeH))
        wedge.addLine(to: CGPoint(x: wedgeCX - wedgeW * 0.3, y: wedgeBottom - wedgeH))
        wedge.closeSubpath()
        ctx.fill(wedge, with: .color(hi.opacity(0.15)))
    }

    // MARK: - Trunnions

    private func drawTrunnions(ctx: GraphicsContext, ox: CGFloat,
                               pivotY: CGFloat, s: CGFloat,
                               color: Color, hi: Color) {
        let trunnionLen = 10 * s
        let trunnionR = 4 * s
        for sign: CGFloat in [-1, 1] {
            let tx = ox + sign * Self.carriageW * s * 0.42
            // Cylindrical trunnion stub
            var stub = Path()
            stub.move(to: CGPoint(x: tx, y: pivotY - trunnionR))
            stub.addLine(to: CGPoint(x: tx + sign * trunnionLen, y: pivotY - trunnionR))
            stub.addLine(to: CGPoint(x: tx + sign * trunnionLen, y: pivotY + trunnionR))
            stub.addLine(to: CGPoint(x: tx, y: pivotY + trunnionR))
            stub.closeSubpath()
            ctx.fill(stub, with: .color(color))

            // Trunnion end cap
            let capRect = CGRect(x: tx + sign * trunnionLen - trunnionR,
                                 y: pivotY - trunnionR,
                                 width: trunnionR * 2, height: trunnionR * 2)
            ctx.fill(Circle().path(in: capRect), with: .color(color))
            ctx.stroke(Circle().path(in: capRect), with: .color(hi.opacity(0.25)), lineWidth: 1 * s)
        }
    }

    // MARK: - Barrel (tapered)

    private func drawBarrel(ctx: GraphicsContext, ox: CGFloat, pivotY: CGFloat,
                            tipX: CGFloat, tipY: CGFloat, rad: CGFloat,
                            s: CGFloat, color: Color, hi: Color, shadow: Color) {
        let breechHalf = Self.breechThick * s / 2
        let muzzleHalf = Self.muzzleThick * s / 2

        // Perpendicular direction to barrel axis
        let perpX = sin(rad)
        let perpY = cos(rad)

        // Tapered barrel polygon (wider at breech, narrower at muzzle)
        var barrelPath = Path()
        barrelPath.move(to: CGPoint(x: ox + perpX * breechHalf,
                                    y: pivotY - perpY * breechHalf))
        barrelPath.addLine(to: CGPoint(x: tipX + perpX * muzzleHalf,
                                       y: tipY - perpY * muzzleHalf))
        barrelPath.addLine(to: CGPoint(x: tipX - perpX * muzzleHalf,
                                       y: tipY + perpY * muzzleHalf))
        barrelPath.addLine(to: CGPoint(x: ox - perpX * breechHalf,
                                       y: pivotY + perpY * breechHalf))
        barrelPath.closeSubpath()
        ctx.fill(barrelPath, with: .color(color))

        // Barrel top highlight (along the taper)
        var barrelHi = Path()
        barrelHi.move(to: CGPoint(x: ox + perpX * breechHalf * 0.6,
                                  y: pivotY - perpY * breechHalf * 0.6))
        barrelHi.addLine(to: CGPoint(x: tipX + perpX * muzzleHalf * 0.6,
                                     y: tipY - perpY * muzzleHalf * 0.6))
        ctx.stroke(barrelHi, with: .color(hi.opacity(0.3)), lineWidth: 1.5 * s)

        // Bottom shadow line
        var barrelSh = Path()
        barrelSh.move(to: CGPoint(x: ox - perpX * breechHalf * 0.8,
                                  y: pivotY + perpY * breechHalf * 0.8))
        barrelSh.addLine(to: CGPoint(x: tipX - perpX * muzzleHalf * 0.8,
                                     y: tipY + perpY * muzzleHalf * 0.8))
        ctx.stroke(barrelSh, with: .color(shadow), lineWidth: 1 * s)

        // Reinforcement bands (raised rings)
        let bandPositions: [CGFloat] = [0.15, 0.35, 0.55, 0.75, 0.92]
        for t in bandPositions {
            let bx = ox + (-cos(rad) * Self.barrelLength * s * t)
            let by = pivotY + (-sin(rad) * Self.barrelLength * s * t)
            // Interpolate width at this position
            let halfW = breechHalf + (muzzleHalf - breechHalf) * t
            let bandHalf = halfW + 4 * s

            var band = Path()
            band.move(to: CGPoint(x: bx + perpX * bandHalf, y: by - perpY * bandHalf))
            band.addLine(to: CGPoint(x: bx - perpX * bandHalf, y: by + perpY * bandHalf))
            ctx.stroke(band, with: .color(hi.opacity(0.25)), lineWidth: 3 * s)

            // Inner band shadow
            let innerBand = halfW + 2 * s
            var bandInner = Path()
            bandInner.move(to: CGPoint(x: bx + perpX * innerBand, y: by - perpY * innerBand))
            bandInner.addLine(to: CGPoint(x: bx - perpX * innerBand, y: by + perpY * innerBand))
            ctx.stroke(bandInner, with: .color(shadow.opacity(0.5)), lineWidth: 1.5 * s)
        }

        // Decorative center molding (wider band at 45%)
        let moldT: CGFloat = 0.45
        let moldX = ox + (-cos(rad) * Self.barrelLength * s * moldT)
        let moldY = pivotY + (-sin(rad) * Self.barrelLength * s * moldT)
        let moldHalf = (breechHalf + (muzzleHalf - breechHalf) * moldT) + 6 * s
        var mold = Path()
        mold.move(to: CGPoint(x: moldX + perpX * moldHalf, y: moldY - perpY * moldHalf))
        mold.addLine(to: CGPoint(x: moldX - perpX * moldHalf, y: moldY + perpY * moldHalf))
        ctx.stroke(mold, with: .color(hi.opacity(0.18)), lineWidth: 5 * s)
    }

    // MARK: - Cascabel (breech knob)

    private func drawCascabel(ctx: GraphicsContext, ox: CGFloat,
                              pivotY: CGFloat, rad: CGFloat,
                              s: CGFloat, color: Color, hi: Color) {
        // Cascabel sits behind the breech
        let overhang: CGFloat = 12 * s
        let cx = ox + cos(rad) * overhang
        let cy = pivotY + sin(rad) * overhang
        let knobR = 8 * s

        // Neck (connects breech to knob)
        let neckLen = 8 * s
        let nx = ox + cos(rad) * (overhang - neckLen)
        let ny = pivotY + sin(rad) * (overhang - neckLen)
        var neck = Path()
        neck.move(to: CGPoint(x: nx, y: ny))
        neck.addLine(to: CGPoint(x: cx, y: cy))
        ctx.stroke(neck, with: .color(color), lineWidth: 6 * s)

        // Knob
        let knobRect = CGRect(x: cx - knobR, y: cy - knobR,
                               width: knobR * 2, height: knobR * 2)
        ctx.fill(Circle().path(in: knobRect), with: .color(color))
        ctx.stroke(Circle().path(in: knobRect), with: .color(hi.opacity(0.3)), lineWidth: 1.5 * s)

        // Knob highlight dot
        let dotR = 2.5 * s
        let dotRect = CGRect(x: cx - dotR - 1 * s, y: cy - dotR - 1 * s,
                             width: dotR * 2, height: dotR * 2)
        ctx.fill(Circle().path(in: dotRect), with: .color(hi.opacity(0.25)))
    }

    // MARK: - Muzzle

    private func drawMuzzle(ctx: GraphicsContext, tipX: CGFloat, tipY: CGFloat,
                            s: CGFloat, color: Color, hi: Color) {
        let mR = Self.muzzleR * s

        // Outer muzzle ring (flared lip)
        let outerR = mR * 1.2
        let outerRect = CGRect(x: tipX - outerR, y: tipY - outerR,
                               width: outerR * 2, height: outerR * 2)
        ctx.fill(Circle().path(in: outerRect), with: .color(color))
        ctx.stroke(Circle().path(in: outerRect), with: .color(hi.opacity(0.3)), lineWidth: 2.5 * s)

        // Inner muzzle ring
        let innerRect = CGRect(x: tipX - mR, y: tipY - mR,
                               width: mR * 2, height: mR * 2)
        ctx.stroke(Circle().path(in: innerRect), with: .color(hi.opacity(0.2)), lineWidth: 1.5 * s)

        // Bore (dark interior)
        let boreR = mR * 0.5
        let boreRect = CGRect(x: tipX - boreR, y: tipY - boreR,
                              width: boreR * 2, height: boreR * 2)
        ctx.fill(Circle().path(in: boreRect), with: .color(Color.black.opacity(0.6)))

        // Bore inner highlight (rim light)
        ctx.stroke(Circle().path(in: boreRect), with: .color(hi.opacity(0.1)), lineWidth: 0.5 * s)
    }

    // MARK: - Touch hole

    private func drawTouchHole(ctx: GraphicsContext, ox: CGFloat,
                               pivotY: CGFloat, rad: CGFloat,
                               s: CGFloat, hi: Color) {
        // Small vent hole on top of barrel near breech
        let t: CGFloat = 0.12
        let hx = ox + (-cos(rad) * Self.barrelLength * s * t)
        let hy = pivotY + (-sin(rad) * Self.barrelLength * s * t)
        // Offset upward from barrel center
        let perpX = sin(rad)
        let perpY = cos(rad)
        let offset = Self.breechThick * s * 0.35
        let thx = hx + perpX * offset
        let thy = hy - perpY * offset

        let holeR = 2 * s
        let holeRect = CGRect(x: thx - holeR, y: thy - holeR,
                              width: holeR * 2, height: holeR * 2)
        ctx.fill(Circle().path(in: holeRect), with: .color(Color.black.opacity(0.4)))

        // Small fuse stub sticking out
        var fuse = Path()
        fuse.move(to: CGPoint(x: thx, y: thy))
        fuse.addLine(to: CGPoint(x: thx + perpX * 6 * s, y: thy - perpY * 6 * s))
        ctx.stroke(fuse, with: .color(hi.opacity(0.35)), lineWidth: 1.5 * s)
    }

    // MARK: - Wheel drawing

    private func drawWheel(ctx: GraphicsContext, cx: CGFloat, cy: CGFloat,
                           s: CGFloat, color: Color, hi: Color, shadow: Color) {
        let outerR = Self.wheelR * s
        let innerR = Self.wheelInnerR * s
        let hub    = Self.hubR * s

        // Outer iron rim (thick)
        let outerRect = CGRect(x: cx - outerR, y: cy - outerR,
                               width: outerR * 2, height: outerR * 2)
        ctx.stroke(Circle().path(in: outerRect), with: .color(color), lineWidth: 5 * s)
        // Rim highlight (top half)
        ctx.stroke(Circle().path(in: outerRect), with: .color(hi.opacity(0.2)), lineWidth: 1.5 * s)

        // Inner felloe ring
        let innerRect = CGRect(x: cx - innerR, y: cy - innerR,
                               width: innerR * 2, height: innerR * 2)
        ctx.stroke(Circle().path(in: innerRect), with: .color(color), lineWidth: 3 * s)
        ctx.stroke(Circle().path(in: innerRect), with: .color(hi.opacity(0.1)), lineWidth: 0.5 * s)

        // Wooden spokes (8 for more detail)
        for i in 0..<8 {
            let angle = CGFloat(i) * 45.0 * .pi / 180
            var spoke = Path()
            spoke.move(to: CGPoint(x: cx + cos(angle) * (hub + 1 * s),
                                   y: cy + sin(angle) * (hub + 1 * s)))
            spoke.addLine(to: CGPoint(x: cx + cos(angle) * (innerR - 1 * s),
                                      y: cy + sin(angle) * (innerR - 1 * s)))
            ctx.stroke(spoke, with: .color(color), lineWidth: 3 * s)
            // Spoke highlight
            ctx.stroke(spoke, with: .color(hi.opacity(0.08)), lineWidth: 1 * s)
        }

        // Hub (larger, more detailed)
        let hubRect = CGRect(x: cx - hub, y: cy - hub,
                             width: hub * 2, height: hub * 2)
        ctx.fill(Circle().path(in: hubRect), with: .color(color))
        ctx.stroke(Circle().path(in: hubRect), with: .color(hi.opacity(0.35)), lineWidth: 1.5 * s)

        // Hub center bolt
        let boltR = 2.5 * s
        let boltRect = CGRect(x: cx - boltR, y: cy - boltR,
                              width: boltR * 2, height: boltR * 2)
        ctx.fill(Circle().path(in: boltRect), with: .color(hi.opacity(0.2)))
    }
}

// MARK: - CannonFireEffect (SpriteKit)

import SpriteKit

/// SpriteKit scene that simulates cannon fire with real physics:
/// muzzle flash, expanding smoke ring, cannonball with gravity, and a spark trail.
/// Re-fires automatically every few seconds.
class CannonFireScene: SKScene {

    private var muzzlePos: CGPoint = .zero
    private var fireAngleRad: CGFloat = 0
    private var flashColor: NSColor = .yellow
    private var smokeColor: NSColor = .gray
    private var refireInterval: TimeInterval = 6.0

    func configure(
        muzzlePosition: CGPoint,
        fireAngleDeg: CGFloat,
        flashColor: NSColor,
        smokeColor: NSColor,
        containerSize: CGSize
    ) {
        self.size = containerSize
        self.scaleMode = .resizeFill
        self.backgroundColor = .clear

        // SpriteKit Y is flipped vs SwiftUI (0 at bottom)
        self.muzzlePos = CGPoint(x: muzzlePosition.x,
                                  y: containerSize.height - muzzlePosition.y)
        self.fireAngleRad = fireAngleDeg * .pi / 180
        self.flashColor = flashColor
        self.smokeColor = smokeColor

        // No global gravity — we apply it per-body so smoke floats up
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
    }

    override func didMove(to view: SKView) {
        view.allowsTransparency = true
        fire()
        startRefireLoop()
    }

    private func startRefireLoop() {
        let wait = SKAction.wait(forDuration: refireInterval)
        let fireAction = SKAction.run { [weak self] in self?.fire() }
        run(.repeatForever(.sequence([wait, fireAction])), withKey: "refire")
    }

    // MARK: - Fire sequence

    private func fire() {
        spawnMuzzleFlash()
        spawnSmoke()
        // Cannonball after a tiny delay for realism
        run(.sequence([.wait(forDuration: 0.05), .run { [weak self] in self?.spawnCannonball() }]))
    }

    // MARK: Muzzle flash

    private func spawnMuzzleFlash() {
        let flash = SKShapeNode(circleOfRadius: 18)
        flash.position = muzzlePos
        flash.fillColor = flashColor
        flash.strokeColor = .clear
        flash.alpha = 0.9
        flash.zPosition = 10
        flash.blendMode = .add
        addChild(flash)

        // Outer glow
        let glow = SKShapeNode(circleOfRadius: 40)
        glow.position = muzzlePos
        glow.fillColor = flashColor.withAlphaComponent(0.3)
        glow.strokeColor = .clear
        glow.blendMode = .add
        glow.zPosition = 9
        addChild(glow)

        let expand = SKAction.scale(to: 4.0, duration: 0.3)
        let fade = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        flash.run(.sequence([.group([expand, fade]), remove]))
        glow.run(.sequence([.group([.scale(to: 3.0, duration: 0.4), .fadeOut(withDuration: 0.4)]), remove]))
    }

    // MARK: Smoke

    private func spawnSmoke() {
        for i in 0..<8 {
            let delay = Double(i) * 0.04
            run(.sequence([.wait(forDuration: delay), .run { [weak self] in
                guard let self = self else { return }
                let puff = SKShapeNode(circleOfRadius: CGFloat.random(in: 6...14))
                puff.position = self.muzzlePos
                puff.fillColor = self.smokeColor.withAlphaComponent(CGFloat.random(in: 0.25...0.45))
                puff.strokeColor = .clear
                puff.zPosition = 5
                self.addChild(puff)

                // Give it a physics body so it drifts
                puff.physicsBody = SKPhysicsBody(circleOfRadius: 8)
                puff.physicsBody?.isDynamic = true
                puff.physicsBody?.affectedByGravity = false
                puff.physicsBody?.linearDamping = 1.5
                puff.physicsBody?.collisionBitMask = 0

                // Drift: mostly along fire direction + upward spread
                let spread = CGFloat.random(in: -0.4...0.4)
                let speed = CGFloat.random(in: 30...80)
                let dx = cos(self.fireAngleRad + spread) * speed
                let dy = sin(self.fireAngleRad + spread) * speed + CGFloat.random(in: 20...50)
                puff.physicsBody?.velocity = CGVector(dx: dx, dy: dy)

                // Expand and fade
                let expandDur = Double.random(in: 1.5...2.5)
                puff.run(.sequence([
                    .group([
                        .scale(to: CGFloat.random(in: 3.0...5.0), duration: expandDur),
                        .fadeOut(withDuration: expandDur)
                    ]),
                    .removeFromParent()
                ]))
            }]))
        }
    }

    // MARK: Cannonball

    private func spawnCannonball() {
        let ball = SKShapeNode(circleOfRadius: 7)
        ball.position = muzzlePos
        ball.fillColor = NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1)
        ball.strokeColor = NSColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        ball.lineWidth = 1.5
        ball.zPosition = 8
        addChild(ball)

        ball.physicsBody = SKPhysicsBody(circleOfRadius: 7)
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.affectedByGravity = true
        ball.physicsBody?.linearDamping = 0.1
        ball.physicsBody?.collisionBitMask = 0
        // Real gravity just for the cannonball
        ball.physicsBody?.fieldBitMask = 0

        // Launch impulse
        let launchSpeed: CGFloat = 320
        let dx = cos(fireAngleRad) * launchSpeed
        let dy = sin(fireAngleRad) * launchSpeed
        ball.physicsBody?.velocity = CGVector(dx: dx, dy: dy)

        // Spark trail emitter attached to cannonball
        if let trail = makeTrailEmitter() {
            trail.zPosition = 7
            trail.targetNode = self  // particles stay in world space
            ball.addChild(trail)
        }

        // Glow behind cannonball
        let glow = SKShapeNode(circleOfRadius: 14)
        glow.fillColor = flashColor.withAlphaComponent(0.2)
        glow.strokeColor = .clear
        glow.blendMode = .add
        ball.addChild(glow)

        // Simulate gravity manually via update (SpriteKit Y-up)
        let gravityAction = SKAction.customAction(withDuration: 4.0) { node, elapsed in
            node.physicsBody?.applyForce(CGVector(dx: 0, dy: -120))
        }
        ball.run(.sequence([gravityAction, .fadeOut(withDuration: 0.3), .removeFromParent()]))
    }

    private func makeTrailEmitter() -> SKEmitterNode? {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 120
        emitter.numParticlesToEmit = 0  // continuous while alive
        emitter.particleLifetime = 0.5
        emitter.particleLifetimeRange = 0.2
        emitter.emissionAngle = fireAngleRad + .pi  // trail behind
        emitter.emissionAngleRange = 0.4
        emitter.particleSpeed = 20
        emitter.particleSpeedRange = 15
        emitter.particleAlpha = 0.7
        emitter.particleAlphaSpeed = -1.4
        emitter.particleScale = 0.08
        emitter.particleScaleSpeed = -0.05
        emitter.particleColor = flashColor
        emitter.particleColorBlendFactor = 1
        emitter.particleBlendMode = .add

        // Create a small radial gradient texture for the spark
        let texSize = 16
        let image = NSImage(size: NSSize(width: texSize, height: texSize), flipped: false) { rect in
            let ctx = NSGraphicsContext.current!.cgContext
            let colors = [NSColor.white.cgColor, NSColor.white.withAlphaComponent(0).cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                let centre = CGPoint(x: rect.midX, y: rect.midY)
                ctx.drawRadialGradient(gradient, startCenter: centre, startRadius: 0,
                                       endCenter: centre, endRadius: CGFloat(texSize / 2),
                                       options: .drawsAfterEndLocation)
            }
            return true
        }
        emitter.particleTexture = SKTexture(image: image)
        return emitter
    }
}

/// SwiftUI wrapper that hosts the SpriteKit `CannonFireScene`.
struct CannonFireEffect: View {
    let muzzlePosition: CGPoint
    let fireAngle: Double
    let flashColor: Color
    let smokeColor: Color
    let size: CGSize

    var body: some View {
        SpriteView(scene: makeScene(), options: [.allowsTransparency])
            .frame(width: size.width, height: size.height)
            .allowsHitTesting(false)
    }

    private func makeScene() -> CannonFireScene {
        let scene = CannonFireScene()
        scene.configure(
            muzzlePosition: muzzlePosition,
            fireAngleDeg: CGFloat(fireAngle),
            flashColor: NSColor(flashColor),
            smokeColor: NSColor(smokeColor),
            containerSize: size
        )
        return scene
    }
}

// MARK: - TopHalfClip

/// A `Shape` that masks only the upper half of its bounding rectangle.
/// Used by `CelestialBody` to render the half-disc (sun peaking above horizon).
private struct TopHalfClip: Shape {
    func path(in rect: CGRect) -> Path {
        Path(CGRect(
            x: rect.minX,
            y: rect.minY,
            width: rect.width,
            height: rect.height * 0.5
        ))
    }
}

// MARK: - Helpers

private extension CGFloat {
    /// Clamps the value into the given closed range.
    func clamped(to range: ClosedRange<CGFloat>) -> CGFloat {
        Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
