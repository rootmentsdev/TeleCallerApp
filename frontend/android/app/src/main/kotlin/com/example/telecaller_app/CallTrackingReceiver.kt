package com.example.telecaller_app

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Handler
import android.os.Looper
import android.provider.CallLog
import android.telephony.TelephonyManager
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.UUID

class CallTrackingReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "CallTrackingReceiver"
        private var flutterEngine: FlutterEngine? = null

        // Session-based tracking
        private var currentSessionId: String? = null
        private var dialedPhoneNumber: String? = null  // Original dialed number
        private var isOutgoing = false
        private var callStartTime: Long = 0
        private var callAnswerTime: Long = 0
        private var previousState = TelephonyManager.CALL_STATE_IDLE
        private var offhookOccurred = false
        private var callEndProcessed = false
        private var earlyIdleIgnored = false  // Track if we ignored early IDLE

        fun setFlutterEngine(engine: FlutterEngine) {
            flutterEngine = engine
            Log.d(TAG, "FlutterEngine attached")
        }

        fun setOutgoingCallNumber(phoneNumber: String) {
            // Generate unique session ID for this call
            currentSessionId = UUID.randomUUID().toString()
            dialedPhoneNumber = phoneNumber
            isOutgoing = true
            callAnswerTime = 0
            previousState = TelephonyManager.CALL_STATE_IDLE
            offhookOccurred = false
            callEndProcessed = false
            earlyIdleIgnored = false
            
            Log.d(TAG, "📱 Outgoing call session: $currentSessionId, number: '$phoneNumber'")
        }
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        when (intent.action) {
            Intent.ACTION_NEW_OUTGOING_CALL -> {
                val rawNumber = intent.getStringExtra(Intent.EXTRA_PHONE_NUMBER)
                setOutgoingCallNumber(if (!rawNumber.isNullOrEmpty()) cleanNumber(rawNumber) else "Unknown")
                Log.d(TAG, "📤 Outgoing: $rawNumber -> $dialedPhoneNumber")
            }

            TelephonyManager.ACTION_PHONE_STATE_CHANGED -> {
                val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
                val phoneNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)

                Log.d(TAG, "State: $state, Phone: $phoneNumber, Session: $currentSessionId, OffhookOccurred: $offhookOccurred")

                when (state) {
                    TelephonyManager.EXTRA_STATE_RINGING -> {
                        if (!phoneNumber.isNullOrEmpty() && !isOutgoing) {
                            dialedPhoneNumber = cleanNumber(phoneNumber)
                        }
                        isOutgoing = false
                        previousState = TelephonyManager.CALL_STATE_RINGING
                        callStartTime = System.currentTimeMillis()
                        callEndProcessed = false
                        earlyIdleIgnored = false
                        
                        sendToFlutterMain(
                            "onCallStateChanged",
                            mapOf(
                                "state" to "ringing",
                                "phoneNumber" to (dialedPhoneNumber ?: "Unknown"),
                                "sessionId" to (currentSessionId ?: "")
                            )
                        )
                        Log.d(TAG, "📞 RINGING: $dialedPhoneNumber, Session: $currentSessionId")
                    }

                    TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                        if (previousState != TelephonyManager.CALL_STATE_OFFHOOK) {
                            offhookOccurred = true
                            previousState = TelephonyManager.CALL_STATE_OFFHOOK
                            callAnswerTime = System.currentTimeMillis()
                            earlyIdleIgnored = false  // Reset early IDLE flag when OFFHOOK occurs
                            
                            Log.d(TAG, "✅ OFFHOOK at: $callAnswerTime, Phone: $dialedPhoneNumber, Session: $currentSessionId")
                            
                            sendToFlutterMain(
                                "onCallStateChanged",
                                mapOf(
                                    "state" to "answered",
                                    "phoneNumber" to (dialedPhoneNumber ?: "Unknown"),
                                    "sessionId" to (currentSessionId ?: "")
                                )
                            )
                        }
                    }

                    TelephonyManager.EXTRA_STATE_IDLE -> {
                        // CRITICAL: Ignore early IDLE before OFFHOOK (Android quirk)
                        if (!offhookOccurred && !earlyIdleIgnored) {
                            earlyIdleIgnored = true
                            Log.d(TAG, "⚠️ EARLY IDLE (before OFFHOOK) - treating as cancelled call, Session: $currentSessionId")
                            
                            // Send cancelled call event
                            sendToFlutterMain(
                                "onCallEnded",
                                mapOf(
                                    "phoneNumber" to (dialedPhoneNumber ?: "Unknown"),
                                    "duration" to 0,
                                    "sessionId" to (currentSessionId ?: ""),
                                    "cancelled" to true
                                )
                            )
                            
                            // Reset session
                            currentSessionId = null
                            dialedPhoneNumber = null
                            offhookOccurred = false
                            callEndProcessed = true
                            return
                        }
                        
                        // Real call end: only process if OFFHOOK occurred
                        if (offhookOccurred && !callEndProcessed) {
                            callEndProcessed = true
                            Log.d(TAG, "🔴 IDLE - Real call ended, Session: $currentSessionId")
                            
                            // Send IDLE state change to Flutter so it can calculate duration from timestamps
                            sendToFlutterMain(
                                "onCallStateChanged",
                                mapOf(
                                    "state" to "idle",
                                    "phoneNumber" to (dialedPhoneNumber ?: "Unknown"),
                                    "sessionId" to (currentSessionId ?: "")
                                )
                            )
                            
                            // Then process the call end
                            processCallEnd(context)
                        }
                    }
                }
            }
        }
    }

    private fun processCallEnd(context: Context) {
        val sessionIdSnapshot = currentSessionId
        val phoneSnapshot = dialedPhoneNumber
        val outgoingSnapshot = isOutgoing
        val offhookSnapshot = offhookOccurred
        val answerTimeSnapshot = callAnswerTime
        val endTimeSnapshot = System.currentTimeMillis()

        // Reset state immediately to prevent duplicate processing
        currentSessionId = null
        dialedPhoneNumber = null
        isOutgoing = false
        callStartTime = 0
        callAnswerTime = 0
        previousState = TelephonyManager.CALL_STATE_IDLE
        offhookOccurred = false
        callEndProcessed = false  // Reset for next call

        Thread {
            try {
                var duration = 0
                var durationSource = "none"  // Track duration source: "timestamp" or "calllog"

                // RULE 1: Single Source of Truth - Use ONLY timestamp-based duration
                // Only calculate duration if call was answered (OFFHOOK occurred)
                if (offhookSnapshot && answerTimeSnapshot > 0) {
                    // Calculate duration from timestamps (OFFHOOK → IDLE)
                    // This is the ONLY source of truth
                    duration = ((endTimeSnapshot - answerTimeSnapshot) / 1000).toInt()
                    durationSource = "timestamp"  // Mark as timestamp-based
                    
                    Log.d(TAG, "✅ FINAL DURATION (timestamp-based): ${duration}s, Session: $sessionIdSnapshot, Phone: $phoneSnapshot")
                    
                    // Call log is secondary fallback only - verify but don't override
                    Thread.sleep(1500)  // Wait for call log to be written
                    val callLogDuration = fetchCallLogDurationWithRetry(
                        context,
                        phoneSnapshot,
                        answerTimeSnapshot,
                        endTimeSnapshot
                    )
                    
                    if (callLogDuration > 0) {
                        Log.d(TAG, "📋 Call log duration (for reference): ${callLogDuration}s (using timestamp: ${duration}s)")
                    } else {
                        Log.d(TAG, "📋 Call log not available (using timestamp: ${duration}s)")
                    }
                } else {
                    // Call was not answered - duration is 0
                    Log.d(TAG, "🔴 Call not answered (OFFHOOK not occurred): duration=0, Session: $sessionIdSnapshot")
                    durationSource = "none"
                }

                // Validate: Never emit with phone=null or Unknown
                if (phoneSnapshot.isNullOrEmpty() || phoneSnapshot == "Unknown") {
                    Log.w(TAG, "⚠️ SKIPPING: Invalid phone number: $phoneSnapshot, Session: $sessionIdSnapshot")
                    return@Thread
                }

                // Cache and send to Flutter using ORIGINAL dialed number
                CallResultCache.cacheCallResult(
                    context,
                    phoneSnapshot,
                    duration,
                    if (outgoingSnapshot) "outgoing" else "incoming"
                )

                // RULE 4: Emit ONLY ONCE with final duration
                // CRITICAL: Include durationSource flag so Flutter knows to lock only on timestamp
                sendToFlutterMain(
                    "onCallEnded",
                    mapOf(
                        "phoneNumber" to phoneSnapshot,
                        "duration" to duration,
                        "sessionId" to (sessionIdSnapshot ?: ""),
                        "cancelled" to false,
                        "durationSource" to durationSource  // "timestamp" or "calllog" or "none"
                    )
                )
                
                Log.d(TAG, "📤 FINAL onCallEnded to Flutter: phone=$phoneSnapshot, duration=$duration, source=$durationSource, session=$sessionIdSnapshot")
            } catch (e: Exception) {
                Log.e(TAG, "Error in processCallEnd: ${e.message}")
            }
        }.start()
    }

    private fun fetchCallLogDurationWithRetry(
        context: Context,
        phoneNumber: String?,
        answerTime: Long,
        endTime: Long
    ): Int {
        if (!hasCallLogPermission(context)) {
            Log.w(TAG, "No call log permission")
            return 0
        }

        // Time window: ±5 seconds around answer time
        val timeWindowStart = answerTime - 5000
        val timeWindowEnd = endTime + 5000

        // Retry up to 3 times with 500ms delay between retries
        for (attempt in 1..3) {
            try {
                val cursor = context.contentResolver.query(
                    CallLog.Calls.CONTENT_URI,
                    arrayOf(CallLog.Calls.NUMBER, CallLog.Calls.DURATION, CallLog.Calls.DATE),
                    null,
                    null,
                    "${CallLog.Calls.DATE} DESC LIMIT 5"
                )

                cursor?.use {
                    while (it.moveToNext()) {
                        val logNumber = cleanNumber(it.getString(0))
                        val logDuration = it.getInt(1)
                        val logDate = it.getLong(2)

                        // Match by cleaned number and time window
                        if (logNumber == cleanNumber(phoneNumber ?: "") &&
                            logDate in timeWindowStart..timeWindowEnd &&
                            logDuration > 0) {
                            Log.d(TAG, "✅ Found call log match (attempt $attempt): duration=$logDuration, number=$logNumber")
                            return logDuration
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error fetching call log (attempt $attempt): ${e.message}")
            }

            // Wait before retry
            if (attempt < 3) {
                Thread.sleep(500)
            }
        }

        Log.w(TAG, "⚠️ No matching call log found after 3 attempts")
        return 0
    }

    private fun hasCallLogPermission(context: Context): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.READ_CALL_LOG
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun cleanNumber(number: String?): String {
        if (number.isNullOrEmpty()) return "Unknown"
        
        val digits = number.replace(Regex("[^0-9]"), "")
        
        val tenDigits = when {
            digits.length == 12 && digits.startsWith("91") -> digits.substring(2)
            digits.length == 11 && digits.startsWith("0") -> digits.substring(1)
            digits.length >= 10 -> digits.takeLast(10)
            else -> return "Unknown"
        }
        
        return if (tenDigits.length == 10 && tenDigits.all { it.isDigit() }) {
            tenDigits
        } else {
            "Unknown"
        }
    }

    private fun sendToFlutterMain(method: String, args: Map<String, Any>) {
        Handler(Looper.getMainLooper()).post {
            flutterEngine?.let {
                try {
                    MethodChannel(
                        it.dartExecutor.binaryMessenger,
                        "com.telecaller.app/call_tracking"
                    ).invokeMethod(method, args)
                    Log.d(TAG, "📤 Flutter: $method")
                } catch (e: Exception) {
                    Log.e(TAG, "Flutter error: ${e.message}")
                }
            }
        }
    }
}
