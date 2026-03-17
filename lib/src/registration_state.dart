/// The registration state of the Meta Wearables SDK.
enum RegistrationState {
  /// The SDK is currently registering with the Meta AI app.
  registering,

  /// The SDK is registered and ready for use.
  registered,

  /// The SDK is currently unregistering.
  unregistering,

  /// The SDK is not registered.
  unregistered,
}
