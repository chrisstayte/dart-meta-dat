/// The state of a stream session.
enum StreamSessionState {
  /// The stream session is stopped.
  stopped,

  /// The stream session is waiting for a device to connect.
  waitingForDevice,

  /// The stream session is starting.
  starting,

  /// The stream session is actively streaming.
  streaming,

  /// The stream session is stopping.
  stopping,

  /// The stream session is paused.
  paused,
}
