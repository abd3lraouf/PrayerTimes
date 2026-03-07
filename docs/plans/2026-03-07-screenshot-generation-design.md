# Screenshot Generation System Design

## Goal

Generate per-language marketing collage images showcasing the app's 4 main views, for all 5 supported languages (en, ar, id, fa, ur). Run locally on demand when the UI changes.

## Screenshot Capture

A UI test class `ScreenshotGenerator` in `PrayerTimesUITests/` that:

- Iterates over all 5 languages by setting app launch arguments to override locale
- Navigates to 4 views and captures each:
  1. **Main popover** — prayer times list with countdown
  2. **Settings** — display settings view
  3. **Notifications** — notification settings view
  4. **About** — about screen
- Saves raw PNGs to `screenshots/raw/{lang}/{view}.png`

Run with: `xcodebuild test -only-testing:PrayerTimesUITests/ScreenshotGenerator`

## Collage Composition

A Swift script at `scripts/generate-screenshots.swift` using AppKit/CoreGraphics.

### Input

`screenshots/raw/{lang}/` folders, each containing 4 view PNGs (`main.png`, `settings.png`, `notifications.png`, `about.png`).

### Output

`screenshots/output/{lang}.png` — one collage image per language.

### Layout

Inspired by App Store marketing materials (see reference: Brex-style vertical cards):

- 4 vertical cards side by side with ~20px gaps
- Each card: dark rounded rectangle with frosted/blurred background gradient (dark navy to teal)
- Alternating vertical offset — cards 1 & 3 shifted up, cards 2 & 4 shifted down (staggered rhythm)
- Screenshot with rounded corners and drop shadow in the lower portion of each card
- Localized tagline in bold white text in the top free space
- Text right-aligned for RTL languages (ar, fa, ur), left-aligned for LTR (en, id)

### Final image dimensions

~2400×1200px (4 cards of ~560×1100 each with spacing).

### Taglines

| View | en | ar | id | fa | ur |
|------|----|----|----|----|-----|
| Main | Every prayer, right on time. | كل صلاة، في وقتها. | Setiap shalat, tepat waktu. | هر نماز، درست به موقع. | ہر نماز، بالکل وقت پر. |
| Settings | Your prayers, your way. | صلاتك، بطريقتك. | Shalat Anda, cara Anda. | نمازهای شما، به روش شما. | آپ کی نماز، آپ کے انداز میں. |
| Notifications | A gentle reminder before every prayer. | تذكير لطيف قبل كل صلاة. | Pengingat lembut sebelum setiap shalat. | یادآوری آرام پیش از هر نماز. | ہر نماز سے پہلے ایک نرم یاد دہانی. |
| About | Made with love for the Ummah. | صُنع بحب للأمة. | Dibuat dengan cinta untuk Ummah. | ساخته شده با عشق برای امت. | امت کے لیے محبت سے بنایا گیا. |

## File Structure

```
scripts/
  generate-screenshots.swift

screenshots/
  raw/
    en/  (main.png, settings.png, notifications.png, about.png)
    ar/
    id/
    fa/
    ur/
  output/
    en.png
    ar.png
    id.png
    fa.png
    ur.png

PrayerTimesUITests/
  ScreenshotGenerator.swift
```

## Workflow

1. Run UI tests to recapture raw screenshots
2. Run `swift scripts/generate-screenshots.swift` to regenerate collages
3. Commit updated images

## README Update

Replace the single screenshot with per-language collage images. Update supported languages line to include Persian and Urdu.
