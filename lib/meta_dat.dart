/// A Flutter plugin wrapping the Meta Wearables Device Access Toolkit (DAT)
/// SDK for building hands-free wearable experiences with Meta AI glasses.
///
/// Supports both iOS and Android platforms.
///
/// ## Getting Started
///
/// Initialize the SDK in your app's entry point:
///
/// ```dart
/// import 'package:meta_dat/meta_dat.dart';
///
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Wearables.configure();
///   runApp(MyApp());
/// }
/// ```
///
/// ## Core Features
///
/// - **Device Management**: Discover and register Meta wearable devices via
///   [Wearables].
/// - **Video Streaming**: Stream video from device cameras via
///   [StreamSession].
/// - **Photo Capture**: Capture photos in JPEG or HEIC format.
/// - **Permissions**: Manage camera permissions with [MetaDatPermission].
library;

export 'src/device.dart';
export 'src/device_selector.dart';
export 'src/meta_dat_platform_interface.dart';
export 'src/permission.dart';
export 'src/permission_status.dart';
export 'src/photo_data.dart';
export 'src/photo_format.dart';
export 'src/registration_state.dart';
export 'src/stream_session.dart';
export 'src/stream_session_config.dart';
export 'src/stream_session_error.dart';
export 'src/stream_session_state.dart';
export 'src/streaming_resolution.dart';
export 'src/video_codec.dart';
export 'src/video_frame.dart';
export 'src/wearables.dart';
