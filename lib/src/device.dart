/// Represents a Meta wearable device.
class MetaDatDevice {
  /// Creates a [MetaDatDevice] instance.
  const MetaDatDevice({
    required this.identifier,
    this.name,
  });

  /// Creates a [MetaDatDevice] from a map (platform channel data).
  factory MetaDatDevice.fromMap(Map<String, dynamic> map) {
    return MetaDatDevice(
      identifier: map['identifier'] as String,
      name: map['name'] as String?,
    );
  }

  /// The unique identifier for this device.
  final String identifier;

  /// The human-readable name of this device, if available.
  final String? name;

  /// Returns the name if available, otherwise the identifier.
  String get nameOrId => name ?? identifier;

  /// Converts this device to a map for platform channel communication.
  Map<String, dynamic> toMap() {
    return {
      'identifier': identifier,
      'name': name,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MetaDatDevice &&
          runtimeType == other.runtimeType &&
          identifier == other.identifier;

  @override
  int get hashCode => identifier.hashCode;

  @override
  String toString() => 'MetaDatDevice(identifier: $identifier, name: $name)';
}
