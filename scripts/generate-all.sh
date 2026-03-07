#!/bin/bash
set -euo pipefail

# Ensure pyenv shims are on PATH
export PATH="$HOME/.pyenv/shims:$HOME/.pyenv/bin:$PATH"
eval "$(pyenv init - 2>/dev/null)" || true

# Generates marketing images for PrayerTimes Pro.
#
# Output at project root:
#   {lang}/screenshots.png   — 4-screenshot marketing collage
#   {lang}/logo.png          — app icon + name badge
#
# Usage:
#   ./scripts/generate-all.sh              # full pipeline (UI tests + generate)
#   ./scripts/generate-all.sh --skip-tests # skip UI tests, reuse existing .raw/

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="PrayerTimes"
SKIP_TESTS=false
RAW_DIR="$PROJECT_DIR/.raw"
LANGUAGES=(en ar id fa ur)
VIEWS=(main settings notifications about)

for arg in "$@"; do
    case "$arg" in
        --skip-tests) SKIP_TESTS=true ;;
    esac
done

# ─── Step 1: Capture screenshots via UI tests ────────────────────────────────

if [ "$SKIP_TESTS" = false ]; then
    echo "=== Capturing screenshots via UI tests ==="

    echo "Building for testing..."
    xcodebuild build-for-testing \
        -project "$PROJECT_DIR/PrayerTimes.xcodeproj" \
        -scheme "$SCHEME" \
        -destination 'platform=macOS' \
        -derivedDataPath "$PROJECT_DIR/build" \
        -quiet \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED=NO

    echo "Running screenshot tests..."
    xcodebuild test-without-building \
        -project "$PROJECT_DIR/PrayerTimes.xcodeproj" \
        -scheme "$SCHEME" \
        -destination 'platform=macOS' \
        -derivedDataPath "$PROJECT_DIR/build" \
        -only-testing:"PrayerTimesUITests/ScreenshotGenerator/testGenerateAllScreenshots" \
        -quiet \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_REQUIRED=NO \
        || true

    # ─── Step 2: Extract screenshots from xcresult ────────────────────────────

    echo ""
    echo "=== Extracting screenshots from test results ==="

    XCRESULT=$(ls -t "$PROJECT_DIR"/build/Logs/Test/*.xcresult/Info.plist 2>/dev/null | head -1 | xargs dirname)
    if [ -z "$XCRESULT" ]; then
        echo "ERROR: No xcresult bundle found"
        exit 1
    fi
    echo "Using: $XCRESULT"

    rm -rf "$RAW_DIR"
    mkdir -p "$RAW_DIR"

    # Extract attachment names and IDs, then export each as a file
    xcrun xcresulttool get test-results activities \
        --path "$XCRESULT" \
        --test-id "ScreenshotGenerator/testGenerateAllScreenshots()" 2>/dev/null | \
    python3 -c "
import json, sys, subprocess, os

data = json.load(sys.stdin)
xcresult = '$XCRESULT'
raw_dir = '$RAW_DIR'

def find_attachments(obj, results):
    if isinstance(obj, dict):
        if 'attachments' in obj:
            for a in obj['attachments']:
                results.append((a.get('name', ''), a.get('payloadId', '')))
        for v in obj.values():
            find_attachments(v, results)
    elif isinstance(obj, list):
        for i in obj:
            find_attachments(i, results)

attachments = []
find_attachments(data, attachments)

exported = 0
for name, payload_id in attachments:
    parts = name.split('_')
    if len(parts) >= 2:
        lang, view = parts[0], parts[1]
        lang_dir = os.path.join(raw_dir, lang)
        os.makedirs(lang_dir, exist_ok=True)
        out_path = os.path.join(lang_dir, f'{view}.png')
        result = subprocess.run(
            ['xcrun', 'xcresulttool', 'export', 'object', '--legacy',
             '--path', xcresult, '--id', payload_id, '--type', 'file',
             '--output-path', out_path],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            exported += 1
            print(f'  {lang}/{view}.png')
        else:
            print(f'  FAILED: {lang}/{view}.png - {result.stderr.strip()}')

print(f'\nExtracted {exported} screenshots')
if exported == 0:
    sys.exit(1)
"

    echo ""
fi

# ─── Step 3: Generate marketing images ───────────────────────────────────────

if [ ! -d "$RAW_DIR" ]; then
    echo "ERROR: No raw screenshots found at $RAW_DIR"
    echo "Run without --skip-tests to capture them first."
    exit 1
fi

echo "=== Generating marketing images ==="
python3 "$PROJECT_DIR/scripts/generate-screenshots.py"
