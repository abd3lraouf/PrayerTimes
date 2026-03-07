#!/usr/bin/env python3
"""Marketing image generator for PrayerTimes Pro.

Generates per-language collage (screenshots.png) and logo (logo.png) images
from raw screenshots captured by UI tests.

Usage:
    python3 scripts/generate-screenshots.py                        # reads from default temp dir
    python3 scripts/generate-screenshots.py --raw-dir /path/to/raw # reads from custom dir

Output structure (at project root):
    en/screenshots.png
    en/logo.png
    ar/screenshots.png
    ar/logo.png
    ...
"""

import argparse
import os
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

# ─── Configuration ───────────────────────────────────────────────────────────

LANGUAGES = ["en", "ar", "id", "fa", "ur"]
VIEWS = ["main", "settings", "notifications", "about"]
RTL_LANGUAGES = {"ar", "fa", "ur"}

# Card dimensions
CARD_WIDTH = 560
CARD_CORNER_RADIUS = 24
CARD_SPACING = 20
VERTICAL_OFFSET = 60

# Screenshot inside card
SCREENSHOT_INSET = 24
SCREENSHOT_TOP_PADDING = 24
SCREENSHOT_BOTTOM_PADDING = 24
SCREENSHOT_CORNER_RADIUS = 16

# Tagline row (between header and cards)
TAGLINE_GAP = 30
TAGLINE_ROW_HEIGHTS = {"en": 180, "id": 140, "ar": 220, "fa": 160, "ur": 260}

# Layout
CANVAS_PADDING = 50
HEADER_HEIGHT = 300
SUBTITLE_GAP = 16
HEADER_ICON_SIZE = 120
HEADER_ICON_CORNER_RADIUS = 28
HEADER_SPACING = 28

# Shadow
SHADOW_RADIUS = 20
SHADOW_OFFSET = (0, 10)

# Colors
BG_COLOR = (8, 8, 13)
CARD_GRADIENT_TOP = (15, 20, 36)
CARD_GRADIENT_BOTTOM = (5, 26, 38)
SUBTITLE_COLOR = (140, 166, 204)
WHITE = (255, 255, 255)

# ─── Font paths ──────────────────────────────────────────────────────────────

USER_FONTS = os.path.expanduser("~/Library/Fonts")
SYS_FONTS = "/System/Library/Fonts/Supplemental"

FONT_PATHS = {
    "syne": os.path.join(USER_FONTS, "Syne[wght].ttf"),
    "jakarta": os.path.join(USER_FONTS, "PlusJakartaSans-ExtraBold.ttf"),
    "jakarta_semi": os.path.join(USER_FONTS, "PlusJakartaSans-SemiBold.ttf"),
    "naskh": os.path.join(SYS_FONTS, "DecoTypeNaskh.ttc"),
    "vazirmatn": os.path.join(USER_FONTS, "Vazirmatn[wght].ttf"),
    "nastaliq": os.path.join(USER_FONTS, "NotoNastaliqUrdu[wght].ttf"),
    "gulzar": os.path.join(USER_FONTS, "Gulzar-Regular.ttf"),
}

HEADER_FONTS = {
    "en": ("syne", 64, "ExtraBold"),
    "id": ("jakarta", 64, None),
    "ar": ("naskh", 68, None),
    "fa": ("vazirmatn", 64, "Bold"),
    "ur": ("nastaliq", 64, "Bold"),
}

TAGLINE_FONTS = {
    "en": ("syne", 44, "ExtraBold"),
    "id": ("jakarta", 44, None),
    "ar": ("naskh", 56, None),
    "fa": ("vazirmatn", 44, "Bold"),
    "ur": ("nastaliq", 44, "Bold"),
}

SUBTITLE_FONTS = {
    "en": ("syne", 28, "Bold"),
    "id": ("jakarta_semi", 28, None),
    "ar": ("naskh", 32, None),
    "fa": ("vazirmatn", 28, "SemiBold"),
    "ur": ("gulzar", 28, None),
}

# ─── Content ─────────────────────────────────────────────────────────────────

TAGLINES = {
    "en": {
        "main": "Every prayer,\nright on time.",
        "settings": "Your prayers,\nyour way.",
        "notifications": "Never miss\na prayer.",
        "about": "Made with love\nfor the Ummah.",
    },
    "ar": {
        "main": "كل صلاة،\nفي وقتها.",
        "settings": "صلاتك،\nبطريقتك.",
        "notifications": "تذكير لطيف\nقبل كل صلاة.",
        "about": "صُنع بحب\nللأمة.",
    },
    "id": {
        "main": "Setiap shalat,\ntepat waktu.",
        "settings": "Shalat Anda,\ncara Anda.",
        "notifications": "Pengingat lembut\nsebelum setiap shalat.",
        "about": "Dibuat dengan cinta\nuntuk Ummah.",
    },
    "fa": {
        "main": "هر نماز،\nدرست به موقع.",
        "settings": "نمازهای شما،\nبه روش شما.",
        "notifications": "یادآوری آرام\nپیش از هر نماز.",
        "about": "ساخته شده با عشق\nبرای امت.",
    },
    "ur": {
        "main": "ہر نماز،\nبالکل وقت پر۔",
        "settings": "آپ کی نماز،\nآپ کے انداز میں۔",
        "notifications": "ہر نماز سے پہلے\nایک نرم یاد دہانی۔",
        "about": "امت کے لیے\nمحبت سے بنایا گیا۔",
    },
}

APP_NAMES = {
    "en": "PrayerTimes Pro",
    "ar": "أوقات الصلاة برو",
    "id": "PrayerTimes Pro",
    "fa": "اوقات نماز پرو",
    "ur": "نماز کے اوقات پرو",
}

SUBTITLES = {
    "en": "Your daily prayer companion for macOS",
    "ar": "رفيقك اليومي للصلاة على ماك",
    "id": "Teman shalat harian Anda untuk macOS",
    "fa": "همراه نماز روزانه شما برای مک",
    "ur": "macOS کے لیے آپ کا روزانہ نماز ساتھی",
}

# ─── Globals set at runtime ──────────────────────────────────────────────────

PROJECT_ROOT = Path(__file__).resolve().parent.parent
RAW_DIR: Path = Path()  # set by main()


# ─── Helpers ─────────────────────────────────────────────────────────────────

def load_font(key: str, size: int, variation: str | None = None) -> ImageFont.FreeTypeFont:
    path = FONT_PATHS[key]
    font = ImageFont.truetype(path, size, index=0)
    if variation:
        font.set_variation_by_name(variation)
    return font


def get_font(config: dict, lang: str) -> ImageFont.FreeTypeFont:
    key, size, variation = config[lang]
    return load_font(key, size, variation)


def text_direction(lang: str) -> str:
    return "rtl" if lang in RTL_LANGUAGES else "ltr"


def load_screenshot(lang: str, view: str) -> Image.Image | None:
    path = RAW_DIR / lang / f"{view}.png"
    if path.exists():
        return Image.open(path).convert("RGBA")
    return None


def card_height_for_screenshot(screenshot: Image.Image) -> int:
    ss_width = CARD_WIDTH - SCREENSHOT_INSET * 2
    scaled_h = int(ss_width * screenshot.height / screenshot.width)
    return SCREENSHOT_TOP_PADDING + scaled_h + SCREENSHOT_BOTTOM_PADDING


def compute_max_card_height() -> int:
    max_h = 0
    for lang in LANGUAGES:
        for view in VIEWS:
            img = load_screenshot(lang, view)
            if img:
                max_h = max(max_h, card_height_for_screenshot(img))
    return max_h


def make_gradient(width: int, height: int, top_color: tuple, bottom_color: tuple) -> Image.Image:
    img = Image.new("RGBA", (width, height))
    for y in range(height):
        t = y / max(height - 1, 1)
        r = int(top_color[0] + (bottom_color[0] - top_color[0]) * t)
        g = int(top_color[1] + (bottom_color[1] - top_color[1]) * t)
        b = int(top_color[2] + (bottom_color[2] - top_color[2]) * t)
        for x in range(width):
            img.putpixel((x, y), (r, g, b, 255))
    return img


def make_rounded_mask(width: int, height: int, radius: int) -> Image.Image:
    mask = Image.new("L", (width, height), 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle([(0, 0), (width - 1, height - 1)], radius, fill=255)
    return mask


def paste_rounded(canvas: Image.Image, img: Image.Image, pos: tuple, radius: int):
    mask = make_rounded_mask(img.width, img.height, radius)
    canvas.paste(img, pos, mask)


def add_shadow(canvas: Image.Image, rect: tuple, radius: int, blur: int, offset: tuple, opacity: int = 128):
    x, y, w, h = rect
    shadow = Image.new("RGBA", (canvas.width, canvas.height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow)
    draw.rounded_rectangle(
        [(x + offset[0], y + offset[1]), (x + w + offset[0] - 1, y + h + offset[1] - 1)],
        radius, fill=(0, 0, 0, opacity),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(blur))
    canvas.paste(Image.alpha_composite(Image.new("RGBA", canvas.size, (0, 0, 0, 0)), shadow), (0, 0), shadow)


def measure_text(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.FreeTypeFont, lang: str) -> tuple:
    bbox = draw.multiline_textbbox((0, 0), text, font=font, anchor="la",
                                   align="center", direction=text_direction(lang))
    return bbox[2] - bbox[0], bbox[3] - bbox[1]


def load_icon() -> Image.Image:
    icon_path = PROJECT_ROOT / "PrayerTimes" / "Assets.xcassets" / "AppIcon.appiconset" / "512.png"
    if not icon_path.exists():
        print(f"ERROR: App icon not found at {icon_path}")
        sys.exit(1)
    return Image.open(icon_path).convert("RGBA")


# ─── Drawing ─────────────────────────────────────────────────────────────────

def draw_card(canvas: Image.Image, x: int, y: int, screenshot: Image.Image):
    ss_width = CARD_WIDTH - SCREENSHOT_INSET * 2
    ss_height = int(ss_width * screenshot.height / screenshot.width)
    card_height = SCREENSHOT_TOP_PADDING + ss_height + SCREENSHOT_BOTTOM_PADDING

    card_bg = make_gradient(CARD_WIDTH, card_height, CARD_GRADIENT_TOP, CARD_GRADIENT_BOTTOM)
    paste_rounded(canvas, card_bg, (x, y), CARD_CORNER_RADIUS)

    ss_resized = screenshot.resize((ss_width, ss_height), Image.LANCZOS)
    ss_x = x + SCREENSHOT_INSET
    ss_y = y + SCREENSHOT_TOP_PADDING

    add_shadow(canvas, (ss_x, ss_y, ss_width, ss_height), SCREENSHOT_CORNER_RADIUS, SHADOW_RADIUS, SHADOW_OFFSET)
    paste_rounded(canvas, ss_resized, (ss_x, ss_y), SCREENSHOT_CORNER_RADIUS)


def draw_rounded_icon(canvas: Image.Image, icon: Image.Image, x: int, y: int, size: int, radius: int):
    icon_resized = icon.resize((size, size), Image.LANCZOS)
    add_shadow(canvas, (x, y, size, size), radius, 12, (0, 6), opacity=100)
    paste_rounded(canvas, icon_resized, (x, y), radius)


def draw_header(canvas: Image.Image, lang: str, icon: Image.Image):
    draw = ImageDraw.Draw(canvas)

    title_font = get_font(HEADER_FONTS, lang)
    sub_font = get_font(SUBTITLE_FONTS, lang)
    title_w, title_h = measure_text(draw, APP_NAMES[lang], title_font, lang)
    sub_w, sub_h = measure_text(draw, SUBTITLES[lang], sub_font, lang)

    icon_size = HEADER_ICON_SIZE
    total_row_width = icon_size + HEADER_SPACING + title_w
    icon_row_height = max(icon_size, title_h)
    total_content_h = icon_row_height + SUBTITLE_GAP + sub_h

    content_top = CANVAS_PADDING + (HEADER_HEIGHT - total_content_h) // 2
    icon_row_center_y = content_top + icon_row_height // 2
    group_center_x = canvas.width // 2
    group_left_x = group_center_x - total_row_width // 2

    rtl = lang in RTL_LANGUAGES
    if rtl:
        text_x = group_left_x
        icon_x = group_left_x + title_w + HEADER_SPACING
    else:
        icon_x = group_left_x
        text_x = group_left_x + icon_size + HEADER_SPACING

    draw_rounded_icon(canvas, icon, icon_x, icon_row_center_y - icon_size // 2,
                      icon_size, HEADER_ICON_CORNER_RADIUS)

    direction = text_direction(lang)
    draw.multiline_text((text_x, icon_row_center_y - title_h // 2), APP_NAMES[lang],
                        font=title_font, fill=WHITE, align="center", direction=direction)

    sub_y = content_top + icon_row_height + SUBTITLE_GAP
    draw.multiline_text((group_center_x - sub_w // 2, sub_y), SUBTITLES[lang],
                        font=sub_font, fill=SUBTITLE_COLOR, align="center", direction=direction)


def draw_tagline_row(canvas: Image.Image, lang: str, cards_top_y: int, row_height: int):
    draw = ImageDraw.Draw(canvas)
    font = get_font(TAGLINE_FONTS, lang)
    tagline_y = cards_top_y - TAGLINE_GAP - row_height
    direction = text_direction(lang)

    for i, view in enumerate(VIEWS):
        tagline = TAGLINES[lang].get(view, "")
        center_x = CANVAS_PADDING + i * (CARD_WIDTH + CARD_SPACING) + CARD_WIDTH // 2

        bbox = draw.multiline_textbbox((0, 0), tagline, font=font, anchor="la",
                                       align="center", direction=direction)
        text_w = bbox[2] - bbox[0]
        text_h = bbox[3] - bbox[1]

        draw.multiline_text((center_x - text_w // 2, tagline_y + (row_height - text_h) // 2),
                            tagline, font=font, fill=WHITE, align="center", direction=direction)


# ─── Generators ──────────────────────────────────────────────────────────────

def generate_collage(lang: str, max_card_height: int, icon: Image.Image) -> Path | None:
    screenshots = []
    for view in VIEWS:
        img = load_screenshot(lang, view)
        if img is None:
            print(f"  WARNING: Missing {lang}/{view}.png, skipping language")
            return None
        screenshots.append((view, img))

    total_cards_width = CARD_WIDTH * len(VIEWS) + CARD_SPACING * (len(VIEWS) - 1)
    canvas_width = total_cards_width + CANVAS_PADDING * 2
    cards_area_height = max_card_height + VERTICAL_OFFSET
    header_gap = 40
    max_tagline_row_height = max(TAGLINE_ROW_HEIGHTS.values())

    canvas_height = (CANVAS_PADDING * 2 + HEADER_HEIGHT + header_gap
                     + max_tagline_row_height + TAGLINE_GAP + cards_area_height)

    canvas = Image.new("RGBA", (canvas_width, canvas_height), (*BG_COLOR, 255))
    draw_header(canvas, lang, icon)

    cards_top_y = canvas_height - CANVAS_PADDING - cards_area_height
    draw_tagline_row(canvas, lang, cards_top_y, TAGLINE_ROW_HEIGHTS.get(lang, 140))

    for i, (view, screenshot) in enumerate(screenshots):
        x = CANVAS_PADDING + i * (CARD_WIDTH + CARD_SPACING)
        y = cards_top_y + (VERTICAL_OFFSET if i % 2 else 0)
        draw_card(canvas, x, y, screenshot)

    output_dir = PROJECT_ROOT / "art" / lang
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / "screenshots.png"
    canvas.convert("RGB").save(output_path, "PNG")
    return output_path


def generate_logo(lang: str, icon: Image.Image) -> Path:
    icon_size = 128
    icon_radius = 28
    spacing = 28
    h_pad = 60
    v_pad = 40

    font = get_font(HEADER_FONTS, lang)
    direction = text_direction(lang)
    tmp_draw = ImageDraw.Draw(Image.new("RGBA", (1, 1)))
    title_w, title_h = measure_text(tmp_draw, APP_NAMES[lang], font, lang)

    content_width = icon_size + spacing + title_w
    content_height = max(icon_size, title_h)
    canvas_width = content_width + h_pad * 2
    canvas_height = content_height + v_pad * 2

    canvas = make_gradient(canvas_width, canvas_height, (15, 20, 36), (10, 26, 41))
    mask = make_rounded_mask(canvas_width, canvas_height, 24)
    bg = Image.new("RGBA", (canvas_width, canvas_height), (0, 0, 0, 0))
    bg.paste(canvas, (0, 0), mask)
    canvas = bg

    center_y = canvas_height // 2
    rtl = lang in RTL_LANGUAGES
    if rtl:
        text_x = h_pad
        icon_x = h_pad + title_w + spacing
    else:
        icon_x = h_pad
        text_x = h_pad + icon_size + spacing

    draw_rounded_icon(canvas, icon, icon_x, center_y - icon_size // 2, icon_size, icon_radius)

    draw = ImageDraw.Draw(canvas)
    draw.multiline_text((text_x, center_y - title_h // 2), APP_NAMES[lang],
                        font=font, fill=WHITE, align="center", direction=direction)

    output_dir = PROJECT_ROOT / "art" / lang
    output_dir.mkdir(parents=True, exist_ok=True)
    output_path = output_dir / "logo.png"
    canvas.save(output_path, "PNG")
    return output_path


# ─── Main ────────────────────────────────────────────────────────────────────

def find_raw_dir() -> Path:
    """Find raw screenshots in .raw/ at project root."""
    return PROJECT_ROOT / ".raw"


def main():
    global RAW_DIR

    parser = argparse.ArgumentParser(description="Generate marketing images for PrayerTimes Pro")
    parser.add_argument("--raw-dir", type=Path, default=None,
                        help="Directory containing raw screenshots ({lang}/{view}.png)")
    args = parser.parse_args()

    RAW_DIR = args.raw_dir if args.raw_dir else find_raw_dir()

    print("PrayerTimes Pro — Marketing Image Generator")
    print("=" * 45)
    print(f"Project root:    {PROJECT_ROOT}")
    print(f"Raw screenshots: {RAW_DIR}")
    print()

    if not RAW_DIR.is_dir():
        print(f"ERROR: Raw screenshot directory not found: {RAW_DIR}")
        print("Run UI tests first, or pass --raw-dir explicitly.")
        sys.exit(1)

    icon = load_icon()
    max_card_height = compute_max_card_height()
    print(f"Max card height: {max_card_height}px\n")

    for lang in LANGUAGES:
        print(f"[{lang}]")
        collage = generate_collage(lang, max_card_height, icon)
        if collage:
            print(f"  {collage.relative_to(PROJECT_ROOT)}")
        logo = generate_logo(lang, icon)
        print(f"  {logo.relative_to(PROJECT_ROOT)}")

    print("\nDone!")


if __name__ == "__main__":
    main()
