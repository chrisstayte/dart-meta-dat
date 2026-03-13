import 'dart:typed_data';

import 'photo_format.dart';

/// Represents photo data captured from a stream session.
class PhotoData {
  /// Creates a [PhotoData] instance.
  const PhotoData({
    required this.data,
    required this.format,
  });

  /// Creates a [PhotoData] from a map (platform channel data).
  factory PhotoData.fromMap(Map<String, dynamic> map) {
    return PhotoData(
      data: map['data'] as Uint8List,
      format: PhotoFormat.values.firstWhere(
        (e) => e.name == map['format'] as String,
        orElse: () => PhotoFormat.jpeg,
      ),
    );
  }

  /// The raw photo data bytes.
  final Uint8List data;

  /// The format of the photo.
  final PhotoFormat format;

  @override
  String toString() => 'PhotoData(format: $format, dataSize: ${data.length})';
}
