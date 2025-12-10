package com.example.telecaller_app

import android.Manifest
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val METHOD_CHANNEL = "com.telecaller_app/phone"
    private val EVENT_CHANNEL = "com.telecaller_app/phone_events"
    private val CALL_PHONE_PERMISSION_REQUEST_CODE = 100

    private lateinit var phoneCallService: PhoneCallService
    private var eventSink: EventChannel.EventSink? = null
    private var pendingPhoneNumber: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        phoneCallService = PhoneCallService(this)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "callPhone") {
                    val phoneNumber = call.argument<String>("phoneNumber") ?: ""
                    
                    // Check permission first
                    if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) 
                        != PackageManager.PERMISSION_GRANTED) {
                        // Request permission
                        pendingPhoneNumber = phoneNumber
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(Manifest.permission.CALL_PHONE),
                            CALL_PHONE_PERMISSION_REQUEST_CODE
                        )
                        result.success(false) // Permission not granted yet
                    } else {
                        // Permission already granted, make the call
                        makePhoneCall(phoneNumber)
                        result.success(true)
                    }
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

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == CALL_PHONE_PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                // Permission granted, make the call
                pendingPhoneNumber?.let { phoneNumber ->
                    makePhoneCall(phoneNumber)
                    pendingPhoneNumber = null
                }
            } else {
                Log.e("CALL", "CALL_PHONE permission denied by user")
            }
        }
    }

    private fun makePhoneCall(phoneNumber: String) {
        phoneCallService.setEventSink { eventMap ->
            // Forward the event map directly to Flutter
            eventSink?.success(eventMap)
        }
        phoneCallService.makeCall(phoneNumber)
    }
}