package com.example.telecaller_app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.CallLog
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import android.util.Log
import androidx.core.content.ContextCompat
import android.Manifest
import android.content.pm.PackageManager

class PhoneCallService(private val context: Context) {

    private var callStartTime: Long = 0L
    private var eventSink: ((Map<String, Any>) -> Unit)? = null
    private var currentPhoneNumber: String? = null
    private var offhookOccurred: Boolean = false  // Track if OFFHOOK state was reached
    private val MIN_CALL_DURATION = 3  // Minimum 3 seconds to count as a real call (blocks 1-2 second fake durations)

    // Set the event listener callback for returning call events
    fun setEventSink(listener: (Map<String, Any>) -> Unit) {
        eventSink = listener
    }

    // Start making the call
    fun makeCall(phoneNumber: String) {
        // Check if the permission is granted before making the call
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
            Log.e("CALL", "Permission not granted for CALL_PHONE")
            return
        }

        try {
            currentPhoneNumber = phoneNumber
            val callIntent = Intent(Intent.ACTION_CALL)
            callIntent.data = Uri.parse("tel:$phoneNumber")
            callIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(callIntent)
            Log.d("CALL", "Call intent started for: $phoneNumber")

            // Send call started event
            eventSink?.invoke(mapOf(
                "event" to "callStarted",
                "phoneNumber" to phoneNumber
            ))

            // Register the call state listener
            registerCallStateListener()
        } catch (e: SecurityException) {
            Log.e("CALL", "SecurityException: Permission denied for making call", e)
        } catch (e: Exception) {
            Log.e("CALL", "Error making call: ${e.message}", e)
        }
    }

    // Register a listener to detect when the call state changes (answered, ended, ringing)
    private fun registerCallStateListener() {
        val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

        telephonyManager.listen(object : PhoneStateListener() {
            override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                super.onCallStateChanged(state, phoneNumber)

                when (state) {
                    TelephonyManager.CALL_STATE_OFFHOOK -> {
                        // Call has been answered - start tracking duration
                        callStartTime = System.currentTimeMillis()
                        offhookOccurred = true  // Mark that OFFHOOK occurred
                        Log.d("CALL", "Call Answered - OFFHOOK occurred.")
                        
                        // Send call answered event to Flutter
                        eventSink?.invoke(mapOf(
                            "event" to "callAnswered",
                            "phoneNumber" to (currentPhoneNumber ?: phoneNumber ?: "")
                        ))
                    }

                    TelephonyManager.CALL_STATE_IDLE -> {
                        // Call has ended
                        // Only show duration if OFFHOOK occurred AND call log duration > 0
                        if (offhookOccurred && callStartTime > 0) {
                            // Fetch from call log for accurate duration validation
                            val callLogDuration = getCallDurationFromCallLog(currentPhoneNumber ?: phoneNumber)
                            
                            if (callLogDuration > 0) {
                                // Block fake 1-2 second durations even if call log says otherwise
                                val finalDuration = if (callLogDuration < MIN_CALL_DURATION) {
                                    Log.d("CALL", "Call Ended - Duration: 0s (call log duration $callLogDuration < $MIN_CALL_DURATION seconds, blocked fake duration)")
                                    0
                                } else {
                                    Log.d("CALL", "Call Ended - Duration: ${callLogDuration}s (from call log)")
                                    callLogDuration
                                }

                                // Send the call ended event with validated duration to Flutter
                                eventSink?.invoke(mapOf(
                                    "event" to "callEnded",
                                    "phoneNumber" to (currentPhoneNumber ?: phoneNumber ?: ""),
                                    "duration" to finalDuration
                                ))
                            } else {
                                // Call log shows 0 duration - call was not answered or was cancelled
                                Log.d("CALL", "Call Ended - Duration: 0s (call log duration is 0, call was not answered or cancelled)")
                                eventSink?.invoke(mapOf(
                                    "event" to "callEnded",
                                    "phoneNumber" to (currentPhoneNumber ?: phoneNumber ?: ""),
                                    "duration" to 0
                                ))
                            }
                            callStartTime = 0L
                            offhookOccurred = false
                        } else {
                            // Call ended but was never answered (missed/rejected/cancelled - no OFFHOOK)
                            Log.d("CALL", "Call Ended - Duration: 0s (missed/rejected/cancelled - offhookOccurred=$offhookOccurred, callStartTime=$callStartTime)")
                            eventSink?.invoke(mapOf(
                                "event" to "callEnded",
                                "phoneNumber" to (currentPhoneNumber ?: phoneNumber ?: ""),
                                "duration" to 0
                            ))
                        }
                        currentPhoneNumber = null
                    }

                    TelephonyManager.CALL_STATE_RINGING -> {
                        Log.d("CALL", "Phone ringing.")
                        // Send call ringing event
                        eventSink?.invoke(mapOf(
                            "event" to "callRinging",
                            "phoneNumber" to (currentPhoneNumber ?: phoneNumber ?: "")
                        ))
                    }
                }
            }
        }, PhoneStateListener.LISTEN_CALL_STATE)
    }

    // Fetch the last call duration from the call log for the given phone number
    // Returns the duration in seconds, or 0 if not found or permission denied
    private fun getCallDurationFromCallLog(phoneNumber: String?): Int {
        if (phoneNumber == null) {
            return 0
        }

        // Check permission first
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CALL_LOG) 
            != PackageManager.PERMISSION_GRANTED) {
            Log.d("CALL", "READ_CALL_LOG permission not granted, cannot validate call duration")
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
                    Log.d("CALL", "Fetched duration from call log: $duration seconds for $phoneNumber")
                    it.close()
                    return duration
                }
                it.close()
            }
        } catch (e: Exception) {
            Log.e("CALL", "Error reading call log: ${e.message}")
        }

        return 0
    }
}
