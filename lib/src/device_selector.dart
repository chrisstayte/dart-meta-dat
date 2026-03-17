/// Specifies how to select a device for a stream session.
abstract class DeviceSelector {
  /// Converts this selector to a map for platform channel communication.
  Map<String, dynamic> toMap();
}

/// Automatically selects the best available device.
class AutoDeviceSelector extends DeviceSelector {
  @override
  Map<String, dynamic> toMap() {
    return {'type': 'auto'};
  }
}

/// Selects a specific device by its identifier.
class SpecificDeviceSelector extends DeviceSelector {
  /// Creates a [SpecificDeviceSelector] for the given [deviceIdentifier].
  SpecificDeviceSelector(this.deviceIdentifier);

  /// The identifier of the device to select.
  final String deviceIdentifier;

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': 'specific',
      'deviceIdentifier': deviceIdentifier,
    };
  }
}
