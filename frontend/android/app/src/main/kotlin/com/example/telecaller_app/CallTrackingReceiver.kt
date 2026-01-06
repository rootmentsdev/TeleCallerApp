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
        private var callEndTime: Long = 0
        private var previousState = TelephonyManager.CALL_STATE_IDLE
        private var offhookOccurred = false
        private var callEndProcessed = false  // Prevent duplicate onCallEnded events
        private var currentCallSessionId: Long = 0  // Unique ID for each call to prevent cross-call collision

        fun setFlutterEngine(engine: FlutterEngine) {
            flutterEngine = engine
            Log.d(TAG, "FlutterEngine attached")
        }

        fun setOutgoingCallNumber(phoneNumber: String) {
            Log.d(TAG, "📱 Outgoing call: '$phoneNumber'")
            // Increment session ID to mark new call session
            currentCallSessionId = System.currentTimeMillis()
            lastPhoneNumber = phoneNumber
            isOutgoing = true
            callAnswerTime = 0
            callEndTime = 0
            previousState = TelephonyManager.CALL_STATE_IDLE
            offhookOccurred = false
            callEndProcessed = false  // Reset flag to allow processing of this new call
            Log.d(TAG, "🔄 Reset callEndProcessed for new outgoing call")
        }
        
        private fun startNewCallSession() {
            // Increment session ID to mark new call session
            currentCallSessionId = System.currentTimeMillis()
            Log.d(TAG, "🆔 New call session started: $currentCallSessionId")
        }
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        when (intent.action) {
            Intent.ACTION_NEW_OUTGOING_CALL -> {
                startNewCallSession()
                val rawNumber = intent.getStringExtra(Intent.EXTRA_PHONE_NUMBER)
                lastPhoneNumber = if (!rawNumber.isNullOrEmpty()) cleanNumber(rawNumber) else null
                isOutgoing = true
                callAnswerTime = 0
                callEndTime = 0
                callEndProcessed = false  // Reset flag to allow processing of this new call
                Log.d(TAG, "🔄 Reset callEndProcessed for ACTION_NEW_OUTGOING_CALL")
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
                        startNewCallSession()
                        if (!phoneNumber.isNullOrEmpty()) {
                            lastPhoneNumber = cleanNumber(phoneNumber)
                        }
                        isOutgoing = false
                        previousState = TelephonyManager.CALL_STATE_RINGING
                        callStartTime = System.currentTimeMillis()
                        callAnswerTime = 0
                        callEndTime = 0
                        callEndProcessed = false  // Reset flag to allow processing of this new call
                        Log.d(TAG, "🔄 Reset callEndProcessed for RINGING state")
                        
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
                            callEndTime = System.currentTimeMillis()
                            Log.d(TAG, "🔴 IDLE - Call ended at: $callEndTime")
                            processCallEnd(context)
                        } else {
                            Log.w(TAG, "⚠️ IDLE event ignored - call end already processed")
                        }
                    }
                }
            }
        }
    }

    private fun processCallEnd(context: Context) {
        // Capture session ID and all state BEFORE resetting
        val sessionIdSnapshot = currentCallSessionId
        val phoneSnapshot = lastPhoneNumber
        val outgoingSnapshot = isOutgoing
        val offhookSnapshot = offhookOccurred
        val answerTimeSnapshot = callAnswerTime
        val endTimeSnapshot = callEndTime

        Log.d(TAG, "🔴 Processing call end for session: $sessionIdSnapshot")

        // Reset state immediately to allow new call to start
        // BUT keep callEndProcessed = true until processing completes
        lastPhoneNumber = null
        isOutgoing = false
        callStartTime = 0
        // DON'T reset callAnswerTime and callEndTime here - they're used in the thread
        // They will be reset when a new call starts
        previousState = TelephonyManager.CALL_STATE_IDLE
        offhookOccurred = false
        // Note: callEndProcessed stays true until processing completes or new call starts

        Thread {
            try {
                // CRITICAL: Validate session ID before sending event
                // If session ID changed, a new call started - discard this event
                if (sessionIdSnapshot != currentCallSessionId) {
                    Log.w(TAG, "⚠️ Session ID mismatch (old: $sessionIdSnapshot, current: $currentCallSessionId) - new call started, discarding old call end event")
                    return@Thread
                }

                var number = phoneSnapshot
                var duration = 0

                // Only fetch duration if call was answered
                if (offhookSnapshot && answerTimeSnapshot > 0) {
                    // CRITICAL: We MUST get duration from call log ONLY
                    // Call log DURATION field = actual answered call time (from when customer answered to call ended)
                    // This is EXACTLY what we want - only the answered call duration, NOT dialing time
                    // Calculated duration (OFFHOOK to IDLE) includes dialing time and is INACCURATE
                    // NEVER use calculated duration - only use call log DURATION field
                    
                    // Progressive retry strategy: Wait longer each time for call log to be written
                    // Android can take 5-20 seconds to write call log entries on some devices
                    val maxRetries = 15
                    var retryCount = 0
                    
                    while (duration == 0 && retryCount < maxRetries) {
                        // Progressive wait: 3s, 4s, 5s, 6s, 7s, etc. (up to 17s)
                        val waitTime = if (retryCount == 0) 3000 else (4000 + retryCount * 1000)
                        if (retryCount > 0) {
                            Log.d(TAG, "⏳ Retry #$retryCount: Waiting ${waitTime}ms for call log to be written...")
                            Thread.sleep(waitTime.toLong())
                        } else {
                            // First attempt: wait 3 seconds
                            Thread.sleep(3000)
                        }
                        
                        // Check session ID after wait
                        if (sessionIdSnapshot != currentCallSessionId) {
                            Log.w(TAG, "⚠️ Session ID changed during wait - new call started, discarding")
                            return@Thread
                        }
                        
                        // Try to get phone number from call log if we don't have it
                        if (number == null || number == "Unknown") {
                            val logNumber = getLatestCallNumber(context)
                            if (logNumber != null && logNumber != "Unknown") {
                                number = logNumber
                                Log.d(TAG, "📱 Got number from call log: $number")
                            }
                        }
                        
                        // PRIORITY 1: Try latest call log entry (works even without phone number)
                        duration = getDurationFromLatestCall(context, outgoingSnapshot)
                        if (duration > 0) {
                            Log.d(TAG, "✅ Got duration from latest call log: ${duration}s (attempt ${retryCount + 1})")
                            break
                        }
                        
                        // PRIORITY 2: Try by phone number if we have it
                        if (duration == 0 && number != null && number != "Unknown") {
                            duration = getDurationFromCallLog(context, number)
                            if (duration > 0) {
                                Log.d(TAG, "✅ Got duration by phone number: ${duration}s for $number (attempt ${retryCount + 1})")
                                break
                            }
                        }
                        
                        retryCount++
                    }
                    
                    // CRITICAL: NEVER use calculated duration - it includes dialing time and is INACCURATE
                    // We ONLY want answered call time (from when customer answered to call ended)
                    // Call log DURATION field provides exactly this - answered time only
                    // If call log is unavailable, duration MUST stay 0 - DO NOT calculate duration
                    if (duration == 0) {
                        Log.w(TAG, "⚠️ Could not read call duration from call log after $retryCount attempts. Call log may not be written yet or call was not answered. Duration will be 0 (NOT using calculated duration).")
                        // Duration stays 0 - ABSOLUTELY DO NOT use calculated duration
                        // Calculated duration = (endTime - answerTime) includes dialing time and is WRONG
                    } else {
                        Log.d(TAG, "✅ Final: $number, duration=${duration}s (from call log DURATION field - accurate answered time only, NO dialing time)")
                    }
                } else {
                    // Call was not answered - duration is 0
                    Log.d(TAG, "🔴 Call not answered: duration=0")
                }

                // Final validation: Check session ID one more time before sending
                if (sessionIdSnapshot != currentCallSessionId) {
                    Log.w(TAG, "⚠️ Session ID changed during processing - discarding event")
                    return@Thread
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
                        "duration" to duration,
                        "callType" to (if (outgoingSnapshot) "outgoing" else "incoming")
                    )
                )
                Log.d(TAG, "✅ Call end event sent for session: $sessionIdSnapshot")
                
                // Reset callEndProcessed AFTER sending event (allows next call to be processed)
                // But only if no new call has started (session ID hasn't changed)
                if (sessionIdSnapshot == currentCallSessionId) {
                    callEndProcessed = false
                    // Reset call times only if no new call started (they're already reset if new call started)
                    callAnswerTime = 0
                    callEndTime = 0
                    Log.d(TAG, "🔄 Reset callEndProcessed flag and call times - ready for next call")
                } else {
                    Log.d(TAG, "🔄 New call started (session changed) - callEndProcessed and call times already reset by new call")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error in processCallEnd: ${e.message}")
                // Reset flag and times on error too
                callEndProcessed = false
                callAnswerTime = 0
                callEndTime = 0
            }
        }.start()
    }

    private fun getDurationFromCallLog(context: Context, phoneNumber: String?): Int {
        if (!hasCallLogPermission(context)) {
            Log.w(TAG, "⚠️ No call log permission")
            return 0
        }
        if (phoneNumber == null || phoneNumber == "Unknown") {
            Log.w(TAG, "⚠️ Invalid phone number: $phoneNumber")
            return 0
        }

        return try {
            val cleanedNumber = cleanNumber(phoneNumber)
            Log.d(TAG, "🔍 Searching call log for: original=$phoneNumber, cleaned=$cleanedNumber")
            
            // Try multiple number formats to match call log entries
            val numberVariants = mutableListOf<String>()
            numberVariants.add(phoneNumber)
            numberVariants.add(cleanedNumber)
            
            // Add variants with country code
            if (cleanedNumber.length == 10) {
                numberVariants.add("91$cleanedNumber")
                numberVariants.add("0$cleanedNumber")
            }
            
            // Remove duplicates
            val uniqueVariants = numberVariants.distinct()
            Log.d(TAG, "🔍 Trying number variants: $uniqueVariants")
            
            val cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(CallLog.Calls.DURATION, CallLog.Calls.DATE, CallLog.Calls.NUMBER),
                null, // No filter - we'll check manually
                null,
                "${CallLog.Calls.DATE} DESC"
            )

            var foundDuration = 0
            cursor?.use {
                // Check first 5 most recent calls to find matching number
                var checkedCount = 0
                while (it.moveToNext() && checkedCount < 5) {
                    checkedCount++
                    val logNumber = it.getString(it.getColumnIndexOrThrow(CallLog.Calls.NUMBER))
                    val logNumberCleaned = cleanNumber(logNumber ?: "")
                    val duration = it.getInt(it.getColumnIndexOrThrow(CallLog.Calls.DURATION))
                    val date = it.getLong(it.getColumnIndexOrThrow(CallLog.Calls.DATE))
                    val ageMs = System.currentTimeMillis() - date
                    
                    Log.d(TAG, "📞 Checking call log entry: number=$logNumber, cleaned=$logNumberCleaned, duration=$duration, age=${ageMs}ms")
                    
                    // Check if this entry matches our phone number (any variant)
                    val matches = uniqueVariants.any { variant ->
                        val variantCleaned = cleanNumber(variant)
                        logNumberCleaned == variantCleaned || logNumber == variant
                    }
                    
                    // CRITICAL: Only use duration if call was answered (duration > 0 means call was answered)
                    // Call log DURATION = answered call time ONLY (from when customer answered to call ended)
                    // This does NOT include dialing time - it's exactly what we need
                    if (matches && ageMs < 90000 && duration > 0) { // Increased window to 90 seconds
                        Log.d(TAG, "✅ Match found: duration=$duration (answered time only), age=${ageMs}ms")
                        foundDuration = duration
                        break // Found match, exit loop
                    }
                }
                
                if (foundDuration == 0) {
                    Log.w(TAG, "⚠️ No matching call log entry found for $phoneNumber (checked $checkedCount entries)")
                }
            }
            
            foundDuration
        } catch (e: Exception) {
            Log.e(TAG, "Call log error: ${e.message}", e)
            0
        }
    }

    private fun getDurationFromLatestCall(context: Context, isOutgoing: Boolean): Int {
        if (!hasCallLogPermission(context)) {
            Log.w(TAG, "⚠️ No call log permission for latest call")
            return 0
        }

        return try {
            val cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(CallLog.Calls.DURATION, CallLog.Calls.DATE, CallLog.Calls.TYPE, CallLog.Calls.NUMBER),
                null,
                null,
                "${CallLog.Calls.DATE} DESC"
            )

            var foundDuration = 0
            cursor?.use {
                // Check first 10 most recent calls to find the most recent one with duration > 0
                var checkedCount = 0
                while (it.moveToNext() && checkedCount < 10) {
                    checkedCount++
                    val duration = it.getInt(it.getColumnIndexOrThrow(CallLog.Calls.DURATION))
                    val date = it.getLong(it.getColumnIndexOrThrow(CallLog.Calls.DATE))
                    val callType = it.getInt(it.getColumnIndexOrThrow(CallLog.Calls.TYPE))
                    val logNumber = it.getString(it.getColumnIndexOrThrow(CallLog.Calls.NUMBER))
                    val ageMs = System.currentTimeMillis() - date
                    val ageSeconds = ageMs / 1000
                    
                    // CRITICAL: Only use INCOMING or OUTGOING calls (not MISSED)
                    // Call type: 1=INCOMING, 2=OUTGOING, 3=MISSED
                    val isAnsweredCall = callType == CallLog.Calls.INCOMING_TYPE || callType == CallLog.Calls.OUTGOING_TYPE
                    
                    Log.d(TAG, "📞 Checking latest call log entry #$checkedCount: duration=$duration, age=${ageSeconds}s, type=$callType, number=$logNumber, isAnswered=$isAnsweredCall")
                    
                    // Use if call is recent (within last 300 seconds), duration > 0, and call was answered
                    // Increased window to 300 seconds to account for delayed call log writes on some devices
                    // Call log DURATION field = answered call time ONLY (from when customer answered to call ended)
                    // This does NOT include dialing time - it's exactly what we need
                    if (ageMs < 300000 && duration > 0 && isAnsweredCall) {
                        Log.d(TAG, "✅ Latest call log match: duration=$duration (answered time only - customer answered to call ended), age=${ageSeconds}s, type=$callType")
                        foundDuration = duration
                        break // Found valid duration, exit loop
                    } else {
                        if (!isAnsweredCall) {
                            Log.d(TAG, "⏭️ Skipping entry: type=$callType (missed call, not answered)")
                        } else if (duration == 0) {
                            Log.d(TAG, "⏭️ Skipping entry: duration=0 (call log still writing or not answered)")
                        } else {
                            Log.d(TAG, "⏭️ Skipping entry: age=${ageSeconds}s too old")
                        }
                    }
                }
                
                if (foundDuration == 0) {
                    Log.w(TAG, "⚠️ No recent call log entry with valid duration found (checked $checkedCount entries)")
                }
            }
            
            foundDuration
        } catch (e: Exception) {
            Log.e(TAG, "Latest call log error: ${e.message}", e)
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
