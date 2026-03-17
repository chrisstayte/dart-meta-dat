import 'device.dart';
import 'meta_dat_platform_interface.dart';
import 'permission.dart';
import 'permission_status.dart';
import 'registration_state.dart';

/// Main entry point for the Meta Wearables Device Access Toolkit.
///
/// Use [Wearables.configure] to initialize the SDK at app launch, then access
/// the singleton via [Wearables.instance].
///
/// ```dart
/// // Initialize in your app's main entry point
/// await Wearables.configure();
///
/// // Access the singleton
/// final wearables = Wearables.instance;
///
/// // Check registration state
/// final state = await wearables.getRegistrationState();
/// ```
class Wearables {
  Wearables._();

  static final Wearables _instance = Wearables._();

  /// The singleton instance of [Wearables].
  ///
  /// Call [configure] before accessing this.
  static Wearables get instance => _instance;

  MetaDatPlatform get _platform => MetaDatPlatform.instance;

  /// Initializes the Meta Wearables SDK.
  ///
  /// This must be called once at app launch before using any other SDK
  /// features. Typically called in your app's `main()` or root widget
  /// initialization.
  ///
  /// Throws a [PlatformException] if initialization fails.
  static Future<void> configure() async {
    await MetaDatPlatform.instance.configure();
  }

  /// Returns the current registration state.
  Future<RegistrationState> getRegistrationState() {
    return _platform.getRegistrationState();
  }

  /// Returns a stream of registration state changes.
  ///
  /// Listen to this stream to react to changes in the SDK's registration
  /// status with the Meta AI app.
  Stream<RegistrationState> registrationStateStream() {
    return _platform.registrationStateStream();
  }

  /// Returns the list of currently available devices.
  Future<List<MetaDatDevice>> getDevices() {
    return _platform.getDevices();
  }

  /// Returns a stream of device list changes.
  ///
  /// Listen to this stream to be notified when devices connect, disconnect,
  /// or change.
  Stream<List<MetaDatDevice>> devicesStream() {
    return _platform.devicesStream();
  }

  /// Starts the device registration flow.
  ///
  /// This opens the Meta AI app for the user to authorize access to their
  /// wearable device. Use [handleUrl] to process the callback URL when
  /// the user returns to your app.
  ///
  /// Throws a [PlatformException] if registration fails.
  Future<void> startRegistration() {
    return _platform.startRegistration();
  }

  /// Starts the device unregistration flow.
  ///
  /// This revokes access to previously registered devices.
  ///
  /// Throws a [PlatformException] if unregistration fails.
  Future<void> startUnregistration() {
    return _platform.startUnregistration();
  }

  /// Handles a URL callback from the Meta AI app.
  ///
  /// Call this method when your app receives a deep link callback during
  /// the registration flow. Returns `true` if the URL was handled
  /// successfully.
  ///
  /// ```dart
  /// // In your app's URL handler
  /// final handled = await Wearables.instance.handleUrl(url);
  /// ```
  Future<bool> handleUrl(String url) {
    return _platform.handleUrl(url);
  }

  /// Checks the current status of a permission.
  ///
  /// Returns the permission status without prompting the user.
  Future<MetaDatPermissionStatus> checkPermissionStatus(
    MetaDatPermission permission,
  ) {
    return _platform.checkPermissionStatus(permission);
  }

  /// Requests a permission from the user.
  ///
  /// This may show a system dialog or redirect the user to grant the
  /// requested permission.
  ///
  /// Returns the resulting permission status after the request.
  Future<MetaDatPermissionStatus> requestPermission(
    MetaDatPermission permission,
  ) {
    return _platform.requestPermission(permission);
  }
}
