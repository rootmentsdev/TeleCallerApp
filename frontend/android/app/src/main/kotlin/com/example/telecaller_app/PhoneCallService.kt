package com.example.telecaller_app

import android.content.Context
import android.content.SharedPreferences
import android.database.Cursor
import android.provider.CallLog
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import kotlinx.coroutines.*
import java.util.concurrent.TimeUnit

class PhoneCallService(private val context: Context) {
    private val prefs: SharedPreferences = context.getSharedPreferences("call_tracking", Context.MODE_PRIVATE)
    private val telephonyManager: TelephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager
    private var phoneStateListener: PhoneStateListener? = null
    private var callCheckJob: Job? = null
    private val scope = CoroutineScope(Dispatchers.IO + SupervisorJob())
    
    var onCallEnded: ((String, Int?) -> Unit)? = null // phoneNumber, duration in seconds
    
    companion object {
        private const val KEY_PHONE_NUMBER = "pending_phone_number"
        private const val KEY_START_TIME = "call_start_time"
        private const val KEY_LEAD_ID = "call_lead_id"
    }
    
    /**
     * Initiates a call and saves tracking information
     */
    fun makeCall(phoneNumber: String, leadId: String? = null) {
        // Save phone number and start time before launching dialer
        val startTime = System.currentTimeMillis()
        prefs.edit().apply {
            putString(KEY_PHONE_NUMBER, phoneNumber)
            putLong(KEY_START_TIME, startTime)
            putString(KEY_LEAD_ID, leadId)
            apply()
        }
        
        // Start listening to phone state changes
        startPhoneStateListener()
        
        // Start periodic check for call answered
        startCallCheck()
    }
    
    /**
     * Starts listening to phone state changes
     */
    private fun startPhoneStateListener() {
        if (phoneStateListener != null) return
        
        phoneStateListener = object : PhoneStateListener() {
            override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                when (state) {
                    TelephonyManager.CALL_STATE_IDLE -> {
                        // Call ended - query call log for duration
                        handleCallEnded()
                    }
                    TelephonyManager.CALL_STATE_OFFHOOK -> {
                        // Call answered or active
                    }
                    TelephonyManager.CALL_STATE_RINGING -> {
                        // Call ringing
                    }
                }
            }
        }
        
        if (ContextCompat.checkSelfPermission(context, android.Manifest.permission.READ_PHONE_STATE) 
            == PackageManager.PERMISSION_GRANTED) {
            telephonyManager.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE)
        }
    }
    
    /**
     * Starts periodic check (every 3 seconds) to detect when call is answered
     */
    private fun startCallCheck() {
        callCheckJob?.cancel()
        callCheckJob = scope.launch {
            while (isActive) {
                delay(3000L) // Check every 3 seconds
                
                val phoneNumber = prefs.getString(KEY_PHONE_NUMBER, null)
                if (phoneNumber != null) {
                    val duration = getCallDurationFromLog(phoneNumber)
                    if (duration != null && duration > 0) {
                        // Call was answered (duration > 0)
                        // Continue monitoring until call ends
                    }
                } else {
                    // No pending call, stop checking
                    cancel()
                }
            }
        }
    }
    
    /**
     * Handles call ended - queries call log with retry logic
     */
    private fun handleCallEnded() {
        scope.launch {
            val phoneNumber = prefs.getString(KEY_PHONE_NUMBER, null)
            if (phoneNumber == null) return@launch
            
            var duration: Int? = null
            var attempts = 0
            val maxAttempts = 3
            
            // Retry logic - query call log up to 3 times
            while (attempts < maxAttempts && duration == null) {
                delay((1000 * (attempts + 1)).toLong()) // Increasing delay: 1s, 2s, 3s
                duration = getCallDurationFromLog(phoneNumber)
                attempts++
            }
            
            // Only save duration if call was outgoing, answered (duration > 0), and ended
            val finalDuration = if (duration != null && duration > 0) duration else null
            
            // Clear tracking data
            clearTrackingData()
            
            // Stop monitoring
            stopMonitoring()
            
            // Notify callback
            android.util.Log.d("PhoneCallService", "Call ended - Phone: $phoneNumber, Duration: $finalDuration")
            onCallEnded?.invoke(phoneNumber, finalDuration)
        }
    }
    
    /**
     * Gets call duration from Call Log API
     * Returns duration in seconds (OFFHOOK to IDLE, excluding ringing)
     * Returns null if call not found or not answered
     */
    private fun getCallDurationFromLog(phoneNumber: String): Int? {
        android.util.Log.d("PhoneCallService", "getCallDurationFromLog: phoneNumber=$phoneNumber")
        if (ContextCompat.checkSelfPermission(context, android.Manifest.permission.READ_CALL_LOG) 
            != PackageManager.PERMISSION_GRANTED) {
            android.util.Log.w("PhoneCallService", "READ_CALL_LOG permission not granted")
            return null
        }
        
        val cleanedNumber = phoneNumber.replace(Regex("[^0-9+]"), "")
        android.util.Log.d("PhoneCallService", "Cleaned number: $cleanedNumber")
        val projection = arrayOf(
            CallLog.Calls.NUMBER,
            CallLog.Calls.DURATION,
            CallLog.Calls.TYPE,
            CallLog.Calls.DATE
        )
        
        val selection = "${CallLog.Calls.NUMBER} LIKE ? AND ${CallLog.Calls.TYPE} = ?"
        val selectionArgs = arrayOf("%$cleanedNumber%", CallLog.Calls.OUTGOING_TYPE.toString())
        val sortOrder = "${CallLog.Calls.DATE} DESC"
        
        var cursor: Cursor? = null
        try {
            cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                sortOrder
            )
            
            if (cursor != null && cursor.moveToFirst()) {
                val callDate = cursor.getLong(cursor.getColumnIndexOrThrow(CallLog.Calls.DATE))
                val startTime = prefs.getLong(KEY_START_TIME, 0)
                val duration = cursor.getInt(cursor.getColumnIndexOrThrow(CallLog.Calls.DURATION))
                val callNumber = cursor.getString(cursor.getColumnIndexOrThrow(CallLog.Calls.NUMBER))
                
                android.util.Log.d("PhoneCallService", "Found call: number=$callNumber, date=$callDate, duration=$duration")
                android.util.Log.d("PhoneCallService", "Start time: $startTime, time diff: ${kotlin.math.abs(callDate - startTime)}")
                
                // Check if this call matches our call (within 5 minutes of start time)
                val timeDiff = kotlin.math.abs(callDate - startTime)
                if (timeDiff < TimeUnit.MINUTES.toMillis(5)) {
                    android.util.Log.d("PhoneCallService", "Call matches! Duration: $duration seconds")
                    // Duration is in seconds, only return if > 0 (answered)
                    return if (duration > 0) duration else {
                        android.util.Log.d("PhoneCallService", "Call not answered (duration = 0)")
                        null
                    }
                } else {
                    android.util.Log.d("PhoneCallService", "Call time mismatch (diff: ${timeDiff}ms)")
                }
            } else {
                android.util.Log.d("PhoneCallService", "No call found in log")
            }
        } catch (e: Exception) {
            e.printStackTrace()
        } finally {
            cursor?.close()
        }
        
        return null
    }
    
    /**
     * Clears tracking data from SharedPreferences
     */
    private fun clearTrackingData() {
        prefs.edit().apply {
            remove(KEY_PHONE_NUMBER)
            remove(KEY_START_TIME)
            remove(KEY_LEAD_ID)
            apply()
        }
    }
    
    /**
     * Stops monitoring phone state and call checks
     */
    fun stopMonitoring() {
        callCheckJob?.cancel()
        callCheckJob = null
        
        phoneStateListener?.let {
            if (ContextCompat.checkSelfPermission(context, android.Manifest.permission.READ_PHONE_STATE) 
                == PackageManager.PERMISSION_GRANTED) {
                telephonyManager.listen(it, PhoneStateListener.LISTEN_NONE)
            }
        }
        phoneStateListener = null
    }
    
    /**
     * Recovers state from SharedPreferences (if app was killed during call)
     */
    fun recoverState() {
        val phoneNumber = prefs.getString(KEY_PHONE_NUMBER, null)
        if (phoneNumber != null) {
            // Resume monitoring
            startPhoneStateListener()
            startCallCheck()
        }
    }
    
    /**
     * Cleanup
     */
    fun cleanup() {
        stopMonitoring()
        scope.cancel()
    }
}

