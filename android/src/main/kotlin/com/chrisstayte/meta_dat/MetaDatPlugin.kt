package com.chrisstayte.meta_dat

import android.app.Activity
import android.content.Context
import android.net.Uri
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.util.UUID

/**
 * Flutter plugin wrapping the Meta Wearables DAT Android SDK.
 *
 * Uses method channels and event channels to communicate with Dart,
 * mirroring the iOS implementation's channel structure.
 */
class MetaDatPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var methodChannel: MethodChannel
    private lateinit var registrationStateChannel: EventChannel
    private lateinit var devicesChannel: EventChannel

    private var registrationStateSink: EventChannel.EventSink? = null
    private var devicesSink: EventChannel.EventSink? = null

    private var context: Context? = null
    private var activity: Activity? = null
    private var messenger: io.flutter.plugin.common.BinaryMessenger? = null

    // Track event channels and sinks per stream session
    private val streamSessionStateChannels = mutableMapOf<String, EventChannel>()
    private val streamSessionVideoFrameChannels = mutableMapOf<String, EventChannel>()
    private val streamSessionErrorChannels = mutableMapOf<String, EventChannel>()
    private val streamSessionPhotoDataChannels = mutableMapOf<String, EventChannel>()

    private val streamSessionStateSinks = mutableMapOf<String, EventChannel.EventSink?>()
    private val streamSessionVideoFrameSinks = mutableMapOf<String, EventChannel.EventSink?>()
    private val streamSessionErrorSinks = mutableMapOf<String, EventChannel.EventSink?>()
    private val streamSessionPhotoDataSinks = mutableMapOf<String, EventChannel.EventSink?>()

    // SDK availability flag
    private var isSdkAvailable = false

    // Native SDK references (only set when SDK is available)
    private var wearablesInstance: Any? = null
    private var streamSessions: MutableMap<String, Any> = mutableMapOf()

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        messenger = binding.binaryMessenger
        context = binding.applicationContext

        methodChannel = MethodChannel(binding.binaryMessenger, "meta_dat")
        methodChannel.setMethodCallHandler(this)

        registrationStateChannel = EventChannel(binding.binaryMessenger, "meta_dat/registration_state")
        registrationStateChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                registrationStateSink = events
            }

            override fun onCancel(arguments: Any?) {
                registrationStateSink = null
            }
        })

        devicesChannel = EventChannel(binding.binaryMessenger, "meta_dat/devices")
        devicesChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                devicesSink = events
            }

            override fun onCancel(arguments: Any?) {
                devicesSink = null
            }
        })

        // Check if the Meta Wearables DAT Android SDK is available
        isSdkAvailable = checkSdkAvailability()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        registrationStateChannel.setStreamHandler(null)
        devicesChannel.setStreamHandler(null)
        messenger = null
        context = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "configure" -> handleConfigure(result)
            "getRegistrationState" -> handleGetRegistrationState(result)
            "getDevices" -> handleGetDevices(result)
            "startRegistration" -> handleStartRegistration(result)
            "startUnregistration" -> handleStartUnregistration(result)
            "handleUrl" -> handleHandleUrl(call, result)
            "checkPermissionStatus" -> handleCheckPermissionStatus(call, result)
            "requestPermission" -> handleRequestPermission(call, result)
            "createStreamSession" -> handleCreateStreamSession(call, result)
            "startStreamSession" -> handleStartStreamSession(call, result)
            "stopStreamSession" -> handleStopStreamSession(call, result)
            "capturePhoto" -> handleCapturePhoto(call, result)
            "getStreamSessionState" -> handleGetStreamSessionState(call, result)
            "disposeStreamSession" -> handleDisposeStreamSession(call, result)
            else -> result.notImplemented()
        }
    }

    // MARK: - SDK Availability

    private fun checkSdkAvailability(): Boolean {
        return try {
            Class.forName("com.meta.wearable.mwdat.core.Wearables")
            true
        } catch (e: ClassNotFoundException) {
            false
        }
    }

    private fun checkCameraSdkAvailability(): Boolean {
        return try {
            Class.forName("com.meta.wearable.mwdat.camera.StreamSession")
            true
        } catch (e: ClassNotFoundException) {
            false
        }
    }

    // MARK: - Core Methods

    private fun handleConfigure(result: Result) {
        if (!isSdkAvailable) {
            result.error(
                "SDK_NOT_AVAILABLE",
                "MWDATCore SDK is not available. Add the Meta Wearables DAT Android SDK to your project.",
                null
            )
            return
        }

        try {
            val ctx = context
            if (ctx == null) {
                result.error("CONFIGURE_ERROR", "Android context is not available.", null)
                return
            }

            // Use reflection to call Wearables.initialize(context)
            val wearablesClass = Class.forName("com.meta.wearable.mwdat.core.Wearables")
            val initMethod = wearablesClass.getMethod("initialize", Context::class.java)
            initMethod.invoke(null, ctx)

            // Get the Wearables singleton instance
            val getInstanceMethod = wearablesClass.getMethod("getInstance")
            wearablesInstance = getInstanceMethod.invoke(null)

            setupWearablesListeners()
            result.success(null)
        } catch (e: Exception) {
            result.error(
                "CONFIGURE_ERROR",
                "Failed to configure Meta Wearables SDK: ${e.message}",
                null
            )
        }
    }

    private fun handleGetRegistrationState(result: Result) {
        if (!isSdkAvailable || wearablesInstance == null) {
            result.error("SDK_NOT_AVAILABLE", "MWDATCore SDK is not available.", null)
            return
        }

        try {
            val wearables = wearablesInstance!!
            val method = wearables.javaClass.getMethod("getRegistrationState")
            val state = method.invoke(wearables)
            result.success(registrationStateToString(state))
        } catch (e: Exception) {
            result.error(
                "STATE_ERROR",
                "Failed to get registration state: ${e.message}",
                null
            )
        }
    }

    private fun handleGetDevices(result: Result) {
        if (!isSdkAvailable || wearablesInstance == null) {
            result.error("SDK_NOT_AVAILABLE", "MWDATCore SDK is not available.", null)
            return
        }

        try {
            val wearables = wearablesInstance!!
            val method = wearables.javaClass.getMethod("getDevices")
            val devices = method.invoke(wearables) as? List<*> ?: emptyList<Any>()
            val deviceList = devices.map { device ->
                mapOf(
                    "identifier" to device.toString(),
                    "name" to null
                )
            }
            result.success(deviceList)
        } catch (e: Exception) {
            result.error(
                "DEVICES_ERROR",
                "Failed to get devices: ${e.message}",
                null
            )
        }
    }

    private fun handleStartRegistration(result: Result) {
        if (!isSdkAvailable || wearablesInstance == null) {
            result.error("SDK_NOT_AVAILABLE", "MWDATCore SDK is not available.", null)
            return
        }

        try {
            val wearables = wearablesInstance!!
            val act = activity
            if (act == null) {
                result.error("REGISTRATION_ERROR", "Activity is not available.", null)
                return
            }

            val method = wearables.javaClass.getMethod("startRegistration", Activity::class.java)
            method.invoke(wearables, act)
            result.success(null)
        } catch (e: Exception) {
            result.error(
                "REGISTRATION_ERROR",
                "Failed to start registration: ${e.message}",
                null
            )
        }
    }

    private fun handleStartUnregistration(result: Result) {
        if (!isSdkAvailable || wearablesInstance == null) {
            result.error("SDK_NOT_AVAILABLE", "MWDATCore SDK is not available.", null)
            return
        }

        try {
            val wearables = wearablesInstance!!
            val method = wearables.javaClass.getMethod("startUnregistration")
            method.invoke(wearables)
            result.success(null)
        } catch (e: Exception) {
            result.error(
                "UNREGISTRATION_ERROR",
                "Failed to start unregistration: ${e.message}",
                null
            )
        }
    }

    private fun handleHandleUrl(call: MethodCall, result: Result) {
        if (!isSdkAvailable || wearablesInstance == null) {
            result.error("SDK_NOT_AVAILABLE", "MWDATCore SDK is not available.", null)
            return
        }

        val url = call.argument<String>("url")
        if (url == null) {
            result.error("INVALID_ARGUMENT", "Invalid URL argument.", null)
            return
        }

        try {
            val wearables = wearablesInstance!!
            val uri = Uri.parse(url)
            val method = wearables.javaClass.getMethod("handleUrl", Uri::class.java)
            val handled = method.invoke(wearables, uri) as? Boolean ?: false
            result.success(handled)
        } catch (e: Exception) {
            result.error(
                "HANDLE_URL_ERROR",
                "Failed to handle URL: ${e.message}",
                null
            )
        }
    }

    private fun handleCheckPermissionStatus(call: MethodCall, result: Result) {
        if (!isSdkAvailable || wearablesInstance == null) {
            result.error("SDK_NOT_AVAILABLE", "MWDATCore SDK is not available.", null)
            return
        }

        try {
            val wearables = wearablesInstance!!
            val method = wearables.javaClass.getMethod("checkPermissionStatus")
            val status = method.invoke(wearables)
            result.success(permissionStatusToString(status))
        } catch (e: Exception) {
            result.error(
                "PERMISSION_ERROR",
                "Failed to check permission status: ${e.message}",
                null
            )
        }
    }

    private fun handleRequestPermission(call: MethodCall, result: Result) {
        if (!isSdkAvailable || wearablesInstance == null) {
            result.error("SDK_NOT_AVAILABLE", "MWDATCore SDK is not available.", null)
            return
        }

        try {
            val wearables = wearablesInstance!!
            val act = activity
            if (act == null) {
                result.error("PERMISSION_ERROR", "Activity is not available.", null)
                return
            }

            val method = wearables.javaClass.getMethod("requestPermission", Activity::class.java)
            val status = method.invoke(wearables, act)
            result.success(permissionStatusToString(status))
        } catch (e: Exception) {
            result.error(
                "PERMISSION_ERROR",
                "Failed to request permission: ${e.message}",
                null
            )
        }
    }

    // MARK: - Stream Session Methods

    private fun handleCreateStreamSession(call: MethodCall, result: Result) {
        if (!isSdkAvailable || !checkCameraSdkAvailability()) {
            result.error(
                "SDK_NOT_AVAILABLE",
                "MWDATCore and MWDATCamera SDKs are not available.",
                null
            )
            return
        }

        val configMap = call.argument<Map<String, Any>>("config")
        val selectorMap = call.argument<Map<String, Any>>("deviceSelector")

        if (configMap == null || selectorMap == null) {
            result.error("INVALID_ARGUMENT", "Invalid stream session arguments.", null)
            return
        }

        try {
            val sessionId = UUID.randomUUID().toString()

            // Parse config
            val videoCodecStr = configMap["videoCodec"] as? String ?: "raw"
            val resolutionStr = configMap["resolution"] as? String ?: "low"
            val frameRate = configMap["frameRate"] as? Int ?: 24

            // Use reflection to create the stream session config and session
            val configClass = Class.forName("com.meta.wearable.mwdat.camera.StreamSessionConfig")
            val configBuilder = configClass.getMethod("builder").invoke(null)
            val builderClass = configBuilder.javaClass

            // Set video codec
            val videoCodecClass = Class.forName("com.meta.wearable.mwdat.camera.VideoCodec")
            val videoCodec = if (videoCodecStr == "hvc1") {
                videoCodecClass.getField("HVC1").get(null)
            } else {
                videoCodecClass.getField("RAW").get(null)
            }
            builderClass.getMethod("setVideoCodec", videoCodecClass).invoke(configBuilder, videoCodec)

            // Set resolution
            val resolutionClass = Class.forName("com.meta.wearable.mwdat.camera.StreamingResolution")
            val resolution = when (resolutionStr) {
                "medium" -> resolutionClass.getField("MEDIUM").get(null)
                "high" -> resolutionClass.getField("HIGH").get(null)
                else -> resolutionClass.getField("LOW").get(null)
            }
            builderClass.getMethod("setResolution", resolutionClass).invoke(configBuilder, resolution)

            // Set frame rate
            builderClass.getMethod("setFrameRate", Int::class.java).invoke(configBuilder, frameRate)

            val streamConfig = builderClass.getMethod("build").invoke(configBuilder)

            // Parse device selector
            val selectorType = selectorMap["type"] as? String ?: "auto"
            val wearables = wearablesInstance!!

            val deviceSelector: Any
            if (selectorType == "specific") {
                val deviceId = selectorMap["deviceIdentifier"] as? String
                val selectorClass = Class.forName("com.meta.wearable.mwdat.core.SpecificDeviceSelector")
                deviceSelector = selectorClass.getConstructor(String::class.java).newInstance(deviceId)
            } else {
                val selectorClass = Class.forName("com.meta.wearable.mwdat.core.AutoDeviceSelector")
                deviceSelector = selectorClass.getConstructor(wearables.javaClass).newInstance(wearables)
            }

            // Create StreamSession
            val sessionClass = Class.forName("com.meta.wearable.mwdat.camera.StreamSession")
            val deviceSelectorInterface = Class.forName("com.meta.wearable.mwdat.core.DeviceSelector")
            val streamSession = sessionClass.getConstructor(
                streamConfig.javaClass,
                deviceSelectorInterface
            ).newInstance(streamConfig, deviceSelector)

            streamSessions[sessionId] = streamSession

            // Set up event channels for this session
            setupStreamSessionEventChannels(sessionId, streamSession)

            result.success(sessionId)
        } catch (e: Exception) {
            result.error(
                "CREATE_SESSION_ERROR",
                "Failed to create stream session: ${e.message}",
                null
            )
        }
    }

    private fun handleStartStreamSession(call: MethodCall, result: Result) {
        val sessionId = call.argument<String>("sessionId")
        if (sessionId == null) {
            result.error("INVALID_ARGUMENT", "Invalid session ID.", null)
            return
        }

        val session = streamSessions[sessionId]
        if (session == null) {
            result.error(
                "SESSION_NOT_FOUND",
                "Stream session not found for ID: $sessionId",
                null
            )
            return
        }

        try {
            val method = session.javaClass.getMethod("start")
            method.invoke(session)
            result.success(null)
        } catch (e: Exception) {
            result.error(
                "START_SESSION_ERROR",
                "Failed to start stream session: ${e.message}",
                null
            )
        }
    }

    private fun handleStopStreamSession(call: MethodCall, result: Result) {
        val sessionId = call.argument<String>("sessionId")
        if (sessionId == null) {
            result.error("INVALID_ARGUMENT", "Invalid session ID.", null)
            return
        }

        val session = streamSessions[sessionId]
        if (session == null) {
            result.error(
                "SESSION_NOT_FOUND",
                "Stream session not found for ID: $sessionId",
                null
            )
            return
        }

        try {
            val method = session.javaClass.getMethod("stop")
            method.invoke(session)
            result.success(null)
        } catch (e: Exception) {
            result.error(
                "STOP_SESSION_ERROR",
                "Failed to stop stream session: ${e.message}",
                null
            )
        }
    }

    private fun handleCapturePhoto(call: MethodCall, result: Result) {
        val sessionId = call.argument<String>("sessionId")
        if (sessionId == null) {
            result.error("INVALID_ARGUMENT", "Invalid session ID.", null)
            return
        }

        val session = streamSessions[sessionId]
        if (session == null) {
            result.error(
                "SESSION_NOT_FOUND",
                "Stream session not found for ID: $sessionId",
                null
            )
            return
        }

        try {
            val formatStr = call.argument<String>("format") ?: "jpeg"
            val photoFormatClass = Class.forName("com.meta.wearable.mwdat.camera.PhotoFormat")
            val format = if (formatStr == "heic") {
                photoFormatClass.getField("HEIC").get(null)
            } else {
                photoFormatClass.getField("JPEG").get(null)
            }

            val method = session.javaClass.getMethod("capturePhoto", photoFormatClass)
            method.invoke(session, format)
            result.success(null)
        } catch (e: Exception) {
            result.error(
                "CAPTURE_PHOTO_ERROR",
                "Failed to capture photo: ${e.message}",
                null
            )
        }
    }

    private fun handleGetStreamSessionState(call: MethodCall, result: Result) {
        val sessionId = call.argument<String>("sessionId")
        if (sessionId == null) {
            result.error("INVALID_ARGUMENT", "Invalid session ID.", null)
            return
        }

        val session = streamSessions[sessionId]
        if (session == null) {
            result.error(
                "SESSION_NOT_FOUND",
                "Stream session not found for ID: $sessionId",
                null
            )
            return
        }

        try {
            val method = session.javaClass.getMethod("getState")
            val state = method.invoke(session)
            result.success(streamSessionStateToString(state))
        } catch (e: Exception) {
            result.error(
                "STATE_ERROR",
                "Failed to get stream session state: ${e.message}",
                null
            )
        }
    }

    private fun handleDisposeStreamSession(call: MethodCall, result: Result) {
        val sessionId = call.argument<String>("sessionId")
        if (sessionId == null) {
            result.error("INVALID_ARGUMENT", "Invalid session ID.", null)
            return
        }

        // Remove session reference
        streamSessions.remove(sessionId)

        // Clean up event channels for this session
        streamSessionStateChannels.remove(sessionId)?.setStreamHandler(null)
        streamSessionVideoFrameChannels.remove(sessionId)?.setStreamHandler(null)
        streamSessionErrorChannels.remove(sessionId)?.setStreamHandler(null)
        streamSessionPhotoDataChannels.remove(sessionId)?.setStreamHandler(null)
        streamSessionStateSinks.remove(sessionId)
        streamSessionVideoFrameSinks.remove(sessionId)
        streamSessionErrorSinks.remove(sessionId)
        streamSessionPhotoDataSinks.remove(sessionId)

        result.success(null)
    }

    // MARK: - Helpers

    private fun setupWearablesListeners() {
        // Listeners for registration state and device changes would be set up
        // using the native SDK's callback/listener mechanisms.
        // The exact API depends on the Meta Wearables DAT Android SDK version.
        // These listeners forward events to the Flutter event sinks.
        try {
            val wearables = wearablesInstance ?: return

            // Set up registration state listener
            val listenerClass = Class.forName(
                "com.meta.wearable.mwdat.core.Wearables\$RegistrationStateListener"
            )
            val registrationProxy = java.lang.reflect.Proxy.newProxyInstance(
                listenerClass.classLoader,
                arrayOf(listenerClass)
            ) { _, method, args ->
                if (method.name == "onRegistrationStateChanged" && args != null && args.isNotEmpty()) {
                    val stateStr = registrationStateToString(args[0])
                    activity?.runOnUiThread {
                        registrationStateSink?.success(stateStr)
                    }
                }
                null
            }

            wearables.javaClass
                .getMethod("addRegistrationStateListener", listenerClass)
                .invoke(wearables, registrationProxy)

            // Set up devices listener
            val devicesListenerClass = Class.forName(
                "com.meta.wearable.mwdat.core.Wearables\$DevicesListener"
            )
            val devicesProxy = java.lang.reflect.Proxy.newProxyInstance(
                devicesListenerClass.classLoader,
                arrayOf(devicesListenerClass)
            ) { _, method, args ->
                if (method.name == "onDevicesChanged" && args != null && args.isNotEmpty()) {
                    val devices = args[0] as? List<*> ?: emptyList<Any>()
                    val deviceList = devices.map { device ->
                        mapOf(
                            "identifier" to device.toString(),
                            "name" to null
                        )
                    }
                    activity?.runOnUiThread {
                        devicesSink?.success(deviceList)
                    }
                }
                null
            }

            wearables.javaClass
                .getMethod("addDevicesListener", devicesListenerClass)
                .invoke(wearables, devicesProxy)

        } catch (e: Exception) {
            // Listener setup failed - SDK API may differ from expected.
            // Plugin will still work for method calls but won't receive
            // streaming registration/device updates.
        }
    }

    private fun setupStreamSessionEventChannels(sessionId: String, session: Any) {
        val binaryMessenger = messenger ?: return

        // State event channel
        val stateChannel = EventChannel(
            binaryMessenger,
            "meta_dat/stream_session/$sessionId/state"
        )
        stateChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                streamSessionStateSinks[sessionId] = events
            }

            override fun onCancel(arguments: Any?) {
                streamSessionStateSinks[sessionId] = null
            }
        })
        streamSessionStateChannels[sessionId] = stateChannel

        // Video frame event channel
        val videoFrameChannel = EventChannel(
            binaryMessenger,
            "meta_dat/stream_session/$sessionId/video_frame"
        )
        videoFrameChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                streamSessionVideoFrameSinks[sessionId] = events
            }

            override fun onCancel(arguments: Any?) {
                streamSessionVideoFrameSinks[sessionId] = null
            }
        })
        streamSessionVideoFrameChannels[sessionId] = videoFrameChannel

        // Error event channel
        val errorChannel = EventChannel(
            binaryMessenger,
            "meta_dat/stream_session/$sessionId/error"
        )
        errorChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                streamSessionErrorSinks[sessionId] = events
            }

            override fun onCancel(arguments: Any?) {
                streamSessionErrorSinks[sessionId] = null
            }
        })
        streamSessionErrorChannels[sessionId] = errorChannel

        // Photo data event channel
        val photoDataChannel = EventChannel(
            binaryMessenger,
            "meta_dat/stream_session/$sessionId/photo_data"
        )
        photoDataChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                streamSessionPhotoDataSinks[sessionId] = events
            }

            override fun onCancel(arguments: Any?) {
                streamSessionPhotoDataSinks[sessionId] = null
            }
        })
        streamSessionPhotoDataChannels[sessionId] = photoDataChannel

        // Subscribe to session callbacks via reflection
        try {
            // Set up state listener
            val stateListenerClass = Class.forName(
                "com.meta.wearable.mwdat.camera.StreamSession\$StateListener"
            )
            val stateProxy = java.lang.reflect.Proxy.newProxyInstance(
                stateListenerClass.classLoader,
                arrayOf(stateListenerClass)
            ) { _, method, args ->
                if (method.name == "onStateChanged" && args != null && args.isNotEmpty()) {
                    val stateStr = streamSessionStateToString(args[0])
                    activity?.runOnUiThread {
                        streamSessionStateSinks[sessionId]?.success(stateStr)
                    }
                }
                null
            }
            session.javaClass
                .getMethod("addStateListener", stateListenerClass)
                .invoke(session, stateProxy)

            // Set up video frame listener
            val frameListenerClass = Class.forName(
                "com.meta.wearable.mwdat.camera.StreamSession\$VideoFrameListener"
            )
            val frameProxy = java.lang.reflect.Proxy.newProxyInstance(
                frameListenerClass.classLoader,
                arrayOf(frameListenerClass)
            ) { _, method, args ->
                if (method.name == "onVideoFrame" && args != null && args.isNotEmpty()) {
                    try {
                        val videoFrame = args[0]
                        val dataMethod = videoFrame.javaClass.getMethod("getData")
                        val widthMethod = videoFrame.javaClass.getMethod("getWidth")
                        val heightMethod = videoFrame.javaClass.getMethod("getHeight")
                        val timestampMethod = videoFrame.javaClass.getMethod("getTimestamp")

                        val data = dataMethod.invoke(videoFrame) as ByteArray
                        val width = widthMethod.invoke(videoFrame) as Int
                        val height = heightMethod.invoke(videoFrame) as Int
                        val timestamp = timestampMethod.invoke(videoFrame) as Long

                        val frameData = mapOf(
                            "data" to data,
                            "width" to width,
                            "height" to height,
                            "timestamp" to timestamp
                        )

                        activity?.runOnUiThread {
                            streamSessionVideoFrameSinks[sessionId]?.success(frameData)
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("MetaDatPlugin", "Video frame processing error", e)
                    }
                }
                null
            }
            session.javaClass
                .getMethod("addVideoFrameListener", frameListenerClass)
                .invoke(session, frameProxy)

            // Set up error listener
            val errorListenerClass = Class.forName(
                "com.meta.wearable.mwdat.camera.StreamSession\$ErrorListener"
            )
            val errorProxy = java.lang.reflect.Proxy.newProxyInstance(
                errorListenerClass.classLoader,
                arrayOf(errorListenerClass)
            ) { _, method, args ->
                if (method.name == "onError" && args != null && args.isNotEmpty()) {
                    val errorStr = streamSessionErrorToString(args[0])
                    activity?.runOnUiThread {
                        streamSessionErrorSinks[sessionId]?.success(errorStr)
                    }
                }
                null
            }
            session.javaClass
                .getMethod("addErrorListener", errorListenerClass)
                .invoke(session, errorProxy)

            // Set up photo data listener
            val photoListenerClass = Class.forName(
                "com.meta.wearable.mwdat.camera.StreamSession\$PhotoDataListener"
            )
            val photoProxy = java.lang.reflect.Proxy.newProxyInstance(
                photoListenerClass.classLoader,
                arrayOf(photoListenerClass)
            ) { _, method, args ->
                if (method.name == "onPhotoData" && args != null && args.isNotEmpty()) {
                    try {
                        val photoData = args[0]
                        val dataMethod = photoData.javaClass.getMethod("getData")
                        val data = dataMethod.invoke(photoData) as ByteArray

                        val photoMap = mapOf(
                            "data" to data,
                            "format" to "jpeg"
                        )

                        activity?.runOnUiThread {
                            streamSessionPhotoDataSinks[sessionId]?.success(photoMap)
                        }
                    } catch (e: Exception) {
                        android.util.Log.e("MetaDatPlugin", "Photo data processing error", e)
                    }
                }
                null
            }
            session.javaClass
                .getMethod("addPhotoDataListener", photoListenerClass)
                .invoke(session, photoProxy)

        } catch (e: Exception) {
            // Session listener setup failed - SDK API may differ from expected.
        }
    }

    // MARK: - State Conversion Helpers

    private fun registrationStateToString(state: Any?): String {
        return when (state?.toString()) {
            "REGISTERING", "registering" -> "registering"
            "REGISTERED", "registered" -> "registered"
            "UNREGISTERING", "unregistering" -> "unregistering"
            else -> "unregistered"
        }
    }

    private fun streamSessionStateToString(state: Any?): String {
        return when (state?.toString()) {
            "STOPPED", "stopped" -> "stopped"
            "WAITING_FOR_DEVICE", "waitingForDevice" -> "waitingForDevice"
            "STARTING", "starting" -> "starting"
            "STREAMING", "streaming" -> "streaming"
            "STOPPING", "stopping" -> "stopping"
            "PAUSED", "paused" -> "paused"
            else -> "stopped"
        }
    }

    private fun streamSessionErrorToString(error: Any?): String {
        return when (error?.toString()) {
            "INTERNAL_ERROR", "internalError" -> "internalError"
            "DEVICE_NOT_FOUND", "deviceNotFound" -> "deviceNotFound"
            "DEVICE_NOT_CONNECTED", "deviceNotConnected" -> "deviceNotConnected"
            "TIMEOUT", "timeout" -> "timeout"
            "VIDEO_STREAMING_ERROR", "videoStreamingError" -> "videoStreamingError"
            "PERMISSION_DENIED", "permissionDenied" -> "permissionDenied"
            "HINGES_CLOSED", "hingesClosed" -> "hingesClosed"
            "THERMAL_CRITICAL", "thermalCritical" -> "thermalCritical"
            else -> "internalError"
        }
    }

    private fun permissionStatusToString(status: Any?): String {
        return when (status?.toString()) {
            "GRANTED", "granted" -> "granted"
            else -> "denied"
        }
    }
}
