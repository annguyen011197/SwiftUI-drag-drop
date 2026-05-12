# DragDropDemo

Single-target iOS SwiftUI + SwiftData app. No package managers, no tests, no CI.

## Build & Run

```bash
xcodebuild -project DragDropDemo.xcodeproj -scheme DragDropDemo build
```

Or open in Xcode and run from there.

## Key facts

- **iOS target:** 26.2 (from `project.pbxproj`)
- **Bundle ID:** `com.kst.dev.DragDropDemo`
- **Swift version:** 5.0
- **SwiftData:** uses auto-generated `ModelContainer` in `DragDropDemoApp.swift` with a single `Item` model
- **No tests, no CI, no README** — the entire app is 3 Swift files under `DragDropDemo/`
- **Info.plist** is auto-generated (`GENERATE_INFOPLIST_FILE = YES`)
