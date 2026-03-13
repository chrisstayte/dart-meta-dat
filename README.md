# meta_dat

A Flutter plugin wrapping the [Meta Wearables Device Access Toolkit (DAT)](https://github.com/facebook/meta-wearables-dat-ios) iOS SDK for building hands-free wearable experiences with Meta AI glasses (Ray-Ban Meta smart glasses and Meta Ray-Ban Display glasses).

> **Note:** This plugin currently supports **iOS only**. Android support is planned for a future release.

## Features

- **Device Discovery & Registration** — Discover and register Meta wearable devices through the Meta AI app
- **Video Streaming** — Stream video from device cameras with configurable codec, resolution, and frame rate
- **Photo Capture** — Capture photos in JPEG or HEIC format
- **Permission Management** — Request and check camera permissions
- **Background Streaming** — Support for HEVC codec to continue streaming in the background

## Requirements

- **iOS 16.0+**
- **Flutter 3.29.0+**
- **Xcode 15.0+**
- **Meta AI app** installed on the test device with Developer Mode enabled
- **Ray-Ban Meta** or **Meta Ray-Ban Display** glasses (or use the MockDeviceKit for testing)

## Installation

Add `meta_dat` to your `pubspec.yaml`:

```yaml
dependencies:
  meta_dat: ^0.1.0
```

### iOS Setup

#### 1. Add the Meta Wearables DAT iOS SDK

The native Meta Wearables DAT iOS SDK must be added to your iOS project via Swift Package Manager:

1. Open your project's iOS workspace in Xcode (`ios/Runner.xcworkspace`)
2. Go to **File → Add Package Dependencies**
3. Enter the URL: `https://github.com/facebook/meta-wearables-dat-ios`
4. Add both **MWDATCore** and **MWDATCamera** packages to your Runner target

#### 2. Configure Info.plist

Add the following entries to your `ios/Runner/Info.plist`:

```xml
<!-- URL Scheme for Meta AI callback -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>your-app-scheme</string>
        </array>
    </dict>
</array>

<!-- Required for communicating with Meta AI app -->
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>fb-viewapp</string>
</array>

<!-- Required for Bluetooth communication with glasses -->
<key>UISupportedExternalAccessoryProtocols</key>
<array>
    <string>com.meta.ar.wearable</string>
</array>

<!-- Required background modes -->
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-peripheral</string>
    <string>external-accessory</string>
</array>

<!-- Meta Wearables SDK Configuration -->
<key>MWDAT</key>
<dict>
    <key>AppLinkURLScheme</key>
    <string>your-app-scheme</string>
    <key>MetaAppID</key>
    <string>0</string> <!-- Use 0 for Developer Mode -->
    <key>TeamID</key>
    <string>YOUR_APPLE_TEAM_ID</string>
</dict>
```

## Usage

### Initialize the SDK

```dart
import 'package:meta_dat/meta_dat.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Wearables.configure();
  runApp(MyApp());
}
```

### Handle URL Callbacks

In your app, handle the deep link callback from the Meta AI app:

```dart
// Using go_router, uni_links, or similar deep link handling
void onDeepLink(String url) async {
  final handled = await Wearables.instance.handleUrl(url);
  if (handled) {
    // URL was processed by the Meta Wearables SDK
  }
}
```

### Register a Device

```dart
final wearables = Wearables.instance;

// Listen to registration state changes
wearables.registrationStateStream().listen((state) {
  print('Registration state: $state');
});

// Start registration (opens Meta AI app)
await wearables.startRegistration();
```

### Check Permissions

```dart
final status = await wearables.checkPermissionStatus(MetaDatPermission.camera);
if (status == MetaDatPermissionStatus.denied) {
  final newStatus = await wearables.requestPermission(MetaDatPermission.camera);
  print('Permission status: $newStatus');
}
```

### Stream Video

```dart
// Create a stream session
final session = await StreamSession.create(
  config: StreamSessionConfig(
    videoCodec: VideoCodec.raw,
    resolution: StreamingResolution.medium,
    frameRate: 30,
  ),
  deviceSelector: AutoDeviceSelector(),
);

// Listen to state changes
session.stateStream.listen((state) {
  print('Stream state: $state');
});

// Listen to video frames
session.videoFrameStream.listen((frame) {
  // Process the video frame
  print('Frame: ${frame.width}x${frame.height}');
});

// Listen to errors
session.errorStream.listen((error) {
  print('Stream error: $error');
});

// Start streaming
await session.start();

// Later, stop streaming
await session.stop();

// Clean up
await session.dispose();
```

### Capture a Photo

```dart
// Listen for photo data before capturing
session.photoDataStream.listen((photo) {
  print('Photo captured: ${photo.format}, ${photo.data.length} bytes');
});

// Capture a photo
await session.capturePhoto(format: PhotoFormat.jpeg);
```

### List Connected Devices

```dart
// Get current devices
final devices = await wearables.getDevices();
for (final device in devices) {
  print('Device: ${device.nameOrId}');
}

// Listen to device changes
wearables.devicesStream().listen((devices) {
  print('Devices updated: ${devices.length} devices');
});
```

### Use a Specific Device

```dart
final devices = await wearables.getDevices();
if (devices.isNotEmpty) {
  final session = await StreamSession.create(
    config: StreamSessionConfig(),
    deviceSelector: SpecificDeviceSelector(devices.first.identifier),
  );
}
```

## API Reference

### Core Classes

| Class | Description |
|-------|-------------|
| `Wearables` | Main SDK entry point. Initialize with `configure()`, access via `instance`. |
| `StreamSession` | Manages video streaming from a wearable device. |
| `StreamSessionConfig` | Configuration for video streaming (codec, resolution, frame rate). |
| `MetaDatDevice` | Represents a paired Meta wearable device. |
| `VideoFrame` | A video frame with raw image data and metadata. |
| `PhotoData` | Captured photo data with format information. |
| `AutoDeviceSelector` | Automatically selects the best available device. |
| `SpecificDeviceSelector` | Selects a specific device by identifier. |

### Enums

| Enum | Values |
|------|--------|
| `RegistrationState` | `registering`, `registered`, `unregistering`, `unregistered` |
| `StreamSessionState` | `stopped`, `waitingForDevice`, `starting`, `streaming`, `stopping`, `paused` |
| `StreamSessionError` | `internalError`, `deviceNotFound`, `deviceNotConnected`, `timeout`, `videoStreamingError`, `permissionDenied`, `hingesClosed`, `thermalCritical` |
| `VideoCodec` | `raw`, `hvc1` |
| `StreamingResolution` | `low` (360×640), `medium` (504×896), `high` (720×1280) |
| `PhotoFormat` | `jpeg`, `heic` |
| `MetaDatPermission` | `camera` |
| `MetaDatPermissionStatus` | `granted`, `denied` |

## Privacy

To opt out of Meta analytics collection, add the following to your `Info.plist`:

```xml
<key>MWDAT</key>
<dict>
    <key>Analytics</key>
    <dict>
        <key>OptOut</key>
        <true/>
    </dict>
</dict>
```

## License

This package is licensed under the MIT License. See [LICENSE](LICENSE) for details.

The Meta Wearables DAT iOS SDK is subject to Meta's own licensing terms.
