import 'streaming_resolution.dart';
import 'video_codec.dart';

/// Configuration for a stream session.
class StreamSessionConfig {
  /// Creates a [StreamSessionConfig] instance.
  const StreamSessionConfig({
    this.videoCodec = VideoCodec.raw,
    this.resolution = StreamingResolution.low,
    this.frameRate = 24,
  });

  /// The video codec to use for streaming.
  ///
  /// Defaults to [VideoCodec.raw]. Use [VideoCodec.hvc1] for background
  /// streaming support.
  final VideoCodec videoCodec;

  /// The streaming resolution.
  ///
  /// Defaults to [StreamingResolution.low] (360x640).
  final StreamingResolution resolution;

  /// The target frame rate for streaming.
  ///
  /// Defaults to 24 frames per second.
  final int frameRate;

  /// Converts this config to a map for platform channel communication.
  Map<String, dynamic> toMap() {
    return {
      'videoCodec': videoCodec.name,
      'resolution': resolution.name,
      'frameRate': frameRate,
    };
  }

  @override
  String toString() =>
      'StreamSessionConfig(videoCodec: $videoCodec, resolution: $resolution, '
      'frameRate: $frameRate)';
}
