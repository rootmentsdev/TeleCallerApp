package com.example.telecaller_app

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.CallLog
import android.telephony.TelephonyManager
import android.util.Log
import androidx.core.content.ContextCompat
import android.Manifest
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class CallTrackingReceiver : BroadcastReceiver() {
    companion object {
        private var flutterEngine: FlutterEngine? = null
        private var lastPhoneNumber: String? = null
        private var callAnswerTime: Long = 0
        private var previousState = TelephonyManager.CALL_STATE_IDLE
        private var isOutgoingCall = false
        private var outgoingCallStartTime: Long = 0
        private var offhookTime: Long = 0  // Track when OFFHOOK first occurred
        private var offhookOccurred: Boolean = false  // Track if OFFHOOK state was reached
        private const val TAG = "CallTrackingReceiver"
        private const val MIN_CALL_DURATION = 3  // Minimum 3 seconds to count as a real call (blocks 1-2 second fake durations)

        fun setFlutterEngine(engine: FlutterEngine) {
            flutterEngine = engine
            Log.d(TAG, "FlutterEngine set for call tracking")
        }
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (intent == null) return

        val action = intent.action
        Log.d(TAG, "onReceive called with action: $action")

        when (action) {
            "android.intent.action.PHONE_STATE" -> {
                handlePhoneState(intent)
            }
            "android.intent.action.NEW_OUTGOING_CALL" -> {
                handleOutgoingCall(intent)
            }
        }
    }

    private fun handlePhoneState(intent: Intent) {
        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
        val phoneNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)

        Log.d(TAG, "Phone state: $state, Phone: $phoneNumber, previousState: $previousState")

        when (state) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                lastPhoneNumber = phoneNumber
                previousState = TelephonyManager.CALL_STATE_RINGING
                Log.d(TAG, "📞 Incoming call RINGING from: $phoneNumber (timer NOT started)")
                sendToFlutter("onCallStateChanged", mapOf(
                    "phoneNumber" to (phoneNumber ?: "Unknown"),
                    "state" to "ringing"
                ))
            }
            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                if (previousState != TelephonyManager.CALL_STATE_OFFHOOK) {
                    offhookTime = System.currentTimeMillis()
                    offhookOccurred = true  // Mark that OFFHOOK occurred
                    previousState = TelephonyManager.CALL_STATE_OFFHOOK
                    Log.d(TAG, "✅ Call OFFHOOK - Waiting for actual audio connection at: $offhookTime")
                    
                    // For outgoing calls, delay timer start to detect actual answer
                    // For incoming calls, start timer immediately (user answered)
                    if (isOutgoingCall) {
                        // Delay 1.5 seconds to let audio connection establish
                        // Then set callAnswerTime to detect actual talking time
                        Thread {
                            Thread.sleep(1500)
                            if (previousState == TelephonyManager.CALL_STATE_OFFHOOK) {
                                callAnswerTime = System.currentTimeMillis()
                                Log.d(TAG, "📞 Outgoing call - Actual audio connection detected, timer STARTED at: $callAnswerTime")
                            }
                        }.start()
                    } else {
                        // Incoming call - start timer immediately
                        callAnswerTime = System.currentTimeMillis()
                        Log.d(TAG, "📞 Incoming call - Timer STARTED at: $callAnswerTime")
                    }
                    
                    sendToFlutter("onCallStateChanged", mapOf(
                        "phoneNumber" to (phoneNumber ?: lastPhoneNumber ?: "Unknown"),
                        "state" to "answered"
                    ))
                } else {
                    Log.d(TAG, "⚠️ OFFHOOK received again (duplicate), ignoring")
                }
            }
            TelephonyManager.EXTRA_STATE_IDLE -> {
                // Only show duration if OFFHOOK occurred AND call log duration > 0
                if (offhookOccurred && previousState == TelephonyManager.CALL_STATE_OFFHOOK) {
                    // Fetch call log duration to validate
                    val callLogDuration = getCallDurationFromCallLog(context, lastPhoneNumber)
                    
                    if (callLogDuration > 0) {
                        // Validate calculated duration as well
                        val endTime = System.currentTimeMillis()
                        var calculatedDuration = if (callAnswerTime > 0) {
                            ((endTime - callAnswerTime) / 1000).toInt()
                        } else {
                            0
                        }
                        
                        // Use call log duration as source of truth, but validate it
                        var finalDuration = callLogDuration
                        
                        // Block fake 1-2 second durations even if call log says otherwise
                        if (finalDuration < MIN_CALL_DURATION) {
                            finalDuration = 0
                            Log.d(TAG, "🔴 Call ENDED - Duration: 0s (call log duration $callLogDuration < $MIN_CALL_DURATION seconds, blocked fake duration)")
                        } else {
                            Log.d(TAG, "🔴 Call ENDED - Duration: ${finalDuration}s (from call log, calculated: ${calculatedDuration}s), Phone: $lastPhoneNumber, isOutgoing: $isOutgoingCall")
                        }
                        
                        sendToFlutter("onCallEnded", mapOf(
                            "phoneNumber" to (lastPhoneNumber ?: "Unknown"),
                            "duration" to finalDuration
                        ))
                    } else {
                        // Call log shows 0 duration - call was not answered or was cancelled
                        Log.d(TAG, "🔴 Call ENDED - Duration: 0s (call log duration is 0, call was not answered or cancelled)")
                        sendToFlutter("onCallEnded", mapOf(
                            "phoneNumber" to (lastPhoneNumber ?: "Unknown"),
                            "duration" to 0
                        ))
                    }
                } else {
                    // Missed, rejected, or cancelled call (no OFFHOOK = no answer)
                    Log.d(TAG, "🔴 Call ENDED - Duration: 0s (missed/rejected/cancelled - offhookOccurred=$offhookOccurred, previousState=$previousState, callAnswerTime=$callAnswerTime)")
                    sendToFlutter("onCallEnded", mapOf(
                        "phoneNumber" to (lastPhoneNumber ?: "Unknown"),
                        "duration" to 0
                    ))
                }
                lastPhoneNumber = null
                callAnswerTime = 0
                offhookTime = 0
                offhookOccurred = false
                previousState = TelephonyManager.CALL_STATE_IDLE
                isOutgoingCall = false
            }
        }
    }

    private fun handleOutgoingCall(intent: Intent) {
        val phoneNumber = intent.getStringExtra(Intent.EXTRA_PHONE_NUMBER)
        Log.d(TAG, "📤 Outgoing call initiated to: $phoneNumber")
        
        // Mark this as an outgoing call so we can adjust duration later
        isOutgoingCall = true
        
        // Store the phone number but DO NOT start the timer yet
        // Timer will start only when call state becomes OFFHOOK (call answered)
        lastPhoneNumber = phoneNumber
        callAnswerTime = 0 // Reset timer - will be set when call is answered
        previousState = TelephonyManager.CALL_STATE_IDLE // Not yet answered
        
        sendToFlutter("onCallStateChanged", mapOf(
            "phoneNumber" to (phoneNumber ?: "Unknown"),
            "state" to "outgoing"
        ))
    }

    private fun sendToFlutter(method: String, arguments: Map<String, Any>) {
        flutterEngine?.let {
            try {
                val channel = MethodChannel(it.dartExecutor.binaryMessenger, "com.telecaller.app/call_tracking")
                channel.invokeMethod(method, arguments)
                Log.d(TAG, "Sent to Flutter: $method with args: $arguments")
            } catch (e: Exception) {
                Log.e(TAG, "Error sending to Flutter: ${e.message}")
            }
        } ?: run {
            Log.w(TAG, "FlutterEngine not set, cannot send to Flutter")
        }
    }

    // Fetch call duration from call log for validation
    private fun getCallDurationFromCallLog(context: Context?, phoneNumber: String?): Int {
        if (context == null || phoneNumber == null) {
            return 0
        }

        // Check permission first
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CALL_LOG)
            != PackageManager.PERMISSION_GRANTED) {
            Log.d(TAG, "READ_CALL_LOG permission not granted, cannot validate call duration")
            return 0
        }

        try {
            val callLogUri = CallLog.Calls.CONTENT_URI
            val cursor = context.contentResolver.query(
                callLogUri,
                arrayOf(CallLog.Calls.DURATION, CallLog.Calls.NUMBER),
                CallLog.Calls.NUMBER + " = ?",
                arrayOf(phoneNumber),
                CallLog.Calls.DATE + " DESC" // Sort by the most recent call
            )

            cursor?.let {
                if (it.moveToFirst()) {
                    val duration = it.getInt(it.getColumnIndex(CallLog.Calls.DURATION))
                    Log.d(TAG, "Fetched duration from call log: $duration seconds for $phoneNumber")
                    it.close()
                    return duration
                }
                it.close()
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error reading call log: ${e.message}")
        }

        return 0
    }
}
