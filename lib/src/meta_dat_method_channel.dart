import 'package:flutter/services.dart';

import 'device.dart';
import 'meta_dat_platform_interface.dart';
import 'permission.dart';
import 'permission_status.dart';
import 'photo_data.dart';
import 'photo_format.dart';
import 'registration_state.dart';
import 'stream_session_config.dart';
import 'stream_session_error.dart';
import 'stream_session_state.dart';
import 'video_frame.dart';

/// An implementation of [MetaDatPlatform] that uses method channels.
class MethodChannelMetaDat extends MetaDatPlatform {
  /// The method channel used to interact with the native platform.
  final MethodChannel _methodChannel = const MethodChannel('meta_dat');

  /// The event channel for registration state changes.
  final EventChannel _registrationStateChannel =
      const EventChannel('meta_dat/registration_state');

  /// The event channel for device list changes.
  final EventChannel _devicesChannel =
      const EventChannel('meta_dat/devices');

  @override
  Future<void> configure() async {
    await _methodChannel.invokeMethod<void>('configure');
  }

  @override
  Future<RegistrationState> getRegistrationState() async {
    final result =
        await _methodChannel.invokeMethod<String>('getRegistrationState');
    return RegistrationState.values.firstWhere(
      (e) => e.name == result,
      orElse: () => RegistrationState.unregistered,
    );
  }

  @override
  Stream<RegistrationState> registrationStateStream() {
    return _registrationStateChannel
        .receiveBroadcastStream()
        .map((event) => RegistrationState.values.firstWhere(
              (e) => e.name == event as String,
              orElse: () => RegistrationState.unregistered,
            ));
  }

  @override
  Future<List<MetaDatDevice>> getDevices() async {
    final result = await _methodChannel.invokeListMethod<Map>('getDevices');
    if (result == null) return [];
    return result
        .map((map) =>
            MetaDatDevice.fromMap(Map<String, dynamic>.from(map)))
        .toList();
  }

  @override
  Stream<List<MetaDatDevice>> devicesStream() {
    return _devicesChannel.receiveBroadcastStream().map((event) {
      final list = (event as List)
          .map((map) => MetaDatDevice.fromMap(
              Map<String, dynamic>.from(map as Map)))
          .toList();
      return list;
    });
  }

  @override
  Future<void> startRegistration() async {
    await _methodChannel.invokeMethod<void>('startRegistration');
  }

  @override
  Future<void> startUnregistration() async {
    await _methodChannel.invokeMethod<void>('startUnregistration');
  }

  @override
  Future<bool> handleUrl(String url) async {
    final result = await _methodChannel.invokeMethod<bool>(
      'handleUrl',
      {'url': url},
    );
    return result ?? false;
  }

  @override
  Future<MetaDatPermissionStatus> checkPermissionStatus(
    MetaDatPermission permission,
  ) async {
    final result = await _methodChannel.invokeMethod<String>(
      'checkPermissionStatus',
      {'permission': permission.name},
    );
    return MetaDatPermissionStatus.values.firstWhere(
      (e) => e.name == result,
      orElse: () => MetaDatPermissionStatus.denied,
    );
  }

  @override
  Future<MetaDatPermissionStatus> requestPermission(
    MetaDatPermission permission,
  ) async {
    final result = await _methodChannel.invokeMethod<String>(
      'requestPermission',
      {'permission': permission.name},
    );
    return MetaDatPermissionStatus.values.firstWhere(
      (e) => e.name == result,
      orElse: () => MetaDatPermissionStatus.denied,
    );
  }

  @override
  Future<String> createStreamSession({
    required StreamSessionConfig config,
    required Map<String, dynamic> deviceSelector,
  }) async {
    final result = await _methodChannel.invokeMethod<String>(
      'createStreamSession',
      {
        'config': config.toMap(),
        'deviceSelector': deviceSelector,
      },
    );
    return result!;
  }

  @override
  Future<void> startStreamSession(String sessionId) async {
    await _methodChannel.invokeMethod<void>(
      'startStreamSession',
      {'sessionId': sessionId},
    );
  }

  @override
  Future<void> stopStreamSession(String sessionId) async {
    await _methodChannel.invokeMethod<void>(
      'stopStreamSession',
      {'sessionId': sessionId},
    );
  }

  @override
  Future<void> capturePhoto(String sessionId, PhotoFormat format) async {
    await _methodChannel.invokeMethod<void>(
      'capturePhoto',
      {
        'sessionId': sessionId,
        'format': format.name,
      },
    );
  }

  @override
  Future<StreamSessionState> getStreamSessionState(String sessionId) async {
    final result = await _methodChannel.invokeMethod<String>(
      'getStreamSessionState',
      {'sessionId': sessionId},
    );
    return StreamSessionState.values.firstWhere(
      (e) => e.name == result,
      orElse: () => StreamSessionState.stopped,
    );
  }

  @override
  Stream<StreamSessionState> streamSessionStateStream(String sessionId) {
    return EventChannel('meta_dat/stream_session/$sessionId/state')
        .receiveBroadcastStream()
        .map((event) => StreamSessionState.values.firstWhere(
              (e) => e.name == event as String,
              orElse: () => StreamSessionState.stopped,
            ));
  }

  @override
  Stream<VideoFrame> videoFrameStream(String sessionId) {
    return EventChannel('meta_dat/stream_session/$sessionId/video_frame')
        .receiveBroadcastStream()
        .map((event) =>
            VideoFrame.fromMap(Map<String, dynamic>.from(event as Map)));
  }

  @override
  Stream<StreamSessionError> streamSessionErrorStream(String sessionId) {
    return EventChannel('meta_dat/stream_session/$sessionId/error')
        .receiveBroadcastStream()
        .map((event) => StreamSessionError.values.firstWhere(
              (e) => e.name == event as String,
              orElse: () => StreamSessionError.internalError,
            ));
  }

  @override
  Stream<PhotoData> photoDataStream(String sessionId) {
    return EventChannel('meta_dat/stream_session/$sessionId/photo_data')
        .receiveBroadcastStream()
        .map((event) =>
            PhotoData.fromMap(Map<String, dynamic>.from(event as Map)));
  }

  @override
  Future<void> disposeStreamSession(String sessionId) async {
    await _methodChannel.invokeMethod<void>(
      'disposeStreamSession',
      {'sessionId': sessionId},
    );
  }
}
