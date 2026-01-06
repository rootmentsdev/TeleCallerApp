package com.example.telecaller_app

import android.Manifest
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {

    private val METHOD_CHANNEL = "com.telecaller_app/phone"
    private val EVENT_CHANNEL = "com.telecaller_app/phone_events"
    private val CALL_PHONE_PERMISSION_REQUEST_CODE = 100
    private val PERMISSIONS_REQUEST = 200

    private lateinit var phoneCallService: PhoneCallService
    private var pendingPhoneNumber: String? = null
    private var eventSink: EventChannel.EventSink? = null

    private val PHONE_STATE_PERMISSION = Manifest.permission.READ_PHONE_STATE

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Initialize call tracking receiver with FlutterEngine
        CallTrackingReceiver.setFlutterEngine(flutterEngine)
        Log.d("MainActivity", "CallTrackingReceiver initialized with FlutterEngine")

        phoneCallService = PhoneCallService(this)

        // Set up event channel for call events
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    // Set the event sink in PhoneCallService
                    phoneCallService.setEventSink { event ->
                        eventSink?.success(event)
                    }
                    Log.d("MainActivity", "EventChannel listener attached")
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    Log.d("MainActivity", "EventChannel listener detached")
                }
            })

        // Set up method channel for making phone calls
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
                        result.success(false)
                    } else {
                        // Permission already granted, make the call
                        makePhoneCall(phoneNumber)
                        result.success(true)
                    }
                } else {
                    result.notImplemented()
                }
            }

        // Set up method channel for call tracking
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.telecaller.app/call_tracking")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCachedCallResult" -> {
                        val phoneNumber = call.argument<String>("phoneNumber") ?: ""
                        val cachedResult = CallResultCache.getCachedCallResult(this, phoneNumber)
                        result.success(cachedResult)
                    }
                    else -> result.notImplemented()
                }
            }

        // Request necessary permissions on startup
        ensurePermissions()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        if (requestCode == CALL_PHONE_PERMISSION_REQUEST_CODE) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                pendingPhoneNumber?.let { phoneNumber ->
                    makePhoneCall(phoneNumber)
                    pendingPhoneNumber = null
                }
            } else {
                Log.e("MainActivity", "CALL_PHONE permission denied by user")
            }
        }
    }

    private fun makePhoneCall(phoneNumber: String) {
        phoneCallService.makeCall(phoneNumber)
    }

    private fun ensurePermissions() {
        val neededPermissions = mutableListOf<String>()

        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
            neededPermissions.add(Manifest.permission.CALL_PHONE)
        }
        if (ContextCompat.checkSelfPermission(this, PHONE_STATE_PERMISSION) != PackageManager.PERMISSION_GRANTED) {
            neededPermissions.add(PHONE_STATE_PERMISSION)
        }

        if (neededPermissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(this, neededPermissions.toTypedArray(), PERMISSIONS_REQUEST)
        }
    }
}