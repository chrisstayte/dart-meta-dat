import Flutter
import UIKit

#if canImport(MWDATCore)
import MWDATCore
#endif

#if canImport(MWDATCamera)
import MWDATCamera
#endif

public class MetaDatPlugin: NSObject, FlutterPlugin {

    private var registrationStateChannel: FlutterEventChannel?
    private var devicesChannel: FlutterEventChannel?

    private var registrationStateSink: FlutterEventSink?
    private var devicesSink: FlutterEventSink?

    private var messenger: FlutterBinaryMessenger?

    // Track active stream sessions
    #if canImport(MWDATCamera)
    private var streamSessions: [String: StreamSession] = [:]
    #endif

    // Track event channels and sinks per session
    private var streamSessionStateChannels: [String: FlutterEventChannel] = [:]
    private var streamSessionVideoFrameChannels: [String: FlutterEventChannel] = [:]
    private var streamSessionErrorChannels: [String: FlutterEventChannel] = [:]
    private var streamSessionPhotoDataChannels: [String: FlutterEventChannel] = [:]

    private var streamSessionStateSinks: [String: FlutterEventSink] = [:]
    private var streamSessionVideoFrameSinks: [String: FlutterEventSink] = [:]
    private var streamSessionErrorSinks: [String: FlutterEventSink] = [:]
    private var streamSessionPhotoDataSinks: [String: FlutterEventSink] = [:]

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "meta_dat",
            binaryMessenger: registrar.messenger()
        )
        let instance = MetaDatPlugin()
        instance.messenger = registrar.messenger()
        registrar.addMethodCallDelegate(instance, channel: channel)

        // Set up event channels
        instance.registrationStateChannel = FlutterEventChannel(
            name: "meta_dat/registration_state",
            binaryMessenger: registrar.messenger()
        )
        instance.registrationStateChannel?.setStreamHandler(
            EventStreamHandler { sink in
                instance.registrationStateSink = sink
            } onCancel: {
                instance.registrationStateSink = nil
            }
        )

        instance.devicesChannel = FlutterEventChannel(
            name: "meta_dat/devices",
            binaryMessenger: registrar.messenger()
        )
        instance.devicesChannel?.setStreamHandler(
            EventStreamHandler { sink in
                instance.devicesSink = sink
            } onCancel: {
                instance.devicesSink = nil
            }
        )
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "configure":
            handleConfigure(result: result)
        case "getRegistrationState":
            handleGetRegistrationState(result: result)
        case "getDevices":
            handleGetDevices(result: result)
        case "startRegistration":
            handleStartRegistration(result: result)
        case "startUnregistration":
            handleStartUnregistration(result: result)
        case "handleUrl":
            handleHandleUrl(call: call, result: result)
        case "checkPermissionStatus":
            handleCheckPermissionStatus(call: call, result: result)
        case "requestPermission":
            handleRequestPermission(call: call, result: result)
        case "createStreamSession":
            handleCreateStreamSession(call: call, result: result)
        case "startStreamSession":
            handleStartStreamSession(call: call, result: result)
        case "stopStreamSession":
            handleStopStreamSession(call: call, result: result)
        case "capturePhoto":
            handleCapturePhoto(call: call, result: result)
        case "getStreamSessionState":
            handleGetStreamSessionState(call: call, result: result)
        case "disposeStreamSession":
            handleDisposeStreamSession(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Core Methods

    private func handleConfigure(result: @escaping FlutterResult) {
        #if canImport(MWDATCore)
        do {
            try Wearables.configure()
            setupWearablesListeners()
            result(nil)
        } catch {
            result(FlutterError(
                code: "CONFIGURE_ERROR",
                message: "Failed to configure Meta Wearables SDK: \(error.localizedDescription)",
                details: nil
            ))
        }
        #else
        result(FlutterError(
            code: "SDK_NOT_AVAILABLE",
            message: "MWDATCore SDK is not available. Add the Meta Wearables DAT iOS SDK to your project.",
            details: nil
        ))
        #endif
    }

    private func handleGetRegistrationState(result: @escaping FlutterResult) {
        #if canImport(MWDATCore)
        let state = Wearables.shared.registrationState
        result(registrationStateToString(state))
        #else
        result(FlutterError(
            code: "SDK_NOT_AVAILABLE",
            message: "MWDATCore SDK is not available.",
            details: nil
        ))
        #endif
    }

    private func handleGetDevices(result: @escaping FlutterResult) {
        #if canImport(MWDATCore)
        let devices = Wearables.shared.devices
        let deviceList = devices.map { device -> [String: Any?] in
            return [
                "identifier": "\(device)",
                "name": nil
            ]
        }
        result(deviceList)
        #else
        result(FlutterError(
            code: "SDK_NOT_AVAILABLE",
            message: "MWDATCore SDK is not available.",
            details: nil
        ))
        #endif
    }

    private func handleStartRegistration(result: @escaping FlutterResult) {
        #if canImport(MWDATCore)
        Task {
            do {
                try await Wearables.shared.startRegistration()
                DispatchQueue.main.async {
                    result(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "REGISTRATION_ERROR",
                        message: "Failed to start registration: \(error.localizedDescription)",
                        details: nil
                    ))
                }
            }
        }
        #else
        result(FlutterError(
            code: "SDK_NOT_AVAILABLE",
            message: "MWDATCore SDK is not available.",
            details: nil
        ))
        #endif
    }

    private func handleStartUnregistration(result: @escaping FlutterResult) {
        #if canImport(MWDATCore)
        Task {
            do {
                try await Wearables.shared.startUnregistration()
                DispatchQueue.main.async {
                    result(nil)
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "UNREGISTRATION_ERROR",
                        message: "Failed to start unregistration: \(error.localizedDescription)",
                        details: nil
                    ))
                }
            }
        }
        #else
        result(FlutterError(
            code: "SDK_NOT_AVAILABLE",
            message: "MWDATCore SDK is not available.",
            details: nil
        ))
        #endif
    }

    private func handleHandleUrl(call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if canImport(MWDATCore)
        guard let args = call.arguments as? [String: Any],
              let urlString = args["url"] as? String,
              let url = URL(string: urlString) else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Invalid URL argument.",
                details: nil
            ))
            return
        }

        Task {
            do {
                let handled = try await Wearables.shared.handleUrl(url)
                DispatchQueue.main.async {
                    result(handled)
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "HANDLE_URL_ERROR",
                        message: "Failed to handle URL: \(error.localizedDescription)",
                        details: nil
                    ))
                }
            }
        }
        #else
        result(FlutterError(
            code: "SDK_NOT_AVAILABLE",
            message: "MWDATCore SDK is not available.",
            details: nil
        ))
        #endif
    }

    private func handleCheckPermissionStatus(call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if canImport(MWDATCore)
        Task {
            do {
                let status = try await Wearables.shared.checkPermissionStatus(.camera)
                DispatchQueue.main.async {
                    result(self.permissionStatusToString(status))
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "PERMISSION_ERROR",
                        message: "Failed to check permission status: \(error.localizedDescription)",
                        details: nil
                    ))
                }
            }
        }
        #else
        result(FlutterError(
            code: "SDK_NOT_AVAILABLE",
            message: "MWDATCore SDK is not available.",
            details: nil
        ))
        #endif
    }

    private func handleRequestPermission(call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if canImport(MWDATCore)
        Task {
            do {
                let status = try await Wearables.shared.requestPermission(.camera)
                DispatchQueue.main.async {
                    result(self.permissionStatusToString(status))
                }
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "PERMISSION_ERROR",
                        message: "Failed to request permission: \(error.localizedDescription)",
                        details: nil
                    ))
                }
            }
        }
        #else
        result(FlutterError(
            code: "SDK_NOT_AVAILABLE",
            message: "MWDATCore SDK is not available.",
            details: nil
        ))
        #endif
    }

    // MARK: - Stream Session Methods

    private func handleCreateStreamSession(call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if canImport(MWDATCore) && canImport(MWDATCamera)
        guard let args = call.arguments as? [String: Any],
              let configMap = args["config"] as? [String: Any],
              let selectorMap = args["deviceSelector"] as? [String: Any] else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Invalid stream session arguments.",
                details: nil
            ))
            return
        }

        let sessionId = UUID().uuidString

        // Parse config
        let videoCodecStr = configMap["videoCodec"] as? String ?? "raw"
        let resolutionStr = configMap["resolution"] as? String ?? "low"
        let frameRate = configMap["frameRate"] as? Int ?? 24

        let videoCodec: VideoCodec = videoCodecStr == "hvc1" ? .hvc1 : .raw
        let resolution: StreamingResolution
        switch resolutionStr {
        case "medium": resolution = .medium
        case "high": resolution = .high
        default: resolution = .low
        }

        let config = StreamSessionConfig(
            videoCodec: videoCodec,
            resolution: resolution,
            frameRate: frameRate
        )

        // Parse device selector
        let selectorType = selectorMap["type"] as? String ?? "auto"
        let deviceSelector: DeviceSelector
        if selectorType == "specific",
           let deviceId = selectorMap["deviceIdentifier"] as? String,
           let device = Wearables.shared.deviceForIdentifier(DeviceIdentifier(deviceId)) {
            deviceSelector = SpecificDeviceSelector(wearables: Wearables.shared, device: device)
        } else {
            deviceSelector = AutoDeviceSelector(wearables: Wearables.shared)
        }

        let streamSession = StreamSession(
            streamSessionConfig: config,
            deviceSelector: deviceSelector
        )

        // Store session for later use
        streamSessions[sessionId] = streamSession

        // Set up event channels for this session
        setupStreamSessionEventChannels(sessionId: sessionId, session: streamSession)

        result(sessionId)
        #else
        result(FlutterError(
            code: "SDK_NOT_AVAILABLE",
            message: "MWDATCore and MWDATCamera SDKs are not available.",
            details: nil
        ))
        #endif
    }

    private func handleStartStreamSession(call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if canImport(MWDATCamera)
        guard let args = call.arguments as? [String: Any],
              let sessionId = args["sessionId"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Invalid session ID.",
                details: nil
            ))
            return
        }

        guard let session = streamSessions[sessionId] else {
            result(FlutterError(
                code: "SESSION_NOT_FOUND",
                message: "Stream session not found for ID: \(sessionId)",
                details: nil
            ))
            return
        }

        Task {
            await session.start()
            DispatchQueue.main.async {
                result(nil)
            }
        }
        #else
        result(FlutterError(
            code: "SDK_NOT_AVAILABLE",
            message: "MWDATCamera SDK is not available.",
            details: nil
        ))
        #endif
    }

    private func handleStopStreamSession(call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if canImport(MWDATCamera)
        guard let args = call.arguments as? [String: Any],
              let sessionId = args["sessionId"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Invalid session ID.",
                details: nil
            ))
            return
        }

        guard let session = streamSessions[sessionId] else {
            result(FlutterError(
                code: "SESSION_NOT_FOUND",
                message: "Stream session not found for ID: \(sessionId)",
                details: nil
            ))
            return
        }

        Task {
            await session.stop()
            DispatchQueue.main.async {
                result(nil)
            }
        }
        #else
        result(FlutterError(
            code: "SDK_NOT_AVAILABLE",
            message: "MWDATCamera SDK is not available.",
            details: nil
        ))
        #endif
    }

    private func handleCapturePhoto(call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if canImport(MWDATCamera)
        guard let args = call.arguments as? [String: Any],
              let sessionId = args["sessionId"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Invalid session ID.",
                details: nil
            ))
            return
        }

        guard let session = streamSessions[sessionId] else {
            result(FlutterError(
                code: "SESSION_NOT_FOUND",
                message: "Stream session not found for ID: \(sessionId)",
                details: nil
            ))
            return
        }

        let formatStr = args["format"] as? String ?? "jpeg"
        let format: PhotoFormat = formatStr == "heic" ? .heic : .jpeg
        session.capturePhoto(format: format)
        result(nil)
        #else
        result(FlutterError(
            code: "SDK_NOT_AVAILABLE",
            message: "MWDATCamera SDK is not available.",
            details: nil
        ))
        #endif
    }

    private func handleGetStreamSessionState(call: FlutterMethodCall, result: @escaping FlutterResult) {
        #if canImport(MWDATCamera)
        guard let args = call.arguments as? [String: Any],
              let sessionId = args["sessionId"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Invalid session ID.",
                details: nil
            ))
            return
        }

        guard let session = streamSessions[sessionId] else {
            result(FlutterError(
                code: "SESSION_NOT_FOUND",
                message: "Stream session not found for ID: \(sessionId)",
                details: nil
            ))
            return
        }

        result(streamSessionStateToString(session.state))
        #else
        result(FlutterError(
            code: "SDK_NOT_AVAILABLE",
            message: "MWDATCamera SDK is not available.",
            details: nil
        ))
        #endif
    }

    private func handleDisposeStreamSession(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let sessionId = args["sessionId"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Invalid session ID.",
                details: nil
            ))
            return
        }

        // Remove session reference
        #if canImport(MWDATCamera)
        streamSessions.removeValue(forKey: sessionId)
        #endif

        // Clean up event channels for this session
        streamSessionStateChannels.removeValue(forKey: sessionId)
        streamSessionVideoFrameChannels.removeValue(forKey: sessionId)
        streamSessionErrorChannels.removeValue(forKey: sessionId)
        streamSessionPhotoDataChannels.removeValue(forKey: sessionId)
        streamSessionStateSinks.removeValue(forKey: sessionId)
        streamSessionVideoFrameSinks.removeValue(forKey: sessionId)
        streamSessionErrorSinks.removeValue(forKey: sessionId)
        streamSessionPhotoDataSinks.removeValue(forKey: sessionId)

        result(nil)
    }

    // MARK: - Helpers

    private func setupWearablesListeners() {
        #if canImport(MWDATCore)
        Task {
            for await state in Wearables.shared.registrationStateStream() {
                DispatchQueue.main.async {
                    self.registrationStateSink?(self.registrationStateToString(state))
                }
            }
        }

        Task {
            for await devices in Wearables.shared.devicesStream() {
                let deviceList = devices.map { device -> [String: Any?] in
                    return [
                        "identifier": "\(device)",
                        "name": nil
                    ]
                }
                DispatchQueue.main.async {
                    self.devicesSink?(deviceList)
                }
            }
        }
        #endif
    }

    #if canImport(MWDATCamera)
    private func setupStreamSessionEventChannels(sessionId: String, session: StreamSession) {
        guard let messenger = self.messenger else { return }

        // State event channel
        let stateChannel = FlutterEventChannel(
            name: "meta_dat/stream_session/\(sessionId)/state",
            binaryMessenger: messenger
        )
        stateChannel.setStreamHandler(
            EventStreamHandler { [weak self] sink in
                self?.streamSessionStateSinks[sessionId] = sink
            } onCancel: { [weak self] in
                self?.streamSessionStateSinks[sessionId] = nil
            }
        )
        streamSessionStateChannels[sessionId] = stateChannel

        // Video frame event channel
        let videoFrameChannel = FlutterEventChannel(
            name: "meta_dat/stream_session/\(sessionId)/video_frame",
            binaryMessenger: messenger
        )
        videoFrameChannel.setStreamHandler(
            EventStreamHandler { [weak self] sink in
                self?.streamSessionVideoFrameSinks[sessionId] = sink
            } onCancel: { [weak self] in
                self?.streamSessionVideoFrameSinks[sessionId] = nil
            }
        )
        streamSessionVideoFrameChannels[sessionId] = videoFrameChannel

        // Error event channel
        let errorChannel = FlutterEventChannel(
            name: "meta_dat/stream_session/\(sessionId)/error",
            binaryMessenger: messenger
        )
        errorChannel.setStreamHandler(
            EventStreamHandler { [weak self] sink in
                self?.streamSessionErrorSinks[sessionId] = sink
            } onCancel: { [weak self] in
                self?.streamSessionErrorSinks[sessionId] = nil
            }
        )
        streamSessionErrorChannels[sessionId] = errorChannel

        // Photo data event channel
        let photoDataChannel = FlutterEventChannel(
            name: "meta_dat/stream_session/\(sessionId)/photo_data",
            binaryMessenger: messenger
        )
        photoDataChannel.setStreamHandler(
            EventStreamHandler { [weak self] sink in
                self?.streamSessionPhotoDataSinks[sessionId] = sink
            } onCancel: { [weak self] in
                self?.streamSessionPhotoDataSinks[sessionId] = nil
            }
        )
        streamSessionPhotoDataChannels[sessionId] = photoDataChannel

        // Subscribe to session publishers
        _ = session.statePublisher.listen { [weak self] state in
            DispatchQueue.main.async {
                self?.streamSessionStateSinks[sessionId]?(
                    self?.streamSessionStateToString(state) ?? "stopped"
                )
            }
        }

        _ = session.videoFramePublisher.listen { [weak self] videoFrame in
            guard let uiImage = videoFrame.makeUIImage(),
                  let imageData = uiImage.jpegData(compressionQuality: 0.8) else { return }
            let frameData: [String: Any] = [
                "data": FlutterStandardTypedData(bytes: imageData),
                "width": Int(uiImage.size.width),
                "height": Int(uiImage.size.height),
                "timestamp": Int(Date().timeIntervalSince1970 * 1000)
            ]
            DispatchQueue.main.async {
                self?.streamSessionVideoFrameSinks[sessionId]?(frameData)
            }
        }

        _ = session.errorPublisher.listen { [weak self] error in
            DispatchQueue.main.async {
                self?.streamSessionErrorSinks[sessionId]?(
                    self?.streamSessionErrorToString(error) ?? "internalError"
                )
            }
        }

        _ = session.photoDataPublisher.listen { [weak self] photoData in
            let photoMap: [String: Any] = [
                "data": FlutterStandardTypedData(bytes: photoData.data),
                "format": "jpeg"
            ]
            DispatchQueue.main.async {
                self?.streamSessionPhotoDataSinks[sessionId]?(photoMap)
            }
        }
    }

    private func streamSessionStateToString(_ state: StreamSessionState) -> String {
        switch state {
        case .stopped: return "stopped"
        case .waitingForDevice: return "waitingForDevice"
        case .starting: return "starting"
        case .streaming: return "streaming"
        case .stopping: return "stopping"
        case .paused: return "paused"
        @unknown default: return "stopped"
        }
    }

    private func streamSessionErrorToString(_ error: StreamSessionError) -> String {
        switch error {
        case .internalError: return "internalError"
        case .deviceNotFound: return "deviceNotFound"
        case .deviceNotConnected: return "deviceNotConnected"
        case .timeout: return "timeout"
        case .videoStreamingError: return "videoStreamingError"
        case .permissionDenied: return "permissionDenied"
        case .hingesClosed: return "hingesClosed"
        case .thermalCritical: return "thermalCritical"
        @unknown default: return "internalError"
        }
    }
    #endif

    #if canImport(MWDATCore)
    private func registrationStateToString(_ state: RegistrationState) -> String {
        switch state {
        case .registering: return "registering"
        case .registered: return "registered"
        case .unregistering: return "unregistering"
        case .unregistered: return "unregistered"
        @unknown default: return "unregistered"
        }
    }

    private func permissionStatusToString(_ status: PermissionStatus) -> String {
        switch status {
        case .granted: return "granted"
        case .denied: return "denied"
        @unknown default: return "denied"
        }
    }
    #endif
}

// MARK: - Event Stream Handler

private class EventStreamHandler: NSObject, FlutterStreamHandler {
    private let onListenCallback: (FlutterEventSink) -> Void
    private let onCancelCallback: () -> Void

    init(onListen: @escaping (FlutterEventSink) -> Void, onCancel: @escaping () -> Void) {
        self.onListenCallback = onListen
        self.onCancelCallback = onCancel
    }

    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        onListenCallback(events)
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        onCancelCallback()
        return nil
    }
}
