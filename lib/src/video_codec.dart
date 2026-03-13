/// The video codec to use for streaming.
enum VideoCodec {
  /// Raw uncompressed video. Pauses when the app goes to background.
  raw,

  /// HEVC (H.265) compressed video. Continues streaming in background.
  hvc1,
}
