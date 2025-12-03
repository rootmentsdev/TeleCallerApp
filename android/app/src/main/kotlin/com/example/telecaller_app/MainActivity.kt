package com.example.telecaller_app

import android.content.Intent
import android.net.Uri
import android.Manifest
import android.content.pm.PackageManager
import android.telephony.TelephonyManager
import android.content.Context
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.telecaller_app/phone"
    private val EVENT_CHANNEL = "com.telecaller_app/phone_events"
    private val CALL_PHONE_PERMISSION = 100
    private val READ_PHONE_STATE_PERMISSION = 101
    private val READ_CALL_LOG_PERMISSION = 102
    private var pendingPhoneNumber: String? = null
    private var pendingResult: MethodChannel.Result? = null
    private var phoneCallService: PhoneCallService? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize PhoneCallService
        phoneCallService = PhoneCallService(this)
        phoneCallService?.onCallEnded = { phoneNumber, duration ->
            android.util.Log.d("MainActivity", "onCallEnded callback: phoneNumber=$phoneNumber, duration=$duration")
            // Send call ended event to Flutter
            val eventData = mapOf(
                "event" to "callEnded",
                "phoneNumber" to phoneNumber,
                "duration" to (duration ?: -1) // -1 means null/call not answered
            )
            android.util.Log.d("MainActivity", "Sending event to Flutter: $eventData")
            eventSink?.success(eventData)
        }
        
        // Recover state if app was killed during a call
        phoneCallService?.recoverState()
        
        // Method channel for making calls
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "callPhone" -> {
                    val phoneNumber = call.argument<String>("phoneNumber")
                    val leadId = call.argument<String>("leadId")
                    if (phoneNumber != null) {
                        makePhoneCall(phoneNumber, leadId, result)
                    } else {
                        result.error("INVALID_ARGUMENT", "Phone number is required", null)
                    }
                }
                "getCallState" -> {
                    getCallState(result)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        // Event channel for call events
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    private fun getCallState(result: MethodChannel.Result) {
        try {
            val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
            
            // Check permission
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) 
                != PackageManager.PERMISSION_GRANTED) {
                result.success("UNKNOWN")
                return
            }
            
            val callState = telephonyManager.callState
            val state = when (callState) {
                TelephonyManager.CALL_STATE_IDLE -> "IDLE"
                TelephonyManager.CALL_STATE_RINGING -> "RINGING"
                TelephonyManager.CALL_STATE_OFFHOOK -> "OFFHOOK"
                else -> "UNKNOWN"
            }
            result.success(state)
        } catch (e: Exception) {
            result.success("UNKNOWN")
        }
    }

    private fun makePhoneCall(phoneNumber: String, leadId: String?, result: MethodChannel.Result) {
        // Check if CALL_PHONE permission is granted
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) 
            != PackageManager.PERMISSION_GRANTED) {
            // Store the phone number and result for later use
            pendingPhoneNumber = phoneNumber
            pendingResult = result
            
            // Request permission
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.CALL_PHONE),
                CALL_PHONE_PERMISSION
            )
            return
        }

        // Permission already granted, make the call
        try {
            // Start call tracking before launching dialer
            phoneCallService?.makeCall(phoneNumber, leadId)
            
            val intent = Intent(Intent.ACTION_CALL)
            intent.data = Uri.parse("tel:$phoneNumber")
            startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            result.error("CALL_FAILED", "Failed to make call: ${e.message}", null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == CALL_PHONE_PERMISSION) {
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                // Permission granted, make the call with stored phone number
                pendingPhoneNumber?.let { phoneNumber ->
                    try {
                        // Start call tracking before launching dialer
                        phoneCallService?.makeCall(phoneNumber, null)
                        
                        val intent = Intent(Intent.ACTION_CALL)
                        intent.data = Uri.parse("tel:$phoneNumber")
                        startActivity(intent)
                        pendingResult?.success(true)
                    } catch (e: Exception) {
                        pendingResult?.error("CALL_FAILED", "Failed to make call: ${e.message}", null)
                    }
                }
            } else {
                // Permission denied
                pendingResult?.error("PERMISSION_DENIED", "Call phone permission was denied", null)
            }
            
            // Clear pending values
            pendingPhoneNumber = null
            pendingResult = null
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        phoneCallService?.cleanup()
    }
}
