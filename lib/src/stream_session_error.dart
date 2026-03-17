/// Errors that can occur during a stream session.
enum StreamSessionError {
  /// An internal error occurred.
  internalError,

  /// The device was not found.
  deviceNotFound,

  /// The device is not connected.
  deviceNotConnected,

  /// The operation timed out.
  timeout,

  /// A video streaming error occurred.
  videoStreamingError,

  /// Camera permission was denied.
  permissionDenied,

  /// The glasses hinges are closed.
  hingesClosed,

  /// The device reached a critical thermal state.
  thermalCritical,
}
