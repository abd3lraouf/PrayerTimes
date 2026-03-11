import SwiftUI

// MARK: - Night Scene (Fajr, Isha, Tahajud)

/// Deep stillness, vast sky, spiritual solitude.
/// Crescent moon with halo, twinkling stars, thin cloud wisps, desert dunes,
/// tree silhouettes, and low-lying mist.
struct NightSceneView: View {
    let size: CGSize
    let appear: Bool

    var body: some View {
        ZStack {
            // Layer 0: Sky gradient
            LinearGradient(
                colors: [
                    Color(red: 0.03, green: 0.04, blue: 0.14),
                    Color(red: 0.07, green: 0.05, blue: 0.22),
                    Color(red: 0.04, green: 0.03, blue: 0.10)
                ],
                startPoint: .top, endPoint: .bottom
            )

            // Layer 1: Desert dunes
            DesertDunes(
                layers: 3,
                colors: [
                    Color(red: 0.05, green: 0.04, blue: 0.12),
                    Color(red: 0.04, green: 0.03, blue: 0.10),
                    Color(red: 0.03, green: 0.02, blue: 0.08)
                ],
                heightFraction: 0.15,
                size: size
            )

            // Layer 2: Tree silhouettes
            TreeSilhouettes(
                count: 5,
                style: .mixed,
                color: Color(red: 0.03, green: 0.02, blue: 0.08),
                opacityRange: 0.06...0.10,
                baseY: size.height * 0.87,
                size: size
            )

            // Layer 3: Mist
            MistLayer(
                color: Color(red: 0.15, green: 0.15, blue: 0.30),
                heightFraction: 0.08,
                opacity: 0.06,
                riseSpeed: 10,
                size: size
            )

            // Layer 4: Stars
            StarsField(
                count: 55,
                sizeRange: 1.0...4.0,
                opacityRange: 0.2...0.8,
                topHeavy: false,
                appear: appear,
                size: size
            )

            // Layer 5: Crescent moon (upper-right area)
            CelestialBody(
                bodyType: .crescent(radius: 20, shadowOffset: 14),
                glowRadius: 50,
                glowColor: Color(red: 0.4, green: 0.4, blue: 0.8),
                position: UnitPoint(x: 0.7, y: 0.15),
                pulseScale: 0.95...1.05,
                size: size
            )

            // Layer 6: Thin cloud wisps
            CloudLayer(
                width: size.width * 0.35,
                height: 8,
                color: Color(red: 0.4, green: 0.4, blue: 0.65),
                opacity: 0.04,
                yPosition: 0.35,
                driftSpeed: 18,
                driftDistance: 30,
                size: size
            )
            CloudLayer(
                width: size.width * 0.25,
                height: 6,
                color: Color(red: 0.4, green: 0.4, blue: 0.65),
                opacity: 0.03,
                yPosition: 0.45,
                driftSpeed: 22,
                driftDistance: 25,
                size: size
            )
        }
        .drawingGroup()
    }
}

// MARK: - Dawn Scene (Sunrise)

/// Awakening, hope, the first light breaking through darkness.
/// Sun half-disc emerging, warm horizon glow, fading stars, pink-orange clouds,
/// light rays, desert dunes, and tree silhouettes.
struct DawnSceneView: View {
    let size: CGSize
    let appear: Bool

    var body: some View {
        ZStack {
            // Layer 0: Sky gradient
            LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.08, blue: 0.22),
                    Color(red: 0.35, green: 0.15, blue: 0.25),
                    Color(red: 0.55, green: 0.25, blue: 0.18),
                    Color(red: 0.82, green: 0.65, blue: 0.25)
                ],
                startPoint: .top, endPoint: .bottom
            )

            // Layer 1: Desert dunes
            DesertDunes(
                layers: 2,
                colors: [
                    Color(red: 0.15, green: 0.08, blue: 0.12),
                    Color(red: 0.10, green: 0.05, blue: 0.08)
                ],
                heightFraction: 0.14,
                size: size
            )

            // Layer 2: Tree silhouettes
            TreeSilhouettes(
                count: 4,
                style: .palm,
                color: Color(red: 0.08, green: 0.04, blue: 0.06),
                opacityRange: 0.08...0.12,
                baseY: size.height * 0.88,
                size: size
            )

            // Layer 3: Horizon glow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.75, blue: 0.35).opacity(0.18),
                            Color(red: 0.9, green: 0.5, blue: 0.25).opacity(0.08),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: size.width * 0.4
                    )
                )
                .frame(width: size.width * 0.8, height: 250)
                .position(x: size.width * 0.5, y: size.height * 0.85)

            // Layer 4: Sun half-disc
            CelestialBody(
                bodyType: .halfDisc(radius: 30),
                glowRadius: 120,
                glowColor: Color(red: 1.0, green: 0.75, blue: 0.35),
                position: UnitPoint(x: 0.5, y: 0.86),
                pulseScale: 0.97...1.03,
                size: size
            )

            // Layer 5: Fading stars
            StarsField(
                count: 18,
                sizeRange: 1.0...2.5,
                opacityRange: 0.1...0.3,
                topHeavy: true,
                appear: appear,
                size: size
            )

            // Layer 6: Warm cloud wisps
            CloudLayer(
                width: size.width * 0.30,
                height: 10,
                color: Color(red: 1.0, green: 0.5, blue: 0.3),
                opacity: 0.06,
                yPosition: 0.30,
                driftSpeed: 16,
                driftDistance: 20,
                size: size
            )
            CloudLayer(
                width: size.width * 0.38,
                height: 12,
                color: Color(red: 1.0, green: 0.45, blue: 0.25),
                opacity: 0.07,
                yPosition: 0.42,
                driftSpeed: 20,
                driftDistance: 25,
                size: size
            )
            CloudLayer(
                width: size.width * 0.25,
                height: 8,
                color: Color(red: 0.9, green: 0.4, blue: 0.3),
                opacity: 0.05,
                yPosition: 0.55,
                driftSpeed: 18,
                driftDistance: 15,
                size: size
            )

            // Layer 7: Light rays
            LightRays(
                count: 5,
                color: Color(red: 1.0, green: 0.8, blue: 0.4),
                length: size.height * 0.35,
                origin: UnitPoint(x: 0.5, y: 0.86),
                rotationSpeed: 30,
                size: size
            )
        }
        .drawingGroup()
    }
}

// MARK: - Day Scene (Dhuhr, Dhuha)

/// Expansive, bright, serene confidence. Midday clarity.
/// Bright sun with rays, scattered high clouds, heat haze, desert dunes,
/// sparse trees, and floating dust particles.
struct DaySceneView: View {
    let size: CGSize
    let appear: Bool

    var body: some View {
        ZStack {
            // Layer 0: Sky gradient
            LinearGradient(
                colors: [
                    Color(red: 0.20, green: 0.45, blue: 0.72),
                    Color(red: 0.35, green: 0.58, blue: 0.80),
                    Color(red: 0.50, green: 0.70, blue: 0.85),
                    Color(red: 0.78, green: 0.88, blue: 0.95)
                ],
                startPoint: .top, endPoint: .bottom
            )

            // Layer 1: Desert dunes (sandy)
            DesertDunes(
                layers: 2,
                colors: [
                    Color(red: 0.70, green: 0.60, blue: 0.40),
                    Color(red: 0.60, green: 0.50, blue: 0.32)
                ],
                heightFraction: 0.12,
                size: size
            )

            // Layer 2: Tree silhouettes (sparse acacia)
            TreeSilhouettes(
                count: 3,
                style: .acacia,
                color: Color(red: 0.30, green: 0.25, blue: 0.15),
                opacityRange: 0.08...0.15,
                baseY: size.height * 0.89,
                size: size
            )

            // Layer 3: Heat haze
            HeatHaze(
                color: Color(red: 0.95, green: 0.90, blue: 0.70),
                yPosition: 0.87,
                size: size
            )

            // Layer 4: Sun disc (centered high)
            CelestialBody(
                bodyType: .sun(radius: 22),
                glowRadius: 150,
                glowColor: Color(red: 1.0, green: 0.95, blue: 0.6),
                position: UnitPoint(x: 0.5, y: 0.20),
                pulseScale: 0.98...1.02,
                size: size
            )

            // Layer 5: Sun rays
            LightRays(
                count: 8,
                color: Color(red: 1.0, green: 0.95, blue: 0.7),
                length: size.height * 0.25,
                origin: UnitPoint(x: 0.5, y: 0.20),
                rotationSpeed: 40,
                size: size
            )

            // Layer 6: High scattered clouds
            CloudLayer(
                width: size.width * 0.28,
                height: 10,
                color: .white,
                opacity: 0.08,
                yPosition: 0.28,
                driftSpeed: 28,
                driftDistance: 20,
                size: size
            )
            CloudLayer(
                width: size.width * 0.22,
                height: 8,
                color: .white,
                opacity: 0.06,
                yPosition: 0.38,
                driftSpeed: 30,
                driftDistance: 18,
                size: size
            )
            CloudLayer(
                width: size.width * 0.18,
                height: 6,
                color: .white,
                opacity: 0.05,
                yPosition: 0.48,
                driftSpeed: 25,
                driftDistance: 15,
                size: size
            )

            // Layer 7: Dust particles
            DustParticles(
                count: 10,
                color: Color(red: 1.0, green: 0.90, blue: 0.55),
                sizeRange: 1.5...3.0,
                riseSpeed: 12,
                size: size
            )
        }
        .drawingGroup()
    }
}

// MARK: - Afternoon Scene (Asr)

/// Golden hour approaching, warm and contemplative, time passing.
/// Lower off-center sun, long stretched clouds, golden mist, prominent dunes,
/// more visible trees, dust particles, and light streaks.
struct AfternoonSceneView: View {
    let size: CGSize
    let appear: Bool

    var body: some View {
        ZStack {
            // Layer 0: Sky gradient
            LinearGradient(
                colors: [
                    Color(red: 0.45, green: 0.50, blue: 0.65),
                    Color(red: 0.55, green: 0.50, blue: 0.45),
                    Color(red: 0.65, green: 0.55, blue: 0.38),
                    Color(red: 0.72, green: 0.58, blue: 0.30)
                ],
                startPoint: .top, endPoint: .bottom
            )

            // Layer 1: Desert dunes (prominent golden)
            DesertDunes(
                layers: 3,
                colors: [
                    Color(red: 0.55, green: 0.45, blue: 0.25),
                    Color(red: 0.48, green: 0.38, blue: 0.20),
                    Color(red: 0.40, green: 0.30, blue: 0.15)
                ],
                heightFraction: 0.18,
                size: size
            )

            // Layer 2: Tree silhouettes (more visible, mixed)
            TreeSilhouettes(
                count: 5,
                style: .mixed,
                color: Color(red: 0.25, green: 0.18, blue: 0.08),
                opacityRange: 0.10...0.18,
                baseY: size.height * 0.84,
                size: size
            )

            // Layer 3: Golden mist
            MistLayer(
                color: Color(red: 0.80, green: 0.65, blue: 0.30),
                heightFraction: 0.10,
                opacity: 0.06,
                riseSpeed: 12,
                size: size
            )

            // Layer 4: Sun disc (lower, off-center right)
            CelestialBody(
                bodyType: .sun(radius: 18),
                glowRadius: 120,
                glowColor: Color(red: 1.0, green: 0.80, blue: 0.40),
                position: UnitPoint(x: 0.72, y: 0.35),
                pulseScale: 0.97...1.03,
                size: size
            )

            // Layer 5: Long stretched clouds
            CloudLayer(
                width: size.width * 0.45,
                height: 10,
                color: Color(red: 1.0, green: 0.80, blue: 0.50),
                opacity: 0.06,
                yPosition: 0.22,
                driftSpeed: 22,
                driftDistance: 25,
                size: size
            )
            CloudLayer(
                width: size.width * 0.40,
                height: 8,
                color: Color(red: 1.0, green: 0.75, blue: 0.45),
                opacity: 0.05,
                yPosition: 0.35,
                driftSpeed: 26,
                driftDistance: 20,
                size: size
            )
            CloudLayer(
                width: size.width * 0.50,
                height: 12,
                color: Color(red: 0.95, green: 0.70, blue: 0.40),
                opacity: 0.05,
                yPosition: 0.48,
                driftSpeed: 20,
                driftDistance: 22,
                size: size
            )

            // Layer 6: Dust particles (more prominent)
            DustParticles(
                count: 14,
                color: Color(red: 1.0, green: 0.85, blue: 0.45),
                sizeRange: 1.5...3.5,
                riseSpeed: 10,
                size: size
            )

            // Layer 7: Light streaks from sun through clouds
            LightRays(
                count: 3,
                color: Color(red: 1.0, green: 0.85, blue: 0.50),
                length: size.height * 0.30,
                origin: UnitPoint(x: 0.72, y: 0.35),
                rotationSpeed: 45,
                size: size
            )
        }
        .drawingGroup()
    }
}

// MARK: - Ramadan Suhoor Scene (Pre-Fajr cannon)

/// Deep pre-dawn sky with the iconic Ramadan cannon firing to announce
/// the end of Suhoor. Dark indigo palette with cannon silhouette on dunes,
/// muzzle flash, smoke, and arcing projectile.
struct SuhoorCannonSceneView: View {
    let size: CGSize
    let appear: Bool

    private let cannonScale: CGFloat = 1.6

    private var cannonBase: CGPoint {
        CGPoint(x: size.width * 0.68, y: size.height * 0.88)
    }

    private var muzzleTip: CGPoint {
        RamadanCannon.muzzleTip(base: cannonBase, scale: cannonScale)
    }

    var body: some View {
        ZStack {
            // Layers 0–7: atmosphere + cannon (rasterised for performance)
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.02, blue: 0.10),
                        Color(red: 0.05, green: 0.04, blue: 0.18),
                        Color(red: 0.08, green: 0.06, blue: 0.22),
                        Color(red: 0.12, green: 0.08, blue: 0.20)
                    ],
                    startPoint: .top, endPoint: .bottom
                )

                DesertDunes(
                    layers: 3,
                    colors: [
                        Color(red: 0.06, green: 0.04, blue: 0.12),
                        Color(red: 0.04, green: 0.03, blue: 0.09),
                        Color(red: 0.03, green: 0.02, blue: 0.06)
                    ],
                    heightFraction: 0.16,
                    size: size
                )

                TreeSilhouettes(
                    count: 4,
                    style: .palm,
                    color: Color(red: 0.03, green: 0.02, blue: 0.06),
                    opacityRange: 0.06...0.12,
                    baseY: size.height * 0.87,
                    size: size
                )

                MistLayer(
                    color: Color(red: 0.12, green: 0.10, blue: 0.25),
                    heightFraction: 0.07,
                    opacity: 0.05,
                    riseSpeed: 12,
                    size: size
                )

                StarsField(
                    count: 50,
                    sizeRange: 1.0...3.5,
                    opacityRange: 0.2...0.75,
                    topHeavy: false,
                    appear: appear,
                    size: size
                )

                CelestialBody(
                    bodyType: .crescent(radius: 18, shadowOffset: 12),
                    glowRadius: 45,
                    glowColor: Color(red: 0.4, green: 0.4, blue: 0.75),
                    position: UnitPoint(x: 0.25, y: 0.12),
                    pulseScale: 0.96...1.04,
                    size: size
                )

                CloudLayer(
                    width: size.width * 0.30, height: 7,
                    color: Color(red: 0.35, green: 0.30, blue: 0.55),
                    opacity: 0.04, yPosition: 0.30,
                    driftSpeed: 20, driftDistance: 25, size: size
                )
                CloudLayer(
                    width: size.width * 0.22, height: 5,
                    color: Color(red: 0.30, green: 0.28, blue: 0.50),
                    opacity: 0.03, yPosition: 0.45,
                    driftSpeed: 24, driftDistance: 20, size: size
                )

                RamadanCannon(
                    color: Color(red: 0.28, green: 0.24, blue: 0.38),
                    highlightColor: Color(red: 0.50, green: 0.46, blue: 0.65),
                    scale: cannonScale, position: cannonBase
                )
            }
            .drawingGroup()

            // Layer 8: SpriteKit cannon fire (own Metal pass)
            CannonFireEffect(
                muzzlePosition: muzzleTip,
                fireAngle: 145,
                flashColor: Color(red: 1.0, green: 0.85, blue: 0.3),
                smokeColor: Color(red: 0.5, green: 0.5, blue: 0.6),
                size: size
            )
        }
    }
}

// MARK: - Ramadan Iftar Scene (Maghrib cannon)

/// Dramatic sunset sky with the Ramadan cannon firing to announce Iftar.
/// Fiery orange-magenta palette, cannon silhouette against the glowing horizon,
/// muzzle flash, smoke, and arcing projectile.
struct IftarCannonSceneView: View {
    let size: CGSize
    let appear: Bool

    private let cannonScale: CGFloat = 1.7

    private var cannonBase: CGPoint {
        CGPoint(x: size.width * 0.35, y: size.height * 0.88)
    }

    private var muzzleTip: CGPoint {
        RamadanCannon.muzzleTip(base: cannonBase, scale: cannonScale)
    }

    var body: some View {
        ZStack {
            // Layers 0–8: atmosphere + cannon (rasterised)
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.04, blue: 0.18),
                        Color(red: 0.25, green: 0.08, blue: 0.22),
                        Color(red: 0.55, green: 0.15, blue: 0.12),
                        Color(red: 0.85, green: 0.40, blue: 0.10),
                        Color(red: 0.95, green: 0.55, blue: 0.15)
                    ],
                    startPoint: .top, endPoint: .bottom
                )

                DesertDunes(
                    layers: 3,
                    colors: [
                        Color(red: 0.10, green: 0.05, blue: 0.10),
                        Color(red: 0.06, green: 0.03, blue: 0.06),
                        Color(red: 0.03, green: 0.02, blue: 0.04)
                    ],
                    heightFraction: 0.15, size: size
                )

                TreeSilhouettes(
                    count: 5, style: .palm,
                    color: Color(red: 0.04, green: 0.02, blue: 0.04),
                    opacityRange: 0.10...0.20,
                    baseY: size.height * 0.86, size: size
                )

                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color(red: 1.0, green: 0.55, blue: 0.15).opacity(0.25),
                                Color(red: 0.95, green: 0.40, blue: 0.12).opacity(0.12),
                                Color(red: 0.80, green: 0.25, blue: 0.10).opacity(0.05),
                                .clear
                            ],
                            center: .center, startRadius: 10,
                            endRadius: size.width * 0.45
                        )
                    )
                    .frame(width: size.width * 0.9, height: 300)
                    .position(x: size.width * 0.5, y: size.height * 0.85)

                CelestialBody(
                    bodyType: .halfDisc(radius: 22), glowRadius: 110,
                    glowColor: Color(red: 1.0, green: 0.50, blue: 0.15),
                    position: UnitPoint(x: 0.55, y: 0.86),
                    pulseScale: 0.96...1.04, size: size
                )

                CloudLayer(
                    width: size.width * 0.50, height: 14,
                    color: Color(red: 0.95, green: 0.40, blue: 0.15),
                    opacity: 0.08, yPosition: 0.25,
                    driftSpeed: 18, driftDistance: 22, size: size
                )
                CloudLayer(
                    width: size.width * 0.42, height: 10,
                    color: Color(red: 1.0, green: 0.50, blue: 0.20),
                    opacity: 0.06, yPosition: 0.38,
                    driftSpeed: 22, driftDistance: 18, size: size
                )
                CloudLayer(
                    width: size.width * 0.55, height: 16,
                    color: Color(red: 0.90, green: 0.35, blue: 0.12),
                    opacity: 0.06, yPosition: 0.50,
                    driftSpeed: 16, driftDistance: 25, size: size
                )

                StarsField(
                    count: 10, sizeRange: 1.0...2.0,
                    opacityRange: 0.12...0.30, topHeavy: true,
                    appear: appear, size: size
                )

                MistLayer(
                    color: Color(red: 0.55, green: 0.22, blue: 0.08),
                    heightFraction: 0.06, opacity: 0.05,
                    riseSpeed: 14, size: size
                )

                RamadanCannon(
                    color: Color(red: 0.30, green: 0.18, blue: 0.14),
                    highlightColor: Color(red: 0.55, green: 0.38, blue: 0.28),
                    scale: cannonScale, position: cannonBase
                )
            }
            .drawingGroup()

            // Layer 9: SpriteKit cannon fire (own Metal pass)
            CannonFireEffect(
                muzzlePosition: muzzleTip,
                fireAngle: 145,
                flashColor: Color(red: 1.0, green: 0.65, blue: 0.2),
                smokeColor: Color(red: 0.6, green: 0.35, blue: 0.15),
                size: size
            )
        }
    }
}

// MARK: - Sunset Scene (Maghrib)

/// Dramatic, the day's last breath, urgency mixed with beauty.
/// Sinking sun at horizon, dramatic layered clouds, early stars,
/// dark dune silhouettes, palm tree silhouettes, horizon fire glow, rising mist.
struct SunsetSceneView: View {
    let size: CGSize
    let appear: Bool

    var body: some View {
        ZStack {
            // Layer 0: Sky gradient
            LinearGradient(
                colors: [
                    Color(red: 0.10, green: 0.06, blue: 0.20),
                    Color(red: 0.30, green: 0.10, blue: 0.25),
                    Color(red: 0.60, green: 0.18, blue: 0.15),
                    Color(red: 0.80, green: 0.35, blue: 0.12),
                    Color(red: 0.85, green: 0.45, blue: 0.15)
                ],
                startPoint: .top, endPoint: .bottom
            )

            // Layer 1: Desert dunes (dark silhouettes)
            DesertDunes(
                layers: 3,
                colors: [
                    Color(red: 0.08, green: 0.04, blue: 0.10),
                    Color(red: 0.05, green: 0.03, blue: 0.07),
                    Color(red: 0.03, green: 0.02, blue: 0.05)
                ],
                heightFraction: 0.15,
                size: size
            )

            // Layer 2: Tree silhouettes (most visible)
            TreeSilhouettes(
                count: 5,
                style: .palm,
                color: Color(red: 0.03, green: 0.02, blue: 0.04),
                opacityRange: 0.12...0.20,
                baseY: size.height * 0.86,
                size: size
            )

            // Layer 3: Horizon fire glow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.50, blue: 0.15).opacity(0.22),
                            Color(red: 0.9, green: 0.35, blue: 0.10).opacity(0.10),
                            Color(red: 0.7, green: 0.20, blue: 0.08).opacity(0.04),
                            .clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: size.width * 0.45
                    )
                )
                .frame(width: size.width * 0.9, height: 280)
                .position(x: size.width * 0.5, y: size.height * 0.85)

            // Layer 4: Setting sun (thin sliver at horizon)
            CelestialBody(
                bodyType: .halfDisc(radius: 18),
                glowRadius: 100,
                glowColor: Color(red: 1.0, green: 0.50, blue: 0.15),
                position: UnitPoint(x: 0.45, y: 0.87),
                pulseScale: 0.96...1.04,
                size: size
            )

            // Layer 5: Dramatic clouds (most substantial, lit from below)
            CloudLayer(
                width: size.width * 0.55,
                height: 14,
                color: Color(red: 0.9, green: 0.35, blue: 0.15),
                opacity: 0.08,
                yPosition: 0.28,
                driftSpeed: 18,
                driftDistance: 22,
                size: size
            )
            CloudLayer(
                width: size.width * 0.45,
                height: 10,
                color: Color(red: 1.0, green: 0.45, blue: 0.20),
                opacity: 0.07,
                yPosition: 0.40,
                driftSpeed: 22,
                driftDistance: 18,
                size: size
            )
            CloudLayer(
                width: size.width * 0.60,
                height: 16,
                color: Color(red: 0.85, green: 0.30, blue: 0.12),
                opacity: 0.06,
                yPosition: 0.52,
                driftSpeed: 16,
                driftDistance: 25,
                size: size
            )
            CloudLayer(
                width: size.width * 0.35,
                height: 8,
                color: Color(red: 1.0, green: 0.55, blue: 0.25),
                opacity: 0.05,
                yPosition: 0.65,
                driftSpeed: 20,
                driftDistance: 15,
                size: size
            )

            // Layer 6: Early stars (upper sky)
            StarsField(
                count: 12,
                sizeRange: 1.0...2.5,
                opacityRange: 0.15...0.35,
                topHeavy: true,
                appear: appear,
                size: size
            )

            // Layer 7: Rising mist
            MistLayer(
                color: Color(red: 0.60, green: 0.25, blue: 0.10),
                heightFraction: 0.06,
                opacity: 0.05,
                riseSpeed: 14,
                size: size
            )
        }
        .drawingGroup()
    }
}
