package com.example.telecaller_app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import android.util.Log
import androidx.core.content.ContextCompat
import android.Manifest
import android.content.pm.PackageManager

class PhoneCallService(private val context: Context) {

    private var callAnswerTime: Long = 0L  // When call was answered (OFFHOOK)
    private var eventSink: ((Map<String, Any>) -> Unit)? = null
    private var currentPhoneNumber: String? = null
    private var offhookOccurred: Boolean = false  // Track if OFFHOOK state was reached
    private val MIN_CALL_DURATION = 3  // Minimum 3 seconds to count as a real call
    private var phoneStateListener: PhoneStateListener? = null  // Keep reference to unregister later
    private var telephonyManager: TelephonyManager? = null

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
            callAnswerTime = 0L  // Reset answer time
            offhookOccurred = false  // Reset offhook flag
            
            // IMPORTANT: Register listener BEFORE starting the call to catch OFFHOOK event
            registerCallStateListener()
            
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
        } catch (e: SecurityException) {
            Log.e("CALL", "SecurityException: Permission denied for making call", e)
        } catch (e: Exception) {
            Log.e("CALL", "Error making call: ${e.message}", e)
        }
    }

    // Register a listener to detect when the call state changes (answered, ended, ringing)
    private fun registerCallStateListener() {
        // Unregister previous listener if it exists
        if (phoneStateListener != null && telephonyManager != null) {
            telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_NONE)
            Log.d("CALL", "Unregistered previous phone state listener")
        }

        telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

        phoneStateListener = object : PhoneStateListener() {
            override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                super.onCallStateChanged(state, phoneNumber)

                when (state) {
                    TelephonyManager.CALL_STATE_OFFHOOK -> {
                        // Call has been answered - record the exact time
                        callAnswerTime = System.currentTimeMillis()
                        offhookOccurred = true  // Mark that OFFHOOK occurred
                        Log.d("CALL", "Call Answered - OFFHOOK occurred")
                        Log.d("CALL", "  - Answer time: $callAnswerTime")
                        
                        // Send call answered event to Flutter
                        eventSink?.invoke(mapOf(
                            "event" to "callAnswered",
                            "phoneNumber" to (currentPhoneNumber ?: phoneNumber ?: "")
                        ))
                    }

                    TelephonyManager.CALL_STATE_IDLE -> {
                        // Call has ended - calculate duration from PhoneStateListener timestamps
                        Log.d("CALL", "Call Ended - IDLE state")
                        
                        if (offhookOccurred && callAnswerTime > 0) {
                            // Calculate duration from PhoneStateListener timestamps (ONLY source)
                            val endTime = System.currentTimeMillis()
                            val durationMs = endTime - callAnswerTime
                            val durationSeconds = (durationMs / 1000).toInt()
                            
                            Log.d("CALL", "Duration Calculation:")
                            Log.d("CALL", "  - End time: $endTime")
                            Log.d("CALL", "  - Answer time: $callAnswerTime")
                            Log.d("CALL", "  - Duration (ms): $durationMs")
                            Log.d("CALL", "  - Duration (seconds): $durationSeconds")
                            
                            if (durationSeconds >= MIN_CALL_DURATION) {
                                Log.d("CALL", "Call Ended - Duration: ${durationSeconds}s")
                                
                                // Send the call ended event with duration
                                eventSink?.invoke(mapOf(
                                    "event" to "callEnded",
                                    "phoneNumber" to (currentPhoneNumber ?: phoneNumber ?: ""),
                                    "duration" to durationSeconds
                                ))
                            } else {
                                // Duration too short (< 3 seconds) - likely a fake/test call
                                Log.d("CALL", "Call Ended - Duration: 0s (blocked - duration $durationSeconds < $MIN_CALL_DURATION seconds)")
                                eventSink?.invoke(mapOf(
                                    "event" to "callEnded",
                                    "phoneNumber" to (currentPhoneNumber ?: phoneNumber ?: ""),
                                    "duration" to 0
                                ))
                            }
                        } else {
                            // Call ended but was never answered (missed/rejected/cancelled)
                            Log.d("CALL", "Call Ended - Duration: 0s (call was not answered)")
                            eventSink?.invoke(mapOf(
                                "event" to "callEnded",
                                "phoneNumber" to (currentPhoneNumber ?: phoneNumber ?: ""),
                                "duration" to 0
                            ))
                        }
                        
                        // Reset state and unregister listener
                        callAnswerTime = 0L
                        offhookOccurred = false
                        currentPhoneNumber = null
                        if (telephonyManager != null) {
                            telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_NONE)
                            Log.d("CALL", "Unregistered phone state listener after call ended")
                        }
                    }

                    TelephonyManager.CALL_STATE_RINGING -> {
                        Log.d("CALL", "Phone ringing")
                        // Send call ringing event
                        eventSink?.invoke(mapOf(
                            "event" to "callRinging",
                            "phoneNumber" to (currentPhoneNumber ?: phoneNumber ?: "")
                        ))
                    }
                }
            }
        }

        // Register the listener
        telephonyManager?.listen(phoneStateListener, PhoneStateListener.LISTEN_CALL_STATE)
        Log.d("CALL", "Registered phone state listener")
    }
}
