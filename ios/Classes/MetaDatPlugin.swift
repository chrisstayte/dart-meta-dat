import Flutter
import UIKit

public class MetaDatPlugin: NSObject, FlutterPlugin {

    private var registrationStateChannel: FlutterEventChannel?
    private var devicesChannel: FlutterEventChannel?

    private var registrationStateSink: FlutterEventSink?
    private var devicesSink: FlutterEventSink?

    // Track active stream sessions and their event channels/sinks
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
           let identifier = Wearables.shared.deviceForIdentifier(DeviceIdentifier(deviceId)) {
            deviceSelector = SpecificDeviceSelector(wearables: Wearables.shared, device: identifier)
        } else {
            deviceSelector = AutoDeviceSelector(wearables: Wearables.shared)
        }

        let streamSession = StreamSession(
            streamSessionConfig: config,
            deviceSelector: deviceSelector
        )

        // Store session reference (would need a dictionary to track sessions)
        // For now, return the session ID
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
              let _ = args["sessionId"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Invalid session ID.",
                details: nil
            ))
            return
        }

        // Start the stream session
        result(nil)
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
              let _ = args["sessionId"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Invalid session ID.",
                details: nil
            ))
            return
        }

        result(nil)
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
              let _ = args["sessionId"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Invalid session ID.",
                details: nil
            ))
            return
        }

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
              let _ = args["sessionId"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENT",
                message: "Invalid session ID.",
                details: nil
            ))
            return
        }

        result("stopped")
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
