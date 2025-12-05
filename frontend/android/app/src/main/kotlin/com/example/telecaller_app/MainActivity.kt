package com.example.telecaller_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val METHOD_CHANNEL = "com.telecaller_app/phone"
    private val EVENT_CHANNEL = "com.telecaller_app/phone_events"

    private lateinit var phoneCallService: PhoneCallService
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        phoneCallService = PhoneCallService(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "callPhone") {
                    val phoneNumber = call.argument<String>("phoneNumber") ?: ""
                    phoneCallService.setEventSink { duration ->
                        eventSink?.success(
                            mapOf(
                                "event" to "callEnded",
                                "duration" to duration,
                                "phoneNumber" to phoneNumber
                            )
                        )
                    }
                    phoneCallService.makeCall(phoneNumber)
                    result.success(true)
                } else {
                    result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }
}