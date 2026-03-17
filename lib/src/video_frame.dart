import 'dart:typed_data';

/// Represents a video frame received from a stream session.
class VideoFrame {
  /// Creates a [VideoFrame] instance.
  const VideoFrame({
    required this.data,
    required this.width,
    required this.height,
    required this.timestamp,
  });

  /// Creates a [VideoFrame] from a map (platform channel data).
  factory VideoFrame.fromMap(Map<String, dynamic> map) {
    return VideoFrame(
      data: map['data'] as Uint8List,
      width: map['width'] as int,
      height: map['height'] as int,
      timestamp: map['timestamp'] as int,
    );
  }

  /// The raw image data bytes.
  final Uint8List data;

  /// The width of the frame in pixels.
  final int width;

  /// The height of the frame in pixels.
  final int height;

  /// The timestamp of the frame in milliseconds.
  final int timestamp;

  @override
  String toString() =>
      'VideoFrame(width: $width, height: $height, timestamp: $timestamp, '
      'dataSize: ${data.length})';
}
