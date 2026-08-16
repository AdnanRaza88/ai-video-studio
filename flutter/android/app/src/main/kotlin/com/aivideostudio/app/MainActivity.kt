package com.aivideostudio.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val methodChannelName = "com.aivideostudio.app/native"
    private val eventChannelName = "com.aivideostudio.app/progress"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getDeviceCapabilities" -> {
                        // TODO: real RAM / GPU / NNAPI / Vulkan detection
                        result.success(mapOf(
                            "ramMb" to 0,
                            "hasVulkan" to false,
                            "androidVersion" to android.os.Build.VERSION.SDK_INT
                        ))
                    }
                    "ping" -> result.success("pong")
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, eventChannelName)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    // TODO: stream generation progress from native workers
                }
                override fun onCancel(arguments: Any?) {}
            })
    }
}
