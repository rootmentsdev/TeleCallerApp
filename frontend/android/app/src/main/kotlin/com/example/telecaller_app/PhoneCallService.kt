package com.example.telecaller_app

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.CallLog
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import android.util.Log
import androidx.core.app.ActivityCompat
import android.Manifest
import android.content.pm.PackageManager

class PhoneCallService(private val context: Context) {

    private var callStartTime: Long = 0L
    private var eventSink: ((Int) -> Unit)? = null

    // Set the event listener callback for returning the call duration
    fun setEventSink(listener: (Int) -> Unit) {
        eventSink = listener
    }

    // Start making the call
    fun makeCall(phoneNumber: String) {
        // Check if the permission is granted before making the call
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.CALL_PHONE) != PackageManager.PERMISSION_GRANTED) {
            Log.e("CALL", "Permission not granted for CALL_PHONE")
            return
        }

        val callIntent = Intent(Intent.ACTION_CALL)
        callIntent.data = Uri.parse("tel:$phoneNumber")
        callIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(callIntent)

        // Register the call state listener
        registerCallStateListener()
    }

    // Register a listener to detect when the call state changes (answered, ended, ringing)
    private fun registerCallStateListener() {
        val telephonyManager = context.getSystemService(Context.TELEPHONY_SERVICE) as TelephonyManager

        telephonyManager.listen(object : PhoneStateListener() {
            override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                super.onCallStateChanged(state, phoneNumber)

                when (state) {
                    TelephonyManager.CALL_STATE_OFFHOOK -> {
                        // Call has been answered
                        callStartTime = System.currentTimeMillis()
                        Log.d("CALL", "Call Answered.")
                    }

                    TelephonyManager.CALL_STATE_IDLE -> {
                        // Call has ended
                        if (callStartTime > 0) {
                            val durationSeconds = ((System.currentTimeMillis() - callStartTime) / 1000).toInt()
                            Log.d("CALL", "Call Ended. Duration: $durationSeconds seconds")

                            // Send the call duration to Flutter via eventSink
                            eventSink?.invoke(durationSeconds)
                            callStartTime = 0L

                            // Optionally fetch the call log for further details (optional)
                            getCallDurationFromCallLog(phoneNumber)
                        }
                    }

                    TelephonyManager.CALL_STATE_RINGING -> {
                        Log.d("CALL", "Phone ringing.")
                    }
                }
            }
        }, PhoneStateListener.LISTEN_CALL_STATE)
    }

    // Fetch the last call duration from the call log for the given phone number
    private fun getCallDurationFromCallLog(phoneNumber: String?) {
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
                Log.d("CALL", "Fetched duration from call log: $duration seconds")

                // Send this duration to Flutter via eventSink
                eventSink?.invoke(duration)
            }
            it.close()
        }
    }
}
