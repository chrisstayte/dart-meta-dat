import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'device.dart';
import 'meta_dat_method_channel.dart';
import 'permission.dart';
import 'permission_status.dart';
import 'photo_data.dart';
import 'photo_format.dart';
import 'registration_state.dart';
import 'stream_session_config.dart';
import 'stream_session_error.dart';
import 'stream_session_state.dart';
import 'video_frame.dart';

/// The interface that platform-specific implementations of the MetaDat plugin
/// must extend.
abstract class MetaDatPlatform extends PlatformInterface {
  /// Constructs a [MetaDatPlatform].
  MetaDatPlatform() : super(token: _token);

  static final Object _token = Object();

  static MetaDatPlatform _instance = MethodChannelMetaDat();

  /// The default instance of [MetaDatPlatform] to use.
  static MetaDatPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MetaDatPlatform] when they register
  /// themselves.
  static set instance(MetaDatPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Initializes the Meta Wearables SDK.
  Future<void> configure() {
    throw UnimplementedError('configure() has not been implemented.');
  }

  /// Returns the current registration state.
  Future<RegistrationState> getRegistrationState() {
    throw UnimplementedError(
      'getRegistrationState() has not been implemented.',
    );
  }

  /// Returns a stream of registration state changes.
  Stream<RegistrationState> registrationStateStream() {
    throw UnimplementedError(
      'registrationStateStream() has not been implemented.',
    );
  }

  /// Returns the list of available devices.
  Future<List<MetaDatDevice>> getDevices() {
    throw UnimplementedError('getDevices() has not been implemented.');
  }

  /// Returns a stream of device list changes.
  Stream<List<MetaDatDevice>> devicesStream() {
    throw UnimplementedError('devicesStream() has not been implemented.');
  }

  /// Starts the device registration flow.
  Future<void> startRegistration() {
    throw UnimplementedError('startRegistration() has not been implemented.');
  }

  /// Starts the device unregistration flow.
  Future<void> startUnregistration() {
    throw UnimplementedError(
      'startUnregistration() has not been implemented.',
    );
  }

  /// Handles a URL callback from the Meta AI app.
  Future<bool> handleUrl(String url) {
    throw UnimplementedError('handleUrl() has not been implemented.');
  }

  /// Checks the status of a permission.
  Future<MetaDatPermissionStatus> checkPermissionStatus(
    MetaDatPermission permission,
  ) {
    throw UnimplementedError(
      'checkPermissionStatus() has not been implemented.',
    );
  }

  /// Requests a permission from the user.
  Future<MetaDatPermissionStatus> requestPermission(
    MetaDatPermission permission,
  ) {
    throw UnimplementedError('requestPermission() has not been implemented.');
  }

  /// Creates a new stream session with the given configuration.
  ///
  /// Returns a session ID that can be used to control the session.
  Future<String> createStreamSession({
    required StreamSessionConfig config,
    required Map<String, dynamic> deviceSelector,
  }) {
    throw UnimplementedError(
      'createStreamSession() has not been implemented.',
    );
  }

  /// Starts a stream session.
  Future<void> startStreamSession(String sessionId) {
    throw UnimplementedError(
      'startStreamSession() has not been implemented.',
    );
  }

  /// Stops a stream session.
  Future<void> stopStreamSession(String sessionId) {
    throw UnimplementedError('stopStreamSession() has not been implemented.');
  }

  /// Captures a photo in the given format.
  Future<void> capturePhoto(String sessionId, PhotoFormat format) {
    throw UnimplementedError('capturePhoto() has not been implemented.');
  }

  /// Returns the current state of a stream session.
  Future<StreamSessionState> getStreamSessionState(String sessionId) {
    throw UnimplementedError(
      'getStreamSessionState() has not been implemented.',
    );
  }

  /// Returns a stream of state changes for a stream session.
  Stream<StreamSessionState> streamSessionStateStream(String sessionId) {
    throw UnimplementedError(
      'streamSessionStateStream() has not been implemented.',
    );
  }

  /// Returns a stream of video frames for a stream session.
  Stream<VideoFrame> videoFrameStream(String sessionId) {
    throw UnimplementedError('videoFrameStream() has not been implemented.');
  }

  /// Returns a stream of errors for a stream session.
  Stream<StreamSessionError> streamSessionErrorStream(String sessionId) {
    throw UnimplementedError(
      'streamSessionErrorStream() has not been implemented.',
    );
  }

  /// Returns a stream of captured photo data for a stream session.
  Stream<PhotoData> photoDataStream(String sessionId) {
    throw UnimplementedError('photoDataStream() has not been implemented.');
  }

  /// Disposes a stream session and releases its resources.
  Future<void> disposeStreamSession(String sessionId) {
    throw UnimplementedError(
      'disposeStreamSession() has not been implemented.',
    );
  }
}
