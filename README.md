# 10x Alarm

An iOS alarm clock that won't stop until you prove you're brushing your teeth.

## Requirements

- iOS 26+
- iPhone 11 or newer
- Xcode 16+

## Project Setup

### 1. Create Xcode Project

1. Open Xcode → File → New → Project
2. Choose **App** template
3. Settings:
   - Product Name: `TenXAlarm`
   - Organization Identifier: `com.yourorg`
   - Interface: SwiftUI
   - Language: Swift
   - Storage: SwiftData
4. Save in the `10x-alarm` directory

### 2. Add Widget Target

1. File → New → Target
2. Choose **Widget Extension**
3. Name: `TenXAlarmWidget`
4. Uncheck "Include Live Activity" (we handle this manually)
5. Uncheck "Include Configuration App Intent"

### 3. Import Source Files

Drag these folders into your Xcode project:
- `TenXAlarm/` → Main app target
- `TenXAlarmWidget/` → Widget target

### 4. Configure Info.plist

Add these entries to your main app's Info.plist:

```xml
<!-- Camera access -->
<key>NSCameraUsageDescription</key>
<string>10x Alarm needs camera access to verify you're brushing your teeth.</string>

<!-- AlarmKit -->
<key>NSAlarmKitUsageDescription</key>
<string>10x Alarm uses alarms to wake you up for your morning brush routine.</string>

<!-- URL Scheme for deep links -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>tenxalarm</string>
        </array>
    </dict>
</array>

<!-- Live Activities -->
<key>NSSupportsLiveActivities</key>
<true/>
```

### 5. Configure Capabilities

In Xcode, go to Signing & Capabilities and add:

1. **App Groups** - Create group: `group.com.yourorg.tenxalarm`
2. **Background Modes** - Enable: Audio, Background fetch
3. **Push Notifications** (for future widget updates)

### 6. Add App Group to Widget

The widget needs to share data with the main app:

1. Select widget target
2. Add App Groups capability
3. Use same group: `group.com.yourorg.tenxalarm`

### 7. Add YOLO Model (Optional for full ML)

To enable toothbrush detection:

1. Download YOLOv8n COCO model
2. Convert to Core ML format:
   ```bash
   pip install ultralytics coremltools
   python -c "from ultralytics import YOLO; YOLO('yolov8n.pt').export(format='coreml')"
   ```
3. Add `yolov8n.mlpackage` to project
4. Update `ToothbrushDetector.swift` to load the model

## Architecture

```
TenXAlarm/
├── App/                    # Entry point
├── Features/
│   ├── Onboarding/        # First-time setup
│   ├── Dashboard/         # Main screen
│   ├── Verification/      # Camera + ML
│   └── Settings/          # Configuration
├── Services/              # Business logic
├── ML/                    # Vision + Core ML
├── Models/                # SwiftData models
└── AlarmKit/              # Alarm integration

TenXAlarmWidget/           # Home screen widget
```

## Key Features

- **Relentless Alarm**: Fires every 3 minutes until verified
- **ML Verification**: Face + toothbrush detection
- **Streak Tracking**: Consecutive days of brushing
- **Weekly Commitment**: Minimum 4 days/week
- **Home Screen Widget**: Streak display

## Core Decisions

| Feature | Implementation |
|---------|----------------|
| Alarm | AlarmKit (iOS 26) |
| ML | Vision + YOLO Core ML |
| Storage | SwiftData |
| UI | SwiftUI |
| Min Days | 4-7 configurable |
| Max Time | 10:00 AM |
| Re-fire | Every 3 minutes |
| Snooze | None |

## Testing

The ML pipeline works best with:
- Good lighting (face visible)
- Toothbrush clearly in mouth
- Single person in frame
- Front-facing camera

## License

Proprietary - 10x Alarm Inc.
