import 'device_selector.dart';
import 'meta_dat_platform_interface.dart';
import 'photo_data.dart';
import 'photo_format.dart';
import 'stream_session_config.dart';
import 'stream_session_error.dart';
import 'stream_session_state.dart';
import 'video_frame.dart';

/// Manages a video streaming session from a Meta wearable device.
///
/// Create a [StreamSession] with a configuration and device selector, then
/// call [start] to begin streaming.
///
/// ```dart
/// final session = await StreamSession.create(
///   config: StreamSessionConfig(
///     videoCodec: VideoCodec.raw,
///     resolution: StreamingResolution.medium,
///     frameRate: 30,
///   ),
///   deviceSelector: AutoDeviceSelector(),
/// );
///
/// // Listen to video frames
/// session.videoFrameStream.listen((frame) {
///   // Process frame
/// });
///
/// // Start streaming
/// await session.start();
/// ```
class StreamSession {
  StreamSession._(this._sessionId);

  final String _sessionId;

  MetaDatPlatform get _platform => MetaDatPlatform.instance;

  /// Creates a new stream session with the given configuration.
  ///
  /// The [config] specifies the video codec, resolution, and frame rate.
  /// The [deviceSelector] determines which device to stream from.
  static Future<StreamSession> create({
    required StreamSessionConfig config,
    required DeviceSelector deviceSelector,
  }) async {
    final sessionId = await MetaDatPlatform.instance.createStreamSession(
      config: config,
      deviceSelector: deviceSelector.toMap(),
    );
    return StreamSession._(sessionId);
  }

  /// Returns the current state of this stream session.
  Future<StreamSessionState> getState() {
    return _platform.getStreamSessionState(_sessionId);
  }

  /// Returns a stream of state changes for this session.
  ///
  /// Listen to this stream to react to session state transitions such as
  /// starting, streaming, paused, or stopped.
  Stream<StreamSessionState> get stateStream {
    return _platform.streamSessionStateStream(_sessionId);
  }

  /// Returns a stream of video frames received during streaming.
  ///
  /// Each [VideoFrame] contains the raw image data, dimensions, and
  /// timestamp.
  Stream<VideoFrame> get videoFrameStream {
    return _platform.videoFrameStream(_sessionId);
  }

  /// Returns a stream of errors that occur during the session.
  Stream<StreamSessionError> get errorStream {
    return _platform.streamSessionErrorStream(_sessionId);
  }

  /// Returns a stream of captured photo data.
  ///
  /// Listen to this stream before calling [capturePhoto] to receive the
  /// captured photo data.
  Stream<PhotoData> get photoDataStream {
    return _platform.photoDataStream(_sessionId);
  }

  /// Starts the streaming session.
  ///
  /// The session will transition through [StreamSessionState.starting] to
  /// [StreamSessionState.streaming] if successful.
  Future<void> start() {
    return _platform.startStreamSession(_sessionId);
  }

  /// Stops the streaming session.
  ///
  /// The session will transition through [StreamSessionState.stopping] to
  /// [StreamSessionState.stopped].
  Future<void> stop() {
    return _platform.stopStreamSession(_sessionId);
  }

  /// Captures a photo in the specified format.
  ///
  /// The captured photo data will be delivered through [photoDataStream].
  /// Defaults to [PhotoFormat.jpeg] if no format is specified.
  Future<void> capturePhoto({PhotoFormat format = PhotoFormat.jpeg}) {
    return _platform.capturePhoto(_sessionId, format);
  }

  /// Disposes this stream session and releases its native resources.
  ///
  /// After calling this method, the session can no longer be used.
  Future<void> dispose() {
    return _platform.disposeStreamSession(_sessionId);
  }
}
