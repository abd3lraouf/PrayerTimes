# Full-Screen Prayer Notification Themes — Design Spec

## Overview

Rework the full-screen notification backgrounds to create distinct, immersive atmospheric scenes for each prayer time. Each scene simulates the time of day using layered SwiftUI shapes with rich ambient animations. No image assets — everything is procedurally drawn.

**Art direction:** Atmospheric Layered — soft celestial objects, layered clouds, subtle mist, glowing horizons. Everything blends. Dreamy and meditative.

**Animation style:** Rich motion — stars twinkle, clouds drift, sun rays rotate, mist rises, dust particles float, horizon glow breathes.

---

## Architecture

### File Structure

All scene code lives in `FullScreenNotificationView.swift`. The current `backgroundView(geo:)` method and `StarsView` struct will be replaced with a richer system:

```
PrayerTheme (enum)           — unchanged mapping, adds new properties
├── SceneView (new)          — dispatches to per-theme scene
├── NightSceneView           — Fajr / Isha / Tahajud
├── DawnSceneView            — Sunrise
├── DaySceneView             — Dhuhr / Dhuha
├── AfternoonSceneView       — Asr
├── SunsetSceneView          — Maghrib
└── Shared element views:
    ├── StarsField            — replaces current StarsView, more stars, varied sizes
    ├── CloudLayer            — reusable drifting cloud wisps
    ├── CelestialBody         — sun/moon disc with configurable glow
    ├── MistLayer             — rising mist at ground level
    ├── DustParticles         — floating golden particles
    ├── DesertDunes           — soft rolling dune silhouettes at bottom
    └── TreeSilhouettes       — soft blurred tree shapes at horizon
```

### PrayerTheme Extensions

Changes to existing enum:
- Remove `showStars` (replaced by scene-level composition)
- Keep `gradientColors`, `glowColor`, `iconName`, `cardFill` unchanged
- Theme-to-scene dispatch handled via `switch` in `backgroundView`, no new properties needed

---

## Scene Definitions

### 1. Night — Fajr, Isha, Tahajud

**Mood:** Deep stillness, vast sky, spiritual solitude.

**Layers (bottom to top):**

| Layer | Element | Details |
|-------|---------|---------|
| 0 | Sky gradient | Deep indigo → dark purple → near-black |
| 1 | Desert dunes | 2-3 overlapping soft dune curves at bottom 15% of screen, very dark purple-blue, subtle opacity variations between layers |
| 2 | Tree silhouettes | 3-5 soft blurred palm/cypress shapes along dune line, dark, barely visible (opacity 0.06-0.1) |
| 3 | Mist layer | Low-lying mist hugging the dunes, slowly rising and fading |
| 4 | Stars field | 50+ stars, varied sizes (1-4pt), twinkling at different rates. Denser near zenith, sparse near horizon |
| 5 | Crescent moon | Off-center (upper-left or upper-right), created via overlapping circles. Soft halo glow around it (radial gradient) |
| 6 | Thin cloud wisps | 2-3 very subtle elongated shapes drifting slowly across mid-sky |

**Animations:**
- Stars: opacity oscillates (0.2-0.8) with randomized periods (2-5s), staggered delays
- Moon halo: gentle pulse (scale 0.95-1.05, 4s period)
- Clouds: drift horizontally 20-40px over 15-20s, loop
- Mist: slow upward drift with opacity fade (0.03-0.06), 10s cycle

---

### 2. Dawn — Sunrise

**Mood:** Awakening, hope, the first light breaking through darkness.

**Layers (bottom to top):**

| Layer | Element | Details |
|-------|---------|---------|
| 0 | Sky gradient | Dark purple top → warm magenta → burnt orange → golden yellow at bottom |
| 1 | Desert dunes | Warmer tones than night, silhouetted against the dawn glow, 2-3 layers |
| 2 | Tree silhouettes | Palm trees and shrubs along dune line, slightly more visible than night (opacity 0.08-0.12) |
| 3 | Horizon glow | Wide elliptical radial gradient at bottom center, warm golden-orange |
| 4 | Sun half-disc | Semi-circle emerging from behind the dunes, warm white-yellow with radial glow |
| 5 | Fading stars | 15-20 stars, dimmer than night (opacity 0.1-0.3), concentrated in upper portion |
| 6 | Warm cloud wisps | 3-4 clouds tinted pink-orange, more substantial than night clouds |
| 7 | Light rays | 3-5 subtle radial lines emanating upward from sun position, very low opacity |

**Animations:**
- Sun glow: slow pulse (3s, subtle scale)
- Light rays: slow rotation (360° over 30s)
- Clouds: drift with slight vertical oscillation
- Stars: slowly fading out (opacity decreasing over time)
- Mist: absent (morning clarity)

---

### 3. Day — Dhuhr, Dhuha

**Mood:** Expansive, bright, serene confidence. Midday clarity.

**Layers (bottom to top):**

| Layer | Element | Details |
|-------|---------|---------|
| 0 | Sky gradient | Medium blue top → lighter blue → pale blue-white near bottom |
| 1 | Desert dunes | Sandy-colored dunes at bottom 12%, warm beige-gold tones, 2 layers |
| 2 | Tree silhouettes | Sparse acacia-like shapes on dunes, warm dark tone (opacity 0.08-0.15) |
| 3 | Heat haze | Subtle wavering band just above dune line (opacity shimmer) |
| 4 | Sun disc | Centered high (upper 20%), bright with large soft radial glow |
| 5 | Sun rays | 6-8 thin lines radiating outward from sun, very subtle |
| 6 | High clouds | 3-4 thin cirrus-style clouds scattered across upper-mid sky, white with low opacity |
| 7 | Dust particles | 8-12 tiny golden specks floating slowly upward across the scene |

**Animations:**
- Sun rays: slow rotation (360° over 40s)
- Sun glow: gentle breathe (scale 0.98-1.02, 5s)
- Clouds: very slow drift (25-30s cycle)
- Dust particles: float upward with slight lateral sway, loop when reaching top
- Heat haze: opacity oscillation (0.02-0.06, 3s)

---

### 4. Afternoon — Asr

**Mood:** Golden hour approaching, warm and contemplative, time passing.

**Layers (bottom to top):**

| Layer | Element | Details |
|-------|---------|---------|
| 0 | Sky gradient | Muted blue-grey top → warm amber → golden-brown at bottom |
| 1 | Desert dunes | Prominent warm golden dunes at bottom 18%, 3 layers with depth via opacity |
| 2 | Tree silhouettes | More visible (opacity 0.1-0.18), casting "long shadow" feel. Mix of palms and broad trees |
| 3 | Golden mist | Low warm-toned haze above dunes |
| 4 | Sun disc | Positioned lower and off-center (right side, 35% from top), warm amber glow, smaller than midday |
| 5 | Long clouds | 3-5 stretched horizontal clouds, longer than other themes, warm-tinted |
| 6 | Dust particles | 10-15 golden particles, more prominent than day, floating upward |
| 7 | Light streaks | 2-3 diagonal light beams from sun through clouds, very subtle |

**Animations:**
- Sun glow: gentle pulse (4s)
- Clouds: slow drift
- Dust particles: float upward, more visible with golden tint
- Mist: slow lateral drift
- Light streaks: slow opacity breathe (6s)

---

### 5. Sunset — Maghrib

**Mood:** Dramatic, the day's last breath, urgency mixed with beauty.

**Layers (bottom to top):**

| Layer | Element | Details |
|-------|---------|---------|
| 0 | Sky gradient | Dark purple-blue top → deep magenta → fiery orange-red → warm orange at horizon |
| 1 | Desert dunes | Dark silhouetted dunes at bottom 15%, 2-3 layers, near-black against the glow |
| 2 | Tree silhouettes | Dark palm silhouettes against the fire sky, most visible of all themes (opacity 0.12-0.2) |
| 3 | Horizon fire glow | Intense wide elliptical glow at bottom, orange-red |
| 4 | Setting sun | Thin sliver/arc barely visible at horizon line, sinking behind dunes |
| 5 | Dramatic clouds | 4-6 layered clouds, most substantial of all themes, lit from below with warm colors |
| 6 | Early stars | 10-15 stars appearing in upper portion, faint (opacity 0.15-0.35) |
| 7 | Rising mist | Thin mist rising from the warm ground |

**Animations:**
- Horizon glow: slow pulse (5s)
- Clouds: drift, lit edges flicker subtly
- Stars: slowly brightening (opacity increasing)
- Mist: rising slowly
- Sun sliver: very slow descent (subtle position change over 20s)

---

## Shared Element Specifications

### StarsField

Replaces current `StarsView`. Parameters:
- `count: Int` (15-60 depending on theme)
- `sizeRange: ClosedRange<CGFloat>` (1.0...4.0)
- `opacityRange: ClosedRange<Double>` (varies per theme)
- `distribution`: `.uniform` or `.topHeavy` (denser near top of screen)

Each star: random position, size, twinkle period (2-5s), twinkle delay (0-4s). Uses `Circle` with `.fill(.white)`.

### CloudLayer

Reusable drifting cloud. Parameters:
- `width: CGFloat`, `height: CGFloat`
- `color: Color` (tinted per theme)
- `opacity: Double`
- `yPosition: CGFloat` (fraction of screen height)
- `driftSpeed: Double` (seconds for full drift cycle)
- `driftDistance: CGFloat` (points to travel horizontally)

Implementation: `RoundedRectangle` or `Capsule` with gradient fill (transparent edges, colored center). Animated with `offset(x:)` using repeating animation.

### CelestialBody

Sun or moon disc. Parameters:
- `bodyType`: `.sun(radius:)` or `.crescent(radius:shadowOffset:)` or `.halfDisc(radius:)`
- `glowRadius: CGFloat`
- `glowColor: Color`
- `position: UnitPoint` (relative to screen)
- `pulseScale: ClosedRange<CGFloat>` (e.g., 0.95...1.05)

Moon: two overlapping circles (bright + dark offset = crescent). Sun: filled circle with radial gradient glow. Half-disc: clipped circle for sunrise/sunset.

### MistLayer

Low-lying fog. Parameters:
- `color: Color`
- `height: CGFloat` (fraction of screen)
- `opacity: Double`
- `riseSpeed: Double`

Implementation: multiple overlapping ellipses at bottom of screen with slow upward drift animation, fading as they rise.

### DustParticles

Floating golden specks. Parameters:
- `count: Int` (8-15)
- `color: Color`
- `sizeRange: ClosedRange<CGFloat>` (1.5...3.5)
- `riseSpeed: Double`

Each particle: random x-position, starts at random y, drifts upward with slight horizontal sway. Resets to bottom when reaching top. Uses `Circle`.

### DesertDunes

Rolling sand dune silhouettes at screen bottom. Parameters:
- `layers: Int` (2-3)
- `colors: [Color]` (one per layer, back to front)
- `height: CGFloat` (fraction of screen, 0.12-0.18)

Implementation: each layer is a `Path` drawing a smooth sine-like curve across the screen bottom. Front layers are darker/more opaque, back layers are lighter. Uses `addCurve(to:control1:control2:)` for organic curves.

### TreeSilhouettes

Soft tree shapes along the dune line. Parameters:
- `count: Int` (3-6)
- `style`: `.palm` or `.cypress` or `.acacia` or `.mixed`
- `color: Color`
- `opacityRange: ClosedRange<Double>`

Implementation: each tree is a combination of `Capsule` (trunk) and `Ellipse`/`Path` (canopy). Palm = thin trunk + offset ellipse top. Acacia = short trunk + wide flat ellipse. Positioned along the dune curve with slight random offsets.

---

## Integration

### backgroundView Replacement

The current `backgroundView(geo:)` method in `FullScreenNotificationView` gets replaced with a single dispatch:

```swift
@ViewBuilder
private func backgroundView(geo: GeometryProxy) -> some View {
    switch theme {
    case .night:     NightSceneView(size: geo.size, appear: appear)
    case .dawn:      DawnSceneView(size: geo.size, appear: appear)
    case .day:       DaySceneView(size: geo.size, appear: appear)
    case .afternoon: AfternoonSceneView(size: geo.size, appear: appear)
    case .sunset:    SunsetSceneView(size: geo.size, appear: appear)
    }
}
```

Each scene view composes shared elements with theme-specific parameters.

### Performance

- All elements use basic SwiftUI shapes (`Circle`, `Capsule`, `Path`, `Ellipse`)
- Animations use `withAnimation(.easeInOut(...).repeatForever(...))` — GPU-accelerated
- Total animated elements per scene: ~70-90 (stars + clouds + particles + celestial)
- No `Canvas` or custom drawing needed
- `drawingGroup()` modifier on the scene container for Metal-backed rendering if needed

### Removal

Delete from current code:
- `StarsView` struct (replaced by `StarsField`)
- `backgroundView` method body (replaced by scene dispatch)
- `showStars` property on `PrayerTheme` (no longer needed)
- `VisualEffectBlurView` (unused)

---

## Decisions Made

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Art direction | Atmospheric Layered | Dreamy, meditative, everything blends — fits prayer context |
| Scene variation | Distinct per prayer | Each prayer time has a unique atmosphere worth capturing |
| Animation | Rich motion | Stars twinkle, clouds drift, rays rotate, mist rises, particles float |
| Environmental elements | Desert landscape | Dunes, palm/acacia trees, dust — evocative and universal Islamic aesthetic |
| Implementation | SwiftUI shapes only | No asset dependencies, resolution-independent, animatable |
