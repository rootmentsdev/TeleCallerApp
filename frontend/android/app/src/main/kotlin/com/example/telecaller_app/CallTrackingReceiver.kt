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

class CallTrackingReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "CallTrackingReceiver"
        private var flutterEngine: FlutterEngine? = null

        private var lastPhoneNumber: String? = null
        private var isOutgoing = false
        private var callStartTime: Long = 0
        private var callAnswerTime: Long = 0
        private var previousState = TelephonyManager.CALL_STATE_IDLE
        private var offhookOccurred = false
        private var callEndProcessed = false  // Prevent duplicate onCallEnded events

        fun setFlutterEngine(engine: FlutterEngine) {
            flutterEngine = engine
            Log.d(TAG, "FlutterEngine attached")
        }

        fun setOutgoingCallNumber(phoneNumber: String) {
            Log.d(TAG, "📱 Outgoing call: '$phoneNumber'")
            lastPhoneNumber = phoneNumber
            isOutgoing = true
            callAnswerTime = 0
            previousState = TelephonyManager.CALL_STATE_IDLE
            offhookOccurred = false
            callEndProcessed = false
        }
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        when (intent.action) {
            Intent.ACTION_NEW_OUTGOING_CALL -> {
                val rawNumber = intent.getStringExtra(Intent.EXTRA_PHONE_NUMBER)
                lastPhoneNumber = if (!rawNumber.isNullOrEmpty()) cleanNumber(rawNumber) else null
                isOutgoing = true
                callEndProcessed = false
                sendToFlutterMain(
                    "onCallStateChanged",
                    mapOf("state" to "outgoing", "phoneNumber" to (lastPhoneNumber ?: "Unknown"))
                )
                Log.d(TAG, "📤 Outgoing: $rawNumber -> $lastPhoneNumber")
            }

            TelephonyManager.ACTION_PHONE_STATE_CHANGED -> {
                val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
                val phoneNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)

                Log.d(TAG, "State: $state, Phone: $phoneNumber, Previous: $previousState")

                when (state) {
                    TelephonyManager.EXTRA_STATE_RINGING -> {
                        if (!phoneNumber.isNullOrEmpty()) {
                            lastPhoneNumber = cleanNumber(phoneNumber)
                        }
                        isOutgoing = false
                        previousState = TelephonyManager.CALL_STATE_RINGING
                        callStartTime = System.currentTimeMillis()
                        callEndProcessed = false
                        
                        sendToFlutterMain(
                            "onCallStateChanged",
                            mapOf("state" to "ringing", "phoneNumber" to (lastPhoneNumber ?: "Unknown"))
                        )
                        Log.d(TAG, "📞 RINGING: $lastPhoneNumber")
                    }

                    TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                        if (previousState != TelephonyManager.CALL_STATE_OFFHOOK) {
                            offhookOccurred = true
                            previousState = TelephonyManager.CALL_STATE_OFFHOOK
                            callAnswerTime = System.currentTimeMillis()
                            
                            if (!phoneNumber.isNullOrEmpty()) {
                                lastPhoneNumber = cleanNumber(phoneNumber)
                            }
                            
                            Log.d(TAG, "✅ OFFHOOK at: $callAnswerTime, Phone: $lastPhoneNumber")
                            
                            sendToFlutterMain(
                                "onCallStateChanged",
                                mapOf("state" to "answered", "phoneNumber" to (lastPhoneNumber ?: "Unknown"))
                            )
                        }
                    }

                    TelephonyManager.EXTRA_STATE_IDLE -> {
                        // Prevent duplicate processing
                        if (!callEndProcessed) {
                            callEndProcessed = true
                            Log.d(TAG, "🔴 IDLE - Call ended")
                            processCallEnd(context)
                        }
                    }
                }
            }
        }
    }

    private fun processCallEnd(context: Context) {
        val phoneSnapshot = lastPhoneNumber
        val outgoingSnapshot = isOutgoing
        val offhookSnapshot = offhookOccurred
        val answerTimeSnapshot = callAnswerTime
        val endTimeSnapshot = System.currentTimeMillis()

        // Reset state immediately
        lastPhoneNumber = null
        isOutgoing = false
        callStartTime = 0
        callAnswerTime = 0
        previousState = TelephonyManager.CALL_STATE_IDLE
        offhookOccurred = false

        Thread {
            try {
                // Initial wait for call log to be written
                Thread.sleep(2000)

                var number = phoneSnapshot
                if (number == null || number == "Unknown") {
                    number = getLatestCallNumber(context)
                    Log.d(TAG, "📱 Got number from call log: $number")
                }

                var duration = 0

                // Only calculate duration if call was answered
                if (offhookSnapshot && answerTimeSnapshot > 0) {
                    // Calculate duration from answer time (OFFHOOK) to end time (IDLE)
                    // This excludes ringing time
                    val calculatedDuration = ((endTimeSnapshot - answerTimeSnapshot) / 1000).toInt()
                    
                    if (calculatedDuration > 0) {
                        duration = calculatedDuration
                        Log.d(TAG, "✅ Call answered: duration=${duration}s (calculated from answer time)")
                    } else {
                        Log.w(TAG, "⚠️ Call answered but duration is 0")
                    }
                } else {
                    // Call was not answered - duration is 0
                    Log.d(TAG, "🔴 Call not answered: duration=0")
                }

                // Cache and send to Flutter
                CallResultCache.cacheCallResult(
                    context,
                    number ?: "Unknown",
                    duration,
                    if (outgoingSnapshot) "outgoing" else "incoming"
                )

                sendToFlutterMain(
                    "onCallEnded",
                    mapOf(
                        "phoneNumber" to (number ?: "Unknown"),
                        "duration" to duration
                    )
                )
            } catch (e: Exception) {
                Log.e(TAG, "Error in processCallEnd: ${e.message}")
            }
        }.start()
    }

    private fun getLatestCallNumber(context: Context): String? {
        if (!hasCallLogPermission(context)) return null

        return try {
            val cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(CallLog.Calls.NUMBER),
                null,
                null,
                "${CallLog.Calls.DATE} DESC"
            )

            cursor?.use {
                if (it.moveToFirst()) cleanNumber(it.getString(0)) else null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Number error: ${e.message}")
            null
        }
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
