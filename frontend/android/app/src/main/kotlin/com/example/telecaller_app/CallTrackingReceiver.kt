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
        private var offhookCaptured = false  // Guard: capture OFFHOOK timestamp only once
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
            offhookCaptured = false
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
                        // Capture OFFHOOK timestamp only once per call
                        if (!offhookCaptured) {
                            offhookCaptured = true
                            offhookOccurred = true
                            previousState = TelephonyManager.CALL_STATE_OFFHOOK
                            callAnswerTime = System.currentTimeMillis()
                            
                            if (!phoneNumber.isNullOrEmpty()) {
                                lastPhoneNumber = cleanNumber(phoneNumber)
                            }
                            
                            Log.d(TAG, "✅ OFFHOOK captured at: $callAnswerTime, Phone: $lastPhoneNumber")
                            
                            sendToFlutterMain(
                                "onCallStateChanged",
                                mapOf("state" to "answered", "phoneNumber" to (lastPhoneNumber ?: "Unknown"))
                            )
                        } else {
                            Log.d(TAG, "⚠️ Ignoring duplicate OFFHOOK event")
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

        // Reset state immediately
        lastPhoneNumber = null
        isOutgoing = false
        callStartTime = 0
        callAnswerTime = 0
        previousState = TelephonyManager.CALL_STATE_IDLE
        offhookOccurred = false
        offhookCaptured = false  // Reset guard for next call

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

                // Try to get duration from call log first (most reliable)
                if (number != null && number != "Unknown") {
                    duration = getDurationFromCallLog(context, number)
                    if (duration > 0) {
                        Log.d(TAG, "✅ Got duration from call log: $number, duration=${duration}s")
                    } else if (offhookSnapshot) {
                        // If call log didn't have duration but call was answered, retry after 2 seconds
                        Log.w(TAG, "⏳ Duration still 0, retrying call log read after 2 seconds...")
                        Thread.sleep(2000)
                        duration = getDurationFromCallLog(context, number)
                        if (duration > 0) {
                            Log.d(TAG, "✅ Got duration on retry: $number, duration=${duration}s")
                        }
                    }
                }

                // If call log didn't have duration but call was answered, calculate from timestamps
                if (duration == 0 && offhookSnapshot && answerTimeSnapshot > 0) {
                    // Call was answered - calculate actual talk time (from answer to end)
                    // This excludes ringing time completely
                    duration = ((System.currentTimeMillis() - answerTimeSnapshot) / 1000).toInt()
                    Log.d(TAG, "✅ Calculated talk time: $number, duration=${duration}s (from answer to end, no ringing)")
                } else if (duration == 0) {
                    // Call was not answered - duration is 0
                    Log.d(TAG, "🔴 Call not answered or no duration found: duration=0")
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

    private fun getDurationFromCallLog(context: Context, phoneNumber: String?): Int {
        if (!hasCallLogPermission(context)) return 0
        if (phoneNumber == null || phoneNumber == "Unknown") return 0

        return try {
            // Try exact match first
            var cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(CallLog.Calls.DURATION, CallLog.Calls.DATE),
                "${CallLog.Calls.NUMBER} = ?",
                arrayOf(phoneNumber),
                "${CallLog.Calls.DATE} DESC"
            )

            var result = cursor?.use {
                if (it.moveToFirst()) {
                    val duration = it.getInt(it.getColumnIndexOrThrow(CallLog.Calls.DURATION))
                    val date = it.getLong(it.getColumnIndexOrThrow(CallLog.Calls.DATE))
                    val ageMs = System.currentTimeMillis() - date
                    
                    // Only use if call is recent (within last 30 seconds)
                    if (ageMs < 30000) {
                        Log.d(TAG, "📞 Call log (exact match): duration=$duration, age=${ageMs}ms, phone=$phoneNumber")
                        duration
                    } else {
                        Log.w(TAG, "⚠️ Call log entry too old: ${ageMs}ms")
                        0
                    }
                } else {
                    Log.w(TAG, "⚠️ No exact call log entry found for $phoneNumber")
                    0
                }
            } ?: 0

            // If exact match didn't work, try with last 10 digits
            if (result == 0 && phoneNumber.length >= 10) {
                val last10 = phoneNumber.takeLast(10)
                Log.d(TAG, "Trying last 10 digits: $last10")
                
                cursor = context.contentResolver.query(
                    CallLog.Calls.CONTENT_URI,
                    arrayOf(CallLog.Calls.DURATION, CallLog.Calls.DATE, CallLog.Calls.NUMBER),
                    null,
                    null,
                    "${CallLog.Calls.DATE} DESC LIMIT 5"
                )

                result = cursor?.use {
                    while (it.moveToNext()) {
                        val logNumber = it.getString(it.getColumnIndexOrThrow(CallLog.Calls.NUMBER))
                        val logNumberLast10 = logNumber.replace(Regex("[^0-9]"), "").takeLast(10)
                        
                        if (logNumberLast10 == last10) {
                            val duration = it.getInt(it.getColumnIndexOrThrow(CallLog.Calls.DURATION))
                            val date = it.getLong(it.getColumnIndexOrThrow(CallLog.Calls.DATE))
                            val ageMs = System.currentTimeMillis() - date
                            
                            if (ageMs < 30000) {
                                Log.d(TAG, "📞 Call log (last 10 match): duration=$duration, age=${ageMs}ms, logNumber=$logNumber")
                                return@use duration
                            }
                        }
                    }
                    0
                } ?: 0
            }

            result
        } catch (e: Exception) {
            Log.e(TAG, "Call log error: ${e.message}")
            0
        }
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
