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
        /// A circle clipped to its bottom half — used for the sunrise/sunset disc.
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
                // Clip to lower half only so it appears rising over the horizon.
                // BottomHalfClip is a Path-based Shape that masks everything above
                // the vertical midpoint of its bounding rect.
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
            path.addCurve(to: p4, control1: c4a, control2: c4b)

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
