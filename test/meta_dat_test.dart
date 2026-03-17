import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta_dat/meta_dat.dart';
import 'package:meta_dat/src/meta_dat_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MetaDatDevice', () {
    test('fromMap creates device correctly', () {
      final device = MetaDatDevice.fromMap({
        'identifier': 'test-id-123',
        'name': 'Test Device',
      });

      expect(device.identifier, 'test-id-123');
      expect(device.name, 'Test Device');
      expect(device.nameOrId, 'Test Device');
    });

    test('nameOrId returns identifier when name is null', () {
      final device = MetaDatDevice.fromMap({
        'identifier': 'test-id-123',
        'name': null,
      });

      expect(device.nameOrId, 'test-id-123');
    });

    test('toMap serializes correctly', () {
      const device = MetaDatDevice(
        identifier: 'test-id',
        name: 'My Device',
      );

      final map = device.toMap();
      expect(map['identifier'], 'test-id');
      expect(map['name'], 'My Device');
    });

    test('equality works based on identifier', () {
      const device1 = MetaDatDevice(identifier: 'id-1', name: 'Device A');
      const device2 = MetaDatDevice(identifier: 'id-1', name: 'Device B');
      const device3 = MetaDatDevice(identifier: 'id-2', name: 'Device A');

      expect(device1, equals(device2));
      expect(device1, isNot(equals(device3)));
    });

    test('hashCode is based on identifier', () {
      const device1 = MetaDatDevice(identifier: 'id-1', name: 'Device A');
      const device2 = MetaDatDevice(identifier: 'id-1', name: 'Device B');

      expect(device1.hashCode, equals(device2.hashCode));
    });

    test('toString returns readable representation', () {
      const device = MetaDatDevice(identifier: 'id-1', name: 'My Device');
      expect(
        device.toString(),
        'MetaDatDevice(identifier: id-1, name: My Device)',
      );
    });
  });

  group('StreamSessionConfig', () {
    test('default values are correct', () {
      const config = StreamSessionConfig();

      expect(config.videoCodec, VideoCodec.raw);
      expect(config.resolution, StreamingResolution.low);
      expect(config.frameRate, 24);
    });

    test('toMap serializes correctly', () {
      const config = StreamSessionConfig(
        videoCodec: VideoCodec.hvc1,
        resolution: StreamingResolution.high,
        frameRate: 30,
      );

      final map = config.toMap();
      expect(map['videoCodec'], 'hvc1');
      expect(map['resolution'], 'high');
      expect(map['frameRate'], 30);
    });

    test('toString returns readable representation', () {
      const config = StreamSessionConfig();
      expect(config.toString(), contains('StreamSessionConfig'));
      expect(config.toString(), contains('raw'));
      expect(config.toString(), contains('low'));
      expect(config.toString(), contains('24'));
    });
  });

  group('DeviceSelector', () {
    test('AutoDeviceSelector toMap returns correct type', () {
      final selector = AutoDeviceSelector();
      expect(selector.toMap(), {'type': 'auto'});
    });

    test('SpecificDeviceSelector toMap returns correct data', () {
      final selector = SpecificDeviceSelector('device-123');
      final map = selector.toMap();

      expect(map['type'], 'specific');
      expect(map['deviceIdentifier'], 'device-123');
    });
  });

  group('VideoFrame', () {
    test('fromMap creates frame correctly', () {
      final frame = VideoFrame.fromMap({
        'data': Uint8List.fromList([1, 2, 3]),
        'width': 640,
        'height': 480,
        'timestamp': 12345,
      });

      expect(frame.width, 640);
      expect(frame.height, 480);
      expect(frame.timestamp, 12345);
      expect(frame.data.length, 3);
    });

    test('toString returns readable representation', () {
      final frame = VideoFrame.fromMap({
        'data': Uint8List.fromList([1, 2, 3]),
        'width': 640,
        'height': 480,
        'timestamp': 12345,
      });

      expect(frame.toString(), contains('640'));
      expect(frame.toString(), contains('480'));
    });
  });

  group('PhotoData', () {
    test('fromMap creates photo data correctly', () {
      final photo = PhotoData.fromMap({
        'data': Uint8List.fromList([1, 2, 3, 4]),
        'format': 'jpeg',
      });

      expect(photo.data.length, 4);
      expect(photo.format, PhotoFormat.jpeg);
    });

    test('fromMap handles heic format', () {
      final photo = PhotoData.fromMap({
        'data': Uint8List.fromList([1]),
        'format': 'heic',
      });

      expect(photo.format, PhotoFormat.heic);
    });

    test('fromMap defaults to jpeg for unknown format', () {
      final photo = PhotoData.fromMap({
        'data': Uint8List.fromList([1]),
        'format': 'unknown',
      });

      expect(photo.format, PhotoFormat.jpeg);
    });
  });

  group('Enums', () {
    test('RegistrationState has all expected values', () {
      expect(RegistrationState.values, hasLength(4));
      expect(
        RegistrationState.values,
        containsAll([
          RegistrationState.registering,
          RegistrationState.registered,
          RegistrationState.unregistering,
          RegistrationState.unregistered,
        ]),
      );
    });

    test('StreamSessionState has all expected values', () {
      expect(StreamSessionState.values, hasLength(6));
      expect(
        StreamSessionState.values,
        containsAll([
          StreamSessionState.stopped,
          StreamSessionState.waitingForDevice,
          StreamSessionState.starting,
          StreamSessionState.streaming,
          StreamSessionState.stopping,
          StreamSessionState.paused,
        ]),
      );
    });

    test('StreamSessionError has all expected values', () {
      expect(StreamSessionError.values, hasLength(8));
      expect(
        StreamSessionError.values,
        containsAll([
          StreamSessionError.internalError,
          StreamSessionError.deviceNotFound,
          StreamSessionError.deviceNotConnected,
          StreamSessionError.timeout,
          StreamSessionError.videoStreamingError,
          StreamSessionError.permissionDenied,
          StreamSessionError.hingesClosed,
          StreamSessionError.thermalCritical,
        ]),
      );
    });

    test('VideoCodec has all expected values', () {
      expect(VideoCodec.values, hasLength(2));
      expect(VideoCodec.values, containsAll([VideoCodec.raw, VideoCodec.hvc1]));
    });

    test('StreamingResolution has all expected values', () {
      expect(StreamingResolution.values, hasLength(3));
      expect(
        StreamingResolution.values,
        containsAll([
          StreamingResolution.low,
          StreamingResolution.medium,
          StreamingResolution.high,
        ]),
      );
    });

    test('PhotoFormat has all expected values', () {
      expect(PhotoFormat.values, hasLength(2));
      expect(
        PhotoFormat.values,
        containsAll([PhotoFormat.jpeg, PhotoFormat.heic]),
      );
    });

    test('MetaDatPermission has all expected values', () {
      expect(MetaDatPermission.values, hasLength(1));
      expect(MetaDatPermission.values, contains(MetaDatPermission.camera));
    });

    test('MetaDatPermissionStatus has all expected values', () {
      expect(MetaDatPermissionStatus.values, hasLength(2));
      expect(
        MetaDatPermissionStatus.values,
        containsAll([
          MetaDatPermissionStatus.granted,
          MetaDatPermissionStatus.denied,
        ]),
      );
    });
  });

  group('MethodChannelMetaDat', () {
    late MethodChannelMetaDat platform;
    final List<MethodCall> log = [];

    setUp(() {
      platform = MethodChannelMetaDat();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('meta_dat'),
        (MethodCall methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'configure':
              return null;
            case 'getRegistrationState':
              return 'unregistered';
            case 'getDevices':
              return [
                {'identifier': 'device-1', 'name': 'Test Device'},
              ];
            case 'startRegistration':
              return null;
            case 'startUnregistration':
              return null;
            case 'handleUrl':
              return true;
            case 'checkPermissionStatus':
              return 'granted';
            case 'requestPermission':
              return 'denied';
            case 'createStreamSession':
              return 'session-123';
            case 'startStreamSession':
              return null;
            case 'stopStreamSession':
              return null;
            case 'capturePhoto':
              return null;
            case 'getStreamSessionState':
              return 'streaming';
            case 'disposeStreamSession':
              return null;
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('meta_dat'), null);
    });

    test('configure calls platform method', () async {
      await platform.configure();
      expect(log, hasLength(1));
      expect(log.last.method, 'configure');
    });

    test('getRegistrationState returns correct state', () async {
      final state = await platform.getRegistrationState();
      expect(state, RegistrationState.unregistered);
    });

    test('getDevices returns list of devices', () async {
      final devices = await platform.getDevices();
      expect(devices, hasLength(1));
      expect(devices.first.identifier, 'device-1');
      expect(devices.first.name, 'Test Device');
    });

    test('startRegistration calls platform method', () async {
      await platform.startRegistration();
      expect(log.last.method, 'startRegistration');
    });

    test('startUnregistration calls platform method', () async {
      await platform.startUnregistration();
      expect(log.last.method, 'startUnregistration');
    });

    test('handleUrl calls platform method with URL', () async {
      final result = await platform.handleUrl('myapp://callback');
      expect(result, true);
      expect(log.last.method, 'handleUrl');
      expect(
        (log.last.arguments as Map)['url'],
        'myapp://callback',
      );
    });

    test('checkPermissionStatus returns correct status', () async {
      final status =
          await platform.checkPermissionStatus(MetaDatPermission.camera);
      expect(status, MetaDatPermissionStatus.granted);
    });

    test('requestPermission returns correct status', () async {
      final status =
          await platform.requestPermission(MetaDatPermission.camera);
      expect(status, MetaDatPermissionStatus.denied);
    });

    test('createStreamSession returns session ID', () async {
      final sessionId = await platform.createStreamSession(
        config: const StreamSessionConfig(),
        deviceSelector: AutoDeviceSelector().toMap(),
      );
      expect(sessionId, 'session-123');
    });

    test('startStreamSession calls platform method', () async {
      await platform.startStreamSession('session-123');
      expect(log.last.method, 'startStreamSession');
      expect(
        (log.last.arguments as Map)['sessionId'],
        'session-123',
      );
    });

    test('stopStreamSession calls platform method', () async {
      await platform.stopStreamSession('session-123');
      expect(log.last.method, 'stopStreamSession');
    });

    test('capturePhoto calls platform method', () async {
      await platform.capturePhoto('session-123', PhotoFormat.jpeg);
      expect(log.last.method, 'capturePhoto');
      expect(
        (log.last.arguments as Map)['format'],
        'jpeg',
      );
    });

    test('getStreamSessionState returns correct state', () async {
      final state = await platform.getStreamSessionState('session-123');
      expect(state, StreamSessionState.streaming);
    });

    test('disposeStreamSession calls platform method', () async {
      await platform.disposeStreamSession('session-123');
      expect(log.last.method, 'disposeStreamSession');
    });
  });

  group('MetaDatPlatform', () {
    test('default instance is MethodChannelMetaDat', () {
      expect(MetaDatPlatform.instance, isA<MethodChannelMetaDat>());
    });

    test('cannot set instance with wrong token', () {
      expect(
        () => MetaDatPlatform.instance = _FakePlatform(),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}

class _FakePlatform extends MetaDatPlatform {}
