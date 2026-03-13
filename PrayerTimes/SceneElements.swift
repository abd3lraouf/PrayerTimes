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

/// A realistic traditional Ramadan cannon (مدفع رمضان) rendered with `Canvas`.
///
/// Rendering uses multi-layer strokes for 3D depth: dark base → main fill →
/// specular highlight. The barrel has a historically-accurate profile with
/// first/second reinforce swells, astragal moldings, chase taper, and muzzle
/// swell. Carriage is rendered as thick oak planks with iron bracket bolts.
/// Wheels have proper felloe segments, tapered spokes, and iron tire bands.
///
/// Image-based Ramadan cannon loaded from the asset catalog (CannonFortress).
/// The raw image has the barrel pointing upper-right. The view flips it so the
/// barrel defaults to upper-left; set `mirrored` to point upper-right instead.
///
/// `position` is the **ground-centre** of the cannon (where wheels touch ground).
struct RamadanCannon: View {

    let scale: CGFloat
    let position: CGPoint     // Ground-centre in parent coords
    /// When `true`, the cannon barrel points upper-right (raw image orientation).
    var mirrored: Bool = false

    // ── Geometry constants matching the CannonFortress artwork ───
    /// Extracted CannonFortress element: 1128×690, aspect ≈ 1.635
    private static let imageAspect: CGFloat = 1128.0 / 690.0
    /// Base (unscaled) image width.
    private static let baseWidth: CGFloat = 200

    // Muzzle centre in the raw image (barrel points upper-right):
    //   x ≈ 0.93 of width, y ≈ 0.27 of height (from grid measurement).
    // Ground anchor is at (0.50, 0.95) of image.
    // Offset from ground anchor (raw image, barrel right):
    private static let rawMuzzleDx: CGFloat =  0.43   // right of centre
    private static let rawMuzzleDy: CGFloat = -0.68   // above ground

    /// Muzzle centre in the parent's coordinate space.
    static func muzzleTip(base: CGPoint, scale: CGFloat, mirrored: Bool = false) -> CGPoint {
        let w = baseWidth * scale
        let h = w / imageAspect
        // Default (non-mirrored) flips the image so barrel points LEFT → dx is negative.
        // Mirrored keeps raw orientation → dx is positive.
        let sign: CGFloat = mirrored ? 1 : -1
        return CGPoint(x: base.x + sign * rawMuzzleDx * w,
                       y: base.y + rawMuzzleDy * h)
    }

    var body: some View {
        let w = Self.baseWidth * scale
        let h = w / Self.imageAspect
        Image("RamadanCannon")
            .resizable()
            .interpolation(.high)
            .frame(width: w, height: h)
            // Default: flip so barrel points left. Mirrored: raw (barrel right).
            .scaleEffect(x: mirrored ? 1 : -1, y: 1)
            // position is ground-centre; shift image up by half its height
            .position(x: position.x, y: position.y - h / 2)
    }
}

/// Stacked cannonball pyramid, placed as a decorative element near the cannon.
struct CannonballsPile: View {
    let scale: CGFloat
    let position: CGPoint     // Ground-centre (bottom-centre of the pile)

    private static let imageAspect: CGFloat = 623.0 / 543.0
    private static let baseWidth: CGFloat = 60

    var body: some View {
        let w = Self.baseWidth * scale
        let h = w / Self.imageAspect
        Image("Cannonballs")
            .resizable()
            .interpolation(.high)
            .frame(width: w, height: h)
            .position(x: position.x, y: position.y - h / 2)
    }
}

// MARK: - CannonFireEffect (SpriteKit)

import SpriteKit

/// SpriteKit scene that simulates realistic cannon fire with physics:
/// bright muzzle flash with shockwave, dense billowing smoke, a visible
/// glowing cannonball that arcs across the sky with a fiery trail, and
/// ground-level dust kick-up. Re-fires automatically.
class CannonFireScene: SKScene {

    private var muzzlePos: CGPoint = .zero
    private var fireAngleRad: CGFloat = 0
    private var flashColor: NSColor = .yellow
    private var smokeColor: NSColor = .gray
    private var refireInterval: TimeInterval = 5.0
    private var sparkTexture: SKTexture?
    /// Ground level in SpriteKit coords (Y-up). Ball rolls at this Y.
    private var groundY: CGFloat = 0

    // Collision categories
    private let groundCategory: UInt32 = 0x1 << 0
    private let ballCategory: UInt32   = 0x1 << 1

    func configure(
        muzzlePosition: CGPoint,
        fireAngleDeg: CGFloat,
        flashColor: NSColor,
        smokeColor: NSColor,
        containerSize: CGSize,
        groundFraction: CGFloat = 0.92
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
        self.sparkTexture = Self.makeSparkTexture()

        // Ground in SpriteKit coords: SwiftUI groundFraction from top → SK Y from bottom
        self.groundY = containerSize.height * (1.0 - groundFraction)

        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
    }

    override func didMove(to view: SKView) {
        view.allowsTransparency = true
        fire()
        let wait = SKAction.wait(forDuration: refireInterval)
        let fireAction = SKAction.run { [weak self] in self?.fire() }
        run(.repeatForever(.sequence([wait, fireAction])), withKey: "refire")
    }

    // MARK: - Fire sequence

    private func fire() {
        spawnMuzzleFlash()
        spawnShockwave()
        spawnSmoke()
        spawnSparks()
        run(.sequence([.wait(forDuration: 0.08), .run { [weak self] in
            self?.spawnCannonball()
        }]))
    }

    // MARK: Muzzle flash (multi-layered)

    private func spawnMuzzleFlash() {
        // Inner white-hot core
        let core = SKShapeNode(circleOfRadius: 12)
        core.position = muzzlePos
        core.fillColor = .white
        core.strokeColor = .clear
        core.alpha = 1.0
        core.zPosition = 12
        core.blendMode = .add
        addChild(core)

        // Middle flash
        let flash = SKShapeNode(circleOfRadius: 22)
        flash.position = muzzlePos
        flash.fillColor = flashColor
        flash.strokeColor = .clear
        flash.alpha = 0.9
        flash.zPosition = 11
        flash.blendMode = .add
        addChild(flash)

        // Outer glow (large)
        let glow = SKShapeNode(circleOfRadius: 55)
        glow.position = muzzlePos
        glow.fillColor = flashColor.withAlphaComponent(0.25)
        glow.strokeColor = .clear
        glow.blendMode = .add
        glow.zPosition = 10
        addChild(glow)

        // Directional flash cone (elongated in fire direction)
        let cone = SKShapeNode(circleOfRadius: 30)
        cone.position = CGPoint(
            x: muzzlePos.x + cos(fireAngleRad) * 25,
            y: muzzlePos.y + sin(fireAngleRad) * 25)
        cone.fillColor = flashColor.withAlphaComponent(0.5)
        cone.strokeColor = .clear
        cone.blendMode = .add
        cone.zPosition = 10
        cone.xScale = 2.0
        addChild(cone)

        let remove = SKAction.removeFromParent()
        core.run(.sequence([.group([.scale(to: 3.0, duration: 0.15),
                                    .fadeOut(withDuration: 0.15)]), remove]))
        flash.run(.sequence([.group([.scale(to: 5.0, duration: 0.25),
                                     .fadeOut(withDuration: 0.25)]), remove]))
        glow.run(.sequence([.group([.scale(to: 3.5, duration: 0.4),
                                    .fadeOut(withDuration: 0.4)]), remove]))
        cone.run(.sequence([.group([.scale(to: 2.5, duration: 0.3),
                                    .fadeOut(withDuration: 0.3)]), remove]))
    }

    // MARK: Shockwave ring

    private func spawnShockwave() {
        let ring = SKShapeNode(circleOfRadius: 8)
        ring.position = muzzlePos
        ring.fillColor = .clear
        ring.strokeColor = flashColor.withAlphaComponent(0.4)
        ring.lineWidth = 3
        ring.blendMode = .add
        ring.zPosition = 9
        addChild(ring)

        ring.run(.sequence([
            .group([
                .scale(to: 12.0, duration: 0.5),
                .fadeOut(withDuration: 0.5),
                .customAction(withDuration: 0.5) { node, t in
                    (node as? SKShapeNode)?.lineWidth = max(0.5, 3.0 - t * 5.0)
                }
            ]),
            .removeFromParent()
        ]))
    }

    // MARK: Smoke (dense billowing)

    private func spawnSmoke() {
        // Dense burst billowing upward from muzzle
        for i in 0..<12 {
            let delay = Double(i) * 0.035
            run(.sequence([.wait(forDuration: delay), .run { [weak self] in
                guard let self = self else { return }
                let radius = CGFloat.random(in: 8...18)
                let puff = SKShapeNode(circleOfRadius: radius)
                puff.position = CGPoint(
                    x: self.muzzlePos.x + CGFloat.random(in: -6...6),
                    y: self.muzzlePos.y + CGFloat.random(in: -4...4))
                let alpha = CGFloat.random(in: 0.3...0.55)
                puff.fillColor = self.smokeColor.withAlphaComponent(alpha)
                puff.strokeColor = .clear
                puff.zPosition = 5
                self.addChild(puff)

                puff.physicsBody = SKPhysicsBody(circleOfRadius: radius * 0.5)
                puff.physicsBody?.isDynamic = true
                puff.physicsBody?.affectedByGravity = false
                puff.physicsBody?.linearDamping = 1.8
                puff.physicsBody?.collisionBitMask = 0

                // Rise upward from muzzle with slight horizontal spread
                let dx = CGFloat.random(in: -25...25)
                let dy = CGFloat.random(in: 40...100) // upward in SpriteKit Y-up
                puff.physicsBody?.velocity = CGVector(dx: dx, dy: dy)

                let dur = Double.random(in: 2.0...3.5)
                puff.run(.sequence([
                    .group([
                        .scale(to: CGFloat.random(in: 4.0...7.0), duration: dur),
                        .fadeOut(withDuration: dur)
                    ]),
                    .removeFromParent()
                ]))
            }]))
        }

        // Secondary slow-rising wispy smoke from muzzle
        for i in 0..<5 {
            let delay = Double(i) * 0.15 + 0.25
            run(.sequence([.wait(forDuration: delay), .run { [weak self] in
                guard let self = self else { return }
                let puff = SKShapeNode(circleOfRadius: CGFloat.random(in: 12...22))
                puff.position = CGPoint(
                    x: self.muzzlePos.x + CGFloat.random(in: -8...8),
                    y: self.muzzlePos.y + CGFloat.random(in: 0...10))
                puff.fillColor = self.smokeColor.withAlphaComponent(0.15)
                puff.strokeColor = .clear
                puff.zPosition = 4
                self.addChild(puff)

                puff.physicsBody = SKPhysicsBody(circleOfRadius: 6)
                puff.physicsBody?.isDynamic = true
                puff.physicsBody?.affectedByGravity = false
                puff.physicsBody?.linearDamping = 2.0
                puff.physicsBody?.collisionBitMask = 0
                // Gentle upward drift
                puff.physicsBody?.velocity = CGVector(
                    dx: CGFloat.random(in: -12...12),
                    dy: CGFloat.random(in: 25...55))

                let dur = Double.random(in: 3.0...5.0)
                puff.run(.sequence([
                    .group([
                        .scale(to: CGFloat.random(in: 5.0...9.0), duration: dur),
                        .fadeOut(withDuration: dur)
                    ]),
                    .removeFromParent()
                ]))
            }]))
        }
    }

    // MARK: Sparks (hot debris)

    private func spawnSparks() {
        for _ in 0..<15 {
            let spark = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.5))
            spark.position = muzzlePos
            spark.fillColor = flashColor
            spark.strokeColor = .clear
            spark.blendMode = .add
            spark.zPosition = 11
            addChild(spark)

            let spread = CGFloat.random(in: -0.6...0.6)
            let speed = CGFloat.random(in: 80...250)
            let dx = cos(fireAngleRad + spread) * speed
            let dy = sin(fireAngleRad + spread) * speed

            spark.physicsBody = SKPhysicsBody(circleOfRadius: 1)
            spark.physicsBody?.isDynamic = true
            spark.physicsBody?.affectedByGravity = false
            spark.physicsBody?.linearDamping = 2.0
            spark.physicsBody?.collisionBitMask = 0
            spark.physicsBody?.velocity = CGVector(dx: dx, dy: dy)

            // Apply gravity to sparks
            let dur = Double.random(in: 0.4...1.0)
            spark.run(.sequence([
                .group([
                    .fadeOut(withDuration: dur),
                    .customAction(withDuration: dur) { node, _ in
                        node.physicsBody?.applyForce(CGVector(dx: 0, dy: -40))
                    }
                ]),
                .removeFromParent()
            ]))
        }
    }

    // MARK: Cannonball (arcs then rolls on ground)

    private func spawnCannonball() {
        let ballRadius: CGFloat = 9
        let ball = SKShapeNode(circleOfRadius: ballRadius)
        ball.position = muzzlePos
        ball.fillColor = NSColor(red: 0.25, green: 0.22, blue: 0.20, alpha: 1)
        ball.strokeColor = NSColor(red: 0.45, green: 0.40, blue: 0.35, alpha: 1)
        ball.lineWidth = 2
        ball.zPosition = 8
        ball.name = "cannonball"
        addChild(ball)

        // Hot glow around ball
        let innerGlow = SKShapeNode(circleOfRadius: 16)
        innerGlow.fillColor = flashColor.withAlphaComponent(0.5)
        innerGlow.strokeColor = .clear
        innerGlow.blendMode = .add
        innerGlow.zPosition = -1
        innerGlow.name = "glow"
        ball.addChild(innerGlow)

        let outerGlow = SKShapeNode(circleOfRadius: 28)
        outerGlow.fillColor = flashColor.withAlphaComponent(0.15)
        outerGlow.strokeColor = .clear
        outerGlow.blendMode = .add
        outerGlow.zPosition = -2
        outerGlow.name = "glow"
        ball.addChild(outerGlow)

        // Fiery trail emitter
        if let trail = makeFireTrailEmitter() {
            trail.zPosition = -3
            trail.targetNode = self
            trail.name = "trail"
            ball.addChild(trail)
        }

        // Smoke trail emitter
        if let smokeTrail = makeSmokeTrailEmitter() {
            smokeTrail.zPosition = -4
            smokeTrail.targetNode = self
            smokeTrail.name = "trail"
            ball.addChild(smokeTrail)
        }

        // Launch the ball along the fire angle
        let launchSpeed: CGFloat = 350
        let launchDX = cos(fireAngleRad) * launchSpeed
        let launchDY = sin(fireAngleRad) * launchSpeed

        let capturedGroundY = self.groundY + ballRadius
        let gravityForce: CGFloat = -180

        // Phase 1: Arc through the air with gravity until it hits ground level
        // Phase 2: Roll along the ground with friction
        // Use a custom action to handle both phases
        ball.run(.customAction(withDuration: 6.0) { [weak self] node, elapsed in
            guard let self = self else { return }
            let dt: CGFloat = 1.0 / 60.0 // approximate frame delta

            if node.userData == nil {
                node.userData = NSMutableDictionary()
                node.userData?["vx"] = launchDX
                node.userData?["vy"] = launchDY
                node.userData?["rolling"] = false
                node.userData?["rollStartTime"] = 0.0 as CGFloat
            }

            var vx = (node.userData?["vx"] as? CGFloat) ?? 0
            var vy = (node.userData?["vy"] as? CGFloat) ?? 0
            let isRolling = (node.userData?["rolling"] as? Bool) ?? false

            if !isRolling {
                // Apply gravity
                vy += gravityForce * dt

                // Update position
                node.position.x += vx * dt
                node.position.y += vy * dt

                // Check if ball reached ground
                if node.position.y <= capturedGroundY {
                    node.position.y = capturedGroundY
                    // Transition to rolling: keep horizontal velocity, zero vertical
                    vy = 0
                    // On landing, reduce horizontal speed slightly (impact)
                    vx *= 0.7
                    node.userData?["rolling"] = true
                    node.userData?["rollStartTime"] = elapsed

                    // Landing dust burst
                    self.spawnLandingDust(at: CGPoint(x: node.position.x,
                                                       y: capturedGroundY - ballRadius))

                    // Kill the fire trail, keep smoke briefly
                    for child in node.children {
                        if let emitter = child as? SKEmitterNode, child.name == "trail" {
                            emitter.particleBirthRate = 0
                        }
                    }
                    // Dim the glow on impact
                    for child in node.children where child.name == "glow" {
                        child.run(.fadeAlpha(to: 0.15, duration: 0.5))
                    }
                }
            } else {
                // Rolling on ground: apply friction
                let friction: CGFloat = 0.97
                vx *= friction
                node.position.x += vx * dt
                node.position.y = capturedGroundY

                // Spin the ball (rotate)
                let angularSpeed = vx / ballRadius
                node.zRotation += angularSpeed * dt

                // Fade and remove when slow enough or after enough time
                let rollStart = (node.userData?["rollStartTime"] as? CGFloat) ?? 0
                let rollTime = elapsed - rollStart
                if rollTime > 2.5 || abs(vx) < 5 {
                    if node.alpha > 0.05 {
                        node.run(.sequence([.fadeOut(withDuration: 0.4),
                                            .removeFromParent()]))
                        // Prevent re-running fade
                        node.userData?["vx"] = CGFloat(0)
                    }
                }
            }

            node.userData?["vx"] = vx
            node.userData?["vy"] = vy
        })
    }

    // MARK: Landing dust

    private func spawnLandingDust(at pos: CGPoint) {
        for _ in 0..<6 {
            let puff = SKShapeNode(circleOfRadius: CGFloat.random(in: 5...12))
            puff.position = pos
            puff.fillColor = smokeColor.withAlphaComponent(CGFloat.random(in: 0.2...0.4))
            puff.strokeColor = .clear
            puff.zPosition = 3
            addChild(puff)

            let dx = CGFloat.random(in: -60...60)
            let dy = CGFloat.random(in: 10...40)
            puff.physicsBody = SKPhysicsBody(circleOfRadius: 4)
            puff.physicsBody?.isDynamic = true
            puff.physicsBody?.affectedByGravity = false
            puff.physicsBody?.linearDamping = 2.5
            puff.physicsBody?.collisionBitMask = 0
            puff.physicsBody?.velocity = CGVector(dx: dx, dy: dy)

            let dur = Double.random(in: 1.0...2.0)
            puff.run(.sequence([
                .group([
                    .scale(to: CGFloat.random(in: 3.0...5.0), duration: dur),
                    .fadeOut(withDuration: dur)
                ]),
                .removeFromParent()
            ]))
        }
    }

    // MARK: - Emitter helpers

    private func makeFireTrailEmitter() -> SKEmitterNode? {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 160
        emitter.numParticlesToEmit = 0
        emitter.particleLifetime = 0.4
        emitter.particleLifetimeRange = 0.15
        emitter.emissionAngle = fireAngleRad + .pi
        emitter.emissionAngleRange = 0.35
        emitter.particleSpeed = 25
        emitter.particleSpeedRange = 20
        emitter.particleAlpha = 0.85
        emitter.particleAlphaSpeed = -2.0
        emitter.particleScale = 0.12
        emitter.particleScaleSpeed = -0.15
        emitter.particleColor = flashColor
        emitter.particleColorBlendFactor = 1
        emitter.particleBlendMode = .add
        if let tex = sparkTexture { emitter.particleTexture = tex }
        return emitter
    }

    private func makeSmokeTrailEmitter() -> SKEmitterNode? {
        let emitter = SKEmitterNode()
        emitter.particleBirthRate = 40
        emitter.numParticlesToEmit = 0
        emitter.particleLifetime = 1.2
        emitter.particleLifetimeRange = 0.4
        emitter.emissionAngle = fireAngleRad + .pi
        emitter.emissionAngleRange = 0.5
        emitter.particleSpeed = 10
        emitter.particleSpeedRange = 8
        emitter.particleAlpha = 0.25
        emitter.particleAlphaSpeed = -0.2
        emitter.particleScale = 0.15
        emitter.particleScaleRange = 0.05
        emitter.particleScaleSpeed = 0.3
        emitter.particleColor = smokeColor.withAlphaComponent(0.5)
        emitter.particleColorBlendFactor = 1
        emitter.particleBlendMode = .alpha
        if let tex = sparkTexture { emitter.particleTexture = tex }
        return emitter
    }

    private static func makeSparkTexture() -> SKTexture {
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
        return SKTexture(image: image)
    }
}

/// SwiftUI wrapper that hosts the SpriteKit `CannonFireScene`.
struct CannonFireEffect: View {
    let muzzlePosition: CGPoint
    let fireAngle: Double
    let flashColor: Color
    let smokeColor: Color
    let size: CGSize
    /// Fraction from top of screen where the ground sits (SwiftUI coords).
    var groundFraction: CGFloat = 0.92

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
            containerSize: size,
            groundFraction: groundFraction
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
