# RTL (Right-to-Left) Text Fix Plan

## Problem
When Arabic (or other RTL languages) is enabled, the menu bar text shows reversed or incorrectly formatted text. Icons and text are not displaying in the correct order.

## Root Cause
The `updateMenuTitle()` function creates an `NSAttributedString` without setting proper text direction attributes for RTL languages. macOS needs explicit bidirectional text handling to display RTL text correctly.

## Solution Architecture

### 1. Text Direction Detection
- Detect current language from `LanguageManager`
- Determine if language is RTL (Arabic, Hebrew, etc.)
- Apply appropriate text direction attributes

### 2. NSAttributedString Enhancement
- Create helper function to build RTL-aware attributed strings
- Set `NSWritingDirection` attribute for proper text direction
- Configure `NSParagraphStyle` with correct alignment and direction
- Handle bidirectional text (RTL text with LTR numbers/symbols)

### 3. Menu Bar Button Configuration
- Ensure NSStatusBarButton respects text direction
- Configure button's `semantics` for RTL languages
- Handle icon positioning for RTL layout

## Implementation Details

### Files to Modify
1. **PrayerTimeViewModel.swift**
   - Add `createMenuTitle()` helper function
   - Update `updateMenuTitle()` to use RTL-aware formatting
   - Add paragraph style configuration

2. **FluidMenuBarExtraStatusItem.swift**
   - Update `updateTitle()` to handle RTL text direction
   - Configure button layout direction
   - Set proper semantic content attributes

3. **LanguageManager.swift**
   - Add helper property to check if current language is RTL
   - Add list of RTL language codes

### Technical Approach

#### Step 1: Add RTL Detection to LanguageManager
```swift
class LanguageManager: ObservableObject {
    static let rtlLanguages = ["ar", "he", "fa", "ur"]
    
    var isRTLEnabled: Bool {
        return Self.rtlLanguages.contains(language)
    }
}
```

#### Step 2: Create RTL-Aware NSAttributedString Builder
```swift
func createMenuTitle(
    _ text: String, 
    isRTL: Bool, 
    color: NSColor? = nil
) -> NSAttributedString {
    let paragraphStyle = NSMutableParagraphStyle()
    
    if isRTL {
        paragraphStyle.alignment = .right
        paragraphStyle.baseWritingDirection = .rightToLeft
    } else {
        paragraphStyle.alignment = .left
        paragraphStyle.baseWritingDirection = .leftToRight
    }
    
    var attributes: [NSAttributedString.Key: Any] = [
        .paragraphStyle: paragraphStyle,
        .writingDirection: isRTL ? [NSWritingDirectionFormatType.override, NSWritingDirection.rightToLeft] : []
    ]
    
    if let color = color {
        attributes[.foregroundColor] = color
    }
    
    return NSAttributedString(string: text, attributes: attributes)
}
```

#### Step 3: Update Menu Bar Title Generation
```swift
func updateMenuTitle() {
    guard isPrayerDataAvailable else {
        self.menuTitle = createMenuTitle("PrayerTimes Pro", isRTL: languageManager.isRTLEnabled)
        return
    }
    
    // Generate text with proper RTL handling
    // Use Unicode bidirectional markers if needed
    // Apply RTL formatting
}
```

#### Step 4: Update Status Bar Button
```swift
public func updateTitle(to newTitle: NSAttributedString) {
    // Set semantic content attribute based on text direction
    if let languageManager = // get language manager {
        if languageManager.isRTLEnabled {
            statusItem.button?.semanticContentAttribute = .forceRightToLeft
        } else {
            statusItem.button?.semanticContentAttribute = .forceLeftToRight
        }
    }
    
    statusItem.button?.attributedTitle = newTitle
}
```

### Bidirectional Text Handling

For text with mixed RTL and LTR content (e.g., Arabic prayer names with LTR times):

1. **Use Unicode Bidirectional Markers**
   - LRM (Left-to-Right Mark): `\u{200E}`
   - RLM (Right-to-Left Mark): `\u{200F}`
   - LRE/LRO/RLE/RLO/PDF for embedding

2. **Example Pattern**
   ```swift
   // For Arabic: "Fajr in 5m"
   let text = "\(arabicPrayerName)\u{200F} \u{200E}\(time)\u{200E}"
   ```

3. **NSAttributedString Writing Direction**
   ```swift
   attributes[.writingDirection] = [
       NSWritingDirectionFormatType.override,
       NSWritingDirection.rightToLeft
   ]
   ```

### Testing Strategy

#### Test Cases
1. **Arabic Language**
   - Prayer names display correctly (right-to-left)
   - Time/numbers remain left-to-right
   - Countdown timer displays correctly
   - Icons position correctly

2. **English Language**
   - Everything displays normally (no regression)
   - LTR text direction maintained

3. **Mixed Content**
   - Arabic prayer names with English numbers
   - Countdown with mixed content
   - Date/time formatting

4. **Edge Cases**
   - Empty text
   - Very long text
   - Text with special characters
   - Switching between languages

## Visual Examples

### Before Fix (Arabic)
```
[moon icon] m5 ni rjaF  ❌ (reversed)
```

### After Fix (Arabic)
```
[moon icon] الفجر في 5د  ✅ (correct)
```

### English (Unchanged)
```
[moon icon] Fajr in 5m  ✅
```

## Implementation Steps

### Phase 1: Detection & Infrastructure
1. Add RTL detection to LanguageManager
2. Create attributed string helper function
3. Add paragraph style configuration

### Phase 2: Menu Bar Update
1. Update updateMenuTitle() function
2. Implement bidirectional text handling
3. Add Unicode markers for mixed content

### Phase 3: Status Bar Button
1. Update updateTitle() to set semantic attributes
2. Configure button layout direction
3. Test icon positioning

### Phase 4: Testing & Polish
1. Test with Arabic language
2. Test language switching
3. Verify no English regression
4. Test edge cases

## Success Criteria
- ✅ Arabic text displays right-to-left correctly
- ✅ Numbers and times remain left-to-right when appropriate
- ✅ Icon positioning works for both RTL and LTR
- ✅ No regression in English or other LTR languages
- ✅ Smooth language switching
- ✅ Countdown timer displays correctly in all languages

## Performance Considerations
- Minimize string processing overhead
- Cache paragraph style objects when possible
- Avoid redundant attribute creation
- Use efficient Unicode handling

## Compatibility
- macOS 13.0+ (Ventura)
- SwiftUI 4.0+
- Works with existing localization system
- Compatible with current FluidMenuBar implementation
